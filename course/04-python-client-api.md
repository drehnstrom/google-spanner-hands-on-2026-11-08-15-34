<!-- course-title: Google Spanner: Hands-On -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Google Spanner: Hands-On

# Chapter 4: Developing Applications with the Python Client API

---

# Chapter 4: Objectives

- Develop robust Python applications using the Cloud Spanner client library
- Configure the Python client SDK and authenticate using service accounts
- Manage database sessions, pool sizing, and client life cycles effectively
- Implement read-write transactions using transaction runner helpers in Python
- Execute stale reads, single-use snapshots, and batched queries for read scale
- Handle transient errors, retry policies, and transaction aborts gracefully
- Build and test an operational Python application connected to Cloud Spanner

---

<!-- layout: navigation -->
# Chapter 4

- **Google Cloud Spanner Python SDK Setup and Authentication**
- Database Sessions, Connection Pools, and Life Cycles
- Executing Read-Write Transactions in Python
- Performing Snapshot Reads and Batched Reads
- Handling Errors, Retries, and Transaction Aborts
- Lab: Building a Python Application with the Cloud Spanner API

---

<!-- layout: 2-column -->
# Python SDK Architecture and Installation

### Package and gRPC Transport
- Install the official library via `pip install google-cloud-spanner`.
- Built on top of high-performance HTTP/2 gRPC channels and Protocol Buffers.
- Multiplexes concurrent database queries over persistent gRPC streaming channels.
- Maintains low-overhead binary serialization directly to Spanner frontends.

### Client Object Hierarchy
- **Client**: Represents the Google Cloud project credentials and gRPC connection settings.
- **Instance**: References a provisioned Spanner instance (`instance = client.instance("inst-id")`).
- **Database**: Binds to a database, managing sessions and transactions (`db = instance.database("db-id")`).
- Thread-safe architecture designed for application-wide singleton reuse.

<!-- below-columns -->

> [!NOTE]
> The `google-cloud-spanner` library is native Python and communicates seamlessly with both GoogleSQL and PostgreSQL dialect databases.

---

<!-- layout: card-layout -->
# Authentication Strategies for Applications

### Application Default Credentials (ADC)
- Recommended standard for Google Cloud and local development environments.
- Automatically resolves credentials from `GOOGLE_APPLICATION_CREDENTIALS` or metadata servers.
- Zero credential secrets committed to application source code or configuration files.

### Workload Identity and IAM Roles
- Binds Kubernetes or Cloud Run service accounts directly to Google Cloud IAM roles.
- Grants least-privilege roles such as `roles/spanner.databaseUser` or `roles/spanner.databaseReader`.
- Eliminates downloaded service account JSON key management and key rotation toil.

### Service Account Key Files
- Used for external data centers or legacy CI/CD pipelines outside Google Cloud.
- Explicitly initialized using `service_account.Credentials.from_service_account_file()`.
- Requires secure vaulting in Secret Manager or HashiCorp Vault to prevent key leakage.

---

# Initializing the Cloud Spanner Client

- Initialize client objects once during application startup and reuse across all threads
- Configure custom client options or credentials explicitly when needed

```python
from google.cloud import spanner
from google.oauth2 import service_account

# 1. Standard initialization using Application Default Credentials (ADC)
client = spanner.Client(project="my-gcp-project")

# 2. Reference the instance and database
instance = client.instance("production-instance")
database = instance.database("orders-db")

# Verify connectivity and database existence
if database.exists():
    print(f"Connected to Spanner database: {database.name}")
```

> [!TIP]
> In managed environments like GKE or Cloud Run, omit project and credentials parameters; the SDK discovers them from the platform environment automatically.

---

# Failure Mode: Per-Request Client Construction

- Anti-pattern: Instantiating `spanner.Client()` inside every HTTP request or web route
  - Developer assumes: “Creating a fresh client ensures isolation between web requests”
  - Reality: Each client creates new gRPC channels, authenticates tokens, and starts worker threads
