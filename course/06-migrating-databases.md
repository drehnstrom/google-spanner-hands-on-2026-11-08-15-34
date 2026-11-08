<!-- course-title: Google Spanner: Hands-On -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Google Spanner: Hands-On

# Chapter 6: Migrating Databases to Cloud Spanner

---

# Chapter 6: Objectives

- Assess, convert schemas, and migrate relational databases to Cloud Spanner
- Evaluate source database workloads and formulate a structured migration plan
- Translate relational schemas and map foreign data types to Spanner constructs
- Convert schemas and generate migration scripts with Spanner Migration Tool
- Ingest historical data in bulk and capture ongoing changes during migration
- Execute cutover workflows and validate zero-downtime transition strategies
- Perform an end-to-end relational database migration to Cloud Spanner

---

<!-- layout: navigation -->
# Chapter 6

- **Migration Strategy and Assessment**
- Schema Translation and Dialect Mapping
- Using the Spanner Migration Tool
- Bulk Data Loading and Change Data Capture
- Production Cutover and Zero-Downtime Strategies
- Lab: Migrating a Relational Database to Cloud Spanner

---

<!-- layout: card-layout -->
# Evaluating Workloads for Cloud Spanner

### Workload Fit Criteria
- Workloads requiring relational semantics, strong ACID transactions, and horizontal scale.
- Applications outgrowing single-instance PostgreSQL, MySQL, Oracle, or SQL Server.
- Systems demanding 99.999% availability with zero planned maintenance downtime.

### Compute and Storage Sizing
- Estimate storage footprint based on the 4 TB per 1,000 Processing Units (1 node) rule.
- Baseline 1,000 PUs for up to 10,000 read QPS or 2,000 single-row write QPS.
- Size instance capacity to maintain high-priority CPU under 65% regional or 45% multi-region.

### Feature Gap Analysis
- Identify relational features not supported in Spanner before planning migration.
- Spanner does not support stored procedures, triggers, or user-defined functions.
- Business logic residing in database procedural code must migrate into application code.

---

<!-- layout: 2-column -->
# Migration Methodology: Offline vs Online

### Offline Migration
- Database dump exported from source and imported directly into Cloud Spanner
- Simplest operational architecture with no real-time synchronization pipelines
- Source database remains locked or unavailable to application writes during import
- Best suited for non-critical workloads, internal tools, or small datasets (< 500 GB)
- Requires an acceptable maintenance downtime window of several hours

### Online Migration
- Initial bulk data snapshot loaded in parallel while source remains live
- Continuous Change Data Capture (CDC) streams ongoing mutations to Spanner
- Near-zero application downtime during production cutover window
- Complex operational tooling involving Datastream, Pub/Sub, and Cloud Dataflow
- Essential for mission-critical enterprise systems and high-volume e-commerce

<!-- below-columns -->

> [!NOTE]
> Online migrations minimize business disruption by keeping the legacy database active right up to the minute cutover verification passes.

---

# Assessing Source Dependencies and Application Compatibility

- Relational migrations require auditing application data access patterns, ORMs, and query models
- Identifying architectural incompatibilities early prevents costly post-cutover rollbacks

- **Stored Procedures and Triggers**: Extract procedural business logic and reimplement inside application services or Cloud Run microservices
- **Sequence Generators and Auto-Increment**: Replace monotonic primary keys with distributed random keys (UUIDv4, bit-reversed sequences, or hash prefixes)
- **ORM Framework Support**: Update ORM dialect configurations (Hibernate, SQLAlchemy, Prisma, Django) to use certified Cloud Spanner drivers
- **Transaction Life Cycles**: Refactor long-running interactive transactions into short, targeted read-write transactions to prevent lock contention

> [!IMPORTANT]
> Because Spanner uses two-phase commit and distributed two-phase locking, transactions should execute within milliseconds. Long-running analytical transactions must use snapshot reads.

---

<!-- layout: 2-column -->
# Failure Mode: Porting Monolithic RDBMS Patterns Directly to Spanner

