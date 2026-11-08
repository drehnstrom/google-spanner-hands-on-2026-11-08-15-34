# Querying, Mutating, and Tuning SQL Queries in Cloud Spanner

## Time Required

45 minutes

## Overview

In this lab, you will query, modify, and tune data in Cloud Spanner using both GoogleSQL and PostgreSQL dialects. You will practice writing parameterized queries with JSON functions, execute co-located joins across interleaved tables, modify data using DML statements with returning clauses, and apply low-level Spanner mutations. You will also execute bulk updates using Partitioned DML, analyze query execution plans and runtime execution profiles, tune queries with optimizer directives, and evaluate point-in-time recovery using snapshot reads.

### You learn how to:
- Query interleaved relational hierarchies using GoogleSQL parameters and JSON operators.
- Execute and compare SQL queries across GoogleSQL and PostgreSQL database dialects.
- Modify data using DML with `THEN RETURN` clauses and low-level Spanner mutations.
- Perform bulk operations using Partitioned DML to scale beyond single-transaction mutation limits.
- Analyze query execution plans and execution profiles using `PLAN` and `PROFILE` query modes.
- Tune query performance using optimizer index hints, join directives, and the `ANALYZE` statement.
- Execute lock-free point-in-time snapshot reads using exact timestamps.

## Scenario

You are a database engineer managing the order management backend for a global retail platform built on Cloud Spanner. Your engineering team has implemented an interleaved table hierarchy for customers, orders, and order items.

To support high-concurrency order placement and reporting workloads, you must optimize query performance across distributed splits. You need to verify that co-located parent-child joins execute efficiently without distributed shuffles, understand when to choose standard DML versus high-throughput mutations, execute large-scale status updates safely without hitting the 80,000 mutation limit, inspect execution plans to resolve performance bottlenecks, and leverage snapshot reads to power read-heavy reporting workflows without acquiring locks or blocking active checkout transactions.

## Lab Instructions

### Task 1: Prepare your environment and populate sample data

In this task, you configure terminal environment variables, verify the existing Spanner instance and databases created in earlier labs, and populate test records across the customer and order hierarchy as well as the PostgreSQL inventory database.

1. Open Cloud Shell from the Google Cloud Console.

2. Set your environment variables for the Google Cloud project, Spanner instance, and database identifiers:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export GOOGLESQL_DB="orders-googlesql-db"
export PG_DB="inventory-pg-db"
```

3. Confirm that both the GoogleSQL and PostgreSQL databases are ready in your Spanner instance:

```bash
gcloud spanner databases list --instance="${INSTANCE_ID}" \
  --format="table(name.basename():label=DATABASE_ID,databaseDialect,state)"
```

4. Populate additional customer accounts, orders, and order items in `orders-googlesql-db`. You can copy the starter script from `starter/populate_sample_data.sql` or create it in your workspace:

```bash
cat << 'EOF' > populate_sample_data.sql
-- Sample Data Population Script for Lab 3
-- Populates multi-tier retail data across Customers, Orders, and OrderItems

-- 1. Insert Additional Customers across different tiers
INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Sophia Rodriguez',
  'sophia.rodriguez@example.com',
  750.25,
  JSON '{"loyalty": {"tier": "PLATINUM", "points": 3200}, "preferences": {"notifications": true, "channel": "email"}}',
  PENDING_COMMIT_TIMESTAMP()
);

INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Devon Park',
  'devon.park@example.com',
  42.00,
  JSON '{"loyalty": {"tier": "SILVER", "points": 450}, "preferences": {"notifications": false, "channel": "sms"}}',
  PENDING_COMMIT_TIMESTAMP()
);

INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
VALUES (
  GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq),
  'Amina Idris',
  'amina.idris@example.com',
  0.00,
  JSON '{"loyalty": {"tier": "BRONZE", "points": 80}, "preferences": {"notifications": true, "channel": "email"}}',
  PENDING_COMMIT_TIMESTAMP()
);

