# Solution: Monitoring, Scaling, and Backing Up a Spanner Database

## End State

- Cloud Spanner regional instance `order-mgmt-instance` evaluated with dynamic compute scaling (100 to 1,000 Processing Units) and verified with native Cloud Spanner Autoscaling policies (1,000 minimum PUs, 3,000 maximum PUs, 65% high-priority CPU target, and 75% storage target).
- Executed tagged SQL statements using statement hints (`@{STATEMENT_TAG=...}`) and inspected performance diagnostics in `SPANNER_SYS.QUERY_STATS_TOP_MINUTE` and `SPANNER_SYS.LOCK_STATS_TOP_MINUTE`.
- Configured Fine-Grained Access Control (FGAC) in `orders-googlesql-db` with custom database roles:
  - Database role `reporting_analyst` granted table-level read access on `Customers` and column-level read access on `Orders(CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)`.
  - Database role `order_manager` granted read, insert, and update privileges on `Orders`.
  - Enforced privilege isolation using `gcloud spanner databases execute-sql --database-role=reporting_analyst`.
- Configured Point-in-Time Recovery (PITR) by extending `version_retention_period` to `7d` via DDL.
- Demonstrated surgical row recovery from simulated data corruption using historical timestamp reads (`--read-timestamp`) without full database restoration or service downtime.
- Created an on-demand consistent backup (`orders-backup-ondemand`) with a 24-hour retention period, configured an automated daily backup schedule (`daily-orders-backup`), and restored a backup into a new database (`orders-restored-db`).

## How to Verify

Set environment variables in Cloud Shell:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export DATABASE_ID="orders-googlesql-db"
```

### 1. Verify Compute Scaling and Autoscaling Configuration

```bash
# Verify instance capacity
gcloud spanner instances describe "${INSTANCE_ID}" \
  --format="yaml(name,nodeCount,processingUnits,state)"

# Configure autoscaling policy
gcloud spanner instances update "${INSTANCE_ID}" \
  --autoscaling-min-processing-units=1000 \
  --autoscaling-max-processing-units=3000 \
  --autoscaling-high-priority-cpu-target=65 \
  --autoscaling-storage-target=75

# Inspect autoscaling status
gcloud spanner instances describe "${INSTANCE_ID}" \
  --format="yaml(autoscalingConfig)"

# Reset to manual 100 Processing Units for cost efficiency
gcloud spanner instances update "${INSTANCE_ID}" \
  --processing-units=100
```

### 2. Verify Query Insights and System Statistics Tables

```bash
# Execute tagged query
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="@{STATEMENT_TAG='customer_tier_audit'} SELECT CustomerTier, COUNT(*) AS tier_count FROM Customers GROUP BY CustomerTier;"

# Inspect top queries in SPANNER_SYS
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT text, execution_count, avg_latency_seconds, avg_cpu_seconds, avg_rows FROM SPANNER_SYS.QUERY_STATS_TOP_MINUTE ORDER BY avg_cpu_seconds DESC LIMIT 5;"

# Inspect lock statistics
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT interval_end, row_range_start_key, lock_wait_seconds FROM SPANNER_SYS.LOCK_STATS_TOP_MINUTE ORDER BY lock_wait_seconds DESC LIMIT 5;"
```

### 3. Verify Fine-Grained Access Control Privileges

```bash
# Query as reporting_analyst on authorized Customers table
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --database-role=reporting_analyst \
  --sql="SELECT CustomerId, FullName, Email FROM Customers LIMIT 2;"

# Query authorized columns on Orders table
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --database-role=reporting_analyst \
  --sql="SELECT CustomerId, OrderId, TotalAmount, OrderStatus FROM Orders LIMIT 2;"

# Confirm unauthorized modification is denied
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --database-role=reporting_analyst \
  --sql="UPDATE Customers SET Balance = 1000.00 WHERE CustomerId = 888888888888888888;"
```

Expected result: The update command fails with a permission denied error.

### 4. Verify Point-in-Time Recovery (PITR)

```bash
# Verify version retention period is 7 days
gcloud spanner databases ddl describe "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}"

# Capture pre-corruption timestamp and simulate accidental corruption
export PITR_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
sleep 5

gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="UPDATE Customers SET Balance = 0.00 WHERE CustomerId = 888888888888888888;"

# Query historical state
gcloud spanner databases execute-sql "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --read-timestamp="${PITR_TIMESTAMP}" \
  --sql="SELECT CustomerId, Balance FROM Customers WHERE CustomerId = 888888888888888888;"
```

Expected result: The historical read displays the original pre-corruption balance (`750.00`).

### 5. Verify Backup and Restore Operations

```bash
# Check on-demand backup state
gcloud spanner backups describe orders-backup-ondemand \
  --instance="${INSTANCE_ID}" \
  --format="table(name.basename():label=BACKUP_ID,state,sizeBytes)"

# Verify backup schedule
gcloud spanner backup-schedules describe daily-orders-backup \
  --instance="${INSTANCE_ID}" \
  --database="${DATABASE_ID}"

# Check restored database state
gcloud spanner databases describe orders-restored-db \
  --instance="${INSTANCE_ID}" \
  --format="value(state,restoreInfo.sourceBackup)"
```

Alternatively, run the automated verification script:

```bash
chmod +x ./verify.sh
./verify.sh
```

## Built With

- Google Cloud CLI (`gcloud`) version 490+ / Cloud Shell
- Google Cloud Spanner GoogleSQL database engine (checked November 2026)
- Cloud Spanner Native Managed Autoscaler (checked November 2026)
- Cloud Spanner Fine-Grained Access Control (FGAC) and Point-in-Time Recovery (PITR) (checked November 2026)
- Unverified: Key Visualizer GUI heatmap visualization (requires sustained production-scale QPS over several hours to generate graphical split heatmaps in Google Cloud Console; verified programmatically via `SPANNER_SYS` query and lock statistics tables)