- Devastating consequences under production load:
  - Latency spikes from 5 ms to 250+ ms per request spent solely negotiating TLS and OAuth tokens
  - File descriptor and socket exhaustion crash the web service within minutes under load
  - The Spanner backend gets flooded with short-lived session creation RPCs
- Architectural Solution:
  - Instantiate `Client`, `Instance`, and `Database` once as application singletons during process boot
  - Share the `Database` reference across all worker threads and request handlers safely

> [!WARNING]
> Never construct client or database objects inside request handlers. A single `Database` object handles thousands of concurrent requests across worker threads.

---

<!-- layout: navigation -->
# Chapter 4

- Google Cloud Spanner Python SDK Setup and Authentication
- **Database Sessions, Connection Pools, and Life Cycles**
- Executing Read-Write Transactions in Python
- Performing Snapshot Reads and Batched Reads
- Handling Errors, Retries, and Transaction Aborts
- Lab: Building a Python Application with the Cloud Spanner API

---

<!-- layout: 2-column -->
# What Is a Spanner Session?

### Server-Side Session Object
- A Spanner session represents an active execution context on Spanner servers.
- Maintains transaction state, schema locks, and query compilation caches.
- Creating a session incurs network round trips and server-side state allocation.
- Inactive sessions are garbage collected by Spanner after 60 minutes of inactivity.

### Client-Side Session Management
- Creating and destroying sessions per query destroys throughput and introduces latency.
- The Python SDK manages a pool of pre-warmed, reusable sessions automatically.
- Operations check out a session from the pool, execute work, and return it immediately.
- Background threads send periodic heartbeat pings to keep pooled sessions warm.

<!-- below-columns -->

> [!IMPORTANT]
> Applications rarely manipulate session objects directly; the `Database` client manages checkout, checkin, and health verification transparently.

---

<!-- layout: 3-column -->
# Built-In Session Pool Implementations

### PingingPool (Default)
- Pre-allocates and maintains a healthy pool of warm sessions
- Runs background thread pings (`SELECT 1`) to prevent idle timeouts
- Balances resource consumption with instant transaction readiness
- Recommended choice for standard web services and APIs

### BurstyPool
- Rapidly instantiates sessions on demand during sudden traffic spikes
- Returns surplus sessions once the traffic burst subsides
- Ideal for periodic batch processing or spiky queue workers
- Higher burst capacity at the cost of occasional creation latency

### FixedSizePool
- Enforces an absolute minimum and maximum session count
- Never creates additional sessions beyond the configured cap
- Guarantees predictable memory and server-side session footprints
- Optimal for resource-constrained containers and strict limits

---

# Configuring Custom Session Pools in Python

- Customize pool parameters to align with application concurrency and worker thread counts
- Configure maximum opened sessions to prevent thread exhaustion or unbounded queueing

```python
from google.cloud import spanner
from google.cloud.spanner_v1.pool import PingingPool

# Configure a customized session pool
pool = PingingPool(
    size=50,                  # Target number of pre-warmed sessions
    default_timeout=10,       # Seconds to wait for a session before timing out
    ping_interval=1800,       # Ping idle sessions every 30 minutes (1800s)
    max_opened=100            # Hard ceiling on total concurrent sessions
)

client = spanner.Client()
instance = client.instance("prod-spanner-inst")
database = instance.database("orders-db", pool=pool)
```

> [!TIP]
> Rule of thumb: Set pool `size` equal to the maximum number of concurrent threads or async tasks executing database calls in the application process.

---

# Failure Mode: Session Pool Exhaustion and Leaks

- Anti-pattern: Checking out a session or snapshot and failing to close or release it
  - Example: Opening a snapshot without a `with` block, or abandoning an uncommitted transaction
  - If an unhandled exception bypasses cleanup, that session never returns to the pool
