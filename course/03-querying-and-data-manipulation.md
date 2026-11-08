<!-- course-title: Google Spanner: Hands-On -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Google Spanner: Hands-On

# Chapter 3: Querying and Data Manipulation with SQL

---

# Chapter 3: Objectives

- Query and manipulate data using SQL, mutations, and transaction modes
- Execute SQL queries across Spanner dialect options and query processing stages
- Insert, update, and delete data using DML statements and mutations
- Analyze query execution plans and optimizer statistics to tune performance
- Explain concurrency control mechanisms and isolation levels in Spanner
- Select appropriate read-write, read-only, and snapshot transaction modes
- Execute queries, apply mutations, and tune SQL statements in Cloud Spanner

---

<!-- layout: navigation -->
# Chapter 3

- **Query Execution and SQL Dialects in Spanner**
- Data Manipulation Language and Mutations
- Query Optimizer and Execution Plans
- Transactions and Concurrency Control
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- Lab: Querying, Mutating, and Tuning SQL Queries

---

<!-- layout: 2-column -->
# Distributed Query Execution Architecture

### Coordinator and Worker Flow
- **Root Coordinator**: The Spanner compute node receiving the client query compiles the execution plan.
- **Split Pruning**: Optimizer inspects primary key filters to route work only to splits hosting relevant data.
- **Remote Execution**: Subplans dispatch via high-speed internal RPC to Paxos leader nodes owning targeted splits.

### Result Aggregation
- **Subplan Streaming**: Split workers stream intermediate results back to the root coordinator concurrently.
- **Root Assembly**: Coordinator performs final sorting, cross-split joins, or aggregations before returning rows.
- **Scalability**: Queries with split-specific filters scale horizontally without bottlenecking cluster nodes.

<!-- below-columns -->

> [!NOTE]
> Queries touching a single split execute locally on that split’s Paxos leader, avoiding distributed cross-split coordination entirely.

---

<!-- layout: card-layout -->
# Comparing Spanner SQL Dialects

### GoogleSQL Standards
- Adheres to ANSI SQL:2011 with BigQuery syntax compatibility.
- Uses named parameters like `@customer_id` and backtick quoting for identifiers.
- Rich support for complex nested structures such as `ARRAY` and native `JSON`.

### PostgreSQL Compatibility
- Implements PostgreSQL core dialect syntax and standard PostgreSQL type mappings.
- Uses positional parameters like `$1`, `$2` and standard double-quote identifier escaping.
- Simplifies application migration for teams using existing PostgreSQL ORMs and drivers.

### Permanent Selection
- Dialect is chosen at database creation and cannot be converted afterward.
- Both dialects execute on the exact same underlying distributed Spanner query engine.
- Both dialects deliver identical horizontal scaling, Paxos consensus, and ACID guarantees.

---

# Querying with the GoogleSQL Dialect

- Demonstrates parameter binding, JSON path extraction, and array handling
- Parameterized queries protect against injection and maximize query plan cache hits

```sql
-- GoogleSQL dialect query with parameters and JSON traversal
SELECT
  c.CustomerId,
  c.CustomerName,
  o.OrderId,
  o.OrderDate,
  JSON_VALUE(o.ShippingAddress, '$.city') AS ShippingCity,
  o.OrderTotal
FROM Customers AS c
JOIN Orders AS o ON c.CustomerId = o.CustomerId
WHERE c.CustomerId = @customer_id
  AND o.OrderStatus = @status
ORDER BY o.OrderDate DESC
LIMIT 10;
```

> [!TIP]
> Always use query parameters instead of string concatenation. Spanner caches compiled execution plans based on parameter signatures.

---

# Querying with the PostgreSQL Dialect

- PostgreSQL dialect uses standard `$1` placeholders and PostgreSQL functions
- Seamlessly maps to standard PostgreSQL client drivers and query tooling

```sql
-- PostgreSQL dialect query with positional parameters
SELECT
  c.customer_id,
  c.customer_name,
  o.order_id,
  o.order_date,
  o.shipping_address->>'city' AS shipping_city,
  o.order_total
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
WHERE c.customer_id = $1
  AND o.order_status = $2
ORDER BY o.order_date DESC
LIMIT 10;
```

