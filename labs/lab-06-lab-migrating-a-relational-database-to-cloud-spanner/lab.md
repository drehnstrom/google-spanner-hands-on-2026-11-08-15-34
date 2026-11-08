# Migrating a Relational Database to Cloud Spanner

## Time Required

45 minutes

## Overview

In this lab, you will assess a legacy relational database schema, convert legacy schema constructs into Cloud Spanner architecture, eliminate monotonic primary key hotspots using bit-reversed sequences, implement table interleaving to replace foreign key joins, execute bulk data ingestion with mutation batching and secondary index deferral, reconcile data parity across engines, and configure Spanner Change Streams for zero-downtime cutover and reverse replication.

### You learn how to:
- Assess legacy relational database schemas and identify migration anti-patterns.
- Refactor auto-increment primary keys using bit-reversed sequences to eliminate write hotspots.
- Translate foreign key hierarchies into co-located interleaved tables.
- Execute bulk data loading using mutation batching and secondary index deferral.
- Validate data parity between source and Spanner using row counts and aggregate checksums.
- Configure Cloud Spanner Change Streams for zero-downtime cutover and reverse replication.

## Scenario

Your enterprise retail organization is migrating its transactional order processing database from an on-premises MySQL cluster to Cloud Spanner. The legacy schema relies on sequential auto-increment primary keys, cross-table foreign keys, and procedural triggers. A direct lift-and-shift migration would cause severe write hotspots on sequential keys and cross-split latency on multi-table joins. As the lead database migration architect, you must assess the legacy schema, redesign the tables for horizontal distribution, bulk-load historical data while deferring secondary indexes, reconcile data parity, and establish change streams to support zero-downtime cutover and emergency rollback.

## Lab Instructions

### Task 1: Assess a legacy relational schema and identify migration anti-patterns

In this task, you inspect your environment, examine a legacy MySQL retail schema, identify architectural anti-patterns, and evaluate migration compatibility.

1. Open Cloud Shell in your Google Cloud Console.

2. Verify that your active Google Cloud project ID is set in your session:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
echo "Active Project ID: ${PROJECT_ID}"
```

> [!NOTE]
> If the command returns empty or `(unset)`, run `gcloud config set project YOUR_PROJECT_ID` using your assigned Google Cloud project ID.

3. Verify that the Cloud Spanner instance `order-mgmt-instance` created in earlier labs is available:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="value(state,processingUnits)"
```

> [!TIP]
> If the instance does not exist, create it now:
> `gcloud spanner instances create order-mgmt-instance --config=regional-us-central1 --description="Order Management Instance" --processing-units=100`

4. Create a working directory for your migration artifacts:

```bash
mkdir -p ~/spanner-migration
cd ~/spanner-migration
```

5. Create the legacy schema file `legacy_retail_schema.sql` representing the source database dump:

```bash
cat << 'EOF' > legacy_retail_schema.sql
-- Legacy Relational Schema (MySQL 8.0 Dialect)
CREATE TABLE customers (
    customer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    account_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2) NOT NULL,
    order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
) ENGINE=InnoDB;

CREATE INDEX idx_legacy_orders_date ON orders (order_date);

CREATE TABLE order_items (
    item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_sku VARCHAR(64) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    line_total DECIMAL(12, 2) NOT NULL,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DELIMITER //
CREATE TRIGGER trg_after_order_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE customers
    SET account_balance = account_balance - NEW.total_amount
    WHERE customer_id = NEW.customer_id;
END;
//
DELIMITER ;
EOF
```

6. Inspect `legacy_retail_schema.sql` and identify the architectural anti-patterns that must be refactored before deploying to Cloud Spanner:
   - **Monotonic primary keys**: `customer_id` and `order_id` use `AUTO_INCREMENT`. In Spanner, monotonically increasing keys concentrate all write operations onto a single storage split and node, causing severe write bottlenecking.
   - **Procedural trigger**: The `trg_after_order_insert` trigger updates customer balances automatically on insert. Spanner does not support stored procedures or triggers; this logic must be moved to application transactions.
   - **Non-interleaved foreign keys**: `orders` and `order_items` reference their parent tables via standalone foreign keys. In Spanner, querying non-interleaved tables requires cross-split network calls and distributed two-phase locking.
   - **Active secondary index**: `idx_legacy_orders_date` multiplies write mutations during bulk data loading.