-- 2. Insert Orders for Sophia Rodriguez
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY),
  340.00,
  'DELIVERED'
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY),
  410.25,
  'PROCESSING'
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

-- 3. Insert Orders for Devon Park
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 25 DAY),
  42.00,
  'SHIPPED'
FROM Customers
WHERE Email = 'devon.park@example.com';

-- 4. Insert Orders for Marcus Vance
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
SELECT
  CustomerId,
  'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b',
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY),
  125.50,
  'DELIVERED'
FROM Customers
WHERE Email = 'marcus.vance@example.com';

-- 5. Insert Interleaved OrderItems for Sophia's Orders
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  1,
  'prod-sku-10293',
  2,
  120.00
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
  2,
  'prod-sku-55412',
  1,
  100.00
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  1,
  'prod-sku-88219',
  3,
  136.75
FROM Customers
WHERE Email = 'sophia.rodriguez@example.com';

-- 6. Insert OrderItems for Devon's Order
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a',
  1,
  'prod-sku-34109',
  1,
  42.00
FROM Customers
WHERE Email = 'devon.park@example.com';

-- 7. Insert OrderItems for Marcus's Order
INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
SELECT
  CustomerId,
  'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b',
  1,
  'prod-sku-98124',
  1,
  125.50
FROM Customers
WHERE Email = 'marcus.vance@example.com';
EOF
```

5. Execute the batch population script against `orders-googlesql-db`:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --file=populate_sample_data.sql
```

6. Initialize and populate the inventory table in the PostgreSQL dialect database `inventory-pg-db`. You can copy the starter script from `starter/pg_inventory.sql` or create it directly:

```bash
cat << 'EOF' > pg_inventory.sql
CREATE TABLE inventory_items (
  item_id character varying(36) NOT NULL PRIMARY KEY,
  item_name character varying(128) NOT NULL,
  category character varying(64) NOT NULL,
  attributes jsonb,
  stock_count bigint NOT NULL
);

INSERT INTO inventory_items (item_id, item_name, category, attributes, stock_count)
VALUES
  ('prod-sku-98124', 'Wireless Noise-Canceling Headphones', 'Electronics', '{"brand": "AuraSound", "model": "NC-500", "specs": {"color": "black", "bluetooth": "5.3"}}', 150),
  ('prod-sku-34109', 'Ergonomic Mechanical Keyboard', 'Peripherals', '{"brand": "KeyCraft", "model": "Pro-Tenkeyless", "specs": {"switch": "tactile", "backlight": "RGB"}}', 85),
  ('prod-sku-10293', 'Ultra-Wide 4K Gaming Monitor', 'Displays', '{"brand": "VisionMax", "model": "VX-34", "specs": {"refresh_rate_hz": 144, "curved": true}}', 30),
  ('prod-sku-55412', 'Braided USB-C Fast Charging Cable', 'Accessories', '{"brand": "CableSync", "model": "ToughFlex-2m", "specs": {"length_meters": 2, "wattage": 100}}', 500),
  ('prod-sku-88219', 'Smart Home Ambient Light Bar', 'Smart Home', '{"brand": "Lumina", "model": "Bar-RGBW", "specs": {"matter_support": true, "voltage": 120}}', 110);
EOF
```

7. Execute the DDL and DML statements against `inventory-pg-db`:

```bash
gcloud spanner databases execute-sql "${PG_DB}" \
  --instance="${INSTANCE_ID}" \
  --file=pg_inventory.sql
```

> [!NOTE]
> The Cloud Spanner CLI evaluates semicolons in the input file and commits each DDL and DML statement sequentially in its appropriate transaction context.

---

### Task 2: Query multi-tier data across Spanner SQL dialects

In this task, you query data across both GoogleSQL and PostgreSQL databases, comparing syntax differences, JSON extraction operators, and co-located relational joins across the interleaved table hierarchy.

