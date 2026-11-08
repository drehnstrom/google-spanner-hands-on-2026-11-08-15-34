# Building a Python Application with the Cloud Spanner API

## Time Required

45 minutes

## Overview

In this lab, you will build an operational Python application that integrates with Cloud Spanner using the official client SDK. You will configure application credentials, implement thread-safe singleton client connections with custom session pools, execute lock-free snapshot reads with bounded staleness, perform high-speed primary key lookups using KeySets, and implement atomic read-write transactions with parameterized SQL DML. You will also ingest batch records using low-level Spanner mutations, configure custom RPC retry policies and timeouts, manage transaction aborts, and parallelize large table scans using the BatchClient.

### You learn how to:
- Initialize a thread-safe Cloud Spanner client with a custom `PingingPool` session pool.
- Execute lock-free snapshot reads with bounded staleness and primary key `KeySet` lookups.
- Implement atomic read-write transactions with parameterized DML using the transaction runner.
- Perform high-throughput batch data ingestion using low-level Spanner mutations and commit timestamps.
- Configure custom RPC retry policies, timeouts, and error handling without intercepting transaction aborts.
- Distribute large analytical queries across parallel partitions using `BatchClient`.

## Scenario

Your engineering team at the enterprise retail platform is building the core order fulfillment microservice in Python. To handle thousands of concurrent checkout operations, the service must avoid connection bottlenecks, prevent session pool exhaustion, execute lock-free reads without hitting the Paxos leader, and process atomic order placements safely under high write contention. You must build an operational order management service in Python using the Cloud Spanner client library that enforces production best practices for session management, transactions, mutations, error handling, and distributed parallel reads.

## Lab Instructions

### Task 1: Set up the Python environment and configure session pooling

In this task, you prepare your Cloud Shell workspace, install the Cloud Spanner Python client library, verify your database resources, and configure a thread-safe singleton client with a customized session pool.

1. Open Cloud Shell from the Google Cloud Console.

2. Verify your active Google Cloud project ID and set your environment variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export DATABASE_ID="orders-googlesql-db"
echo "Project:  ${PROJECT_ID}"
echo "Instance: ${INSTANCE_ID}"
echo "Database: ${DATABASE_ID}"
```

> [!NOTE]
> If your project ID is empty, set it using `gcloud config set project YOUR_PROJECT_ID`.

3. Verify that your Spanner instance and database from earlier labs are in the `READY` state:

```bash
gcloud spanner databases describe "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --format="value(state)"
```

> [!TIP]
> If you are starting fresh and do not have these resources, create them with:
> `gcloud spanner instances create order-mgmt-instance --config=regional-us-central1 --description="Order Management Instance" --processing-units=100`
> and
> `gcloud spanner databases create orders-googlesql-db --instance=order-mgmt-instance --database-dialect=GOOGLE_STANDARD_SQL`

4. Create an isolated workspace directory named `spanner-python-app` and navigate into it:

```bash
mkdir -p ~/spanner-python-app
cd ~/spanner-python-app
```

5. Install the official Cloud Spanner Python client library and Google API Core dependencies:

```bash
pip3 install --upgrade google-cloud-spanner google-api-core
```

6. Create the service module file `order_service.py` with singleton initialization and custom session pool configuration:

```bash
cat << 'EOF' > order_service.py
#!/usr/bin/env python3
"""
Cloud Spanner Order Management Service
Demonstrates Cloud Spanner Python SDK architecture and best practices.
"""

import datetime
import json
import os
import sys
import uuid
from google.api_core.exceptions import Aborted, DeadlineExceeded, ServiceUnavailable
from google.api_core.retry import Retry
from google.cloud import spanner
from google.cloud.spanner_v1.pool import PingingPool


