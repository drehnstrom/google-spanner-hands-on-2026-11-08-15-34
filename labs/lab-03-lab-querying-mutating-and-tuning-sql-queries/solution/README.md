# Solution: Querying, Mutating, and Tuning SQL Queries in Cloud Spanner

## End State

- Populated multi-tier schema in `orders-googlesql-db` across parent table `Customers`, interleaved child table `Orders`, and interleaved grandchild table `OrderItems`.
- A populated table `inventory_items` in PostgreSQL-dialect database `inventory-pg-db` containing sample JSONB attributes and inventory levels.
- Demonstrated GoogleSQL query features:
  - JSON attribute extraction using `JSON_VALUE(Metadata, '$.loyalty.points')`.
  - Co-located relational joins across `Customers`, `Orders`, and `OrderItems` executed via `Distributed Cross Apply` without cross-split network shuffling.
- Demonstrated PostgreSQL dialect query features:
  - Arrow operators (`->>`) to extract values from JSONB columns.
  - Case-folded table and column identifiers.
- Demonstrated data modification mechanisms:
  - SQL DML using `THEN RETURN` to return modified column values within an atomic read-write transaction.
  - Low-level Spanner Mutations using `gcloud spanner rows insert`, `update`, and `delete` bypassing SQL compilation and query planning.
  - Partitioned DML using `--enable-partitioned-dml` to execute bulk updates across split chunks bypassing the 80,000 mutation limit.
- Evaluated Spanner Cost-Based Optimizer behavior:
  - Compile-time plan analysis (`--query-mode=PLAN`) inspecting operators: `Distributed Union`, `Distributed Cross Apply`, `Table Scan`, and `Index Scan`.
  - Runtime execution profiling (`--query-mode=PROFILE`) inspecting execution latency, CPU time, and row scan metrics.
  - Query tuning directives: forcing index usage with `@{FORCE_INDEX=...}`, forcing full table scan with `@{FORCE_INDEX=_BASE_TABLE}`, and forcing join algorithms with `@{JOIN_METHOD=HASH_JOIN}`.
  - Cost-based statistics refresh via `ANALYZE` and validation through `INFORMATION_SCHEMA.SPANNER_STATISTICS`.
- Demonstrated Point-in-Time Recovery and Snapshot Reads:
  - Executed historical snapshot queries with `--read-timestamp` to observe past database state without acquiring locks or blocking concurrent writers.

## How to Verify

From Google Cloud Shell or an authenticated terminal with Cloud SDK:

```bash
# Set environment variables
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export GOOGLESQL_DB="orders-googlesql-db"
export PG_DB="inventory-pg-db"
```

### 1. Verify PostgreSQL Dialect Querying

```bash
gcloud spanner databases execute-sql "${PG_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT item_name, category, attributes->>'brand' AS brand, stock_count FROM inventory_items WHERE stock_count > 50 ORDER BY stock_count DESC;"
```

Expected output:
```text
item_name                            category     brand      stock_count
Braided USB-C Fast Charging Cable    Accessories  CableSync  500
Wireless Noise-Canceling Headphones  Electronics  AuraSound  150
Smart Home Ambient Light Bar         Smart Home   Lumina     110
Ergonomic Mechanical Keyboard        Peripherals  KeyCraft   85
```

### 2. Verify GoogleSQL Parameterized Query and JSON Traversal

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, CustomerTier, JSON_VALUE(Metadata, '$.loyalty.points') AS Points, Balance FROM Customers WHERE CustomerTier = 'PLATINUM';"
```

Expected output includes customer records for Alice Chen and Sophia Rodriguez with their loyalty tier and points.

### 3. Verify DML with THEN RETURN Clause

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Orders SET OrderStatus = 'SHIPPED' WHERE OrderStatus = 'PROCESSING' THEN RETURN CustomerId, OrderId, OrderStatus;"
```

Expected output displays the modified `CustomerId`, `OrderId`, and the new `OrderStatus` of `SHIPPED` directly in the tabular output.

### 4. Verify Low-Level Mutations API

```bash
# Insert via mutation
gcloud spanner rows insert \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,FullName='Elena Gomez',Email='elena.gomez@example.com',Balance=300.00,CreatedAt='spanner.commit_timestamp()'"

# Update via mutation
gcloud spanner rows update \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,Balance=350.00"

# Verify mutation results
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, Balance FROM Customers WHERE CustomerId = 900000000000000001;"

# Delete via mutation
gcloud spanner rows delete \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --keys="900000000000000001"
```

### 5. Verify Partitioned DML Execution

```bash
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --enable-partitioned-dml \
  --sql="UPDATE Orders SET OrderStatus = 'DELIVERED' WHERE OrderStatus = 'SHIPPED';"
```

Expected output:
```text
row_count: 3
```

### 6. Verify Execution Plan and Optimizer Tuning

```bash
# Test covering index plan
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"
```

Expected output contains `Index Scan` targeting `idx_orders_date_covering`.

```bash
# Test forced base table scan
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders @{FORCE_INDEX=_BASE_TABLE} WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"
```

Expected output contains `Distributed Union` and `Table Scan` targeting `Orders`.

```bash
# Run ANALYZE and inspect statistics
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="ANALYZE;"

gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT package_name, allow_gc, timestamp FROM INFORMATION_SCHEMA.SPANNER_STATISTICS;"
```

### 7. Verify Historical Snapshot Read

```bash
# Record current timestamp
TS_RECORD=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sleep 2

# Perform an update
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Customers SET Balance = 999.99 WHERE Email = 'sophia.rodriguez@example.com';"

# Execute historical read at TS_RECORD
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --read-timestamp="${TS_RECORD}" \
  --sql="SELECT Email, Balance FROM Customers WHERE Email = 'sophia.rodriguez@example.com';"
```

Expected: The query returns Sophia's historical balance prior to the update (`750.25`), validating Point-in-Time Recovery.

## Built With

- Google Cloud SDK (`gcloud`) version 490+ / Cloud Shell
- Google Cloud Spanner GoogleSQL and PostgreSQL database engines (checked November 2026)
- Cloud Spanner Cost-Based Optimizer (checked November 2026)
- Unverified: Physical multi-split data distribution across geographically separated zones (tested within a single regional instance where split operators are evaluated across compute workers within the regional Paxos group)