> [!NOTE]
> In the PostgreSQL dialect, table and column names fold to lowercase by default unless explicitly enclosed in double quotes.

---

<!-- layout: 3-column -->
# Distributed Execution Operators

### Distributed Cross Apply
- Feeds rows from an outer table to scan matching inner table rows
- Colocates join processing when parent and child tables are interleaved
- Eliminates expensive network data shuffling across nodes

### Distributed Union
- Queries multiple splits in parallel across the Spanner cluster
- Gathers sorted or filtered subplan results from Paxos leaders
- Scales aggregate throughput linearly as split counts increase

### Distributed Hash Join
- Used when joining large, non-interleaved tables across splits
- Builds in-memory hash tables on worker nodes for distributed matching
- Incurs network RPC data movement to redistribute join keys

---

# Failure Mode: Unbounded Root Aggregation

- Anti-pattern: Running unpartitioned `ORDER BY`, `GROUP BY`, or `DISTINCT` without primary key alignment
  - Example: `SELECT * FROM Orders ORDER BY TotalAmount DESC LIMIT 10;` without an index
- The root coordinator must pull all rows across every split in the cluster over network RPCs
  - The single coordinator node buffers millions of candidate records in memory to sort
  - Result: Coordinator CPU spikes to 100%, memory exhausts, and client queries time out
- Architectural Solution:
  - Create a secondary index on `TotalAmount DESC` to allow index-ordered parallel scanning
  - Scope queries to a partition key (such as `CustomerId` or `TenantId`) to isolate scans to one split

> [!WARNING]
> A distributed database cannot magically sort unindexed data across 50 splits without gathering that data onto a single coordinator node.

---

<!-- layout: navigation -->
# Chapter 3

- Query Execution and SQL Dialects in Spanner
- **Data Manipulation Language and Mutations**
- Query Optimizer and Execution Plans
- Transactions and Concurrency Control
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- Lab: Querying, Mutating, and Tuning SQL Queries

---

<!-- layout: 2-column -->
# Modifying Data: DML vs Mutations

### SQL DML Statements
- Standard `INSERT`, `UPDATE`, and `DELETE` SQL syntax.
- Supports expressions, subqueries, and conditional calculations.
- Supports “read-your-writes”: subsequent statements in the transaction see modified state.
- Each DML statement incurs SQL parsing, planning, and client-server round trips.

### Spanner Mutations
- Low-level API operations: `Insert`, `Update`, `InsertOrUpdate`, `Replace`, `Delete`.
- Buffered entirely client-side; sent in a single bulk batch at commit time.
- Bypasses SQL compilation and parsing for maximum write throughput.
- Cannot read back uncommitted mutation changes within the same transaction.

<!-- below-columns -->

> [!IMPORTANT]
> Use Mutations for high-throughput batch ingestion and simple updates. Use DML when business logic requires reading modified data or dynamic SQL conditions.

---

<!-- layout: card-layout -->
# Mutation Types and Semantics

### Insert and Update
- `Insert`: Appends a new row; fails immediately with `ALREADY_EXISTS` if primary key exists.
- `Update`: Updates specified column values; fails with `NOT_FOUND` if primary key does not exist.

### InsertOrUpdate (Upsert)
- Checks whether the primary key exists in the table.
- Inserts a new row if key is absent; merges specified columns if key is present.

### Replace
- Overwrites the target row completely.
- Sets any column not explicitly specified in the mutation payload to `NULL` or its default value.

### Delete
- Removes rows identified by a single key or a key range (`KeyRange`).
- Silently succeeds even if the target row keys do not exist in the table.

---

# Executing DML with Returning Clauses

- Spanner supports standard parameterized DML and the `THEN RETURN` clause
- `THEN RETURN` avoids a separate follow-up `SELECT` query after an insert or update