> [!WARNING]
> Never perform a direct lift-and-shift of a relational schema to Cloud Spanner without redesigning sequential keys and foreign key hierarchies. Doing so produces hot splits and poor query performance.

### Task 2: Refactor the schema with bit-reversed sequences and table interleaving

In this task, you create the target Spanner database, define bit-reversed sequences to eliminate monotonic hotspots, implement a collocated table hierarchy using table interleaving, and apply optimal data type mappings.

1. Create a new GoogleSQL-dialect database named `retail-migrated-db` on `order-mgmt-instance`:

```bash
gcloud spanner databases create retail-migrated-db \
  --instance=order-mgmt-instance \
  --database-dialect=GOOGLE_STANDARD_SQL
```

2. Confirm that the database is in the `READY` state:

```bash
gcloud spanner databases describe retail-migrated-db \
  --instance=order-mgmt-instance \
  --format="value(state)"
```

3. Create the sequence definitions using DDL to replace the legacy `AUTO_INCREMENT` keys:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE SEQUENCE CustomerIdSeq OPTIONS (sequence_kind = 'bit_reversed_positive');
         CREATE SEQUENCE OrderIdSeq OPTIONS (sequence_kind = 'bit_reversed_positive');"
```

> [!NOTE]
> `bit_reversed_positive` sequences generate unique positive 64-bit integers by bit-reversing an internal counter. Successive calls produce values scattered across the entire keyspace, distributing insert operations evenly across all Spanner splits and nodes.

4. Create the parent `Customers` table, setting the `CustomerId` column default to the bit-reversed sequence:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE Customers (
           CustomerId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerIdSeq)),
           FirstName STRING(50) NOT NULL,
           LastName STRING(50) NOT NULL,
           Email STRING(100) NOT NULL,
           AccountBalance NUMERIC NOT NULL,
           CreatedAt TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)
         ) PRIMARY KEY (CustomerId);"
```

> [!IMPORTANT]
> MySQL `BIGINT` maps to Spanner `INT64`, `VARCHAR(N)` maps to `STRING(N)`, and `DECIMAL(12,2)` maps to `NUMERIC`. Avoid using `STRING(MAX)` when column lengths are bounded, as unbounded strings increase memory buffer allocations in execution plans.

5. Create the child `Orders` table, interleaved inside `Customers`:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE Orders (
           CustomerId INT64 NOT NULL,
           OrderId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderIdSeq)),
           OrderDate TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
           TotalAmount NUMERIC NOT NULL,
           OrderStatus STRING(30) NOT NULL
         ) PRIMARY KEY (CustomerId, OrderId),
           INTERLEAVE IN PARENT Customers ON DELETE CASCADE;"
```

> [!NOTE]
> Notice the composite primary key `(CustomerId, OrderId)`. Child tables in Spanner must include the parent primary key as the leading key part. `INTERLEAVE IN PARENT Customers ON DELETE CASCADE` physically co-locates all order rows for a customer into the same storage split as the customer row.

6. Create the grandchild `OrderItems` table, interleaved inside `Orders`:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE OrderItems (
           CustomerId INT64 NOT NULL,
           OrderId INT64 NOT NULL,
           ItemId INT64 NOT NULL,
           ProductSku STRING(64) NOT NULL,
           Quantity INT64 NOT NULL,
           UnitPrice NUMERIC NOT NULL,
           LineTotal NUMERIC NOT NULL
         ) PRIMARY KEY (CustomerId, OrderId, ItemId),
           INTERLEAVE IN PARENT Orders ON DELETE CASCADE;"
```

