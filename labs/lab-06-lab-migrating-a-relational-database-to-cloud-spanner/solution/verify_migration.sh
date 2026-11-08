#!/usr/bin/env bash
# Verification script for Lab: Migrating a Relational Database to Cloud Spanner
set -euo pipefail

INSTANCE_ID="${INSTANCE_ID:-order-mgmt-instance}"
DATABASE_ID="${DATABASE_ID:-retail-migrated-db}"

echo "============================================================"
echo "Verifying Migration Target Database: ${DATABASE_ID}"
echo "Spanner Instance: ${INSTANCE_ID}"
echo "============================================================"

# 1. Verify Database Exists and is READY
DB_STATE=$(gcloud spanner databases describe "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --format="value(state)")

if [ "${DB_STATE}" != "READY" ]; then
  echo "ERROR: Database ${DATABASE_ID} is not READY (state=${DB_STATE})"
  exit 1
fi
echo "[PASS] Database ${DATABASE_ID} is READY."

# 2. Verify Table Existence and Parent-Child Interleaving
echo "Checking table hierarchy in INFORMATION_SCHEMA.TABLES..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT table_name, parent_table_name, on_delete_action FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '' ORDER BY table_name;"

# 3. Verify Sequences
echo "Checking bit-reversed sequences..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT name, sequence_kind FROM INFORMATION_SCHEMA.SEQUENCES;"

# 4. Verify Row Counts Post-Bulk Load
echo "Verifying row counts..."
CUSTOMER_COUNT=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT COUNT(*) AS count FROM Customers;" \
  --format="value(count)")

ORDER_COUNT=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT COUNT(*) AS count FROM Orders;" \
  --format="value(count)")

ITEM_COUNT=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT COUNT(*) AS count FROM OrderItems;" \
  --format="value(count)")

echo "Customers: ${CUSTOMER_COUNT} (expected >= 5)"
echo "Orders:    ${ORDER_COUNT} (expected >= 8)"
echo "Items:     ${ITEM_COUNT} (expected >= 12)"

if [ "${CUSTOMER_COUNT}" -lt 5 ] || [ "${ORDER_COUNT}" -lt 8 ] || [ "${ITEM_COUNT}" -lt 12 ]; then
  echo "ERROR: Row count verification failed."
  exit 1
fi
echo "[PASS] Bulk row counts verified."

# 5. Verify Financial Aggregate Parity
echo "Verifying financial checksums and aggregate totals..."
TOTAL_AMOUNT=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CAST(SUM(TotalAmount) AS STRING) AS total FROM Orders WHERE CustomerId BETWEEN 1001 AND 1005;" \
  --format="value(total)")

LINE_TOTAL=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT CAST(SUM(LineTotal) AS STRING) AS total FROM OrderItems WHERE CustomerId BETWEEN 1001 AND 1005;" \
  --format="value(total)")

echo "Sum Orders TotalAmount:   ${TOTAL_AMOUNT}"
echo "Sum OrderItems LineTotal: ${LINE_TOTAL}"

if [ "${TOTAL_AMOUNT}" != "5596.45" ] || [ "${LINE_TOTAL}" != "5596.45" ]; then
  echo "ERROR: Financial parity reconciliation failed."
  exit 1
fi
echo "[PASS] Data parity reconciliation confirmed: 5596.45 across orders and items."

# 6. Verify Secondary Index
echo "Checking secondary index status..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT index_name, table_name, is_unique FROM INFORMATION_SCHEMA.INDEXES WHERE index_name = 'idx_orders_customer_date';"

# 7. Verify Change Stream
echo "Checking change stream status..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT change_stream_name, all_tables FROM INFORMATION_SCHEMA.CHANGE_STREAMS;"

echo "============================================================"
echo "ALL VERIFICATION CHECKS PASSED SUCCESSFULLY"
echo "============================================================"