class SpannerOrderService:
    """Application service managing Cloud Spanner database interactions."""

    def __init__(self, project_id: str, instance_id: str, database_id: str):
        self.project_id = project_id
        self.instance_id = instance_id
        self.database_id = database_id

        # Configure custom session pool to pre-warm and manage reusable sessions
        self.pool = PingingPool(
            size=10,             # Pre-warmed session count
            default_timeout=10,  # Wait up to 10 seconds for available session
            ping_interval=1800,  # Heartbeat ping every 30 minutes to keep sessions warm
            max_opened=20        # Hard ceiling on total concurrent sessions
        )

        # Initialize singleton client, instance, and database handles
        self.client = spanner.Client(project=self.project_id)
        self.instance = self.client.instance(self.instance_id)
        self.database = self.instance.database(self.database_id, pool=self.pool)

    def verify_connection(self) -> bool:
        """Verify database connectivity and existence."""
        if not self.database.exists():
            raise RuntimeError(
                f"Database '{self.database_id}' does not exist on instance '{self.instance_id}'."
            )
        # Execute a lightweight ping query within a snapshot context
        with self.database.snapshot() as snapshot:
            results = list(snapshot.execute_sql("SELECT 1"))
            return len(results) == 1
EOF
```

> [!IMPORTANT]
> Always construct `spanner.Client()`, `Instance`, and `Database` objects once as application singletons during process boot. Creating new clients inside per-request web handlers causes TLS and OAuth token thrashing, socket exhaustion, and severe latency spikes.

7. Append test verification logic to the bottom of `order_service.py`:

```bash
cat << 'EOF' >> order_service.py

def main():
    project_id = os.environ.get("PROJECT_ID")
    if not project_id:
        print("ERROR: Set the PROJECT_ID environment variable.")
        sys.exit(1)

    instance_id = os.environ.get("INSTANCE_ID", "order-mgmt-instance")
    database_id = os.environ.get("DATABASE_ID", "orders-googlesql-db")

    print(f"Connecting to Cloud Spanner: {project_id}/{instance_id}/{database_id}")
    service = SpannerOrderService(project_id, instance_id, database_id)

    if service.verify_connection():
        print("SUCCESS: Connected to Cloud Spanner and pre-warmed session pool.")


if __name__ == "__main__":
    main()
EOF
```

8. Execute `order_service.py` to confirm that your client connects and the session pool initializes:

```bash
python3 order_service.py
```

9. Verify that the output prints `SUCCESS: Connected to Cloud Spanner and pre-warmed session pool.`

---

### Task 2: Execute snapshot reads and primary key KeySet lookups

In this task, you implement lock-free read queries using snapshot contexts, evaluate bounded staleness reads to bypass Paxos leaders, and perform primary key lookups using KeySets to bypass the SQL compiler.

1. Review the read mechanics:
   - `database.snapshot()` creates a lock-free snapshot pinned to an exact TrueTime timestamp.
   - Bounded staleness (`max_staleness=timedelta(seconds=15)`) allows non-leader regional replicas to serve queries, reducing read latency.
   - `snapshot.read()` with `spanner.KeySet` executes point lookups directly against storage splits without SQL parsing overhead.

2. Open `order_service.py` and add read methods to the `SpannerOrderService` class directly before the `main()` function:

```python
    def get_customer_by_email(self, email: str, max_staleness_seconds: int = 0) -> dict:
        """
        Read customer record using a lock-free snapshot.
        Supports strong consistency (default) or bounded staleness.
        """
        snapshot_kwargs = {}
        if max_staleness_seconds > 0:
            snapshot_kwargs["max_staleness"] = datetime.timedelta(seconds=max_staleness_seconds)

        with self.database.snapshot(**snapshot_kwargs) as snapshot:
            sql = (
                "SELECT CustomerId, FullName, Email, Balance, CustomerTier "
                "FROM Customers WHERE Email = @email"
            )
            results = snapshot.execute_sql(
                sql,
                params={"email": email},
                param_types={"email": spanner.param_types.STRING}
            )
            rows = list(results)
            if not rows:
                return {}
            row = rows[0]
            return {
                "customer_id": row[0],
                "full_name": row[1],
                "email": row[2],
                "balance": float(row[3]) if row[3] is not None else 0.0,
                "customer_tier": row[4]
            }

    def get_customers_by_keyset(self, customer_ids: list) -> list:
        """
        Read multiple customer records by primary key using KeySet.
        Bypasses SQL compilation and query plan optimization for maximum efficiency.
        """
        keyset = spanner.KeySet(keys=[[cid] for cid in customer_ids])
        with self.database.snapshot() as snapshot:
            results = snapshot.read(
                table="Customers",
                columns=["CustomerId", "FullName", "Email", "Balance", "CustomerTier"],
                keyset=keyset
            )
            customers = []
            for row in results:
                customers.append({
                    "customer_id": row[0],
                    "full_name": row[1],
                    "email": row[2],
                    "balance": float(row[3]) if row[3] is not None else 0.0,
                    "customer_tier": row[4]
                })
            return customers