- The Cascade of Failures:
  - Available sessions in the pool dwindle to zero over hours of operation
  - Subsequent requests block waiting for a session until `default_timeout` expires
  - The application raises: `ResourceExhausted: Pool is empty`
  - All web and API traffic halts even though Spanner CPU utilization remains below 15%!
- Operational Best Practices:
  - Always use context managers: `with database.snapshot() as snapshot:`
  - Use `database.run_in_transaction()` which guarantees session release on exit or error

> [!CAUTION]
> If a long-running background task holds a session for hours without releasing it, you deplete the pool for incoming OLTP web requests.

---

<!-- layout: navigation -->
# Chapter 4

- Google Cloud Spanner Python SDK Setup and Authentication
- Database Sessions, Connection Pools, and Life Cycles
- **Executing Read-Write Transactions in Python**
- Performing Snapshot Reads and Batched Reads
- Handling Errors, Retries, and Transaction Aborts
- Lab: Building a Python Application with the Cloud Spanner API

---

<!-- layout: 2-column -->
# The Transaction Runner Architecture

### How run_in_transaction Works
- Applications pass a callback function to `database.run_in_transaction(unit_of_work)`.
- The runner automatically acquires a session, starts a read-write transaction, and executes the callback.
- If the callback succeeds, the runner issues a two-phase commit with TrueTime commit wait.
- If the transaction aborts due to lock contention, the runner re-executes the callback with backoff.

### Transaction Object Capabilities
- **Reads**: `transaction.execute_sql()` queries data with shared read locks.
- **DML**: `transaction.execute_update()` executes SQL `INSERT`, `UPDATE`, or `DELETE`.
- **Mutations**: `transaction.insert()`, `transaction.update()`, and `transaction.delete()` buffer mutations.
- **Commit Timestamp**: Returns the exact TrueTime commit timestamp upon success.

<!-- below-columns -->

> [!IMPORTANT]
> The callback must be completely idempotent! Because Spanner may abort and retry the callback multiple times, any operations with external side effects inside the callback will repeat.

---

# Executing Read-Write Transactions with DML

- The callback reads current account balances, validates funds, and updates balances via SQL DML
- Returns committed values out of the runner function cleanly

```python
def transfer_funds(transaction, source_id, target_id, amount):
    # Step 1: Read current balances with shared read locks
    query = "SELECT AccountId, Balance FROM Accounts WHERE AccountId IN (@src, @tgt)"
    results = transaction.execute_sql(
        query,
        params={"src": source_id, "tgt": target_id},
        param_types={"src": spanner.param_types.STRING, "tgt": spanner.param_types.STRING}
    )
    balances = {row[0]: row[1] for row in results}

    if balances[source_id] < amount:
        raise ValueError(f"Insufficient funds: balance {balances[source_id]} < {amount}")

    # Step 2: Update balances using parameterized DML statements
    update_sql = "UPDATE Accounts SET Balance = Balance + @delta WHERE AccountId = @acc"
    transaction.execute_update(update_sql, params={"delta": -amount, "acc": source_id})
    transaction.execute_update(update_sql, params={"delta": amount, "acc": target_id})
    return True

# Execute within the transaction runner helper
commit_timestamp = database.run_in_transaction(transfer_funds, "ACC-01", "ACC-02", 250.0)
print(f"Transfer committed at TrueTime: {commit_timestamp}")
```

---

<!-- layout: 2-column -->
# Applying Mutations in Transactions

### Buffering Mutations
- Mutations are staged entirely in client memory during the transaction callback.
- Example methods:
  - `transaction.insert(table, columns, values)`
  - `transaction.update(table, columns, values)`
  - `transaction.insert_or_update(table, columns, values)`
  - `transaction.delete(table, keyset)`
- Sent to Spanner in a single optimized RPC at commit time.

### Key Semantics and Trade-offs
- **Throughput**: Bypasses SQL parsing and execution planning on Spanner nodes.
- **No Read-Your-Writes**: A query inside the same transaction will not see uncommitted mutations!
- **Combined Pattern**: You can execute DML and stage mutations within the same transaction.
- **Commit Limit**: Subject to Spanner’s 80,000 mutation limit per transaction.

