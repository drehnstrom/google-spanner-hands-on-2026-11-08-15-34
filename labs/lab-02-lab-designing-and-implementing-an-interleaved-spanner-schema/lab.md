# Designing and Implementing an Interleaved Spanner Schema

## Time Required

45 minutes

## Overview

In this lab, you will design and implement a production-grade relational schema in Cloud Spanner for an enterprise order management platform. You will configure bit-reversed sequences and UUID primary keys to prevent write hotspots, model multi-tier parent-child relationships using interleaved tables, create covering and interleaved secondary indexes to eliminate distributed back-joins, and enforce data integrity using stored generated columns and check constraints.

### You learn how to:
- Define distributed primary keys using bit-reversed sequences and UUIDv4 to eliminate write hotspots.
- Model multi-tier parent-child relationships using interleaved tables with cascade deletion.
- Create covering secondary indexes with stored columns and interleaved indexes to eliminate back-joins.
- Implement generated stored columns to extract and index semi-structured JSON attributes.
- Enforce domain and relational data integrity rules using check constraints.
- Validate hierarchical local join execution and automatic cascade deletion behavior.

## Scenario

Your engineering team at the retail platform is building the core order management and inventory system on Cloud Spanner. In traditional databases, joining customers, orders, and line items across separate tables incurs heavy network overhead and complex shard management. Furthermore, sequential IDs cause severe write hotspots on distributed storage splits. You must design and implement a production-grade relational schema in Cloud Spanner that leverages bit-reversed sequences, table interleaving, covering indexes, and check constraints to guarantee high-throughput, hotspot-free transactional operations.

## Lab Instructions

### Task 1: Prepare the database environment and configure distributed primary keys

In this task, you verify your Cloud Shell environment, inspect your Spanner instance, and create a bit-reversed sequence and parent table to guarantee uniform write distribution.

1. Open Cloud Shell in your Google Cloud Console.

2. Verify that your active Google Cloud project ID is set in your session:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
echo "Active Project ID: ${PROJECT_ID}"
```

> [!NOTE]
> If the command returns empty or `(unset)`, run `gcloud config set project YOUR_PROJECT_ID` using your assigned Google Cloud project ID.

3. Verify that the Cloud Spanner instance `order-mgmt-instance` and GoogleSQL database `orders-googlesql-db` created in the previous lab are available:

```bash
gcloud spanner databases describe orders-googlesql-db \
  --instance=order-mgmt-instance \
  --format="value(databaseDialect,state)"
```

> [!TIP]
> If you are starting fresh and do not have these resources, create them now with:
> `gcloud spanner instances create order-mgmt-instance --config=regional-us-central1 --description="Order Management Instance" --processing-units=100`
> and
> `gcloud spanner databases create orders-googlesql-db --instance=order-mgmt-instance --database-dialect=GOOGLE_STANDARD_SQL`

4. Create a bit-reversed positive sequence named `CustomerSeq` using DDL:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE SEQUENCE CustomerSeq OPTIONS (sequence_kind = 'bit_reversed_positive');"
```

> [!IMPORTANT]
> Bit-reversed sequences reverse the binary representation of an internal 64-bit integer counter. Sequential logical IDs produce values spread across the full integer range, preventing writes from clustering onto a single split or Paxos leader.

5. Create the parent table `Customers` utilizing `CustomerSeq` as the default primary key generator:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE Customers (
    CustomerId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq)),
    FullName STRING(128) NOT NULL,
    Email STRING(256) NOT NULL,
    Balance NUMERIC,
    Metadata JSON,
    CreatedAt TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)
  ) PRIMARY KEY (CustomerId);"
```

6. Confirm that the `Customers` table exists in the schema catalog:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, parent_table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'Customers';"
```

### Task 2: Implement multi-tier interleaved parent-child tables

In this task, you model a 3-tier hierarchy (`Customers -> Orders -> OrderItems`) using table interleaving to physically co-locate child and grandchild rows alongside parent rows.

1. Review the interleaving requirements for child tables:
   - The child table primary key must begin with the complete primary key of the parent table (`CustomerId`).
   - The child table specifies `INTERLEAVE IN PARENT <ParentTable> ON DELETE CASCADE`.

2. Create the child table `Orders` interleaved in `Customers`:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE Orders (
    CustomerId INT64 NOT NULL,
    OrderId STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
    OrderDate TIMESTAMP NOT NULL,
    TotalAmount NUMERIC NOT NULL,
    OrderStatus STRING(32) NOT NULL
  ) PRIMARY KEY (CustomerId, OrderId),
    INTERLEAVE IN PARENT Customers ON DELETE CASCADE;"
```

> [!NOTE]
> The `OrderId` column uses `GENERATE_UUID()` as its default value, ensuring that orders within any customer partition receive globally unique, non-sequential identifiers.

3. Create the grandchild table `OrderItems` interleaved in `Orders`:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE OrderItems (
    CustomerId INT64 NOT NULL,
    OrderId STRING(36) NOT NULL,
    LineItem INT64 NOT NULL,
    ProductId STRING(36) NOT NULL,
    Quantity INT64 NOT NULL,
    UnitPrice NUMERIC NOT NULL
  ) PRIMARY KEY (CustomerId, OrderId, LineItem),
    INTERLEAVE IN PARENT Orders ON DELETE CASCADE;"
```