1. Query customer records in `orders-googlesql-db` using GoogleSQL syntax, extracting nested attributes from the `Metadata` JSON column with `JSON_VALUE`:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, CustomerTier, JSON_VALUE(Metadata, '$.loyalty.points') AS LoyaltyPoints, JSON_VALUE(Metadata, '$.preferences.channel') AS ContactChannel FROM Customers ORDER BY CustomerTier, FullName;"
```

2. Execute a 3-tier join query across `Customers`, `Orders`, and `OrderItems`:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT c.FullName, c.CustomerTier, o.OrderId, o.OrderStatus, oi.LineItem, oi.ProductId, oi.Quantity, oi.UnitPrice FROM Customers AS c JOIN Orders AS o ON c.CustomerId = o.CustomerId JOIN OrderItems AS oi ON o.CustomerId = oi.CustomerId AND o.OrderId = oi.OrderId WHERE c.CustomerTier = 'PLATINUM' ORDER BY c.FullName, o.OrderId, oi.LineItem;"
```

> [!NOTE]
> Because `Orders` is interleaved in `Customers` and `OrderItems` is interleaved in `Orders`, Spanner stores matching child and grandchild rows in the exact same storage split alongside the parent customer row. This allows the query engine to evaluate the join locally without moving rows across the network.

3. Query `inventory-pg-db` using PostgreSQL dialect syntax, using the arrow operator `->>` to extract JSONB keys:

```bash
gcloud spanner databases execute-sql "${PG_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT item_id, item_name, category, attributes->>'brand' AS brand, attributes->'specs'->>'color' AS color, stock_count FROM inventory_items WHERE stock_count > 50 ORDER BY stock_count DESC;"
```

4. Compare the differences between the two dialects:
   - GoogleSQL uses `JSON_VALUE(column, '$.path')` and named parameters like `@customer_id`.
   - PostgreSQL uses `column->>'key'` and positional parameters like `$1`.
   - Both dialects execute on the same distributed query processing engine and enforce identical ACID guarantees.

---

### Task 3: Modify data using DML and Spanner mutations

In this task, you modify data using standard SQL DML statements with the `THEN RETURN` clause, and compare them with low-level Spanner Mutations executed via the `gcloud spanner rows` CLI.

1. Execute an `UPDATE` statement in `orders-googlesql-db` using the `THEN RETURN` clause to immediately inspect the modified order attributes without executing a secondary `SELECT` query:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Orders SET OrderStatus = 'SHIPPED' WHERE OrderStatus = 'PROCESSING' THEN RETURN CustomerId, OrderId, OrderStatus;"
```

> [!TIP]
> The `THEN RETURN` clause in GoogleSQL (and `RETURNING` in PostgreSQL) eliminates the latency and lock overhead of issuing an additional `SELECT` statement after completing a write.

2. Verify that the updated rows now reflect `OrderStatus = 'SHIPPED'` directly from the command output.

3. Insert a new customer row using low-level Spanner Mutations via `gcloud spanner rows insert`:

```bash
gcloud spanner rows insert \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,FullName='Elena Gomez',Email='elena.gomez@example.com',Balance=300.00,CreatedAt='spanner.commit_timestamp()'"
```

4. Update the newly inserted row using `gcloud spanner rows update`:

```bash
gcloud spanner rows update \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,Balance=350.00"
```

5. Confirm the row exists with the updated balance:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, Balance, CreatedAt FROM Customers WHERE CustomerId = 900000000000000001;"
```

6. Delete the test row using `gcloud spanner rows delete`:

```bash
gcloud spanner rows delete \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --keys="900000000000000001"
```

7. Observe the key operational differences between DML and Mutations:
   - DML statements parse and compile SQL, support SQL expressions and subqueries, and allow subsequent statements in the transaction to read modified rows (“read-your-writes”).
   - Mutations buffer key-value modifications on the client side and transmit them at commit time without SQL parsing overhead, delivering higher write throughput but without read-your-writes visibility during the transaction.