### The Lift-and-Shift Trap
- Engineering team executes a 1:1 schema conversion of an Oracle enterprise database
- Retains monotonic sequence triggers for primary keys across all order tables
- Replaces stored procedures with complex multi-table cross-shard join queries
- Leaves child tables un-interleaved and relies on traditional foreign key cascading

### The Cascading Failure
- All new order inserts funnel into a single Spanner node, saturating its CPU at 100%
- Write throughput crashes from 5,000 writes/sec to 350 writes/sec with high abort rates
- Multi-table joins across un-interleaved tables trigger distributed 2PC locks across dozens of splits
- Application latency spikes past 15 seconds, causing client timeouts and cascading outages

<!-- below-columns -->

> [!CAUTION]
> Never treat Cloud Spanner as a drop-in replacement for a monolithic single-node RDBMS. Schemas and transaction patterns must be refactored for horizontal distribution.

---

<!-- layout: navigation -->
# Chapter 6

- Migration Strategy and Assessment
- **Schema Translation and Dialect Mapping**
- Using the Spanner Migration Tool
- Bulk Data Loading and Change Data Capture
- Production Cutover and Zero-Downtime Strategies
- Lab: Migrating a Relational Database to Cloud Spanner

---

<!-- layout: 2-column -->
# Dialect Selection: GoogleSQL vs PostgreSQL

### GoogleSQL Dialect
- Native Spanner dialect adhering to Google SQL standard
- Aligns syntax directly with Google Cloud BigQuery and internal Google services
- Comprehensive support for all Spanner features: Graph queries, full-text search, fine-grained access control
- Recommended for teams building cloud-native architectures on Google Cloud
- Supported by standard Google Cloud client SDKs across all major languages

### PostgreSQL Dialect
- Implements a core subset of PostgreSQL 14 syntax and semantics
- Enables existing PostgreSQL tooling, drivers, and ORMs to connect directly
- Supports `psql` command-line client, `pgx`, `psycopg2`, and PostgreSQL ecosystem tools
- Minimizes application code refactoring when migrating from on-premises PostgreSQL
- Certain GoogleSQL-specific extensions and functions may not be available

<!-- below-columns -->

> [!NOTE]
> Dialect selection is immutable once a database is created. Choose GoogleSQL for native BigQuery alignment and full feature availability, or PostgreSQL for ecosystem driver compatibility.

---

<!-- layout: 3-column -->
# Data Type Mapping Across Engines

### MySQL to Spanner
- `VARCHAR` / `TEXT` -> `STRING`
- `BIGINT` / `INT` -> `INT64`
- `DECIMAL` / `NUMERIC` -> `NUMERIC`
- `DATETIME` / `TIMESTAMP` -> `TIMESTAMP`
- `BLOB` / `VARBINARY` -> `BYTES`
- `JSON` -> `JSON`

### PostgreSQL to Spanner
- `varchar` / `text` -> `varchar` / `text`
- `bigint` / `integer` -> `bigint`
- `numeric` / `decimal` -> `numeric`
- `timestamptz` -> `timestamptz`
- `bytea` -> `bytea`
- `jsonb` -> `jsonb`

### Unsupported Types
- Unsigned integers (must convert to next larger signed type)
- Custom User Defined Types (UDTs)
- Spatial / GIS types (store as GeoJSON)
- Engine-specific enum types (store as `STRING` with `CHECK` constraints)

---

<!-- layout: card-layout -->
# Converting Foreign Keys and Table Interleaving

### Relational Foreign Keys
- Spanner supports standard ANSI SQL `FOREIGN KEY` constraints across any tables.
- Non-interleaved foreign keys enforce referential integrity across distributed splits.
- Validating foreign key constraints requires distributed locks during insert and delete operations.

### Table Interleaving
- Co-locates child rows physically within the same storage split as the parent row.
- Delivers blazing-fast, single-node joins without distributed locking across splits.
- Converts standard 1:N foreign key hierarchies into high-performance collocated data structures.

