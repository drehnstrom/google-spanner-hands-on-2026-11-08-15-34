#!/usr/bin/env bash
set -euo pipefail

# Automated verification script for Lab 5: Monitoring, Scaling, and Backing Up a Spanner Database

export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
export INSTANCE_ID="${INSTANCE_ID:-order-mgmt-instance}"
export DATABASE_ID="${DATABASE_ID:-orders-googlesql-db}"

echo "============================================================"
echo "Starting Lab 5 Verification against instance: ${INSTANCE_ID}"
echo "Project: ${PROJECT_ID}"
echo "============================================================"

# 1. Verify instance compute capacity and autoscaling support
echo "Checking instance capacity..."
CURRENT_PUS=$(gcloud spanner instances describe "${INSTANCE_ID}" --format="value(processingUnits)")
echo "Current Processing Units: ${CURRENT_PUS}"

# 2. Test dynamic scaling to 1000 PUs
echo "Scaling instance to 1,000 Processing Units (1 node)..."
gcloud spanner instances update "${INSTANCE_ID}" --processing-units=1000

# 3. Configure autoscaling policy
echo "Configuring managed autoscaling policy..."
gcloud spanner instances update "${INSTANCE_ID}" \
  --autoscaling-min-processing-units=1000 \
  --autoscaling-max-processing-units=3000 \
  --autoscaling-high-priority-cpu-target=65 \
  --autoscaling-storage-target=75

echo "Verifying autoscaling configuration..."
gcloud spanner instances describe "${INSTANCE_ID}" --format="yaml(autoscalingConfig)"

# 4. Return to manual 100 PUs for lab economy
echo "Returning instance to manual 100 Processing Units..."
gcloud spanner instances update "${INSTANCE_ID}" --processing-units=100

# 5. Query system tables
echo "Executing tagged query..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="@{STATEMENT_TAG='admin_verification_audit'} SELECT CustomerTier, COUNT(*) AS cnt FROM Customers GROUP BY CustomerTier;"

echo "Querying SPANNER_SYS.QUERY_STATS_TOP_MINUTE..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT text, execution_count, avg_latency_seconds, avg_cpu_seconds FROM SPANNER_SYS.QUERY_STATS_TOP_MINUTE ORDER BY avg_cpu_seconds DESC LIMIT 3;"

# 6. Apply FGAC roles
echo "Applying Fine-Grained Access Control roles..."
gcloud spanner databases ddl update "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --ddl="CREATE ROLE reporting_analyst;
         GRANT SELECT ON TABLE Customers TO ROLE reporting_analyst;
         GRANT SELECT (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus) ON TABLE Orders TO ROLE reporting_analyst;
         CREATE ROLE order_manager;
         GRANT SELECT, INSERT, UPDATE ON TABLE Orders TO ROLE order_manager;" || echo "Roles may already exist; continuing..."

echo "Testing query under reporting_analyst role..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --database-role=reporting_analyst \
  --sql="SELECT CustomerId, FullName FROM Customers LIMIT 2;"

# 7. Configure PITR and surgical recovery
echo "Configuring version_retention_period to 7d..."
gcloud spanner databases ddl update "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --ddl="ALTER DATABASE \`${DATABASE_ID}\` SET OPTIONS (version_retention_period = '7d');"

echo "Inserting test row for PITR verification..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, CreatedAt)
         VALUES (888888888888888888, 'Vance Sterling', 'vance.sterling@example.com', 750.00, PENDING_COMMIT_TIMESTAMP());"

PITR_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Captured baseline timestamp: ${PITR_TS}"
sleep 5

echo "Simulating data corruption..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Customers SET Balance = 0.00 WHERE CustomerId = 888888888888888888;"

echo "Reading historical state via --read-timestamp..."
HIST_BAL=$(gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --read-timestamp="${PITR_TS}" \
  --sql="SELECT Balance FROM Customers WHERE CustomerId = 888888888888888888;" \
  --format="value(Balance)")
echo "Recovered historical balance: ${HIST_BAL}"

echo "Surgically restoring balance in active database..."
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Customers SET Balance = ${HIST_BAL} WHERE CustomerId = 888888888888888888;"

# 8. Create on-demand backup
BACKUP_ID="orders-backup-$(date +%s)"
echo "Creating on-demand backup: ${BACKUP_ID}..."
gcloud spanner backups create "${BACKUP_ID}" \
  --instance="${INSTANCE_ID}" \
  --database="${DATABASE_ID}" \
  --retention-period=24h \
  --async

echo "Creating backup schedule..."
gcloud spanner backup-schedules create daily-orders-backup \
  --instance="${INSTANCE_ID}" \
  --database="${DATABASE_ID}" \
  --backup-type=full-backup \
  --cron="0 2 * * *" \
  --retention-duration=7d || echo "Backup schedule already exists; continuing..."

echo "============================================================"
echo "Lab 5 Verification Completed Successfully!"
echo "============================================================"