7. Verify that the table hierarchy and interleaving relationships are registered in the schema catalog:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"
```

> [!TIP]
> Notice that we deliberately omitted the secondary index `idx_orders_customer_date` from our initial schema. In the next task, you will see why deferring secondary index creation until after data loading is critical for migration performance.

### Task 3: Execute bulk data ingestion with mutation batching and secondary index deferral

In this task, you execute structured bulk data loading respecting Spanner transaction and mutation limits, monitor row ingestion, and build secondary indexes asynchronously post-load.

1. Review the Spanner mutation constraints:
   - Hard limit of 80,000 mutations per commit.
   - 100 MB transaction size limit.
   - Optimal batch size: 2,000 to 5,000 mutations per commit.
   - Each column inserted counts as 1 mutation, and each secondary index on the table adds another mutation per index.

2. Create the historical bulk data script `bulk_load_data.sql`:

```bash
cat << 'EOF' > bulk_load_data.sql
-- Batch 1: Historical Customers
INSERT INTO Customers (CustomerId, FirstName, LastName, Email, AccountBalance, CreatedAt)
VALUES
  (1001, 'Marcus', 'Vance', 'marcus.vance@example.com', 450.00, TIMESTAMP '2025-01-15 10:00:00Z'),
  (1002, 'Elena', 'Reyes', 'elena.reyes@example.com', 1250.75, TIMESTAMP '2025-01-16 11:30:00Z'),
  (1003, 'Tariq', 'Mansoor', 'tariq.mansoor@example.com', 85.20, TIMESTAMP '2025-01-18 14:15:00Z'),
  (1004, 'Sophia', 'Chen', 'sophia.chen@example.com', 3200.00, TIMESTAMP '2025-01-20 09:00:00Z'),
  (1005, 'Liam', 'OConnor', 'liam.oconnor@example.com', 610.50, TIMESTAMP '2025-01-22 16:45:00Z');

-- Batch 2: Historical Orders (Interleaved in Customers)
INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
VALUES
  (1001, 5001, TIMESTAMP '2025-02-01 08:30:00Z', 185.00, 'COMPLETED'),
  (1001, 5002, TIMESTAMP '2025-02-15 12:00:00Z', 265.00, 'COMPLETED'),
  (1002, 5003, TIMESTAMP '2025-02-10 15:45:00Z', 750.50, 'COMPLETED'),
  (1002, 5004, TIMESTAMP '2025-02-28 17:10:00Z', 500.25, 'PROCESSING'),
  (1003, 5005, TIMESTAMP '2025-02-05 11:20:00Z', 85.20, 'COMPLETED'),
  (1004, 5006, TIMESTAMP '2025-02-12 09:15:00Z', 1450.00, 'COMPLETED'),
  (1004, 5007, TIMESTAMP '2025-02-20 14:00:00Z', 1750.00, 'COMPLETED'),
  (1005, 5008, TIMESTAMP '2025-02-18 16:30:00Z', 610.50, 'DELIVERED');

-- Batch 3: Historical OrderItems (Interleaved in Orders)
INSERT INTO OrderItems (CustomerId, OrderId, ItemId, ProductSku, Quantity, UnitPrice, LineTotal)
VALUES
  (1001, 5001, 1, 'SKU-HEADSET-PRO', 1, 185.00, 185.00),
  (1001, 5002, 1, 'SKU-KEYBOARD-MECH', 1, 140.00, 140.00),
  (1001, 5002, 2, 'SKU-MOUSE-WIRELESS', 1, 125.00, 125.00),
  (1002, 5003, 1, 'SKU-MONITOR-4K', 1, 650.00, 650.00),
  (1002, 5003, 2, 'SKU-CABLE-HDMI', 2, 50.25, 100.50),
  (1002, 5004, 1, 'SKU-DESK-MAT', 2, 45.00, 90.00),
  (1002, 5004, 2, 'SKU-DOCKING-STATION', 1, 410.25, 410.25),
  (1003, 5005, 1, 'SKU-WEBCAM-HD', 1, 85.20, 85.20),
  (1004, 5006, 1, 'SKU-LAPTOP-STAND', 2, 75.00, 150.00),
  (1004, 5006, 2, 'SKU-GPU-CARD-RTX', 1, 1300.00, 1300.00),
  (1004, 5007, 1, 'SKU-SERVER-RACK-CAB', 1, 1750.00, 1750.00),
  (1005, 5008, 1, 'SKU-CHAIR-ERGONOMIC', 1, 610.50, 610.50);