<!-- below-columns -->

> [!NOTE]
> If your transaction must read back modified data before committing, use SQL DML statements instead of mutations.

---

# Writing Mutations in Python

- Mutations provide clean, high-performance APIs for inserting, updating, and deleting rows
- Commit timestamps can be recorded automatically using `spanner.COMMIT_TIMESTAMP`

```python
def create_customer_and_order(transaction, customer_id, order_id, total):
    # Insert new customer record via mutation
    transaction.insert(
        table="Customers",
        columns=["CustomerId", "CustomerName", "CreatedAt"],
        values=[(customer_id, "Acme Logistics", spanner.COMMIT_TIMESTAMP)]
    )

    # Insert matching order record
    transaction.insert(
        table="Orders",
        columns=["OrderId", "CustomerId", "OrderTotal", "OrderStatus"],
        values=[(order_id, customer_id, total, "CONFIRMED")]
    )

# Execute via transaction runner
database.run_in_transaction(create_customer_and_order, "C-501", "O-9001", 1250.75)
```

> [!TIP]
> Passing `spanner.COMMIT_TIMESTAMP` populates a column typed with `OPTIONS (allow_commit_timestamp = true)` with Spanner’s authoritative TrueTime commit timestamp.

---

# Failure Mode: Side Effects in Transaction Callbacks

- Anti-pattern: Placing non-database side effects inside the `run_in_transaction` callback
  - Example: Charging a credit card via Stripe, or sending an order confirmation email
  - Developer assumes: “The callback executes only once when the transaction succeeds”
- Catastrophic cascade during lock contention:
  - Another transaction updates the inventory row, triggering a lock conflict
  - Spanner aborts the transaction with `ABORTED`
  - The Python runner automatically catches `Aborted` and restarts the callback from line 1
  - The credit card gets charged a second time, and a second email gets dispatched!
- Architectural Solution:
  - Keep the callback strictly limited to Spanner reads, DML, and mutations
  - Return transaction outcome tokens or order details from `run_in_transaction`
  - Perform external side effects (payments, emails, event publishing) only after the runner returns

> [!CAUTION]
> Never call external microservices, webhooks, or notification systems inside a Spanner transaction callback. Callbacks must be pure and repeatable.

---

<!-- layout: navigation -->
# Chapter 4

- Google Cloud Spanner Python SDK Setup and Authentication
- Database Sessions, Connection Pools, and Life Cycles
- Executing Read-Write Transactions in Python
- **Performing Snapshot Reads and Batched Reads**
- Handling Errors, Retries, and Transaction Aborts
- Lab: Building a Python Application with the Cloud Spanner API

---

<!-- layout: card-layout -->
# Snapshot Read Modes in Python

### Strong Snapshot (Default)
- `database.snapshot()` without arguments reads the most recent committed state.
- Guaranteed to reflect every transaction committed up to the start of the snapshot.
- Ideal for user profile lookups and real-time business validation logic.

### Bounded Staleness (Max Staleness)
- `database.snapshot(max_staleness=timedelta(seconds=15))` permits reading data up to 15s old.
- Enables Spanner to serve reads from the closest regional or read-only replica.
- Bypasses Paxos leader round trips, reducing read latency from 40 ms to under 5 ms.

### Exact Timestamp (Historical Read)
- `database.snapshot(read_timestamp=datetime_object)` reads exact historical data.
- Supported within the database’s version retention window (PITR, up to 7 days).
- Invaluable for running multi-table reports and auditing without data shifting underfoot.

---

# Executing Queries and KeySet Reads

- Use `snapshot.execute_sql()` for queries and `snapshot.read()` for fast primary key lookups
- `KeySet` reads bypass SQL compilation and query plan optimization for maximum efficiency