```sql
-- Parameterized DML with THEN RETURN clause in GoogleSQL
UPDATE Orders
SET OrderStatus = @new_status,
    ShippedAt = PENDING_COMMIT_TIMESTAMP()
WHERE OrderId = @order_id
  AND OrderStatus = 'PROCESSING'
THEN RETURN OrderId, OrderStatus, ShippedAt;
```

- Batch DML (`batch_update`) executes multiple DML statements in one network round trip
  - Groups related inserts, updates, and deletes together
  - Reduces round-trip network latency between application tier and Spanner nodes

---

<!-- layout: 2-column -->
# Bulk Updates: Standard DML vs Partitioned DML

### Standard DML
- Executes inside an atomic read-write ACID transaction.
- Bounded by strict limits: maximum 80,000 mutations and 100 MB data per transaction.
- Rolls back completely if any statement fails or lock conflict occurs.
- Ideal for OLTP operations involving single records or small transactional sets.

### Partitioned DML
- Designed specifically for large-scale backfills, data cleanses, and bulk deletes.
- Automatically partitions the table into split chunks, running separate background transactions.
- Bypasses the 80,000 mutation limit to process billions of rows safely.
- Not fully atomic across the whole table: if aborted, completed partitions remain committed.

<!-- below-columns -->

> [!CAUTION]
> Never run an unbounded `DELETE FROM Orders WHERE OrderDate < '2023-01-01';` in a standard transaction. Use Partitioned DML to avoid transaction memory exhaustion and timeouts.

---

# Failure Mode: The Hidden Mutation Limit Trap

- Spanner limits every transaction to at most 80,000 mutations
  - A mutation is counted for every cell (column value) modified in a table row
  - Every secondary index entry touched counts as an additional mutation!
- Mutation calculation example:
  - Inserting 1 row into a table with 10 columns and 3 secondary indexes = 13 mutations
  - Inserting 6,500 rows in one transaction = `6,500 * 13 = 84,500` mutations
  - Spanner rejects the transaction with: `The transaction contains too many mutations`
- Remediation patterns:
  - Batch application writes into safe chunks of 1,000 to 2,000 rows
  - Calculate total mutations including index overhead before issuing commit payloads

> [!WARNING]
> Secondary indexes multiply mutation counts silently. Adding a new index can break existing batch insert jobs that operated near the 80,000 limit.

---

<!-- layout: navigation -->
# Chapter 3

- Query Execution and SQL Dialects in Spanner
- Data Manipulation Language and Mutations
- **Query Optimizer and Execution Plans**
- Transactions and Concurrency Control
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- Lab: Querying, Mutating, and Tuning SQL Queries

---

<!-- layout: card-layout -->
# The Spanner Cost-Based Optimizer

### Statistical Cardinality Models
- Collects data distribution statistics, row counts, and split boundaries via `ANALYZE`.
- Computes estimated cost across candidate plans to choose indexes and join paths.

### Optimizer Version Management
- Releases updated optimizer engine versions without breaking existing workloads.
- Allows pinning optimizer versions at database level or per-query via `OPTIMIZER_VERSION`.

### Distributed Physical Planning
- Decides whether to push filters down to individual splits or coordinate at root.
- Chooses optimal join mechanisms: Distributed Cross Apply, Hash Join, or Merge Join.

---

<!-- layout: 2-column -->
# Analyzing Plans: Explain vs Explain Analyze

### EXPLAIN (Estimated Plan)
- Generates the physical execution plan without executing the query.
- Displays compile-time metadata: operator hierarchy, scan types, and estimated row counts.
- Highlights whether the optimizer chose an index scan or full table scan.
- Incurs zero database read load or transaction locking overhead.

### EXPLAIN ANALYZE (Actual Profile)
- Executes the query completely and captures real runtime telemetry.
- Reports exact rows scanned, rows returned, CPU execution time, and execution latency.
- Exposes data transfer volume across network splits and coordinator wait times.
- Critical tool for diagnosing slow queries and verifying optimizer accuracy.

<!-- below-columns -->

> [!TIP]
> Use `EXPLAIN` during development to verify index usage; use `EXPLAIN ANALYZE` in staging to profile actual CPU consumption and network latency.