EOF
```

3. Ingest the bulk historical dataset into `retail-migrated-db`:

```bash
# Ingest Batch 1: Customers
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FirstName, LastName, Email, AccountBalance, CreatedAt)
         VALUES
           (1001, 'Marcus', 'Vance', 'marcus.vance@example.com', 450.00, TIMESTAMP '2025-01-15 10:00:00Z'),
           (1002, 'Elena', 'Reyes', 'elena.reyes@example.com', 1250.75, TIMESTAMP '2025-01-16 11:30:00Z'),
           (1003, 'Tariq', 'Mansoor', 'tariq.mansoor@example.com', 85.20, TIMESTAMP '2025-01-18 14:15:00Z'),
           (1004, 'Sophia', 'Chen', 'sophia.chen@example.com', 3200.00, TIMESTAMP '2025-01-20 09:00:00Z'),
           (1005, 'Liam', 'OConnor', 'liam.oconnor@example.com', 610.50, TIMESTAMP '2025-01-22 16:45:00Z');"

# Ingest Batch 2: Orders
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
         VALUES
           (1001, 5001, TIMESTAMP '2025-02-01 08:30:00Z', 185.00, 'COMPLETED'),
           (1001, 5002, TIMESTAMP '2025-02-15 12:00:00Z', 265.00, 'COMPLETED'),
           (1002, 5003, TIMESTAMP '2025-02-10 15:45:00Z', 750.50, 'COMPLETED'),
           (1002, 5004, TIMESTAMP '2025-02-28 17:10:00Z', 500.25, 'PROCESSING'),
           (1003, 5005, TIMESTAMP '2025-02-05 11:20:00Z', 85.20, 'COMPLETED'),
           (1004, 5006, TIMESTAMP '2025-02-12 09:15:00Z', 1450.00, 'COMPLETED'),
           (1004, 5007, TIMESTAMP '2025-02-20 14:00:00Z', 1750.00, 'COMPLETED'),
           (1005, 5008, TIMESTAMP '2025-02-18 16:30:00Z', 610.50, 'DELIVERED');"

# Ingest Batch 3: OrderItems
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO OrderItems (CustomerId, OrderId, ItemId, ProductSku, Quantity, UnitPrice, LineTotal)
         VALUES
           (1001, 5001, 1, 'SKU-HEADSET-PRO', 1, 185.00, 185.00),
           (1001, 5002, 1, 'SKU-KEYBOARD-MECH', 1, 140.00, 140.00),
           (1001, 5002, 2, 'SKU-MOUSE-WIRELESS', 1, 125.00, 125.00),
           (1002, 5003, 1, 'SKU-MONITOR-4K', 1, 650.00, 650.00),
           (1002, 5003, 2, 'SKU-CABLE-HDMI', 2, 50.25, 100.50),
           (1002, 5004, 1, 'SKU-DESK-MAT', 2, 45.00, 90.00),
           (1002, 5004, 2, 'SKU-DOCKING-STATION', 1, 410.25, 410.25),
           (1003, 5005, 1, 'SKU-WEBCAM-HD', 1, 85.20, 85.20),
           (1004, 5006, 1, 'SKU-LAPTOP-STAND', 2, 75.00, 150.00),
           (1004, 5006, 2, 'SKU-GPU-CARD-RTX', 1, 1300.00, 1300.00),
           (1004, 5007, 1, 'SKU-SERVER-RACK-CAB', 1, 1750.00, 1750.00),
           (1005, 5008, 1, 'SKU-CHAIR-ERGONOMIC', 1, 610.50, 610.50);"
```

4. Verify that all rows were ingested across the three tables:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT 'Customers' AS entity, COUNT(*) AS count FROM Customers
         UNION ALL
         SELECT 'Orders' AS entity, COUNT(*) AS count FROM Orders
         UNION ALL
         SELECT 'OrderItems' AS entity, COUNT(*) AS count FROM OrderItems;"
```