---

### Task 4: Execute bulk updates using Partitioned DML

In this task, you execute large-scale status updates using Partitioned DML and contrast its execution semantics with standard atomic transactions.

1. Review the operational constraint: A standard Spanner read-write transaction is strictly capped at 80,000 mutations and 100 MB of transaction data. Running an unbounded `UPDATE` or `DELETE` across thousands of rows can easily exceed this limit when secondary indexes multiply mutation counts.

2. Execute a bulk status transition on `Orders` using Partitioned DML with the `--enable-partitioned-dml` flag:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --enable-partitioned-dml \
  --sql="UPDATE Orders SET OrderStatus = 'DELIVERED' WHERE OrderStatus = 'SHIPPED';"
```

3. Confirm that the affected rows were successfully updated:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT OrderStatus, COUNT(*) AS OrderCount FROM Orders GROUP BY OrderStatus;"
```

> [!WARNING]
> Partitioned DML partitions the table key space and runs independent transactions across splits in parallel. If an error occurs midway, already-committed partitions remain committed. Never use Partitioned DML for transactional multi-table operations where full atomic rollback is required.

---

### Task 5: Analyze query execution plans and profile runtime performance

In this task, you inspect compile-time query execution plans and runtime execution profiles to identify distributed relational operators and measure execution latency.

1. Compile the query execution plan for an order lookup using `--query-mode=PLAN` (the equivalent of `EXPLAIN`):

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"
```

2. Inspect the output structure in the `stats.queryPlan` section:
   - Locate the `Index Scan` operator.
   - Note the `scan_target` metadata: `idx_orders_date_covering`.
   - Observe that because `TotalAmount` and `OrderStatus` are stored in the covering index (`STORING`), the query engine does not perform an expensive back-lookup to the `Orders` base table.

3. Execute the same query in profile mode using `--query-mode=PROFILE` (the equivalent of `EXPLAIN ANALYZE`):

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PROFILE \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"
```

4. Examine the runtime telemetry captured in `stats.queryStats`:
   - `elapsed_time`: Total wall-clock execution time.
   - `cpu_time`: CPU consumption across all participating Spanner nodes.
   - `rows_returned`: Total rows returned to the client.
   - `rows_scanned`: Number of physical index rows scanned.

> [!TIP]
> Use `--query-mode=PLAN` during schema and query design to verify index usage without incurring database read load. Use `--query-mode=PROFILE` to troubleshoot slow queries and measure actual CPU and network overhead.

---

### Task 6: Tune queries using optimizer hints and statistics collection

In this task, you override optimizer decisions using index and join hints, run the `ANALYZE` command to update cost-based optimizer statistics, and query the information schema.

1. Force a full table scan on `Orders` using the `FORCE_INDEX=_BASE_TABLE` directive and inspect the resulting plan:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders @{FORCE_INDEX=_BASE_TABLE} WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"
```

2. Compare this plan against the plan from Task 5:
   - Notice that the operator changes from `Index Scan` to `Table Scan` preceded by a `Distributed Union`.
   - The root coordinator must now gather and scan all table splits across the cluster instead of reading the targeted index key range.

3. Test forcing a distributed hash join between `Customers` and `Orders` using the `JOIN_METHOD=HASH_JOIN` hint:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT c.FullName, o.OrderId, o.TotalAmount FROM Customers AS c JOIN @{JOIN_METHOD=HASH_JOIN} Orders AS o ON c.CustomerId = o.CustomerId WHERE c.CustomerTier = 'PLATINUM';"
```

4. Observe the operator in the plan:
   - Notice that Spanner introduces a `Distributed Hash Join` operator instead of the default `Distributed Cross Apply`.
   - In production, forcing a hash join on interleaved tables is typically an anti-pattern because it forces compute nodes to build in-memory hash tables rather than evaluating the join in local storage.