```python
import datetime
from google.cloud import spanner

# Multi-query consistent snapshot with bounded staleness
staleness = datetime.timedelta(seconds=10)
with database.snapshot(max_staleness=staleness) as snapshot:
    # 1. SQL Query execution with query parameters
    sql = "SELECT CustomerName, AccountStatus FROM Customers WHERE CustomerId = @cid"
    rows = snapshot.execute_sql(sql, params={"cid": "C-100"},
                                param_types={"cid": spanner.param_types.STRING})
    for row in rows:
        print(f"Customer: {row[0]}, Status: {row[1]}")

    # 2. Fast KeySet read by primary key (bypasses SQL optimizer entirely)
    keyset = spanner.KeySet(keys=[["C-100"], ["C-101"], ["C-102"]])
    results = snapshot.read(
        table="Customers",
        columns=["CustomerId", "CustomerName", "Email"],
        keyset=keyset
    )
    customer_list = list(results)
```

> [!TIP]
> For simple primary key lookups or key ranges, `snapshot.read()` is significantly faster and consumes less CPU than executing a `SELECT ... WHERE key = @id` SQL query.

---

<!-- layout: 2-column -->
# Parallel Processing with BatchClient

### Distributed Partitioned Reads
- Analytical frameworks (Dataflow, PySpark, multiprocessing) need to scan huge tables.
- Standard client reads pull data through a single coordinator, creating a bottleneck.
- `spanner.BatchClient` divides large table scans into independent, parallel partitions.
- Each partition corresponds to a split or split range that can be processed concurrently.

### Partitioning Life Cycle
- `batch_client.batch_snapshot()` creates a transaction pinned to an exact TrueTime snapshot.
- `batch_snapshot.generate_partitions_sql()` returns an array of partition tokens.
- Partition tokens serialize to JSON or strings and dispatch to distributed worker nodes.
- Each worker deserializes its token and calls `batch_snapshot.process_partition()`.

<!-- below-columns -->

> [!NOTE]
> All partitions read from the exact same TrueTime timestamp, guaranteeing absolute data consistency across all distributed worker nodes.

---

# Distributing Partitions with BatchClient

- Create partition tokens on coordinator and distribute to worker processes
- Each worker executes its partition in parallel without interfering with others

```python
from google.cloud import spanner

# Coordinator process: generate partitions
batch_client = client.batch_client("production-instance", "orders-db")
with batch_client.batch_snapshot() as snapshot:
    # Partition a massive table scan across splits
    sql = "SELECT OrderId, CustomerId, OrderTotal FROM Orders WHERE OrderDate >= '2025-01-01'"
    partitions = snapshot.generate_partitions_sql(sql)
    print(f"Generated {len(partitions)} parallel partitions across cluster splits")

    # Each partition can be sent over a message queue or worker pool
    # Worker code executed on remote node:
    # rows = snapshot.process_partition(partitions[0])
    # for row in rows:
    #     process_record(row)
```

> [!IMPORTANT]
> A batch snapshot has an execution lifetime of up to 4 hours. Ensure distributed workers finish reading their assigned partitions before the batch snapshot expires.

---

<!-- layout: navigation -->
# Chapter 4

- Google Cloud Spanner Python SDK Setup and Authentication
- Database Sessions, Connection Pools, and Life Cycles
- Executing Read-Write Transactions in Python
- Performing Snapshot Reads and Batched Reads
- **Handling Errors, Retries, and Transaction Aborts**
- Lab: Building a Python Application with the Cloud Spanner API

---

<!-- layout: card-layout -->
# Spanner Exception Hierarchy

### google.api_core.exceptions.Aborted (409)
- Triggered by Spanner’s wound-wait deadlock prevention and lock contention.
- Normal operational occurrence; the transaction runner retries this automatically.
- Do not log as a critical system error unless retry budget is exhausted.

### ResourceExhausted (429 / 8)
- Emitted when session pool is depleted or database node CPU and storage quotas saturate.
- Indicates client-side session leaks or inadequate Spanner compute capacity.
- Requires client backoff and investigation of session checkout life cycles.

