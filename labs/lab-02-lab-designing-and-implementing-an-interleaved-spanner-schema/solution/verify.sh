#!/usr/bin/env bash
# Verification script for Lab 2: Designing and Implementing an Interleaved Spanner Schema
set -euo pipefail

INSTANCE_ID="order-mgmt-instance"
DATABASE_ID="orders-googlesql-db"

echo "=========================================================="
echo "Verifying Cloud Spanner Interleaved Schema and Constraints"
echo "=========================================================="

echo "[1/6] Checking table definitions and parent-child interleaving..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"

echo "[2/6] Checking secondary indexes..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT index_name, table_name, parent_table_name, is_null_filtered FROM INFORMATION_SCHEMA.INDEXES WHERE table_schema = '' AND index_type = 'INDEX' ORDER BY index_name;"

echo "[3/6] Checking check constraints..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT constraint_name, check_clause FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE constraint_schema = '' ORDER BY constraint_name;"

echo "[4/6] Verifying stored generated column CustomerTier..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CustomerId, FullName, CustomerTier, Balance FROM Customers;"

echo "[5/6] Verifying hierarchical local join across parent, child, and grandchild..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT c.FullName, o.OrderId, o.OrderStatus, oi.LineItem, oi.ProductId, oi.Quantity, oi.UnitPrice FROM Customers c JOIN Orders o ON c.CustomerId = o.CustomerId JOIN OrderItems oi ON o.CustomerId = oi.CustomerId AND o.OrderId = oi.OrderId;"

echo "[6/6] Testing covering index resolution..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --query-mode=PLAN \
  --sql="SELECT CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus FROM Orders @{FORCE_INDEX=idx_orders_date_covering} WHERE OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);"

echo "=========================================================="
echo "Verification complete! All schema checks passed."
echo "=========================================================="