---

# Inspecting Key Execution Plan Operators

- Spanner query execution plans display as a hierarchical tree of distributed physical operators
- Understanding key operators allows identifying performance bottlenecks rapidly

| Operator Name | Execution Behavior | Performance Implication |
| :--- | :--- | :--- |
| **Distributed Union** | Evaluates subplans across multiple splits and unions results | Normal for multi-split scans; watch for broad split counts |
| **Distributed Cross Apply** | Feeds outer rows into inner split lookups | Optimal for interleaved child tables and indexed lookups |
| **Table Scan** | Sequentially reads all rows in a table split | High cost if unpartitioned; indicates missing index |
| **Index Scan** | Reads rows from a secondary index | Low cost; verify if back-lookup to base table is needed |
| **Cross Apply Batch** | Batches keys before querying remote child splits | Reduces network RPC overhead across nodes |

> [!NOTE]
> When an Index Scan requires columns not stored in the index, Spanner must perform an expensive back-lookup to the base table for every row.

---

# Query Tuning with Optimizer Hints

- Query hints allow overriding default optimizer decisions when necessary
- Use hints judiciously: forced plans do not adapt when data distributions change

```sql
-- Query tuning with table, index, and join method hints
SELECT
  c.CustomerName,
  o.OrderId,
  o.OrderTotal
FROM Customers AS c
JOIN @{JOIN_METHOD=HASH_JOIN} Orders AS o
  ON c.CustomerId = o.CustomerId
WHERE o.OrderDate >= '2025-01-01'
  @{FORCE_INDEX=OrdersByDateIndex, FORCE_INDEX_BACK_LOOKUP=TRUE}
ORDER BY o.OrderDate DESC
LIMIT 50;
```

- Common hint directives:
  - `FORCE_INDEX`: Forces use of a specific secondary index or table scan (`FORCE_INDEX=_BASE_TABLE`)
  - `JOIN_METHOD`: Enforces `HASH_JOIN`, `CROSS_APPLY`, or `MERGE_JOIN`

---

<!-- layout: 2-column -->
# Failure Mode: Stale Optimizer Statistics

### The Anomaly
- After loading 10 million rows, queries that ran in 4 ms suddenly degrade to 3,500 ms.
- The optimizer still assumes the table contains only 1,000 rows based on old statistics.
- Optimizer selects a full table scan and nested loop join instead of using secondary indexes.
- High-priority CPU spikes across all nodes as splits churn through unindexed scans.

### Remediation Strategy
- Run `ANALYZE` immediately after major bulk data loading or migration tasks.
- Spanner runs automatic background statistics collection, but initial bulk loads outpace it.
- Verify statistics collection timestamps using Spanner information schema tables:
  `INFORMATION_SCHEMA.SPANNER_STATISTICS`

<!-- below-columns -->

> [!IMPORTANT]
> Pinning `OPTIMIZER_VERSION` protects production queries from unexpected plan regressions when Google deploys new Spanner query optimizer engine updates.

---

<!-- layout: navigation -->
# Chapter 3

- Query Execution and SQL Dialects in Spanner
- Data Manipulation Language and Mutations
- Query Optimizer and Execution Plans
- **Transactions and Concurrency Control**
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- Lab: Querying, Mutating, and Tuning SQL Queries

---

<!-- layout: 3-column -->
# Spanner Concurrency Control Pillars

### Strict Serializability
- Strongest consistency model
- Guarantees execution equivalent to a serial sequential order
- Prevents dirty reads, non-repeatable reads, and phantom reads

### TrueTime and MVCC
- Assigns monotonic commit timestamps
- Retains multi-version row states
- Delivers real-world causal ordering across all continents

### Pessimistic Locking
- Uses shared read locks and exclusive write locks
- Employs strict Two-Phase Locking (2PL)
- Held continuously until transaction completes

---

<!-- layout: 2-column -->
# Two-Phase Locking and Lock Modes

