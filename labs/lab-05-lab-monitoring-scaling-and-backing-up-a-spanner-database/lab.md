# Monitoring, Scaling, and Backing Up a Spanner Database

## Time Required

45 minutes

## Overview

In this lab, you will configure autoscaling policies, inspect query execution and lock contention using system statistics tables, implement Fine-Grained Access Control using database roles, protect data with Point-in-Time Recovery, and manage database backups and restores.

### You learn how to:
- Configure native Cloud Spanner autoscaling policies and adjust compute boundaries.
- Monitor query execution and lock contention using Query Insights and `SPANNER_SYS` tables.
- Implement Fine-Grained Access Control by defining database roles and testing column-level privileges.
- Extend the Point-in-Time Recovery retention window and recover data using historical timestamps.
- Create on-demand backups, configure automated backup schedules, and restore a database.

## Scenario

Your enterprise order management platform is entering production operations on Cloud Spanner. As the lead database administrator, you must ensure that Spanner automatically adapts to traffic fluctuations without manual intervention, that application components follow least-privilege security principles, that performance bottlenecks can be diagnosed quickly through internal statistics tables, and that data corruption or disaster scenarios can be remediated rapidly using Point-in-Time Recovery and database backups.

## Lab Instructions

### Task 1: Scale compute capacity and configure Cloud Spanner autoscaling

In this task, you inspect your environment, scale compute capacity dynamically using Processing Units, and configure a native Cloud Spanner autoscaler policy with target utilization thresholds.

1. Open Cloud Shell in your Google Cloud Console.

2. Verify that your active Google Cloud project ID is set in your session:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
echo "Active Project ID: ${PROJECT_ID}"
```

> [!NOTE]
> If the command returns empty or `(unset)`, run `gcloud config set project YOUR_PROJECT_ID` using your assigned Google Cloud project ID.

3. Verify that the Cloud Spanner instance `order-mgmt-instance` and database `orders-googlesql-db` created in earlier labs are available:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="yaml(name,nodeCount,processingUnits,state)"
```

> [!TIP]
> If you are starting fresh and do not have these resources, create them now with:
> `gcloud spanner instances create order-mgmt-instance --config=regional-us-central1 --description="Order Management Instance" --processing-units=100`
> and
> `gcloud spanner databases create orders-googlesql-db --instance=order-mgmt-instance --database-dialect=GOOGLE_STANDARD_SQL`

4. Scale the compute capacity of `order-mgmt-instance` dynamically to 1,000 Processing Units (1 full node):

```bash
gcloud spanner instances update order-mgmt-instance \
  --processing-units=1000
```

> [!NOTE]
> In Cloud Spanner, 1 Node equals exactly 1,000 Processing Units. Sizing up or down takes effect in seconds without interrupting active client transactions or resetting connection pools.

5. Confirm that the instance reports 1,000 Processing Units and is in the `READY` state:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="value(processingUnits,state)"
```

6. Configure native Cloud Spanner Autoscaling on `order-mgmt-instance` with a minimum capacity of 1,000 Processing Units, a maximum capacity of 3,000 Processing Units, a high-priority CPU target of 65 percent, and a storage target of 75 percent:

```bash
gcloud spanner instances update order-mgmt-instance \
  --autoscaling-min-processing-units=1000 \
  --autoscaling-max-processing-units=3000 \
  --autoscaling-high-priority-cpu-target=65 \
  --autoscaling-storage-target=75
```

> [!IMPORTANT]
> For regional instances, the recommended high-priority CPU target is 65 percent. For multi-region instances, never configure the target above 45 percent, because surviving regions require at least 55 percent reserve headroom to absorb cross-region failover traffic without cascading outages.

7. Inspect the autoscaling configuration applied to your instance:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="yaml(autoscalingConfig)"
```

8. Return the instance to a manual compute capacity of 100 Processing Units to manage operational costs during the remainder of the lab:

```bash
gcloud spanner instances update order-mgmt-instance \
  --processing-units=100
```

> [!NOTE]
> Supplying `--processing-units` or `--nodes` automatically removes the autoscaler configuration and returns the instance to manual provisioning mode.

### Task 2: Inspect query performance and lock contention in system tables

In this task, you execute tagged SQL queries and inspect real-time performance and lock metrics using the `SPANNER_SYS` internal statistics tables.