```

> [!TIP]
> Always wrap snapshot operations inside `with self.database.snapshot() as snapshot:` context managers. Leaving snapshots open without a context manager leaks sessions from the pool, eventually triggering `ResourceExhausted: Pool is empty` errors.

3. Update the `main()` function in `order_service.py` to test both strong and stale snapshot reads and KeySet lookups:

```python
    # Test Snapshot Reads
    print("\n--- Testing Snapshot Reads ---")
    test_email = "sophia.rodriguez@example.com"
    customer = service.get_customer_by_email(test_email, max_staleness_seconds=0)
    if customer:
        print(f"Strong Snapshot: {customer['full_name']} (ID: {customer['customer_id']})")
        print(f"  Tier: {customer['customer_tier']} | Balance: ${customer['balance']:.2f}")

    stale_customer = service.get_customer_by_email(test_email, max_staleness_seconds=15)
    if stale_customer:
        print(f"Bounded Staleness (15s): Verified read balance ${stale_customer['balance']:.2f}")

    # Test KeySet Read
    print("\n--- Testing KeySet Read ---")
    if customer:
        keyset_results = service.get_customers_by_keyset([customer["customer_id"]])
        for c in keyset_results:
            print(f"KeySet Read Result: {c['full_name']} | Balance: ${c['balance']:.2f}")
```

4. Run the script to verify snapshot reads:

```bash
python3 order_service.py
```

5. Confirm that both strong snapshot and KeySet read calls successfully return customer details from the database.

---

### Task 3: Implement atomic read-write transactions with parameterized DML

In this task, you implement an order checkout transaction using `database.run_in_transaction()`. You read the customer balance with a shared read lock, validate sufficient funds, deduct the balance using parameterized DML, and insert the order and interleaved order items atomically.

1. Review transaction runner rules:
   - Pass your unit of work callback function to `database.run_in_transaction(callback)`.
   - The runner automatically acquires a session, starts a read-write transaction, issues commit, and handles retries.
   - The callback must be idempotent because lock contention causes Spanner to abort and re-run the callback from the beginning.
   - Never place external side effects such as sending emails or charging credit cards inside the callback!

2. Add the `place_order()` method to the `SpannerOrderService` class in `order_service.py`:

```python
    def place_order(self, customer_id: int, total_amount: float, line_items: list) -> dict:
        """
        Execute an atomic read-write transaction using run_in_transaction.
        Reads customer balance with shared lock, validates funds, updates balance,
        and inserts order and line items.
        """
        order_id = str(uuid.uuid4())

        def _transaction_callback(transaction):
            # Step 1: Read current balance with shared read lock
            query = "SELECT Balance FROM Customers WHERE CustomerId = @cid"
            results = list(transaction.execute_sql(
                query,
                params={"cid": customer_id},
                param_types={"cid": spanner.param_types.INT64}
            ))
            if not results:
                raise ValueError(f"Customer {customer_id} not found.")

            current_balance = float(results[0][0])
            if current_balance < total_amount:
                raise ValueError(
                    f"Insufficient funds: Customer balance ({current_balance:.2f}) "
                    f"is less than order total ({total_amount:.2f})."
                )

            # Step 2: Deduct balance using parameterized DML
            update_sql = "UPDATE Customers SET Balance = Balance - @deduction WHERE CustomerId = @cid"
            transaction.execute_update(
                update_sql,
                params={"deduction": total_amount, "cid": customer_id},
                param_types={
                    "deduction": spanner.param_types.NUMERIC,
                    "cid": spanner.param_types.INT64
                }
            )

            # Step 3: Insert order row using parameterized DML
            insert_order_sql = (
                "INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus) "
                "VALUES (@cid, @oid, CURRENT_TIMESTAMP(), @total, 'PROCESSING')"
            )
            transaction.execute_update(
                insert_order_sql,
                params={"cid": customer_id, "oid": order_id, "total": total_amount},
                param_types={
                    "cid": spanner.param_types.INT64,
                    "oid": spanner.param_types.STRING,
                    "total": spanner.param_types.NUMERIC
                }
            )

            # Step 4: Insert interleaved order items
            insert_item_sql = (
                "INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice) "
                "VALUES (@cid, @oid, @line, @pid, @qty, @price)"
            )
            for item in line_items:
                transaction.execute_update(
                    insert_item_sql,
                    params={
                        "cid": customer_id,
                        "oid": order_id,
                        "line": item["line_item"],
                        "pid": item["product_id"],
                        "qty": item["quantity"],
                        "price": item["unit_price"]
                    },
                    param_types={
                        "cid": spanner.param_types.INT64,
                        "oid": spanner.param_types.STRING,
                        "line": spanner.param_types.INT64,
                        "pid": spanner.param_types.STRING,
                        "qty": spanner.param_types.INT64,
                        "price": spanner.param_types.NUMERIC
                    }
                )

            return {
                "order_id": order_id,
                "customer_id": customer_id,
                "total_amount": total_amount,
                "status": "PROCESSING",
                "items_count": len(line_items)
            }

        # Execute within the transaction runner helper
        result = self.database.run_in_transaction(_transaction_callback)
        return result