### Shared and Exclusive Locks
- **Shared Read Locks**: Acquired whenever a read-write transaction queries or reads rows. Multiple transactions can hold shared locks concurrently.
- **Exclusive Write Locks**: Acquired during write phase before commit. Prevents concurrent transactions from reading or modifying the same rows.
- **Range Locks**: Acquired when scanning key ranges or unindexed tables, locking entire intervals against inserts.

### Strict 2PL Semantics
- Locks are acquired dynamically as data is accessed during transaction execution.
- All acquired locks remain held until the transaction finishes (commit or rollback).
- Locks are never released early, guaranteeing complete serializability across all operations.

<!-- below-columns -->

> [!WARNING]
> Because read-write transactions acquire shared locks on every row read, reading large result sets inside a write transaction blocks other writers from modifying those rows.

---

# Lock Contention and Transaction Aborts

- Spanner uses deadlock detection and wound-wait protocols to prevent deadlocks
- When a lock conflict threatens deadlock, Spanner aborts the younger transaction
  - The client receives an error with status code `ABORTED`
  - Transaction aborts in Spanner are normal operational events, not catastrophic bugs!
- Golden Architectural Rule:
  - Applications **must** wrap all read-write transactions in retry loops with exponential backoff
  - Official Cloud Spanner client SDKs implement automatic retries natively

```python
# Conceptual retry logic for Spanner read-write transactions
def run_with_retry(db, fn):
    while True:
        try:
            return db.run_in_transaction(fn)
        except Aborted:
            time.sleep(backoff_jitter())
```

> [!TIP]
> Cloud Spanner client libraries (Python, Go, Java, Node.js) provide `run_in_transaction()` which handles lock acquisition, commit-wait, and abort retries automatically.

---

<!-- layout: card-layout -->
# Minimizing Lock Contention

### Minimize Transaction Footprint
- Keep read-write transactions as short as possible in wall-clock time.
- Never make external HTTP calls or execute slow business logic inside an active transaction.

### Consistent Lock Ordering
- Access and update rows in a consistent, predictable primary key order across all services.
- Eliminates circular lock dependencies that trigger frequent transaction aborts.

### Separate Read and Write Paths
- Move catalog searches, analytics, and read-only queries into read-only transactions.
- Never read rows inside a write transaction unless those rows directly govern update logic.

---

# Failure Mode: The Hot Row Bottleneck

- Anti-pattern: Updating a single global counter or summary row in high-throughput workflows
  - Examples: `UPDATE GlobalCounters SET count = count + 1 WHERE id = 'orders';`
  - Every concurrent worker requests an exclusive write lock on the exact same row
- Catastrophic cascade:
  - Workers queue for the exclusive lock; transaction latency climbs from 10 ms to seconds
  - Spanner deadlock detection triggers rolling transaction aborts; abort rate hits 80%+
  - Compute CPU saturates managing lock queues and re-executing aborted transactions
- Architectural Solution: Sharded Counters
  - Split the counter into N separate rows (`counter_id`, `shard_id` from 1 to 100)
  - Workers randomly pick a `shard_id` to update, spreading lock contention across 100 splits
  - Read queries calculate the true total with: `SELECT SUM(count) FROM GlobalCounters;`

> [!IMPORTANT]
> Scaling up Spanner nodes does not resolve hot row contention. Contention on a single row is constrained by Amdahl’s law and Paxos leader throughput, not cluster capacity.

---

<!-- layout: navigation -->
# Chapter 3

- Query Execution and SQL Dialects in Spanner
- Data Manipulation Language and Mutations
- Query Optimizer and Execution Plans
- Transactions and Concurrency Control
- **Read-Write Transactions, Read-Only Transactions, and Snapshot Reads**
- Lab: Querying, Mutating, and Tuning SQL Queries

---

<!-- layout: 3-column -->
# The Three Transaction Modes

### Read-Write Transactions
- Full ACID atomicity
- Uses two-phase locking
- Incurs Paxos consensus and TrueTime commit wait
- Used for atomic business state modifications

### Read-Only Transactions
- Lock-free execution
- Multi-query transactional consistency at one snapshot
- Never blocks incoming writes or suffers aborts
- Used for reports, invoices, and multi-query workflows

