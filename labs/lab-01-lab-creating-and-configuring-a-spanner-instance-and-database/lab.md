# Creating and Configuring a Spanner Instance and Database

## Time Required

40 minutes

## Overview

In this lab, you will explore Cloud Spanner instance configurations, provision a regional instance using granular Processing Units, create databases using both GoogleSQL and PostgreSQL dialects, and dynamically scale compute capacity without downtime.

### You learn how to:
- Inspect regional and multi-region Spanner instance configurations and replica topologies.
- Provision a regional Spanner instance using fractional Processing Units.
- Create databases configured with GoogleSQL and PostgreSQL dialects.
- Scale compute capacity dynamically between Processing Unit allocations.
- Execute SQL statements and verify database operational readiness.

## Scenario

You are a database administrator at an enterprise retail platform preparing to deploy Cloud Spanner for an upcoming order management service. Before migrating critical operational workloads, you need to evaluate deployment topologies, provision an initial regional instance with cost-effective fractional compute capacity, deploy databases supporting both standard GoogleSQL and PostgreSQL dialects, and verify that compute capacity can scale dynamically without service disruption.

## Lab Instructions

### Task 1: Explore Spanner deployment topologies and instance configurations

In this task, you prepare your environment, enable the Cloud Spanner API, and examine regional and multi-region instance configurations to understand replica placement and voting quorums.

1. Open Cloud Shell in your Google Cloud Console.

2. Verify that your active Google Cloud project ID is set in your session:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
echo "Active Project ID: ${PROJECT_ID}"
```

> [!NOTE]
> If the command returns empty or `(unset)`, run `gcloud config set project YOUR_PROJECT_ID` using your assigned Google Cloud project ID.

3. Enable the Cloud Spanner API in your project:

```bash
gcloud services enable spanner.googleapis.com
```

4. List available regional instance configurations located in North America:

```bash
gcloud spanner instance-configs list \
  --filter="name:regional-us" \
  --format="table(name.basename():label=CONFIG_ID, displayName)"
```

5. Inspect the multi-region configuration `nam3` to review its replica topology:

```bash
gcloud spanner instance-configs describe nam3 \
  --format="yaml(displayName,leaderOptions,replicas)"
```

> [!NOTE]
> Notice that `nam3` defines read-write replicas in `us-east4` and `us-east1`, along with a witness replica in `us-central1`. The witness replica votes in Paxos consensus rounds to maintain high availability without incurring storage costs.

### Task 2: Provision a Cloud Spanner instance with granular compute capacity

In this task, you create a regional Cloud Spanner instance provisioned with 100 Processing Units, allowing cost-effective development without allocating a full node.

1. Create a regional Spanner instance named `order-mgmt-instance` in `us-central1` using 100 Processing Units:

```bash
gcloud spanner instances create order-mgmt-instance \
  --config=regional-us-central1 \
  --description="Order Management Instance" \
  --processing-units=100 \
  --labels=environment=development,workload=order-processing
```

> [!IMPORTANT]
> A Spanner node equals 1,000 Processing Units. Fractional compute sizing begins at 100 Processing Units and scales in increments of 100 up to 1,000. Each 100 Processing Units provides up to 409.6 GB of database storage.

2. Retrieve and inspect the details of your newly created instance:

```bash
gcloud spanner instances describe order-mgmt-instance
```

3. Confirm that the instance reports a `state` of `READY` and that `processingUnits` equals `100`:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="value(state,processingUnits)"
```

### Task 3: Create databases using GoogleSQL and PostgreSQL dialects

In this task, you create two distinct databases within your Spanner instance to observe dialect selection and schema initialization.

1. Create a database named `orders-googlesql-db` configured with the GoogleSQL dialect and an initial metadata table:

```bash
gcloud spanner databases create orders-googlesql-db \
  --instance=order-mgmt-instance \
  --database-dialect=GOOGLE_STANDARD_SQL \
  --ddl="CREATE TABLE SystemMetadata (PropertyKey STRING(128) NOT NULL, PropertyValue STRING(1024)) PRIMARY KEY (PropertyKey)"
```

> [!NOTE]
> The database dialect is established permanently at database creation time. A database cannot be converted between GoogleSQL and PostgreSQL dialects after initialization.

2. Create a second database named `inventory-pg-db` configured with the PostgreSQL dialect:

```bash
gcloud spanner databases create inventory-pg-db \
  --instance=order-mgmt-instance \
  --database-dialect=POSTGRESQL
```

3. List all databases hosted on `order-mgmt-instance` and verify their configured dialects:

```bash
gcloud spanner databases list \
  --instance=order-mgmt-instance \
  --format="table(name.basename():label=DATABASE_ID,databaseDialect,state)"
```

4. Insert a test configuration record into the `SystemMetadata` table in `orders-googlesql-db`:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="INSERT INTO SystemMetadata (PropertyKey, PropertyValue) VALUES ('schema_version', '1.0');"
```

5. Query the table to verify that the statement committed successfully:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT PropertyKey, PropertyValue FROM SystemMetadata WHERE PropertyKey = 'schema_version';"
```

### Task 4: Scale compute capacity dynamically without downtime

In this task, you dynamically scale compute capacity up and down to observe how Cloud Spanner separates compute capacity from underlying storage.

1. Scale the compute capacity of `order-mgmt-instance` from 100 Processing Units to 400 Processing Units:

```bash
gcloud spanner instances update order-mgmt-instance \
  --processing-units=400
```

2. Confirm that the instance compute capacity is now 400 Processing Units:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="value(processingUnits)"
```

3. Query `orders-googlesql-db` immediately to confirm that reads and writes continue uninterrupted during compute updates:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT COUNT(*) AS total_records FROM SystemMetadata;"
```

4. Scale the compute capacity back down to 100 Processing Units to manage operational costs:

```bash
gcloud spanner instances update order-mgmt-instance \
  --processing-units=100
```

5. Verify that the instance has successfully returned to 100 Processing Units:

```bash
gcloud spanner instances describe order-mgmt-instance \
  --format="value(processingUnits)"
```

### Bonus Task 5: Inspect instance IAM policies and schema metadata

In this task, you inspect Cloud IAM bindings attached to the Spanner instance and query the database schema catalog.

1. Display the Identity and Access Management policy applied to `order-mgmt-instance`:

```bash
gcloud spanner instances get-iam-policy order-mgmt-instance
```

2. Query the relational schema catalog in `orders-googlesql-db` using standard ANSI SQL information schema views:

```bash
gcloud spanner databases execute-sql orders-googlesql-db \
  --instance=order-mgmt-instance \
  --sql="SELECT table_name, parent_table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '';"
```

3. Confirm that the `SystemMetadata` table appears in the query results with no parent table.

## Congratulations!

In this lab, you have:
- Inspected regional and multi-region Spanner instance configurations and replica topologies.
- Provisioned a regional Spanner instance using fractional Processing Units.
- Created databases configured with GoogleSQL and PostgreSQL dialects.
- Scaled compute capacity dynamically between Processing Unit allocations.
- Executed SQL statements and verified database operational readiness.