> [!IMPORTANT]
> The primary key of `OrderItems` defines `(CustomerId, OrderId, LineItem)`. It must preserve the exact column ordering and data types of all ancestor keys before declaring its own line identifier.

4. Query the schema catalog to inspect the parent-child relationships and deletion actions:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"
```

5. Confirm that `Orders` lists `Customers` as its parent table, `OrderItems` lists `Orders` as its parent table, and both report an `on_delete_action` of `CASCADE`.

### Task 3: Create covering and interleaved secondary indexes

In this task, you create secondary indexes with stored columns to eliminate distributed back-joins, and an interleaved secondary index to co-locate index entries with parent records.

1. Create a covering secondary index on `Orders(OrderDate)` storing `TotalAmount` and `OrderStatus`:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE INDEX idx_orders_date_covering ON Orders (OrderDate) STORING (TotalAmount, OrderStatus);"
```

> [!NOTE]
> Standard secondary indexes contain only the indexed keys and the base table primary key. Queries requesting non-indexed columns must back-join the base table split across the network. The `STORING` clause duplicates these attributes directly into the index table, resolving queries with zero network back-joins.

2. Create an interleaved secondary index on `Orders(CustomerId, OrderStatus)` interleaved in `Customers`:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE INDEX idx_orders_customer_status ON Orders (CustomerId, OrderStatus), INTERLEAVE IN Customers;"
```

> [!IMPORTANT]
> An interleaved secondary index co-locates index entries directly inside the parent table split. Updates to this index execute within the parent Paxos group without triggering multi-split Two-Phase Commit consensus.

3. Inspect the newly created indexes in the schema catalog:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT index_name, table_name, parent_table_name FROM INFORMATION_SCHEMA.INDEXES WHERE table_schema = '' AND index_type = 'INDEX' ORDER BY index_name;"
```

4. Verify that `idx_orders_customer_status` reports `Customers` as its parent table.

### Task 4: Add generated stored columns and check constraints

In this task, you evolve the schema online by adding a stored generated column to extract semi-structured JSON attributes and attaching check constraints to enforce business rules.

1. Add a stored generated column named `CustomerTier` to the `Customers` table to extract the loyalty tier from the `Metadata` JSON column:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="ALTER TABLE Customers ADD COLUMN CustomerTier STRING(32) AS (JSON_VALUE(Metadata, '$.loyalty.tier')) STORED;"
```

> [!NOTE]
> In GoogleSQL, generated columns must specify the `STORED` keyword. Cloud Spanner computes and materializes the value at write time, allowing read queries and secondary indexes to access precomputed values instantly.

2. Create a secondary index on the stored generated column:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE INDEX idx_customers_tier ON Customers (CustomerTier);"
```