### Cascading Actions
- Interleaved tables natively support `ON DELETE CASCADE` and `ON DELETE NO ACTION`.
- Standalone foreign keys in Spanner do not support `ON DELETE CASCADE` or `ON UPDATE CASCADE`.
- Cascading deletes on standalone foreign keys must be implemented via application logic.

---

# Primary Key Redesign: Eliminating Sequential Hotspots

- Legacy schemas using auto-increment or sequential numbers must be refactored before migration
- Cloud Spanner requires primary keys with uniform distribution across the keyspace

```sql
-- Legacy MySQL / PostgreSQL Schema (Anti-Pattern on Spanner)
-- CREATE TABLE Orders (
--   OrderId BIGINT AUTO_INCREMENT PRIMARY KEY,
--   CustomerId INT NOT NULL,
--   OrderTotal DECIMAL(10,2) NOT NULL
-- );

-- Refactored GoogleSQL Schema with Bit-Reversed Sequence
CREATE SEQUENCE OrderIdSeq OPTIONS (
  sequence_kind = 'bit_reversed_positive'
);

CREATE TABLE Orders (
  OrderId INT64 DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderIdSeq)),
  CustomerId INT64 NOT NULL,
  OrderTotal NUMERIC NOT NULL,
  OrderDate TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)
) PRIMARY KEY (OrderId);
```

> [!TIP]
> Using `bit_reversed_positive` sequences preserves unique integer primary keys while scattering successive inserts uniformly across all storage splits.

---

<!-- layout: 2-column -->
# Failure Mode: Migrating Auto-Increment Keys Without Redistribution

### The Monotonic Migration Trap
- Data engineers migrate an on-premises database with a sequential `OrderId` integer column
- During schema conversion, the column is mapped directly to `INT64` with an incrementing counter
- Application cutover occurs, and thousands of checkout services start inserting orders simultaneously
- Within 15 minutes, checkout requests begin failing with transaction timeout errors

### Key Space Splitting Reality
- Spanner splits tables by primary key ranges (for example, split 1: 1 to 500,000; split 2: 500,001 to 1,000,000)
- All new incoming orders have IDs greater than the highest existing ID (for example, 1,000,001+)
- Exactly one storage split and one Paxos leader node handles 100% of the write load
- Provisioning 20 additional Spanner nodes provides zero relief because only one split receives writes!

<!-- below-columns -->

> [!CAUTION]
> Never retain monotonically increasing primary keys when migrating to Spanner. Refactor primary keys to UUIDv4, hash prefixes, or bit-reversed sequences prior to data loading.

---

<!-- layout: navigation -->
# Chapter 6

- Migration Strategy and Assessment
- Schema Translation and Dialect Mapping
- **Using the Spanner Migration Tool**
- Bulk Data Loading and Change Data Capture
- Production Cutover and Zero-Downtime Strategies
- Lab: Migrating a Relational Database to Cloud Spanner

---

<!-- layout: card-layout -->
# Overview and Architecture of Spanner Migration Tool

### Open-Source Assessment Tool
- Google-developed open-source tool (formerly HarbourBridge) for end-to-end migrations.
- Connects directly to source databases or parses offline database schema dump files.
- Generates comprehensive compatibility reports with confidence scores for every table.

### Multi-Engine Source Support
- Supports source schemas from PostgreSQL, MySQL, Oracle, and Microsoft SQL Server.
- Maps dialect-specific data types to appropriate GoogleSQL or PostgreSQL dialect types.
- Suggests candidate tables for interleaving based on foreign key relationships.

### Execution Modes
- Command-line interface (CLI) for headless automation, CI/CD pipelines, and scripting.
- Interactive local web UI for visual schema adjustments and rule customizations.
- Generates Spanner DDL scripts, mapping rules JSON, and direct bulk data load commands.

---

# Automated Schema Assessment with the CLI

- Run the Spanner Migration Tool CLI against a schema dump or live source database
- Generates an assessment report highlighting compatibility, warnings, and suggested alterations

