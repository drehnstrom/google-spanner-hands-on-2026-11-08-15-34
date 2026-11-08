#!/usr/bin/env bash
# Verification and Demonstration Script for Lab 3
# Validates SQL queries, DML, Mutations, Execution Plans, Hints, and Snapshot Reads

set -euo pipefail

INSTANCE_ID="order-mgmt-instance"
GOOGLESQL_DB="orders-googlesql-db"
PG_DB="inventory-pg-db"

echo "=== 1. Validating PostgreSQL dialect query on ${PG_DB} ==="
gcloud spanner databases execute-sql "${PG_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT item_name, category, attributes->>'brand' AS brand, stock_count FROM inventory_items WHERE stock_count > 50 ORDER BY stock_count DESC;"

echo "=== 2. Validating GoogleSQL parameterized query with JSON_VALUE on ${GOOGLESQL_DB} ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, CustomerTier, JSON_VALUE(Metadata, '$.loyalty.points') AS Points, Balance FROM Customers WHERE CustomerTier = 'PLATINUM';"

echo "=== 3. Validating Interleaved Co-located Join ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT c.FullName, o.OrderId, o.OrderStatus, oi.LineItem, oi.ProductId, oi.Quantity, oi.UnitPrice FROM Customers c JOIN Orders o ON c.CustomerId = o.CustomerId JOIN OrderItems oi ON o.CustomerId = oi.CustomerId AND o.OrderId = oi.OrderId ORDER BY c.FullName, o.OrderId, oi.LineItem;"

echo "=== 4. Validating DML THEN RETURN ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Orders SET OrderStatus = 'SHIPPED' WHERE OrderStatus = 'PROCESSING' THEN RETURN CustomerId, OrderId, OrderStatus;"

echo "=== 5. Validating Low-level Mutations ==="
gcloud spanner rows insert \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,FullName='Elena Gomez',Email='elena.gomez@example.com',Balance=300.00,CreatedAt='spanner.commit_timestamp()'"

gcloud spanner rows update \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --data="CustomerId=900000000000000001,Balance=350.00"

gcloud spanner rows delete \
  --instance="${INSTANCE_ID}" \
  --database="${GOOGLESQL_DB}" \
  --table="Customers" \
  --keys="900000000000000001"

echo "=== 6. Validating Partitioned DML ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --enable-partitioned-dml \
  --sql="UPDATE Orders SET OrderStatus = 'DELIVERED' WHERE OrderStatus = 'SHIPPED';"

echo "=== 7. Validating Query Execution Plans (PLAN Mode) ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"

echo "=== 8. Validating Query Profile (PROFILE Mode) ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PROFILE \
  --sql="SELECT c.FullName, o.OrderId, o.TotalAmount FROM Customers c JOIN Orders o ON c.CustomerId = o.CustomerId WHERE c.CustomerTier = 'PLATINUM';"

echo "=== 9. Validating Query Optimizer Hints ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders @{FORCE_INDEX=_BASE_TABLE} WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);"

echo "=== 10. Validating ANALYZE and Optimizer Statistics ==="
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="ANALYZE;"

gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT package_name, allow_gc, timestamp FROM INFORMATION_SCHEMA.SPANNER_STATISTICS;"

echo "=== All validation checks completed successfully! ==="