### Single-Use Snapshot Reads
- Lock-free single statement reads
- Configurable staleness bounds
- Routes reads to nearest regional or read-only replicas
- Optimal for high-throughput microservices and APIs

---

<!-- layout: card-layout -->
# Snapshot Staleness Modes

### Strong Read (Default)
- Reads the most up-to-date committed data up to the exact moment of request execution.
- Routes to the split leader or a replica confirmed to have applied all prior transactions.
- Zero risk of reading stale data; standard for real-time customer data lookups.

### Exact Timestamp Read
- Reads database state as it existed at an exact historical timestamp (e.g. 10 minutes ago).
- Supported up to the database version retention period (Point-in-Time Recovery, up to 7 days).
- Invaluable for auditing, point-in-time debugging, and consistent data exports.

### Max Staleness (Bounded)
- Allows Spanner to serve data up to a specified staleness bound (e.g. `max_staleness = 15s`).
- Allows distant regional read-only replicas to serve reads without contacting the write leader.
- Drastically reduces query latency and eliminates cross-region network hops.

---

# Executing Snapshot Reads in Python

- Demonstrates configuring strong reads, historical timestamps, and bounded staleness
- Read-only transactions and snapshot reads acquire no locks and never block writers

```python
from google.cloud import spanner
import datetime

# Create database client
client = spanner.Client()
instance = client.instance("prod-spanner-inst")
database = instance.database("orders-db")

# 1. Strong Snapshot Read (latest consistent data)
with database.snapshot() as snapshot:
    results = snapshot.execute_sql("SELECT * FROM Customers WHERE CustomerId = @id",
                                   params={"id": "C-100"},
                                   param_types={"id": spanner.param_types.STRING})

# 2. Bounded Staleness Read (allows up to 15 seconds staleness for local read speed)
with database.snapshot(max_staleness=datetime.timedelta(seconds=15)) as snapshot:
    results = snapshot.execute_sql("SELECT COUNT(*) FROM Orders")
```

> [!TIP]
> Use bounded staleness for catalog browsing and public dashboards. In multi-region deployments, this serves queries locally within 2 - 5 ms instead of 40 - 60 ms.

---

<!-- layout: 2-column -->
# Transaction Mode Decision Framework

### Use Read-Write Transactions When
- Transferring money between bank accounts or debiting inventory.
- Updating row state based on current row values atomically.
- You must guarantee atomic write consistency across multiple tables.
- Modifying secondary indexes or interleaved child hierarchies.

### Use Read-Only or Snapshot When
- Executing reports, dashboards, or public API read endpoints.
- Generating invoices or auditing statements requiring multi-query consistency.
- Reading data where sub-second staleness is acceptable for latency gains.
- Running analytical queries or bulk exports via Cloud Storage or BigQuery.

<!-- below-columns -->

> [!IMPORTANT]
> If a transaction does not contain an `INSERT`, `UPDATE`, `DELETE`, or Mutation, it should never be executed as a read-write transaction.

---

# Failure Mode: Reading inside Read-Write Transactions

- Anti-pattern: Running read-only queries or user profile fetches inside a read-write transaction
  - Developer believes: “Wrapping everything in read-write ensures total consistency”
  - Reality: Every row read acquires a shared read lock on Spanner compute nodes
- Consequences:
  - Concurrent writers attempting to update those rows are blocked until your read-write transaction commits
  - If another transaction holds an exclusive lock on those rows, your read must wait or gets aborted
  - Paxos commit latency and TrueTime commit wait are incurred unnecessarily
- Solution:
  - Demote pure reads to lock-free `database.snapshot()` reads
  - If a read must precede a write, read only the specific primary keys required for validation

> [!CAUTION]
> Never query unbounded lookup tables (like product catalogs or tax rate tables) inside a read-write transaction. You will lock those tables against administrative updates.

---

<!-- layout: navigation -->
# Chapter 3

- Query Execution and SQL Dialects in Spanner
- Data Manipulation Language and Mutations
- Query Optimizer and Execution Plans
- Transactions and Concurrency Control
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- **Lab: Querying, Mutating, and Tuning SQL Queries**