```bash
# Install and run schema assessment against a MySQL dump file
spanner-migration-tool schema \
    -source=mysql \
    -dump-file=production_dump.sql \
    -target-profile="project=my-spanner-project,instance=prod-spanner,db=ecommerce"

# Inspect the generated schema conversion assessment report
cat schema_assessment_report.txt | grep -E "(HIGH|MEDIUM|LOW) confidence"

# Generate Spanner DDL schema script directly from translated schema
spanner-migration-tool schema \
    -source=postgres \
    -dump-file=pg_backup.sql \
    -target-dialect=POSTGRESQL \
    -output-file=spanner_schema.sql
```

> [!NOTE]
> The assessment report categorizes column mappings into High, Medium, and Low confidence. Medium and Low confidence items represent potential precision loss or unsupported types requiring review.

---

<!-- layout: 2-column -->
# Customizing Schema Mappings in SMT

### SMT Interactive Web Interface
- Launch local web UI using `spanner-migration-tool web`
- Visually inspect source tables, column data types, primary keys, and foreign keys
- Modify table names, drop unnecessary columns, and adjust Spanner data type mappings
- Configure parent-child relationships and establish table interleaving with one click

### Rule-Based Transformation Files
- Define declarative JSON transformation rules for automated schema pipelines
- Rename tables or columns systematically across the entire database
- Alter primary key column orders to eliminate hotspotting
- Configure foreign keys as either interleaved tables or standalone foreign constraints

<!-- below-columns -->

> [!TIP]
> Use the web interface during the schema design phase to experiment with table interleaving configurations and review simulated DDL outputs before provisioning.

---

<!-- layout: 2-column -->
# Failure Mode: Blindly Applying Automated SMT DDL in Production

### The Automated Fallacy
- Engineers run SMT CLI, see a 95% High Confidence score, and immediately run the output DDL
- SMT correctly converted types (such as `BIGINT` to `INT64` and `VARCHAR` to `STRING(MAX)`)
- However, SMT retained the original sequential primary key order from the source database
- SMT also left all tables as standalone un-interleaved entities because it cannot deduce query access patterns

### Operational Degradation
- All primary tables suffer write hotspotting immediately upon loading high-volume traffic
- Massive analytical queries that previously joined parent and child tables in milliseconds now execute distributed RPCs
- Unbounded `STRING(MAX)` columns consume excessive memory buffers in query execution plans
- The team must drop and recreate the database schema after loading hundreds of gigabytes of data

<!-- below-columns -->

> [!WARNING]
> SMT output is a baseline recommendation, not a final production schema. Database architects must inspect primary key distribution, assign proper string lengths, and configure interleaving manually.

---

<!-- layout: navigation -->
# Chapter 6

- Migration Strategy and Assessment
- Schema Translation and Dialect Mapping
- Using the Spanner Migration Tool
- **Bulk Data Loading and Change Data Capture**
- Production Cutover and Zero-Downtime Strategies
- Lab: Migrating a Relational Database to Cloud Spanner

---

<!-- layout: card-layout -->
# Bulk Loading Architecture and Performance Optimization

### Data Export and Cloud Storage Staging
- Export historical table data from source database into Google Cloud Storage (GCS).
- Export formats: CSV, Avro, or Parquet files partitioned into 100 MB to 500 MB chunks.
- Multiple smaller files allow Cloud Dataflow to parallelize ingestion across dozens of worker nodes.

### Cloud Dataflow Ingestion
- Utilize Google-managed Cloud Dataflow bulk import templates (such as GCS Avro to Spanner).
- Dataflow workers read files concurrently and commit batches into Spanner.
- Automatically handles retries, transient backoff, and distributed transaction batching.

### Mutation and Commit Batch Limits
- Cloud Spanner enforces a hard limit of 80,000 mutations and 100 MB per commit.
- Target optimal batch sizes between 2,000 and 5,000 mutations per write commit.
- Excessive mutations per transaction increase lock memory and lead to commit aborts.

---

<!-- layout: 2-column -->
# Optimizing Bulk Load Throughput: Pre-Splitting and Secondary Indexes