```

> [!NOTE]
> Because `Orders` and `OrderItems` are interleaved within `Customers`, all four updates occur within the customer partition's Paxos split. Spanner commits the transaction in a single Paxos consensus round without distributed Two-Phase Commit overhead.

3. Update `main()` in `order_service.py` to execute a valid order placement and an invalid order placement that triggers insufficient funds:

```python
    # Test Read-Write Transaction
    print("\n--- Testing Read-Write Transaction (Checkout) ---")
    if customer:
        cid = customer["customer_id"]
        items = [
            {"line_item": 1, "product_id": "prod-sku-98124", "quantity": 1, "unit_price": 45.00},
            {"line_item": 2, "product_id": "prod-sku-55412", "quantity": 2, "unit_price": 20.00}
        ]
        order_total = 85.00

        try:
            order_info = service.place_order(cid, order_total, items)
            print(f"Transaction Committed: Order {order_info['order_id']}")
            print(f"  Total Charged: ${order_info['total_amount']:.2f} across {order_info['items_count']} item(s)")

            # Verify updated balance
            refreshed = service.get_customer_by_email(test_email)
            print(f"  Refreshed Customer Balance: ${refreshed['balance']:.2f}")
        except ValueError as err:
            print(f"Order placement failed: {err}")

        # Test Insufficient Funds Validation
        print("\nTesting Insufficient Funds Rejection:")
        try:
            service.place_order(cid, 999999.00, items)
            print("UNEXPECTED: Order should have failed validation.")
        except ValueError as err:
            print(f"SUCCESS: Transaction rejected as expected: {err}")