---

# Lab: Querying, Mutating, and Tuning SQL Queries

Lab link: TODO

---

# What You Learned

- Queried and manipulated data using SQL, mutations, and transaction modes
- Executed SQL queries across Spanner dialect options and query processing stages
- Inserted, updated, and deleted data using DML statements and mutations
- Analyzed query execution plans and optimizer statistics to tune performance
- Explained concurrency control mechanisms and isolation levels in Spanner
- Selected appropriate read-write, read-only, and snapshot transaction modes
- Executed queries, applied mutations, and tuned SQL statements in Cloud Spanner

---

# Quiz 1 of 3

**What is a primary operational distinction between Spanner Mutations and standard SQL DML statements?**

- A. Mutations allow an application to read back modified values within the open transaction prior to committing
- B. Mutations are buffered on the client and sent at commit time without SQL parsing, delivering higher write throughput but without read-your-writes
- C. DML statements bypass the Spanner query optimizer and write directly to Colossus storage files
- D. Mutations cannot be executed inside a read-write transaction and can only be used with Partitioned DML

---

# Quiz 1: Answer

**What is a primary operational distinction between Spanner Mutations and standard SQL DML statements?**

**Correct: B.** Mutations are buffered on the client and sent at commit time without SQL parsing, delivering higher write throughput but without read-your-writes

- Mutations bypass SQL parsing, query planning, and intermediate network round trips
- Mutations are buffered client-side and submitted in a single bulk payload at commit
- Because mutations are buffered until commit, subsequent reads in the same transaction cannot see their changes
- Standard DML statements support expressions, conditional updates, and read-your-writes semantics

---

# Quiz 2 of 3

**When querying a multi-region Spanner database for read-heavy public catalog data where 10 seconds of staleness is acceptable, which strategy yields the lowest query latency?**

- A. A read-write transaction with shared read locks placed on all catalog splits
- B. A single-use snapshot read configured with bounded staleness (`max_staleness = 15s`)
- C. A read-only transaction pinned to an exact timestamp equal to TrueTime.now()
- D. Partitioned DML executed with split parallelism across regional nodes

---

# Quiz 2: Answer

**When querying a multi-region Spanner database for read-heavy public catalog data where 10 seconds of staleness is acceptable, which strategy yields the lowest query latency?**

**Correct: B.** A single-use snapshot read configured with bounded staleness (`max_staleness = 15s`)

- Bounded staleness allows local read-only and non-leader replicas to serve the read immediately
- Eliminates WAN network round trips to the multi-region Paxos leader region
- Snapshot reads acquire no locks and never block or get blocked by concurrent writes
- Read-write transactions incur shared locks, Paxos coordination, and unnecessary WAN latency

---

<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
An e-commerce order processing pipeline experiences frequent transaction aborts and 2,500 ms commit latencies during flash sales. The application executes a single read-write transaction that:
1. Queries the item catalog and reviews to display product details
2. Checks and decrements an `inventory_count` row in an `Inventory` table
3. Inserts an order row into `Orders`

### Discuss
- What architectural anti-patterns exist in this transaction design?
- How should the team restructure the read operations versus write operations?
- How can the team resolve the severe write lock contention on the single `inventory_count` row?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**An e-commerce order processing pipeline experiences frequent transaction aborts and 2,500 ms commit latencies during flash sales.**

### Strong Answers Mention
- Evict product catalog and review queries from the read-write transaction into lock-free snapshot reads
- Keep the read-write transaction as brief as possible (only decrement inventory and insert order)
- High lock contention on a single inventory row causes Paxos leader queueing, abort storms, and thread starvation
- Shard the inventory counter across N rows or decouple inventory decrements using an asynchronous reservation queue

### Watch For
- Suggesting Partitioned DML for transactional order placement (Partitioned DML lacks ACID atomicity)
- Believing adding Spanner compute nodes will automatically fix single-row lock contention
- Recommending disabling transaction abort retries instead of resolving the root lock contention

---

# Questions and Answers

Questions?