### Pre-Splitting Empty Tables
- Newly created tables initially reside on a single storage split managed by one node
- Loading billions of rows into a single split forces Spanner to perform split operations during ingestion
- Pre-split tables using known primary key boundaries or utilize hash-prefixed keys
- Spanner distributes initial write batches across all cluster nodes simultaneously from minute one

### Secondary Index Deferral
- Secondary indexes require Spanner to update index tables synchronously for every insert
- Inserting into a table with 4 secondary indexes turns 1 row insert into 5 write mutations
- Secondary index updates multiply lock contention and serialize split write throughput
- **Standard Protocol**: Drop all secondary indexes before bulk loading; recreate them post-load

<!-- below-columns -->

> [!IMPORTANT]
> Creating secondary indexes after loading data executes asynchronously as a background schema update without consuming write transaction locks or degrading bulk load throughput.

---

# Continuous Replication with Change Data Capture (CDC)

- Change Data Capture streams real-time inserts, updates, and deletes from the source transaction log
- Serverless Google Cloud Datastream captures source changes and streams them to Cloud Spanner via Dataflow

```bash
# Step 1: Create a Datastream private connection to source MySQL instance
gcloud datastream connection-profiles create mysql-source-profile \
    --location=us-central1 \
    --mysql-profile=hostname="10.0.0.4",username="cdc_user",password="SecretPass123",port=3306

# Step 2: Create a Cloud Storage destination connection profile
gcloud datastream connection-profiles create gcs-destination-profile \
    --location=us-central1 \
    --gcs-profile=bucket="migration-staging-bucket",root-path="/cdc-events"

# Step 3: Launch Datastream replication stream
gcloud datastream streams create mysql-to-spanner-cdc \
    --location=us-central1 \
    --source=mysql-source-profile \
    --destination=gcs-destination-profile
```

> [!TIP]
> Google Cloud provides an out-of-the-box Dataflow template (`Cloud Datastream to Cloud Spanner`) that consumes CDC event streams from GCS or Pub/Sub and applies mutations directly to Spanner.

---

<!-- layout: 2-column -->
# Failure Mode: Bulk Loading with Active Secondary Indexes and Unpartitioned Keys

### The Ingestion Bottleneck
- An operations team launches a bulk load of 250 million rows into a newly created Spanner table
- The table has 5 secondary indexes enabled, and the primary key is an sequential integer ID
- Cloud Dataflow spins up 50 worker VMs to push maximum write throughput into Spanner
- Within 10 minutes, Dataflow workers report 90% failed write requests with `DeadlineExceeded`

### The Cascading Lock Contention
- Every single row inserted generates 6 mutations (1 base table row + 5 index table rows)
- Because primary keys are sequential, all base table writes bombard one single split leader
- Index table updates scatter mutations across other splits, triggering distributed two-phase commits
- Transaction lock tables fill up, workers retry endlessly, and the load pipeline completely stalls!

<!-- below-columns -->

> [!CAUTION]
> Never bulk load historical data with active secondary indexes. Drop all secondary indexes, pre-split primary keys, execute the bulk load, and build indexes after ingestion completes.

---

<!-- layout: navigation -->
# Chapter 6

- Migration Strategy and Assessment
- Schema Translation and Dialect Mapping
- Using the Spanner Migration Tool
- Bulk Data Loading and Change Data Capture
- **Production Cutover and Zero-Downtime Strategies**
- Lab: Migrating a Relational Database to Cloud Spanner

---

<!-- layout: card-layout -->
# Zero-Downtime Migration Strategies

### Change Data Capture Pipeline
- Source database serves all live application traffic without interruption during data migration.
- Bulk historical data is loaded; CDC pipeline replicates subsequent transactions continuously.
- Replication lag between source and Cloud Spanner is monitored until it stabilizes under 1 second.

### Dual-Writing from Application
- Application microservices write to both the legacy database and Cloud Spanner simultaneously.
- Primary writes commit to source; shadow writes execute asynchronously against Spanner.
- Verifies application compatibility and tests real-world Spanner write performance under load.

