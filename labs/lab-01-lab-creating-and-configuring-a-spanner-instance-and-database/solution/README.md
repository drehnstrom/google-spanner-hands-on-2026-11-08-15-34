# Solution: Creating and Configuring a Spanner Instance and Database

## End State

- Cloud Spanner API enabled in the Google Cloud project (`spanner.googleapis.com`).
- A regional Cloud Spanner instance named `order-mgmt-instance`:
  - Configuration: `regional-us-central1`
  - Display name: `Order Management Instance`
  - Compute capacity: 100 Processing Units (scaled up to 400 PUs during testing, then returned to 100 PUs)
  - Labels: `environment=development`, `workload=order-processing`
- Two databases created within the instance demonstrating both supported dialects:
  - `orders-googlesql-db`: Configured with the `GOOGLE_STANDARD_SQL` dialect
  - `inventory-pg-db`: Configured with the `POSTGRESQL` dialect
- A test table `SystemMetadata` in `orders-googlesql-db` containing one test record to validate DDL execution and SQL query processing.

## How to Verify

From Google Cloud Shell or an authenticated terminal with Cloud SDK:

```bash
# Verify instance existence, configuration, and compute allocation
gcloud spanner instances describe order-mgmt-instance \
  --format="yaml(name,config,displayName,processingUnits,state)"
```

Expected output:
```yaml
config: projects/YOUR_PROJECT_ID/instanceConfigs/regional-us-central1
displayName: Order Management Instance
name: projects/YOUR_PROJECT_ID/instances/order-mgmt-instance
processingUnits: 100
state: READY
```

```bash
# List and verify both databases and their respective dialects
gcloud spanner databases list --instance=order-mgmt-instance \
  --format="table(name.basename():label=DATABASE_ID,databaseDialect,state)"
```

Expected output:
```text
DATABASE_ID          DATABASE_DIALECT     STATE
inventory-pg-db      POSTGRESQL           READY
orders-googlesql-db  GOOGLE_STANDARD_SQL  READY
```

```bash
# Execute SQL query against the GoogleSQL database
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT PropertyKey, PropertyValue FROM SystemMetadata WHERE PropertyKey = 'schema_version';"
```

Expected output:
```text
PropertyKey     PropertyValue
schema_version  1.0
```

## Built With

- Google Cloud SDK (`gcloud`) version 490+ / Cloud Shell
- Google Cloud Spanner API (`spanner.googleapis.com`)
- Cloud Spanner GoogleSQL and PostgreSQL database engines (checked November 2026)
- Unverified: Real project quota and actual billing rate during live multi-region creation (simulated in regional mode using standard lab quotas)