5. Apply the secondary index deferral protocol by creating `idx_orders_customer_date` post-load:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE INDEX idx_orders_customer_date ON Orders (CustomerId, OrderDate DESC);"
```

> [!NOTE]
> Creating secondary indexes after loading data executes as an asynchronous background schema update. Spanner reads data across storage splits in parallel and builds the index without acquiring read-write locks or multiplying mutation counts during bulk ingestion.

6. Confirm that the secondary index is active in the schema catalog:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT index_name, table_name, is_unique FROM INFORMATION_SCHEMA.INDEXES WHERE index_name = 'idx_orders_customer_date';"
```

### Task 4: Validate data parity and referential integrity

In this task, you execute reconciliation queries to compare row counts and financial aggregate totals, verify co-located join performance, and test cascading referential integrity.

1. Execute a financial reconciliation query comparing the sum of `TotalAmount` on `Orders` with the sum of `LineTotal` on `OrderItems`:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT
           SUM(o.TotalAmount) AS total_orders,
           SUM(i.LineTotal) AS total_items,
           SUM(o.TotalAmount) - SUM(i.LineTotal) AS discrepancy
         FROM Orders o
         JOIN OrderItems i ON o.CustomerId = i.CustomerId AND o.OrderId = i.OrderId
         WHERE o.CustomerId BETWEEN 1001 AND 1005;"
```

> [!NOTE]
> Both `total_orders` and `total_items` reconcile to `5596.45`, with a `discrepancy` of `0.00`. In production migrations, parallel checksum and aggregate queries are executed between the legacy source and Cloud Spanner to ensure numeric precision and zero data drift before initiating cutover.

2. Verify that co-located queries across the three-tier hierarchy execute locally within the same storage split without cross-split network shuffles:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --query-mode=PLAN \
  --sql="SELECT c.FullName, o.OrderId, o.TotalAmount, i.ProductSku, i.LineTotal
         FROM (SELECT CustomerId, CONCAT(FirstName, ' ', LastName) AS FullName FROM Customers) c
         JOIN Orders o ON c.CustomerId = o.CustomerId
         JOIN OrderItems i ON o.CustomerId = i.CustomerId AND o.OrderId = i.OrderId
         WHERE c.CustomerId = 1002;"
```

> [!TIP]
> Notice the operator `Distributed Cross Apply`. Because `Orders` and `OrderItems` are interleaved inside `Customers`, Spanner resolves the entire join within the single storage split holding customer 1002, eliminating distributed locks and network latency.

3. Test the generation of new rows using the bit-reversed sequence to observe non-monotonic key distribution:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (FirstName, LastName, Email, AccountBalance, CreatedAt)
         VALUES ('Zara', 'Novak', 'zara.novak@example.com', 500.00, PENDING_COMMIT_TIMESTAMP())
         THEN RETURN CustomerId, FirstName, LastName;"
```

> [!NOTE]
> Notice that the generated `CustomerId` is a large positive 64-bit integer rather than sequential number 1006. This confirms that subsequent inserts will scatter across different splits rather than stacking on the highest key split.

4. Retrieve the newly generated `CustomerId` and store it in an environment variable:

```bash
export NEW_CUST_ID="$(gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId FROM Customers WHERE Email = 'zara.novak@example.com';" \
  --format="value(CustomerId)")"
echo "Generated CustomerId: ${NEW_CUST_ID}"
```

5. Insert an interleaved test order for this new customer:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Orders (CustomerId, OrderDate, TotalAmount, OrderStatus)
         VALUES (${NEW_CUST_ID}, PENDING_COMMIT_TIMESTAMP(), 220.00, 'NEW')
         THEN RETURN CustomerId, OrderId, OrderStatus;"
```

6. Test cascading referential integrity by deleting the parent customer row:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="DELETE FROM Customers WHERE CustomerId = ${NEW_CUST_ID};"
```

7. Verify that the child order row was automatically deleted via `ON DELETE CASCADE`:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT COUNT(*) AS order_count FROM Orders WHERE CustomerId = ${NEW_CUST_ID};"
```

> [!NOTE]
> The query returns `0`. Because `Orders` is interleaved with `ON DELETE CASCADE`, Spanner cleans up child records atomically within the same split transaction.