### DeadlineExceeded (504 / 4)
- Network timeout between application and Spanner, or long query runtime.
- DML statements with `DeadlineExceeded` may have actually succeeded on the server!
- Requires checking operation status or designing idempotent writes.

---

# Custom Timeouts and Retry Configuration

- Configure request timeouts and retry predicates on queries and DML statements
- Prevent runaway queries from stalling worker threads indefinitely

```python
from google.api_core.retry import Retry
from google.api_core.exceptions import DeadlineExceeded, ServiceUnavailable

# Define custom retry policy for idempotent read requests
custom_retry = Retry(
    predicate=lambda exc: isinstance(exc, (DeadlineExceeded, ServiceUnavailable)),
    initial=0.5,       # Initial delay in seconds
    maximum=5.0,       # Maximum delay between retries
    multiplier=2.0,    # Exponential backoff factor
    deadline=15.0      # Total time budget across all attempts
)

with database.snapshot() as snapshot:
    results = snapshot.execute_sql(
        "SELECT * FROM Orders WHERE CustomerId = @cid",
        params={"cid": "C-100"},
        param_types={"cid": spanner.param_types.STRING},
        retry=custom_retry,
        timeout=10.0   # Individual RPC timeout in seconds
    )
```

> [!TIP]
> Only configure automated retries for idempotent operations such as reads. Retrying non-idempotent DML blindly after `DeadlineExceeded` can cause duplicate records.

---

<!-- layout: 2-column -->
# Failure Mode: Swallowing Aborted Exceptions

### The Broken Pattern
```python
def flawed_transaction(transaction, item_id):
    try:
        # Business logic and updates
        transaction.execute_update(...)
    except Exception as e:
        # Anti-pattern: Swallowing all exceptions!
        logger.error(f"Error occurred: {e}")
        return False
```

### The Architectural Crash
- When lock contention occurs, Spanner raises `google.api_core.exceptions.Aborted`.
- The `except Exception` block intercepts `Aborted` and logs it as an application error.
- The transaction runner expects `Aborted` to bubble up so it can trigger an internal retry!
- Because `Aborted` was swallowed, the runner assumes the callback succeeded and issues `COMMIT`.
- Spanner rejects the commit with: `Transaction was aborted`.
- Result: Transactions fail permanently on normal lock conflicts instead of retrying cleanly.

<!-- below-columns -->

> [!CAUTION]
> If you catch exceptions inside a transaction callback, never catch base `Exception` without re-raising `google.api_core.exceptions.Aborted`.

---

<!-- layout: card-layout -->
# Best Practices for Production Python Applications

### Use Context Managers
- Always use `with database.snapshot()` to guarantee sessions return to the pool immediately.
- Prevent silent session leaks from starving production API request threads.

### Keep Transactions Small
- Execute queries outside write transactions whenever possible using lock-free snapshots.
- Keep read-write transactions focused solely on the specific rows being modified.

### Ensure Callback Idempotency
- Never issue HTTP calls, publish events, or charge credit cards inside transaction callbacks.
- Prepare for callbacks to execute two or more times during high-contention spikes.

### Tune Session Pool Size
- Align session pool capacity with web server worker thread and coroutine concurrency.
- Monitor session pool saturation metrics to avoid `ResourceExhausted` timeouts.

---

<!-- layout: navigation -->
# Chapter 4

- Google Cloud Spanner Python SDK Setup and Authentication
- Database Sessions, Connection Pools, and Life Cycles
- Executing Read-Write Transactions in Python
- Performing Snapshot Reads and Batched Reads
- Handling Errors, Retries, and Transaction Aborts
- **Lab: Building a Python Application with the Cloud Spanner API**

---

# Lab: Building a Python Application with the Cloud Spanner API

Lab link: TODO

---

# What You Learned