### Reverse Replication for Fallback
- Spanner Change Streams capture mutations committed to Spanner during and after cutover.
- Dataflow replicates changes back into the legacy database in real time.
- Guarantees zero data loss if unforeseen production issues necessitate an emergency rollback.

---

<!-- layout: 2-column -->
# Data Validation and Parity Reconciliation

### Checksum and Row Count Verification
- Execute parallel validation queries comparing row counts and aggregate checksums across engines
- Cloud Dataflow verification templates compare source tables with Spanner tables row by row
- Validate that all columns, primary keys, and nullable fields match exact source values
- Verify numeric precision and ensure floating-point rounding discrepancies did not introduce drift

### Shadow Reads and Consistency Checks
- Deploy application feature flag to execute shadow reads against Cloud Spanner in production
- Application serves user responses from legacy database while issuing parallel reads to Spanner
- Asynchronously compare Spanner query results and latency against source database responses
- Detect subtle query plan differences, collation sorting discrepancies, or missing rows before cutover

<!-- below-columns -->

> [!NOTE]
> Shadow reads provide 100% confidence in query performance and result correctness without exposing end users to risk.

---

<!-- layout: 3-column -->
# Phased Cutover Execution and Rollback Readiness

### Step 1: Read Cutover
- Shift read queries from legacy database to Cloud Spanner
- Implement gradual canary traffic shift (10%, 25%, 50%, 100%)
- Confirm read latency SLAs, session pool stability, and query plans
- Writes continue directing to source with CDC syncing to Spanner

### Step 2: Write Cutover
- Briefly pause source writes or enable maintenance mode (under 30 seconds)
- Wait for Datastream CDC replication lag to reach zero
- Switch application write traffic to Cloud Spanner
- Enable Spanner Change Streams to activate reverse replication to source

### Step 3: Decommissioning
- Keep legacy database synchronized via reverse CDC for 48 to 72 hours
- On-call teams monitor error logs, query abort rates, and CPU utilization
- Decommission legacy database infrastructure once production stability is proven

---

<!-- layout: 2-column -->
# Failure Mode: Cutover Without Reverse Replication or Rollback Guardrails

### The Irrevocable Cutover
- Team executes write cutover to Spanner successfully on Saturday morning
- Feeling confident, they immediately terminate Datastream and shut down the legacy database cluster
- For the first 18 hours, checkout services and user transactions execute flawlessly
- On Sunday night, a scheduled batch settlement job triggers unexpected distributed transaction lock timeouts

### The Recovery Impasse
- The batch failure prevents millions of dollars in customer settlements from processing
- The incident team wants to roll back immediately to the proven legacy database
- However, Spanner has processed over 250,000 new orders since Saturday that do not exist in the legacy DB!
- Without reverse replication, rolling back means either losing all weekend customer orders or facing days of manual data reconciliation

<!-- below-columns -->

> [!CAUTION]
> Never cut over production writes without an active reverse replication pipeline from Spanner back to the legacy database. Reverse replication is your insurance policy for safe rollback.

---

<!-- layout: navigation -->
# Chapter 6

- Migration Strategy and Assessment
- Schema Translation and Dialect Mapping
- Using the Spanner Migration Tool
- Bulk Data Loading and Change Data Capture
- Production Cutover and Zero-Downtime Strategies
- **Lab: Migrating a Relational Database to Cloud Spanner**

---

# Lab: Migrating a Relational Database to Cloud Spanner

Lab link: TODO

---

# What You Learned

- Assessed, converted schemas, and migrated relational databases to Cloud Spanner
- Evaluated source database workloads and formulated a structured migration plan
- Translated relational schemas and mapped foreign data types to Spanner constructs
- Converted schemas and generated migration scripts with Spanner Migration Tool
- Ingested historical data in bulk and captured ongoing changes during migration
- Executed cutover workflows and validated zero-downtime transition strategies
- Performed an end-to-end relational database migration to Cloud Spanner

---

# Quiz 1 of 3

**Why is it strongly recommended to drop all secondary indexes prior to bulk loading historical data into Cloud Spanner, and re-create them only after data ingestion completes?**