1. Ensure the `Customers` table contains data for performance introspection. Insert baseline records if they do not already exist:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, CreatedAt)
         VALUES
         (100000000000000001, 'Alice Chen', 'alice.chen@example.com', 450.00, CURRENT_TIMESTAMP()),
         (100000000000000002, 'Marcus Vance', 'marcus.vance@example.com', 125.50, CURRENT_TIMESTAMP())
         ON DUPLICATE KEY UPDATE FullName = FullName;"
```

2. Execute an analytical query tagged with a statement hint using the `@{STATEMENT_TAG=...}` directive:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="@{STATEMENT_TAG='customer_tier_audit'} SELECT CustomerTier, COUNT(*) AS tier_count FROM Customers GROUP BY CustomerTier;"
```

> [!TIP]
> Statement and request tags allow database administrators and developers to trace queries from client applications directly into Query Insights dashboards and `SPANNER_SYS` tables.

3. Execute a second tagged query simulating an operational lookup:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="@{STATEMENT_TAG='active_customers_lookup'} SELECT CustomerId, FullName, Email, Balance FROM Customers WHERE Balance > 100.00 ORDER BY Balance DESC;"
```

4. Query the `SPANNER_SYS.QUERY_STATS_TOP_MINUTE` system view to inspect the top queries by CPU consumption over the last minute:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT text, execution_count, avg_latency_seconds, avg_cpu_seconds, avg_rows FROM SPANNER_SYS.QUERY_STATS_TOP_MINUTE ORDER BY avg_cpu_seconds DESC LIMIT 5;"
```

> [!NOTE]
> `SPANNER_SYS.QUERY_STATS_TOP_MINUTE` aggregates query execution count, latency, CPU consumption, and row counts over rolling 1-minute intervals. Spanner retains minute-level statistics for up to 6 hours and hourly statistics (`QUERY_STATS_TOP_HOUR`) for up to 30 days.

5. Query the `SPANNER_SYS.LOCK_STATS_TOP_MINUTE` view to inspect lock wait times and detect potential lock contention across storage splits:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT interval_end, row_range_start_key, lock_wait_seconds FROM SPANNER_SYS.LOCK_STATS_TOP_MINUTE ORDER BY lock_wait_seconds DESC LIMIT 5;"
```

> [!NOTE]
> High values in `lock_wait_seconds` indicate concurrent transactions competing for row or range locks on identical storage splits. Correlating lock statistics with transaction tags isolates application hotspots without external monitoring tools.

### Task 3: Implement Fine-Grained Access Control with database roles

In this task, you create database roles using DDL, grant table-level and column-level privileges, and verify that privilege boundaries are enforced when queries execute.

1. Ensure the child `Orders` table exists before defining fine-grained access rules:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE TABLE IF NOT EXISTS Orders (
           CustomerId INT64 NOT NULL,
           OrderId STRING(36) NOT NULL,
           OrderDate TIMESTAMP NOT NULL,
           TotalAmount NUMERIC NOT NULL,
           OrderStatus STRING(32) NOT NULL
         ) PRIMARY KEY (CustomerId, OrderId),
           INTERLEAVE IN PARENT Customers ON DELETE CASCADE;"
```

