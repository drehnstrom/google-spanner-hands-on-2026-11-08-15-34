# Solution: Migrating a Relational Database to Cloud Spanner

## End State

- Evaluated a legacy relational schema (`legacy_retail`) containing anti-patterns:
  - Monotonic `AUTO_INCREMENT` primary keys on high-volume tables.
  - Standard foreign keys triggering distributed two-phase locking.
  - Procedural database triggers incompatible with Cloud Spanner.
  - Active secondary indexes that cause mutation amplification during bulk loading.
- A fully provisioned target database named `retail-migrated-db` in Spanner instance `order-mgmt-instance` configured with GoogleSQL dialect.
- Distributed schema design eliminating migration anti-patterns:
  - Native Spanner sequences (`CustomerIdSeq` and `OrderIdSeq`) configured with `sequence_kind = 'bit_reversed_positive'` generating non-monotonic keys.
  - Collocated table hierarchy: parent table `Customers`, interleaved child table `Orders` (`INTERLEAVE IN PARENT Customers ON DELETE CASCADE`), and interleaved grandchild table `OrderItems` (`INTERLEAVE IN PARENT Orders ON DELETE CASCADE`).
  - ANSI data types converted to optimal Spanner types: `BIGINT` to `INT64`, `DECIMAL` to `NUMERIC`, `VARCHAR` to bounded `STRING`, `TIMESTAMP` to `TIMESTAMP`.
  - Secondary index deferral strategy applied: initial bulk load executed with zero secondary indexes, and secondary index `idx_orders_customer_date` created post-load via background schema backfill.
- Populated historical dataset:
  - 5 parent `Customers` rows.
  - 8 interleaved `Orders` rows.
  - 12 interleaved `OrderItems` rows.
- Validated data parity across engines:
  - Exact row count matches.
  - Aggregate checksum reconciliation confirming identical financial totals (`5596.45`) across orders and line items.
  - Verified referential integrity and cascading delete behavior.
- Active Cloud Spanner Change Stream named `RetailCutoverStream` tracking all table modifications with a 7-day retention period, enabling real-time reverse replication to the legacy database for zero-downtime cutover and instant rollback guardrails.

## How to Verify

From Google Cloud Shell or an authenticated terminal with Cloud SDK:

```bash
# Set environment variables
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export DATABASE_ID="retail-migrated-db"
```

### 1. Verify Database State and Tables

```bash
gcloud spanner databases describe "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --format="value(state)"
```

Expected: `READY`

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"
```

Expected output:
```text
table_name  parent_table_name  on_delete_action
Customers   NULL               NULL
OrderItems  Orders             CASCADE
Orders      Customers          CASCADE
```

### 2. Verify Bit-Reversed Sequences

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT name, sequence_kind FROM INFORMATION_SCHEMA.SEQUENCES;"
```

Expected output:
```text
name           sequence_kind
CustomerIdSeq  bit_reversed_positive
OrderIdSeq     bit_reversed_positive
```

### 3. Verify Bulk Load Row Counts

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT 'Customers' AS entity, COUNT(*) AS count FROM Customers
         UNION ALL
         SELECT 'Orders' AS entity, COUNT(*) AS count FROM Orders
         UNION ALL
         SELECT 'OrderItems' AS entity, COUNT(*) AS count FROM OrderItems;"
```

Expected output:
```text
entity      count
Customers   5
Orders      8
OrderItems  12
```

### 4. Verify Financial Parity and Aggregate Checksums

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT
           CAST(SUM(o.TotalAmount) AS STRING) AS total_orders,
           CAST(SUM(i.LineTotal) AS STRING) AS total_items
         FROM Orders o
         JOIN OrderItems i ON o.CustomerId = i.CustomerId AND o.OrderId = i.OrderId
         WHERE o.CustomerId BETWEEN 1001 AND 1005;"
```

Expected: Both `total_orders` and `total_items` reconcile to `5596.45`.

### 5. Verify Automatic Bit-Reversed Key Generation

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="INSERT INTO Customers (FirstName, LastName, Email, AccountBalance, CreatedAt)
         VALUES ('Zara', 'Novak', 'zara.novak@example.com', 500.00, PENDING_COMMIT_TIMESTAMP())
         THEN RETURN CustomerId, FirstName, LastName;"
```

Expected: Returns a large positive 64-bit integer (e.g., `4611686018427387905`), proving that inserts scatter uniformly across splits rather than appending monotonically.

### 6. Verify Secondary Index Status

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT index_name, table_name FROM INFORMATION_SCHEMA.INDEXES WHERE index_name = 'idx_orders_customer_date';"
```

Expected: `idx_orders_customer_date` is active on `Orders`.

### 7. Verify Change Stream Configuration

```bash
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT change_stream_name, all_tables FROM INFORMATION_SCHEMA.CHANGE_STREAMS;"
```

Expected: `RetailCutoverStream` reports `all_tables = TRUE`.

### 8. Run Automated Verification Script

```bash
bash labs/lab-06-lab-migrating-a-relational-database-to-cloud-spanner/solution/verify_migration.sh
```

## Built With

- Google Cloud SDK (`gcloud`) version 490+ / Cloud Shell
- Google Cloud Spanner GoogleSQL engine (checked November 2026)
- Cloud Spanner Sequences (`bit_reversed_positive`) and Change Streams
- Unverified: Physical multi-terabyte Dataflow job ingestion pipeline and live Datastream CDC agent connection (demonstrated using equivalent batched DML and Spanner Change Streams in Cloud Shell)