- A. Cloud Spanner does not permit secondary indexes on tables with more than 1,000 rows
- B. Every secondary index converts each inserted row into additional write mutations, multiplying lock contention and causing severe split bottlenecking
- C. Creating secondary indexes before loading data causes Cloud Spanner to permanently reject subsequent primary key inserts
- D. Dataflow bulk import templates automatically delete existing secondary indexes during execution

---

# Quiz 1: Answer

**Why is it strongly recommended to drop all secondary indexes prior to bulk loading historical data into Cloud Spanner, and re-create them only after data ingestion completes?**

**Correct: B.** Every secondary index converts each inserted row into additional write mutations, multiplying lock contention and causing severe split bottlenecking

- Each secondary index requires a separate write mutation for every inserted row, rapidly exhausting transaction mutation limits
- Synchronous secondary index maintenance scatters writes across multiple splits, inducing distributed lock contention and latency spikes
- Creating secondary indexes post-load leverages Spanner’s asynchronous backfill engine, building indexes in the background without locking tables
- Dropping secondary indexes prior to bulk loading can improve ingestion throughput by 4x to 10x

---

# Quiz 2 of 3

**When migrating a relational database schema using the Spanner Migration Tool (SMT), why should an engineer refactor a sequential integer primary key (`AUTO_INCREMENT` or `SERIAL`) before loading production data?**

- A. Cloud Spanner only supports string data types for primary keys
- B. Sequential primary keys cause all consecutive write operations to target the exact same storage split and Paxos leader node, creating an unscalable write hotspot
- C. SMT will fail to generate valid SQL DDL if an integer column is designated as a primary key
- D. Monotonic integers consume 4 times more Colossus disk storage than UUIDs or bit-reversed sequences

---

# Quiz 2: Answer

**When migrating a relational database schema using the Spanner Migration Tool (SMT), why should an engineer refactor a sequential integer primary key (`AUTO_INCREMENT` or `SERIAL`) before loading production data?**

**Correct: B.** Sequential primary keys cause all consecutive write operations to target the exact same storage split and Paxos leader node, creating an unscalable write hotspot

- Cloud Spanner partitions table data lexicographically by primary key across distributed storage splits
- Monotonically increasing numbers always append to the end of the keyspace, concentrating all writes onto a single split and compute node
- Refactoring to bit-reversed sequences, UUIDv4, or hash-prefixed keys distributes successive inserts evenly across all splits and nodes
- Adding nodes to a Spanner instance will not alleviate write hotspots caused by sequential primary keys

---

<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
Your organization is migrating a high-volume mission-critical e-commerce database (1 TB storage, 8,000 write QPS peak) from MySQL to Cloud Spanner. Management mandates a zero-downtime cutover with zero tolerance for lost customer transactions and an immediate rollback capability.

### Discuss
- What data migration architecture would you design to achieve zero downtime during data loading?
- What steps must be executed during the cutover window to ensure data parity and prevent lost updates?
- How does reverse replication protect the business, and how would you implement it?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**Your organization is migrating a mission-critical 1 TB MySQL database to Spanner with zero-downtime and zero data loss mandates.**

### Strong Answers Mention
- Bulk export snapshot to Cloud Storage (Avro/CSV) and load via Cloud Dataflow while MySQL remains live
- Deploy Google Cloud Datastream CDC to continuously stream MySQL binlog changes to Spanner, draining lag to sub-second
- Validate data parity using parallel checksum queries and shadow reads prior to cutover
- Execute write cutover by briefly pausing source writes (< 30 seconds), draining CDC lag to zero, and redirecting application writes to Spanner
- Implement reverse replication using Spanner Change Streams and Dataflow replicating back to MySQL for 48 to 72 hours for safe rollback

### Watch For
- Proposing an offline dump-and-restore strategy that requires hours of maintenance downtime
- Omitting reverse replication, leaving the team with no rollback path once new writes land in Spanner
- Attempting to bulk load data with active secondary indexes and auto-increment keys
- Failing to verify replication lag before switching application write traffic

---

# Questions and Answers

Questions?