3. Add check constraints to `Customers` to validate balance lower bounds and allowable loyalty tiers:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="ALTER TABLE Customers ADD CONSTRAINT chk_customer_balance CHECK (Balance >= 0);
         ALTER TABLE Customers ADD CONSTRAINT chk_customer_tier CHECK (CustomerTier IS NULL OR CustomerTier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM'));"
```

4. Add check constraints to `Orders` and `OrderItems` to enforce positive values for order totals, quantities, and prices:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="ALTER TABLE Orders ADD CONSTRAINT chk_order_total CHECK (TotalAmount >= 0);
         ALTER TABLE Orders ADD CONSTRAINT chk_order_status CHECK (OrderStatus IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'));
         ALTER TABLE OrderItems ADD CONSTRAINT chk_quantity CHECK (Quantity > 0);
         ALTER TABLE OrderItems ADD CONSTRAINT chk_unit_price CHECK (UnitPrice >= 0);"
```

5. Query the check constraint catalog to confirm that all rules are active:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT constraint_name, check_clause FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE constraint_schema = '' ORDER BY constraint_name;"
```

### Task 5: Populate data, validate constraints, and test cascade deletion

In this task, you insert sample data across all three hierarchy tiers, verify that check constraints block invalid data, execute a hierarchical join, and confirm automatic cascade deletion.

1. Insert two customer records with valid loyalty metadata and balances:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
         VALUES
         (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq), 'Alice Chen', 'alice.chen@example.com', 450.00, JSON '{\"loyalty\": {\"tier\": \"PLATINUM\", \"points\": 1420}}', PENDING_COMMIT_TIMESTAMP()),
         (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq), 'Marcus Vance', 'marcus.vance@example.com', 125.50, JSON '{\"loyalty\": {\"tier\": \"GOLD\", \"points\": 880}}', PENDING_COMMIT_TIMESTAMP());"
```

2. Query `Customers` to confirm that the stored generated column `CustomerTier` computed automatically:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId, FullName, Email, CustomerTier, Balance FROM Customers;"
```

> [!NOTE]
> Observe that `CustomerId` values are large positive integers generated from `CustomerSeq`, and `CustomerTier` reflects the JSON loyalty tier (`PLATINUM` and `GOLD`).

3. Test check constraint enforcement by attempting to insert a customer with an invalid negative balance:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
         VALUES (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq), 'Faulty Record', 'faulty@example.com', -50.00, NULL, PENDING_COMMIT_TIMESTAMP());"
```

> [!NOTE]
> The command returns an error indicating that check constraint `chk_customer_balance` was violated. Spanner aborts the transaction, preserving data integrity.

4. Retrieve the generated `CustomerId` for Alice Chen and assign it to an environment variable:

```bash
export ALICE_ID="$(gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId FROM Customers WHERE Email = 'alice.chen@example.com';" \
  --format="value(CustomerId)")"
echo "Alice CustomerId: ${ALICE_ID}"
```

5. Insert an order for Alice Chen into the child `Orders` table:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
         VALUES (${ALICE_ID}, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', CURRENT_TIMESTAMP(), 180.00, 'PROCESSING');"
```

6. Insert two line items for this order into the grandchild `OrderItems` table:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice)
         VALUES
         (${ALICE_ID}, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 1, 'prod-sku-98124', 2, 45.00),
         (${ALICE_ID}, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 2, 'prod-sku-34109', 1, 90.00);"
```

7. Execute a hierarchical local join across parent, child, and grandchild tables:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT c.FullName, o.OrderId, o.OrderStatus, oi.LineItem, oi.ProductId, oi.Quantity, oi.UnitPrice
         FROM Customers c
         JOIN Orders o ON c.CustomerId = o.CustomerId
         JOIN OrderItems oi ON o.CustomerId = oi.CustomerId AND o.OrderId = oi.OrderId
         WHERE c.CustomerId = ${ALICE_ID};"
```

> [!NOTE]
> Because `Orders` and `OrderItems` are interleaved under `Customers`, Spanner resolves this multi-tier join locally from contiguous rows in a single storage split with zero cross-network RPCs.

8. Delete Alice Chen from the `Customers` parent table:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="DELETE FROM Customers WHERE CustomerId = ${ALICE_ID};"
```

9. Verify that cascade deletion purged the associated records from `Orders` and `OrderItems`:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT COUNT(*) AS remaining_orders FROM Orders WHERE CustomerId = ${ALICE_ID};
         SELECT COUNT(*) AS remaining_items FROM OrderItems WHERE CustomerId = ${ALICE_ID};"
```

> [!NOTE]
> Both queries return `0`. The `ON DELETE CASCADE` policy ensured that deleting the parent customer cleanly purged all child orders and grandchild line items in a single Paxos transaction.

### Bonus Task 6: Inspect query execution plans and index covering

In this task, you use query execution plan inspection (`PLAN` mode) and index query hints to verify that covering indexes eliminate back-joins.

1. Insert a new customer and order record for testing query plans:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, Metadata, CreatedAt)
         VALUES (GET_NEXT_SEQUENCE_VALUE(SEQUENCE CustomerSeq), 'Elena Rostova', 'elena.rostova@example.com', 320.00, JSON '{\"loyalty\": {\"tier\": \"SILVER\", \"points\": 450}}', PENDING_COMMIT_TIMESTAMP());"

export ELENA_ID="$(gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId FROM Customers WHERE Email = 'elena.rostova@example.com';" \
  --format="value(CustomerId)")"

gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
         VALUES (${ELENA_ID}, 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', CURRENT_TIMESTAMP(), 210.00, 'SHIPPED');"
```

2. Inspect the execution plan of a query covered by `idx_orders_date_covering`:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus
         FROM Orders @{FORCE_INDEX=idx_orders_date_covering}
         WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY);"
```

> [!NOTE]
> Review the execution plan output. The operator tree demonstrates an index scan directly on `idx_orders_date_covering`. Because `TotalAmount` and `OrderStatus` are stored inside the index, no distributed cross-split back-join operator is present.

3. Compare this with a query that forces the interleaved index `idx_orders_customer_status`:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderStatus
         FROM Orders @{FORCE_INDEX=idx_orders_customer_status}
         WHERE CustomerId = ${ELENA_ID} AND OrderStatus = 'SHIPPED';"
```

4. Notice that because the index is interleaved within `Customers`, queries filtering by the parent key evaluate against locally co-located index splits.

## Congratulations!

In this lab, you have:
- Defined distributed primary keys using bit-reversed sequences and UUIDv4 to eliminate write hotspots.
- Modeled multi-tier parent-child relationships using interleaved tables with cascade deletion.
- Created covering secondary indexes with stored columns and interleaved indexes to eliminate back-joins.
- Implemented generated stored columns to extract and index semi-structured JSON attributes.
- Enforced domain and relational data integrity rules using check constraints.
- Validated hierarchical local join execution and automatic cascade deletion behavior.