- Developed robust Python applications using the Cloud Spanner client library
- Configured the Python client SDK and authenticated using service accounts
- Managed database sessions, pool sizing, and client life cycles effectively
- Implemented read-write transactions using transaction runner helpers in Python
- Executed stale reads, single-use snapshots, and batched queries for read scale
- Handled transient errors, retry policies, and transaction aborts gracefully
- Built and tested an operational Python application connected to Cloud Spanner

---

# Quiz 1 of 3

**Why is it an architectural anti-pattern to execute non-idempotent operations, such as calling an external payment gateway API, inside a Spanner `database.run_in_transaction()` callback?**

- A. Spanner automatically cancels any HTTP requests executed within a transaction callback
- B. If lock contention triggers a transaction abort, the runner re-executes the callback, causing duplicate payment transactions
- C. The Python client library disables all network access outside of Google Cloud during an open transaction
- D. Calling external APIs causes Spanner to immediately downgrade the transaction to an uncommitted snapshot read

---

# Quiz 1: Answer

**Why is it an architectural anti-pattern to execute non-idempotent operations, such as calling an external payment gateway API, inside a Spanner `database.run_in_transaction()` callback?**

**Correct: B.** If lock contention triggers a transaction abort, the runner re-executes the callback, causing duplicate payment transactions

- Transaction aborts in Spanner are normal operational occurrences under concurrent write contention
- `run_in_transaction()` catches `Aborted` exceptions and re-runs the callback function from the beginning
- Any external side effects inside the callback will be repeated on each retry attempt
- External operations should only be executed after `run_in_transaction()` successfully commits

---

# Quiz 2 of 3

**How does checking out a snapshot read using `with database.snapshot(max_staleness=timedelta(seconds=15))` benefit an application running in a multi-region deployment?**

- A. It locks the table for 15 seconds to ensure no concurrent writes can occur
- B. It allows local read-only or non-leader replicas to serve the query, avoiding cross-region network round trips to the Paxos leader
- C. It automatically buffers all mutations client-side for 15 seconds before issuing a batch update
- D. It enables partitioned DML to run across all cluster splits without mutation limits

---

# Quiz 2: Answer

**How does checking out a snapshot read using `with database.snapshot(max_staleness=timedelta(seconds=15))` benefit an application running in a multi-region deployment?**

**Correct: B.** It allows local read-only or non-leader replicas to serve the query, avoiding cross-region network round trips to the Paxos leader

- Bounded staleness allows Spanner to evaluate the query against a replica that is up to 15 seconds behind
- Local regional replicas can serve the query directly without contacting the Paxos leader in another region
- Reduces read latency from 40 - 60 ms WAN round trips to 2 - 5 ms local read times
- Snapshot reads are completely lock-free and never block concurrent writers

---

<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
A production microservice written in Python connects to Cloud Spanner. Under peak traffic, the service experiences sudden latency spikes, requests fail with `ResourceExhausted: Pool is empty`, and server logs show database connection errors, even though Spanner instance CPU utilization is only 15%.

### Discuss
- What is the most likely root cause of the `ResourceExhausted: Pool is empty` error?
- How should the development team inspect their Python code for session leaks?
- What configuration and code changes should be implemented to resolve this issue?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**A production microservice written in Python experiences sudden latency spikes and `ResourceExhausted: Pool is empty` errors while Spanner CPU is only 15%.**

### Strong Answers Mention
- Session pool starvation caused by unclosed snapshots, leaked sessions, or uncommitted transactions
- Code inspection: look for `database.snapshot()` or transaction checkouts that omit `with` context managers
- Long-running worker threads holding sessions without returning them to the pool
- Configure `PingingPool` with appropriate `size` and `max_opened` matching worker concurrency
- Ensure `spanner.Client` and `Database` objects are singletons, not re-created per request

### Watch For
- Believing Spanner server nodes need to be scaled up when server CPU is only 15%
- Confusing client session pool exhaustion with Spanner database storage or node quota exhaustion
- Suggesting disabling connection pooling or creating a new client on every query

---

# Questions and Answers

Questions?