2. Insert a sample order record for testing access control:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)
         VALUES (100000000000000001, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', CURRENT_TIMESTAMP(), 180.00, 'PROCESSING')
         ON DUPLICATE KEY UPDATE OrderStatus = 'PROCESSING';"
```

3. Create two fine-grained database roles using DDL:
   - `reporting_analyst`: table-level read on `Customers`, and column-restricted read on `Orders(CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus)`.
   - `order_manager`: read, insert, and update privileges on `Orders`.

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="CREATE ROLE reporting_analyst;
         GRANT SELECT ON TABLE Customers TO ROLE reporting_analyst;
         GRANT SELECT (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus) ON TABLE Orders TO ROLE reporting_analyst;
         CREATE ROLE order_manager;
         GRANT SELECT, INSERT, UPDATE ON TABLE Orders TO ROLE order_manager;"
```

> [!IMPORTANT]
> Fine-Grained Access Control (FGAC) enables multiple application components or microservices to connect to the same Spanner database while restricting each service to only the tables and columns required for its function.

4. Inspect the information schema to verify that the table privileges have been registered:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT grantee, table_name, privilege_type FROM INFORMATION_SCHEMA.TABLE_PRIVILEGES WHERE grantee IN ('reporting_analyst', 'order_manager') ORDER BY grantee, table_name;"
```

5. Execute a query on `Customers` assuming the `reporting_analyst` database role using the `--database-role` flag:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --database-role=reporting_analyst \
  --sql="SELECT CustomerId, FullName, Email FROM Customers LIMIT 5;"
```

> [!NOTE]
> The query executes successfully because `reporting_analyst` holds `SELECT` privileges on the `Customers` table.

6. Execute a query on authorized columns in `Orders` assuming the `reporting_analyst` database role:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --database-role=reporting_analyst \
  --sql="SELECT CustomerId, OrderId, TotalAmount, OrderStatus FROM Orders LIMIT 5;"
```

7. Test privilege enforcement by attempting to update customer data under the `reporting_analyst` role:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --database-role=reporting_analyst \
  --sql="UPDATE Customers SET Balance = 1000.00 WHERE CustomerId = 100000000000000001;"
```

> [!NOTE]
> Cloud Spanner rejects the statement with a permission denied error. Because `reporting_analyst` has only read privileges, unauthorized modifications are blocked at the database engine level.

### Task 4: Configure Point-in-Time Recovery and perform surgical data recovery

In this task, you extend the database Point-in-Time Recovery (PITR) window, simulate an accidental data corruption event, query historical state using timestamp bounds, and surgically restore the original data.

1. Inspect the existing schema and options for `orders-googlesql-db`:

```bash
gcloud spanner databases ddl describe orders-googlesql-db \
  --instance=order-mgmt-instance
```

> [!NOTE]
> By default, Cloud Spanner retains historical versions for 1 hour (`1h`). If an error is detected after 1 hour, historical data is permanently purged by background compactions.

2. Extend the Point-in-Time Recovery window to the maximum of 7 days (`7d`) using DDL:

```bash
gcloud spanner databases ddl update orders-googlesql-db \
  --instance=order-mgmt-instance \
  --ddl="ALTER DATABASE \`orders-googlesql-db\` SET OPTIONS (version_retention_period = '7d');"
```

> [!IMPORTANT]
> Always configure `version_retention_period = '7d'` on production databases. The incremental storage cost for retaining multi-version concurrency control (MVCC) tombstones is minor compared to the risk of irreversible data loss.

3. Insert a critical test customer record to establish a known baseline:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO Customers (CustomerId, FullName, Email, Balance, CreatedAt)
         VALUES (888888888888888888, 'Vance Sterling', 'vance.sterling@example.com', 750.00, CURRENT_TIMESTAMP())
         ON DUPLICATE KEY UPDATE Balance = 750.00;"
```

4. Capture the current UTC timestamp and save it to an environment variable:

```bash
export PITR_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Baseline recovery timestamp: ${PITR_TIMESTAMP}"
sleep 5
```

5. Simulate an accidental corruption incident where an errant script zeroes out the customer balance:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="UPDATE Customers SET Balance = 0.00 WHERE CustomerId = 888888888888888888;"
```

6. Query the live database to confirm that the customer balance is now corrupted:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId, FullName, Balance FROM Customers WHERE CustomerId = 888888888888888888;"
```

7. Execute a historical snapshot query using the `--read-timestamp` flag to inspect the database state as it existed at `${PITR_TIMESTAMP}`:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --read-timestamp="${PITR_TIMESTAMP}" \
  --sql="SELECT CustomerId, FullName, Balance FROM Customers WHERE CustomerId = 888888888888888888;"
```

> [!NOTE]
> The historical query returns the pre-corruption balance of `750.00`. Spanner resolves stale reads from historical MVCC data blocks without acquiring locks or blocking concurrent writers.

8. Retrieve the exact historical balance from the past snapshot and store it in an environment variable:

```bash
export ORIGINAL_BALANCE="$(gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --read-timestamp="${PITR_TIMESTAMP}" \
  --sql="SELECT Balance FROM Customers WHERE CustomerId = 888888888888888888;" \
  --format="value(Balance)")"
echo "Original balance to restore: ${ORIGINAL_BALANCE}"
```

9. Surgically restore the corrupted record in the live database:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="UPDATE Customers SET Balance = ${ORIGINAL_BALANCE} WHERE CustomerId = 888888888888888888;"
```

10. Confirm that the customer balance has been restored in the live database:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT CustomerId, FullName, Balance FROM Customers WHERE CustomerId = 888888888888888888;"
```

> [!TIP]
> Point-in-Time Recovery allows you to repair localized data errors in seconds within the active database, avoiding the hours of downtime and data loss associated with full database restores.

### Task 5: Create on-demand backups, configure backup schedules, and restore a database

In this task, you create an asynchronous on-demand backup, automate backups using a recurring backup schedule, and restore a backup into a brand-new database.

1. Initiate an asynchronous on-demand backup of `orders-googlesql-db` with a 24-hour retention period:

```bash
gcloud spanner backups create orders-backup-ondemand \
  --instance=order-mgmt-instance \
  --database=orders-googlesql-db \
  --retention-period=24h \
  --async
```

> [!NOTE]
> Spanner captures consistent backups asynchronously from Colossus storage splits with zero impact on active transactions. Retention periods can range from 6 hours up to 366 days.

2. Check the creation status of your on-demand backup:

```bash
gcloud spanner backups describe orders-backup-ondemand \
  --instance=order-mgmt-instance \
  --format="table(name.basename():label=BACKUP_ID,state,sizeBytes)"
```

3. Create an automated backup schedule named `daily-orders-backup` that triggers every day at 02:00 UTC and retains backups for 7 days:

```bash
gcloud spanner backup-schedules create daily-orders-backup \
  --instance=order-mgmt-instance \
  --database=orders-googlesql-db \
  --backup-type=full-backup \
  --cron="0 2 * * *" \
  --retention-duration=7d
```

4. Inspect the configuration of your new backup schedule:

```bash
gcloud spanner backup-schedules describe daily-orders-backup \
  --instance=order-mgmt-instance \
  --database=orders-googlesql-db
```

5. Wait until `orders-backup-ondemand` completes and reports a `state` of `READY`:

```bash
while [ "$(gcloud spanner backups describe orders-backup-ondemand --instance=order-mgmt-instance --format='value(state)')" != "READY" ]; do
  echo "Waiting for backup to complete..."
  sleep 10
done
echo "Backup is READY."
```

6. Restore the backup into a new database named `orders-restored-db`:

```bash
gcloud spanner databases restore \
  --destination-instance=order-mgmt-instance \
  --destination-database=orders-restored-db \
  --source-instance=order-mgmt-instance \
  --source-backup=orders-backup-ondemand \
  --async
```

> [!IMPORTANT]
> Restoring a backup in Cloud Spanner always provisions a brand-new database. It cannot overwrite an existing database in place. Design application connection strings to be configurable so traffic can be redirected to restored databases during disaster recovery cutovers.

7. Describe the restored database to confirm that the restore operation is tracking the source backup:

```bash
gcloud spanner databases describe orders-restored-db \
  --instance=order-mgmt-instance \
  --format="yaml(name,state,restoreInfo)"
```

### Bonus Task 6: Audit database IAM policies and clean up operational resources

In this task, you inspect Cloud IAM permissions and remove the temporary recovery database and backups to preserve project quotas.

1. Inspect the Cloud IAM policy applied to `orders-googlesql-db`:

```bash
gcloud spanner databases get-iam-policy orders-googlesql-db \
  --instance=order-mgmt-instance
```

2. Delete the automated backup schedule:

```bash
gcloud spanner backup-schedules delete daily-orders-backup \
  --instance=order-mgmt-instance \
  --database=orders-googlesql-db \
  --quiet
```

3. Delete the restored database `orders-restored-db`:

```bash
gcloud spanner databases delete orders-restored-db \
  --instance=order-mgmt-instance \
  --quiet
```

4. Delete the on-demand backup `orders-backup-ondemand`:

```bash
gcloud spanner backups delete orders-backup-ondemand \
  --instance=order-mgmt-instance \
  --quiet
```

5. Confirm that the restored database and backup have been removed:

```bash
gcloud spanner databases list --instance=order-mgmt-instance --format="table(name.basename():label=DATABASE_ID,state)"
gcloud spanner backups list --instance=order-mgmt-instance --format="table(name.basename():label=BACKUP_ID,state)"
```

## Congratulations!

In this lab, you have:
- Configured native Cloud Spanner autoscaling policies and adjusted compute boundaries.
- Monitored query execution and lock contention using Query Insights and `SPANNER_SYS` tables.
- Implemented Fine-Grained Access Control by defining database roles and testing column-level privileges.
- Extended the Point-in-Time Recovery retention window and recovered data using historical timestamps.
- Created on-demand backups, configured automated backup schedules, and restored a database.