### Task 5: Configure Change Streams for zero-downtime cutover and rollback readiness

In this task, you create a Cloud Spanner Change Stream to monitor mutations across all migrated tables, providing the continuous replication backbone required for zero-downtime cutover and instant rollback guardrails.

1. Inspect the change streams catalog to confirm no change streams currently exist:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT change_stream_name FROM INFORMATION_SCHEMA.CHANGE_STREAMS;"
```

2. Create a change stream named `RetailCutoverStream` tracking all tables and columns with a 7-day retention period:

```bash
gcloud spanner databases ddl update retail-migrated-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE CHANGE STREAM RetailCutoverStream
         FOR ALL
         OPTIONS (
           retention_period = '7d'
         );"
```

> [!IMPORTANT]
> In production zero-downtime cutovers, `RetailCutoverStream` is consumed by Google Cloud Dataflow, which streams mutations back into the legacy MySQL database in real time. If an unforeseen application bug occurs post-cutover, you can fail back to the legacy database immediately without losing transactions.

3. Verify that `RetailCutoverStream` is registered and watching all tables:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT change_stream_name, all_tables FROM INFORMATION_SCHEMA.CHANGE_STREAMS;"
```

4. Inspect the individual tables watched by the stream:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT change_stream_name, table_name, all_columns FROM INFORMATION_SCHEMA.CHANGE_STREAM_TABLES;"
```

5. Simulate a live application transaction modifying customer balance and order status post-cutover:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="UPDATE Customers SET AccountBalance = AccountBalance - 50.00 WHERE CustomerId = 1001;
         UPDATE Orders SET OrderStatus = 'SHIPPED' WHERE CustomerId = 1001 AND OrderId = 5001;"
```

6. Confirm that the transaction committed successfully:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT c.CustomerId, c.FirstName, c.AccountBalance, o.OrderId, o.OrderStatus
         FROM Customers c
         JOIN Orders o ON c.CustomerId = o.CustomerId
         WHERE c.CustomerId = 1001 AND o.OrderId = 5001;"
```

> [!NOTE]
> This transaction generated change stream records captured by `RetailCutoverStream`. Downstream CDC pipelines read these records using Cloud Spanner change stream connector APIs to synchronize external replica databases.

### Bonus Task 6: Audit migration metadata and manage operational resources

In this task, you audit the migrated schema catalog using Information Schema views and clean up the migration test database.

1. Query `INFORMATION_SCHEMA.SEQUENCES` to audit sequence properties and kinds:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT name, sequence_kind FROM INFORMATION_SCHEMA.SEQUENCES;"
```

2. Query `INFORMATION_SCHEMA.INDEXES` to review all secondary and primary indexes across the database:

```bash
gcloud spanner databases execute-sql retail-migrated-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, index_name, is_unique, is_null_filtered FROM INFORMATION_SCHEMA.INDEXES WHERE table_schema = '' ORDER BY table_name, index_name;"
```

3. Run the automated verification script from the solution directory to validate the complete migration end state:

```bash
bash ~/spanner-migration/verify_migration.sh 2>/dev/null || \
  bash labs/lab-06-lab-migrating-a-relational-database-to-cloud-spanner/solution/verify_migration.sh
```

4. When you are finished with this lab, remove the migration database `retail-migrated-db` to free up storage quotas:

```bash
gcloud spanner databases delete retail-migrated-db \
  --instance=order-mgmt-instance \
  --quiet
```

5. Confirm that `retail-migrated-db` has been deleted:

```bash
gcloud spanner databases list --instance=order-mgmt-instance \
  --format="table(name.basename():label=DATABASE_ID,state)"
```

## Congratulations!

In this lab, you have:
- Assessed legacy relational database schemas and identified migration anti-patterns.
- Refactored auto-increment primary keys using bit-reversed sequences to eliminate write hotspots.
- Translated foreign key hierarchies into co-located interleaved tables.
- Executed bulk data loading using mutation batching and secondary index deferral.
- Validated data parity between source and Spanner using row counts and aggregate checksums.
- Configured Cloud Spanner Change Streams for zero-downtime cutover and reverse replication.