```

4. Run `order_service.py`:

```bash
python3 order_service.py
```

5. Confirm that the checkout transaction successfully commits, the customer balance decreases by $85.00, and the second transaction raises a `ValueError` for insufficient funds.

---

### Task 4: Ingest batch data using low-level Spanner mutations

In this task, you ingest batch customer records using low-level Spanner mutations and record server-authoritative TrueTime commit timestamps with `spanner.COMMIT_TIMESTAMP`.

1. Review mutation characteristics:
   - Mutations buffer row modifications client-side and transmit them in a single batch at commit time.
   - Bypasses SQL parsing, plan compilation, and optimizer evaluation on Spanner nodes.
   - Provides significantly higher write throughput for bulk ingestion and ETL operations.
   - Does not provide read-your-writes visibility within the same transaction.

2. Add the `batch_insert_customers_with_mutations()` method to `SpannerOrderService` in `order_service.py`:

```python
    def batch_insert_customers_with_mutations(self, customers: list) -> int:
        """
        Insert customer records using low-level Spanner mutations and spanner.COMMIT_TIMESTAMP.
        Mutations bypass SQL compilation for maximum write throughput.
        """
        def _mutation_callback(transaction):
            values = []
            for cust in customers:
                metadata_val = spanner.JsonObject(cust["metadata"]) if cust.get("metadata") else None
                values.append((
                    cust["customer_id"],
                    cust["full_name"],
                    cust["email"],
                    cust["balance"],
                    metadata_val,
                    spanner.COMMIT_TIMESTAMP
                ))

            transaction.insert(
                table="Customers",
                columns=["CustomerId", "FullName", "Email", "Balance", "Metadata", "CreatedAt"],
                values=values
            )
            return len(values)

        return self.database.run_in_transaction(_mutation_callback)
```

> [!NOTE]
> Passing `spanner.COMMIT_TIMESTAMP` instructs Spanner to populate the column with the exact TrueTime commit timestamp generated when Paxos consensus completes on the server.

3. Add test execution code to `main()` in `order_service.py`:

```python
    # Test Batch Mutations
    print("\n--- Testing Batch Ingestion with Mutations ---")
    new_customers = [
        {
            "customer_id": 810000000000000001,
            "full_name": "Mateo Silva",
            "email": "mateo.silva@example.com",
            "balance": 500.00,
            "metadata": json.dumps({"loyalty": {"tier": "GOLD", "points": 1200}})
        },
        {
            "customer_id": 810000000000000002,
            "full_name": "Zara Chen",
            "email": "zara.chen@example.com",
            "balance": 250.00,
            "metadata": json.dumps({"loyalty": {"tier": "SILVER", "points": 600}})
        }
    ]
    try:
        count = service.batch_insert_customers_with_mutations(new_customers)
        print(f"Committed {count} customer mutations with TrueTime commit timestamps.")
    except Exception as err:
        print(f"Mutation note: {err}")
```

4. Run `order_service.py`:

```bash
python3 order_service.py
```

5. Query the database using the `gcloud` CLI to verify that the newly inserted customer records have populated TrueTime commit timestamps:

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, CustomerTier, Balance, CreatedAt FROM Customers WHERE CustomerId IN (810000000000000001, 810000000000000002);"
```

6. Confirm that both rows exist and report valid `CreatedAt` timestamps and materialized `CustomerTier` values.

---

### Task 5: Configure custom retry policies and handle transaction errors

In this task, you configure custom exponential backoff retry policies and request timeouts for idempotent reads, and learn how to structure transaction error handling without intercepting `Aborted` exceptions.

1. Review Spanner exception handling architecture:
   - Lock conflicts in Spanner raise `google.api_core.exceptions.Aborted`.
   - The transaction runner catches `Aborted` and automatically re-executes the transaction callback.
   - If user code swallows `Exception` or `Aborted` inside the callback, the runner cannot retry, causing false transaction failures.
   - Catch domain exceptions (such as `ValueError`) explicitly, and allow `Aborted` to bubble up.

2. Add query execution with custom `Retry` and timeout to `SpannerOrderService` in `order_service.py`:

```python
    def execute_query_with_retry_and_timeout(self, query: str, params: dict, param_types: dict) -> list:
        """
        Execute an idempotent read query with custom Retry policy and RPC timeout.
        """
        custom_retry = Retry(
            predicate=lambda exc: isinstance(exc, (DeadlineExceeded, ServiceUnavailable)),
            initial=0.5,       # Initial delay in seconds
            maximum=5.0,       # Maximum delay between retries
            multiplier=2.0,    # Exponential backoff factor
            deadline=15.0      # Total time budget across all attempts
        )

        with self.database.snapshot() as snapshot:
            results = snapshot.execute_sql(
                query,
                params=params,
                param_types=param_types,
                retry=custom_retry,
                timeout=10.0   # Individual RPC timeout in seconds
            )
            return list(results)
```