5. Update the cost-based optimizer statistics by executing the `ANALYZE` statement:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="ANALYZE;"
```

6. Query the information schema to verify the optimizer statistics package and collection timestamp:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT package_name, allow_gc, timestamp FROM INFORMATION_SCHEMA.SPANNER_STATISTICS ORDER BY timestamp DESC LIMIT 5;"
```

> [!IMPORTANT]
> Always execute `ANALYZE` following major data imports or batch migrations. Stale optimizer statistics can cause Spanner to choose full table scans over secondary indexes, triggering severe CPU spikes across cluster nodes.

---

### Task 7: Execute historical snapshot reads and evaluate transaction isolation

In this task, you execute historical snapshot reads using exact timestamps to observe past database state without acquiring locks or blocking concurrent transactions.

1. Record the current UTC timestamp before applying any modifications:

```bash
TS_BASELINE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Baseline timestamp: ${TS_BASELINE}"
```

2. Wait three seconds to ensure TrueTime separation between timestamps:

```bash
sleep 3
```

3. Update the balance of customer `Sophia Rodriguez` to simulate a live business transaction:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Customers SET Balance = 1200.00 WHERE Email = 'sophia.rodriguez@example.com';"
```

4. Query the current balance using a standard strong read:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT FullName, Balance FROM Customers WHERE Email = 'sophia.rodriguez@example.com';"
```

5. Confirm that the current balance reflects `1200.00`.

6. Execute a historical snapshot read at `${TS_BASELINE}` using the `--read-timestamp` flag:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --read-timestamp="${TS_BASELINE}" \
  --sql="SELECT FullName, Balance FROM Customers WHERE Email = 'sophia.rodriguez@example.com';"
```

7. Observe that the returned balance is `750.25`, the exact value Sophia had prior to the update:
   - Spanner uses TrueTime commit timestamps and Multi-Version Concurrency Control (MVCC) to serve historical reads up to the database version retention period (default 1 hour, configurable up to 7 days).
   - Snapshot reads acquire zero shared or exclusive locks, meaning reporting queries can read historical snapshots without stalling active checkout transactions.

---

### Bonus Task 8: Diagnose and remediate an unbounded root aggregation bottleneck

In this optional stretch task, you simulate the “Unbounded Root Aggregation” anti-pattern and compare its execution plan against an index-scoped query.

1. Run an aggregation query across all orders grouped by status using `--query-mode=PROFILE`:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PROFILE \
  --sql="SELECT OrderStatus, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalRevenue FROM Orders GROUP BY OrderStatus;"
```

2. Inspect the operators in the output:
   - Notice the `Distributed Union` gathering all split data back to the root coordinator.
   - For millions of unpartitioned rows, this pattern causes coordinator node memory saturation.

3. Rewrite the query to restrict the aggregation to a specific customer partition key:

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PROFILE \
  --sql="SELECT OrderStatus, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalRevenue FROM Orders WHERE CustomerId = (SELECT CustomerId FROM Customers WHERE Email = 'sophia.rodriguez@example.com') GROUP BY OrderStatus;"
```

4. Compare the profile results:
   - The partition-scoped query targets the specific split hosting Sophia’s records, eliminating distributed cross-split coordination.

---

## Congratulations!

In this lab, you have:
- Queried interleaved relational hierarchies using GoogleSQL parameters and JSON operators.
- Executed and compared SQL queries across GoogleSQL and PostgreSQL database dialects.
- Modified data using DML with `THEN RETURN` clauses and low-level Spanner mutations.
- Performed bulk operations using Partitioned DML to scale beyond single-transaction mutation limits.
- Analyzed query execution plans and execution profiles using `PLAN` and `PROFILE` query modes.
- Tuned query performance using optimizer index hints, join directives, and the `ANALYZE` statement.
- Executed lock-free point-in-time snapshot reads using exact timestamps.
