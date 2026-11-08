# Solution: Designing and Implementing an Interleaved Spanner Schema

## End State

- An active Cloud Spanner instance named `order-mgmt-instance` with database `orders-googlesql-db`.
- A bit-reversed sequence named `CustomerSeq` generating positive 64-bit integers with uniform key distribution.
- A 3-tier interleaved table hierarchy modeling a retail order management system:
  - Parent table `Customers`:
    - Primary key: `CustomerId` (using `CustomerSeq` as default value)
    - Data types: `INT64`, `STRING`, `NUMERIC`, `JSON`, `TIMESTAMP`
    - Stored generated column: `CustomerTier STRING(32)` extracted deterministically from `JSON_VALUE(Metadata, '$.loyalty.tier')`
    - Check constraints: `chk_customer_balance` (`Balance >= 0`) and `chk_customer_tier` (valid loyalty tiers)
  - Interleaved child table `Orders`:
    - Primary key: `(CustomerId, OrderId)`
    - Clause: `INTERLEAVE IN PARENT Customers ON DELETE CASCADE`
    - Check constraints: `chk_order_total` and `chk_order_status`
  - Interleaved grandchild table `OrderItems`:
    - Primary key: `(CustomerId, OrderId, LineItem)`
    - Clause: `INTERLEAVE IN PARENT Orders ON DELETE CASCADE`
    - Check constraints: `chk_quantity` (`Quantity > 0`) and `chk_unit_price` (`UnitPrice >= 0`)
- Secondary indexes optimizing query execution and data locality:
  - `idx_orders_date_covering`: Index on `Orders(OrderDate)` storing `TotalAmount` and `OrderStatus` to eliminate distributed back-joins.
  - `idx_orders_customer_status`: Interleaved index on `Orders(CustomerId, OrderStatus)` interleaved in `Customers` for co-located customer order lookups.
  - `idx_customers_tier`: Index on the stored generated column `Customers(CustomerTier)`.
- Validated runtime behavior:
  - Check constraint enforcement blocks invalid mutations (e.g., negative balance).
  - Co-located relational joins across all three tiers execute without cross-split network RPCs.
  - Deleting a parent customer row cascades automatically to associated orders and order items without orphan rows.

## How to Verify

From Google Cloud Shell or an authenticated terminal with Cloud SDK:

```bash
# Verify table hierarchy and cascade deletion policies
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"
```

Expected output:
```text
table_name      parent_table_name  on_delete_action
Customers       NULL               NULL
OrderItems      Orders             CASCADE
Orders          Customers          CASCADE
SystemMetadata  NULL               NULL
```

```bash
# Verify secondary indexes and interleaved index configuration
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT index_name, table_name, parent_table_name FROM INFORMATION_SCHEMA.INDEXES WHERE table_schema = '' AND index_type = 'INDEX' ORDER BY index_name;"
```

Expected output:
```text
index_name                  table_name  parent_table_name
idx_customers_tier          Customers   NULL
idx_orders_customer_status  Orders      Customers
idx_orders_date_covering    Orders      NULL
```

```bash
# Verify check constraints
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT constraint_name, check_clause FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE constraint_schema = '' ORDER BY constraint_name;"
```

Expected output:
```text
constraint_name       check_clause
chk_customer_balance  (Balance >= 0)
chk_customer_tier     (CustomerTier IS NULL OR CustomerTier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM'))
chk_order_status      (OrderStatus IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'))
chk_order_total       (TotalAmount >= 0)
chk_quantity          (Quantity > 0)
chk_unit_price        (UnitPrice >= 0)
```

```bash
# Verify stored generated column computation from JSON
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId, FullName, CustomerTier, Balance FROM Customers;"
```

```bash
# Execute local hierarchical join across parent, child, and grandchild
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT c.FullName, o.OrderId, o.OrderStatus, oi.LineItem, oi.ProductId, oi.Quantity, oi.UnitPrice FROM Customers c JOIN Orders o ON c.CustomerId = o.CustomerId JOIN OrderItems oi ON o.CustomerId = oi.CustomerId AND o.OrderId = oi.OrderId;"
```

```bash
# Verify covering index query execution plan (Plan mode)
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders @{FORCE_INDEX=idx_orders_date_covering} WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);"
```

## Built With

- Google Cloud SDK (`gcloud`) version 490+ / Cloud Shell
- Google Cloud Spanner GoogleSQL Dialect engine
- Cloud Spanner DDL and DML features: bit-reversed sequences, table interleaving, stored generated columns, check constraints, covering indexes (checked November 2026)
- Unverified: Physical split distribution across multiple nodes (tested on a single instance configuration with 100 PUs where splits are simulated within the regional Paxos group)