> [!CAUTION]
> Only configure automated retries on idempotent operations such as read queries. Automatically retrying non-idempotent write statements following a `DeadlineExceeded` error can produce duplicate data because the statement may have already succeeded on the Spanner server.

3. Add test execution code to `main()` in `order_service.py`:

```python
    # Test Custom Retry Policy
    print("\n--- Testing Custom Retry Policy and Timeout ---")
    query = "SELECT CustomerId, FullName, Email FROM Customers WHERE CustomerTier = @tier"
    params = {"tier": "PLATINUM"}
    param_types = {"tier": spanner.param_types.STRING}
    platinum_records = service.execute_query_with_retry_and_timeout(query, params, param_types)
    print(f"Retrieved {len(platinum_records)} PLATINUM customer(s) using custom retry policy.")
    for r in platinum_records:
        print(f"  {r[1]} ({r[2]})")
```

4. Run `order_service.py`:

```bash
python3 order_service.py
```

5. Verify that the query executes with the custom retry policy and returns all matching customer records.

---

### Bonus Task 6: Parallelize analytical table scans with BatchClient

In this optional stretch task, you use `spanner.BatchClient` to divide a full table scan across cluster splits into independent partition tokens and process those partitions in parallel.

1. Review BatchClient mechanics:
   - `BatchClient` is designed for large-scale analytical and distributed processing frameworks (such as Apache Spark, Cloud Dataflow, or multiprocessing pools).
   - The coordinator calls `generate_partitions_sql()` to divide the table scan across storage splits.
   - Partition tokens serialize to strings and dispatch to worker nodes.
   - Each worker calls `process_partition()` on its assigned partition against the same TrueTime snapshot.

2. Add the `execute_distributed_batch_scan()` method to `SpannerOrderService` in `order_service.py`:

```python
    def execute_distributed_batch_scan(self, sql_query: str) -> int:
        """
        Partition a large table query across cluster splits using BatchClient.
        Simulates coordinator partition generation and distributed worker execution.
        """
        batch_client = self.client.batch_client(self.instance_id, self.database_id)
        total_rows_scanned = 0

        with batch_client.batch_snapshot() as snapshot:
            partitions = snapshot.generate_partitions_sql(sql_query)
            print(f"  [Coordinator] Generated {len(partitions)} parallel partitions across cluster splits.")

            for i, partition in enumerate(partitions):
                partition_rows = list(snapshot.process_partition(partition))
                print(f"  [Worker {i+1}] Processed partition: {len(partition_rows)} rows retrieved.")
                total_rows_scanned += len(partition_rows)

        return total_rows_scanned
```

3. Add batch scan execution code to `main()` in `order_service.py`:

```python
    # Test Distributed Batch Scan
    print("\n--- Testing BatchClient Partitioned Table Scan ---")
    batch_sql = "SELECT CustomerId, OrderId, TotalAmount, OrderStatus FROM Orders"
    total_scanned = service.execute_distributed_batch_scan(batch_sql)
    print(f"BatchClient scan completed: {total_scanned} total order records read across all partitions.")
```

4. Run `order_service.py`:

```bash
python3 order_service.py
```

5. Inspect the output to verify that the coordinator generated partition tokens and the simulated worker loops read the assigned rows from each partition.

6. Optional: Inspect the complete finished solution in `solution/order_service.py` to compare your implementation against the reference design.

---

## Congratulations!

In this lab, you have:
- Initialized a thread-safe Cloud Spanner client with a custom `PingingPool` session pool.
- Executed lock-free snapshot reads with bounded staleness and primary key `KeySet` lookups.
- Implemented atomic read-write transactions with parameterized DML using the transaction runner.
- Performed high-throughput batch data ingestion using low-level Spanner mutations and commit timestamps.
- Configured custom RPC retry policies, timeouts, and error handling without intercepting transaction aborts.
- Distributed large analytical queries across parallel partitions using `BatchClient`.
