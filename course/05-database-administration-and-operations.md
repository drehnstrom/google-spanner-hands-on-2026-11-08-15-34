<!-- course-title: Google Spanner: Hands-On -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Google Spanner: Hands-On

# Chapter 5: Database Administration and Operations

---

# Chapter 5: Objectives

- Monitor performance, configure autoscaling, and manage backup and recovery
- Adjust compute capacity dynamically using nodes and processing units
- Configure autoscaling policies to maintain performance and optimize costs
- Identify performance bottlenecks using Key Visualizer and Query Insights
- Implement least-privilege access with IAM and secure data at rest and in transit
- Protect data assets using on-demand backups and point-in-time recovery
- Monitor instance health, configure autoscaling, and execute backup workflows

---

<!-- layout: navigation -->
# Chapter 5

- **Managing Compute Capacity with Nodes and Processing Units**
- Configuring Cloud Spanner Autoscaling
- Monitoring Metrics, Key Visualizer, and Query Insights
- Identity and Access Management and Data Security
- Backups, Restores, and Point-in-Time Recovery
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

---

<!-- layout: 2-column -->
# Compute Architecture: Nodes and Processing Units

### Compute and Storage Decoupling
- Spanner separates stateless compute workers from distributed Colossus storage
- Adding or reducing compute completes in seconds without data migration or rebalancing
- Stateless compute nodes parse SQL, compile plans, coordinate Paxos, and manage lock tables
- Storage split locations are tracked in metadata, independent of worker nodes

### Units of Capacity
- Compute capacity is provisioned in either Nodes or Processing Units (PUs)
- Baseline equivalence: 1 Node equals exactly 1,000 Processing Units
- Fractional sizing: Provision in 100 PU increments (100, 200, up to 1,000 PUs)
- Linear throughput: Each 1,000 PUs delivers predictable, linear QPS and IOPS

<!-- below-columns -->

> [!NOTE]
> Processing Units allow development environments and low-volume microservices to run on enterprise-grade Spanner infrastructure for a fraction of the cost of a full node.

---

<!-- layout: card-layout -->
# Sizing Compute and Enforcing Storage Limits

### Storage Footprint Limits
- Each 1,000 PUs (1 node) supports up to 4 TB of storage (400 GB per 100 PUs).
- Spanner enforces hard minimum compute limits based on stored data volume.
- An instance hosting 6 TB of data requires a minimum of 2,000 PUs (2 nodes).

### Target CPU Thresholds
- Target 65% maximum high-priority CPU utilization for regional instances.
- Target 45% maximum high-priority CPU utilization for multi-region instances.
- Reserve headroom absorbs automatic failover traffic without cascading brownouts.

### Throughput Baselines
- 1,000 PUs typically delivers up to 10,000 read QPS or 2,000 single-row write QPS.
- Secondary indexes, large transaction mutations, and complex joins reduce QPS.
- Always benchmark capacity using representative production query plans.

---

# Scaling Compute Capacity Dynamically

- Scaling compute in Cloud Spanner is non-blocking and executes with zero application downtime
- Adjust capacity dynamically using the Google Cloud CLI or infrastructure-as-code tooling

```bash
# Scale an existing instance up to 2,000 processing units (2 nodes)
gcloud spanner instances update production-instance \
    --processing-units=2000

# Inspect updated capacity and verify instance state
gcloud spanner instances describe production-instance \
    --format="yaml(name,nodeCount,processingUnits,state)"
```

```hcl
# Manage compute capacity declaratively with Terraform
resource "google_spanner_instance" "main" {
  name             = "production-instance"
  config           = "regional-us-central1"
  display_name     = "Production Spanner"
  processing_units = 2000
}
```

> [!TIP]
> Capacity modifications take effect immediately without dropping existing TCP connections, resetting session pools, or terminating active transactions.

---

<!-- layout: 2-column -->
# Failure Mode: Compute Under-Provisioning and Storage Saturation

### The Capacity Traps
- **CPU Saturation**: High-priority CPU exceeds 85%, creating request queues and timeouts.
- **Storage Downscale Rejection**: Downscaling an instance holding 5 TB to 1 node (1,000 PUs) fails with quota errors.
- **Background Starvation**: Low-priority tasks (compactions, index builds, stats collection) pause when CPU is maxed.

### Operational Cascade
- Client applications observe latency spikes and receive `DeadlineExceeded` exceptions.
- Client retries flood the already saturated cluster, deepening the outage.
- Operators attempting emergency downscaling to cut costs find themselves locked by storage rules.

<!-- below-columns -->

> [!WARNING]
> Never attempt to downscale compute below the 4 TB per 1,000 PU threshold. Always check total instance storage consumption before lowering processing units.

---

<!-- layout: navigation -->
# Chapter 5

- Managing Compute Capacity with Nodes and Processing Units
- **Configuring Cloud Spanner Autoscaling**
- Monitoring Metrics, Key Visualizer, and Query Insights
- Identity and Access Management and Data Security
- Backups, Restores, and Point-in-Time Recovery
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

---

<!-- layout: card-layout -->
# Native Cloud Spanner Autoscaling Architecture

### Built-In Managed Engine
- Managed directly by the Cloud Spanner control plane with zero external infrastructure.
- Replaces legacy custom cron scripts, Cloud Run scalers, and Cloud Functions.
- Eliminates maintenance overhead and external service failure points.

### Dual Metric Evaluation
- Automatically monitors both High-Priority CPU utilization and Storage utilization.
- Triggers scale-out events if either metric breaches its configured target threshold.
- Protects workloads from compute saturation and storage exhaustion simultaneously.

### Asymmetric Scaling Dynamics
- Scale-up events respond rapidly to protect application latency and SLAs.
- Scale-down events enforce safety dampening and cooldowns to prevent thrashing.
- Smoothly rebalances capacity across cluster nodes without sudden drop-offs.

---

# Configuring Autoscaler Policies

- Define minimum and maximum capacity bounds alongside target metric thresholds
- Configure policies using `gcloud` to enforce automated, hands-off elasticity

```bash
# Configure autoscaling with processing unit boundaries and CPU targets
gcloud spanner instances update production-instance \
    --autoscaling-min-processing-units=1000 \
    --autoscaling-max-processing-units=5000 \
    --autoscaling-high-priority-cpu-target=65 \
    --autoscaling-storage-target=75

# Inspect autoscaling status, current targets, and recommendations
gcloud spanner instances describe production-instance \
    --format="yaml(autoscalingConfig)"
```

> [!IMPORTANT]
> The recommended high-priority CPU target is 65% for regional instances and 45% for multi-region instances. Exceeding these targets compromises failover safety.

---

<!-- layout: 2-column -->
# Scale-Up vs Scale-Down Mechanics

### Scale-Up Dynamics
- Evaluated continuously every few minutes against rolling metric windows
- Rapidly allocates additional processing units when high-priority CPU spikes
- Accommodates organic traffic increases, mid-day transaction surges, and batch runs
- Cannot react instantly to sub-minute step-function spikes (such as flash sales)

### Scale-Down Dynamics
- Governed by conservative cooldown periods (typically 30 to 60 minutes)
- Prevents flapping where compute scales down only to spike and scale up moments later
- Allows background storage compactions and split rebalances to stabilize first
- Never scales capacity below the hard threshold required for stored data volume

<!-- below-columns -->

> [!TIP]
> For anticipated massive traffic events (such as Black Friday or a product launch), pre-scale manually or raise `--autoscaling-min-processing-units` 1 to 2 hours in advance.

---

<!-- layout: 2-column -->
# Failure Mode: Aggressive Targets and Insufficient Headroom

### The 85% Target Anti-Pattern
- Operator sets high-priority CPU target to 85% on a multi-region instance to save budget
- In normal operations, CPU hovers around 80% to 85% across all regional replicas
- When an entire Google Cloud region experiences an outage, traffic shifts to surviving regions
- Surviving regions instantly jump from 85% CPU to 130% capacity and crash!

### Multi-Region Headroom Rule
- Multi-region Spanner configurations require at least 55% reserve headroom
- Target CPU must remain at or below 45% to survive complete regional loss
- Autoscaler cannot provision new nodes quickly enough if existing capacity collapses
- Cost savings on reserve capacity directly compromise nine-fives (99.999%) availability

<!-- below-columns -->

> [!CAUTION]
> Never set multi-region autoscaling CPU targets above 45%. The reserve capacity is an insurance policy that guarantees zero-downtime regional failover.

---

<!-- layout: navigation -->
# Chapter 5

- Managing Compute Capacity with Nodes and Processing Units
- Configuring Cloud Spanner Autoscaling
- **Monitoring Metrics, Key Visualizer, and Query Insights**
- Identity and Access Management and Data Security
- Backups, Restores, and Point-in-Time Recovery
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

---

<!-- layout: card-layout -->
# Core Health Metrics in Cloud Monitoring

### High-Priority CPU Utilization
- Quantifies CPU consumed by user queries, mutations, and active transactions.
- Primary operational health metric; alerts should trigger if usage sustains above 65%.
- Spanner prioritizes user operations over background compactions and index builds.

### Frontend and Backend Latency
- Frontend Latency measures round-trip time between client SDK and Spanner API boundary.
- Backend Latency measures time Spanner worker nodes spend executing the operation.
- A wide gap indicates network transit latency, TLS handshakes, or client queuing.

### Lock Wait Time and Aborts
- Measures time transactions spend waiting to acquire row or range locks.
- Sustained lock wait times indicate concurrent write contention on identical keys.
- Correlates with client retry rates and transaction `Aborted` exceptions.

---

# Diagnosing Bottlenecks with Key Visualizer

- Key Visualizer generates interactive diagnostic heatmaps of database traffic over time
- X-axis represents time; Y-axis represents the primary key space ordered lexicographically
- Brightness indicates metric intensity (CPU utilization, read/write ops, and bytes scanned)
- Dark regions reflect idle key ranges, while bright bands expose concentrated load

<!-- TODO IMAGE: Screenshot of Spanner Key Visualizer heatmap showing hotspotting as a bright horizontal stripe -->
![Key Visualizer Heatmap](images/ch05-key-visualizer-heatmap.png)

---

<!-- layout: 3-column -->
# Key Visualizer Diagnostic Patterns

### Bright Horizontal Line
- **Pattern**: Narrow, persistent horizontal stripe
- **Diagnosis**: Severe key hotspotting
- **Cause**: Sequential IDs or timestamps overloading a single split
- **Fix**: Apply hash prefixes, bit-reversal, or UUIDv4 keys

### Diagonal Band
- **Pattern**: Bright diagonal streak moving over time
- **Diagnosis**: Monotonic sequential key scan
- **Cause**: Batch insertion or sequential range table scan
- **Fix**: Use parallel partition queries or interleaved keys

### Diffuse, Even Glow
- **Pattern**: Soft, uniform shading across key ranges
- **Diagnosis**: Well-balanced distributed workload
- **Cause**: Uniformly distributed primary keys across splits
- **Fix**: Target state for healthy production databases

---

# Query Insights and System Statistics Tables

- Spanner exposes real-time and historical performance statistics in the `SPANNER_SYS` schema
- Query top resource-consuming statements, lock conflicts, and transaction aborts directly with SQL

```sql
-- Identify the top queries by total CPU consumption over the last hour
SELECT
  text,
  execution_count,
  avg_latency_seconds,
  cpu_time_seconds,
  avg_rows
FROM SPANNER_SYS.QUERY_STATS_TOP_HOUR
ORDER BY cpu_time_seconds DESC
LIMIT 5;

-- Identify tables and columns experiencing the highest lock contention
SELECT
  lock_mode,
  column_name,
  sample_transaction_tag,
  total_wait_time_ms
FROM SPANNER_SYS.LOCK_STATS_TOP_MINUTE
ORDER BY total_wait_time_ms DESC
LIMIT 5;
```

> [!TIP]
> Include transaction tags (such as `tag="checkout_v2"`) in your application queries; tags surface directly in `SPANNER_SYS` views and Query Insights dashboards for immediate attribution.

---

<!-- layout: 2-column -->
# Failure Mode: Misdiagnosing Split Hotspots as Capacity Deficits

### The False Diagnosis
- Cloud Monitoring reports overall instance CPU utilization at a healthy 20%
- Client applications report p99 write latency jumping from 8 ms to 2,000 ms
- Engineers assume Spanner is under-provisioned and scale from 3 nodes to 15 nodes
- Scaling costs increase fivefold, but query latency does not improve at all!

### The Hotspot Reality
- Primary key is `OrderDate` or an auto-increment sequence; all writes hit one split
- A single Spanner node hosts the Paxos leader for that split and runs at 100% CPU
- The remaining 14 nodes sit completely idle, unable to assist the overloaded leader
- Adding nodes does not rebalance a single hotspot split; schema redesign is required

<!-- below-columns -->

> [!CAUTION]
> Cluster-wide average CPU masks single-node split saturation. Always inspect Key Visualizer before scaling compute nodes in response to unexpected latency spikes.

---

<!-- layout: navigation -->
# Chapter 5

- Managing Compute Capacity with Nodes and Processing Units
- Configuring Cloud Spanner Autoscaling
- Monitoring Metrics, Key Visualizer, and Query Insights
- **Identity and Access Management and Data Security**
- Backups, Restores, and Point-in-Time Recovery
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

---

<!-- layout: card-layout -->
# Cloud Spanner Predefined IAM Roles

### Administrative Roles
- `roles/spanner.admin`: Full control over instances, databases, backups, and IAM policies.
- `roles/spanner.databaseAdmin`: Create and drop databases, alter schemas, and manage backups.
- Restricted strictly to infrastructure CI/CD pipelines and senior platform engineers.

### Application Data Roles
- `roles/spanner.databaseUser`: Execute read-write queries, DML, mutations, and transactions.
- `roles/spanner.databaseReader`: Execute read-only queries and historical snapshots without write access.
- Assigned to application service accounts adhering strictly to the principle of least privilege.

### Operational Roles
- `roles/spanner.viewer`: View instance configurations, database state, and Cloud Monitoring metrics.
- `roles/spanner.backupAdmin`: Create, copy, restore, and delete Spanner database backups.
- Assigned to on-call support personnel, security compliance auditors, and backup jobs.

---

<!-- layout: 2-column -->
# Fine-Grained Access Control (FGAC)

### Database Roles and Privileges
- Spanner supports native database roles for fine-grained authorization
- Define custom roles directly in database DDL (`CREATE ROLE billing_reader`)
- Grant table-level, column-level, or row-level permissions to specific roles
- Restrict sensitive fields (such as credit card numbers, tax IDs, or salaries)

### IAM and Database Role Binding
- External IAM principals cannot assume database roles without explicit IAM grants
- Assign `roles/spanner.fineGrainedAccessUser` to service accounts on the database
- Bind principals to specific database roles using IAM Conditions
- Client SDK passes the targeted database role when creating sessions

<!-- below-columns -->

> [!IMPORTANT]
> Fine-Grained Access Control enables multiple microservices or tenants to share a single Spanner database safely without exposing sensitive columns across services.

---

# Configuring Fine-Grained Access Control in DDL

- Define database roles in SQL DDL and bind service accounts via IAM conditions
- Ensure application components access only the exact columns required for their function

```sql
-- Step 1: Create a specialized database role for the billing service
CREATE ROLE billing_service;

-- Step 2: Grant table-level read access on customer profile metadata
GRANT SELECT ON TABLE Customers TO ROLE billing_service;

-- Step 3: Grant column-level read access on orders, excluding sensitive tokens
GRANT SELECT (OrderId, CustomerId, OrderTotal, OrderStatus) ON TABLE Orders TO ROLE billing_service;

-- Step 4: Grant write privileges strictly on invoices
GRANT INSERT, UPDATE ON TABLE Invoices TO ROLE billing_service;
```

```bash
# Step 5: Authorize application service account to assume the billing_service role
gcloud spanner databases add-iam-policy-binding orders-db \
    --instance=production-instance \
    --member="serviceAccount:billing-app@my-proj.iam.gserviceaccount.com" \
    --role="roles/spanner.fineGrainedAccessUser" \
    --condition="expression=resource.name.endsWith('/databaseRoles/billing_service'),title=billing_role_binding"
```

---

<!-- layout: card-layout -->
# Data Security and Encryption Architectures

### Google-Managed Encryption
- Default encryption at rest applied automatically using Google-managed AES-256 keys.
- All internal network traffic and inter-replica communication encrypted with TLS.
- Incurs zero operational configuration, licensing, or key management overhead.

### Customer-Managed Keys (CMEK)
- Integrates with Cloud Key Management Service (Cloud KMS) for compliance mandates.
- Provides customer ownership of cryptographic keys, key rotation, and instant revocation.
- Uses envelope encryption; database data encryption keys are wrapped by KMS keys.

### Multi-Region CMEK Requirements
- Multi-region instances require KMS keys created in matching regional locations.
- Disabling or revoking a KMS key renders all database data inaccessible within minutes.
- Requires robust key rotation policies and cross-region key backup procedures.

---

<!-- layout: 2-column -->
# Failure Mode: Over-Privileged Application Service Accounts

### The Shortcut
- Developer assigns `roles/spanner.databaseAdmin` to an application microservice
- Justification: “It prevents permission errors during migrations and integration testing”
- The application identity now possesses full administrative authority over the database schema

### The Disaster
- An unvalidated ORM migration script or compromised API endpoint executes `DROP TABLE Customers`
- Spanner processes the valid DDL command immediately and drops the entire table
- The microservice identity can also create unauthorized backups or delete existing backup archives
- A minor application code defect transforms into a catastrophic data loss incident

<!-- below-columns -->

> [!CAUTION]
> Never assign `databaseAdmin` to runtime application identities. Applications should only receive `databaseUser` or targeted fine-grained database roles with zero schema alteration privileges.

---

<!-- layout: navigation -->
# Chapter 5

- Managing Compute Capacity with Nodes and Processing Units
- Configuring Cloud Spanner Autoscaling
- Monitoring Metrics, Key Visualizer, and Query Insights
- Identity and Access Management and Data Security
- **Backups, Restores, and Point-in-Time Recovery**
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

---

<!-- layout: 2-column -->
# Data Protection Strategies: Backups vs PITR

### Cloud Spanner Backups
- Complete, consistent snapshots of database schema and table data
- Captured asynchronously from storage splits with zero impact on live transactions
- Stored independently of the database with retention policies from 6 hours to 1 year
- Incremental and copy backup features optimize storage costs and multi-region replication
- Primary use case: Disaster recovery and long-term regulatory compliance

### Point-in-Time Recovery (PITR)
- Continuous microsecond-granularity version protection built into the storage engine
- Governed by `version_retention_period` (configurable from 1 hour up to 7 days)
- Retains multi-version concurrency control (MVCC) tombstones and historical row versions
- Enables surgical historical queries and recovery without creating new databases
- Primary use case: Rapid recovery from accidental data corruption or bad application logic

<!-- below-columns -->

> [!NOTE]
> Backups and PITR are complementary. PITR protects against immediate human and code errors; backups protect against catastrophic disaster events and long-term compliance mandates.

---

# Managing On-Demand and Scheduled Backups

- Trigger consistent on-demand backups or automate recurring schedules using `gcloud`
- Backups execute asynchronously without taking read locks or slowing transaction throughput

```bash
# Create an on-demand consistent backup retaining data for 14 days
gcloud spanner backups create orders-db-backup-20250501 \
    --instance=production-instance \
    --database=orders-db \
    --retention-period=14d \
    --async

# Create an automated daily backup schedule retaining backups for 30 days
gcloud spanner backup-schedules create daily-orders-backup \
    --instance=production-instance \
    --database=orders-db \
    --cron="0 2 * * *" \
    --retention-duration=30d
```

> [!TIP]
> Spanner supports Copy Backup across instances and regions, allowing disaster recovery backups to be replicated to secondary Google Cloud regions.

---

<!-- layout: 2-column -->
# Restoring a Database from Backup

### Restore Mechanics
- Restoring a backup always creates a **brand new database**; it cannot overwrite an existing database
- The destination database ID must be unique within the target Spanner instance
- Can restore into the original instance or an alternative instance with compatible topology
- The newly restored database becomes available for queries immediately while storage populates

### Production Cutover Steps
- **Step 1**: Initiate restore command via `gcloud spanner databases restore`
- **Step 2**: Recreate database IAM bindings, fine-grained access roles, and database flags
- **Step 3**: Re-establish client service connections by updating environment variables or Secret Manager
- **Step 4**: Decommission the corrupted database once cutover verification completes

<!-- below-columns -->

> [!IMPORTANT]
> Because restores create a new database entity, design client applications with configurable database connection strings (such as environment variables) to simplify cutover redirection.

---

# Point-in-Time Recovery (PITR) Workflows

- Configure `version_retention_period` to enable historical queries up to 7 days in the past
- Surgically inspect and recover corrupted rows directly within the live database

```sql
-- Step 1: Extend database version retention period to maximum (7 days)
ALTER DATABASE orders_db
SET OPTIONS (version_retention_period = '7d');

-- Step 2: Query historical state from 20 minutes ago before an accidental deletion
SELECT CustomerId, OrderId, OrderTotal
FROM Orders {FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 20 MINUTE)}
WHERE OrderStatus = 'PENDING';

-- Step 3: Surgically re-insert corrupted rows directly into the active table
INSERT INTO Orders (OrderId, CustomerId, OrderTotal, OrderStatus)
SELECT OrderId, CustomerId, OrderTotal, OrderStatus
FROM Orders {FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 20 MINUTE)}
WHERE OrderId = 'O-9912';
```

> [!TIP]
> PITR historical queries restore lost data in seconds, completely avoiding the hours of downtime required for full database restoration and DNS cutovers.

---

<!-- layout: 2-column -->
# Failure Mode: The 1-Hour PITR Default Window

### The Default Configuration Trap
- Team deploys a production Spanner database with default engine settings
- Default `version_retention_period` is **1 hour**
- On Friday at 7:00 PM, an erroneous script updates 50,000 customer accounts with invalid data
- The on-call engineering team discovers the data corruption Monday morning at 8:00 AM

### The Recovery Impasse
- Running `FOR SYSTEM_TIME AS OF` fails with: `Out of version retention period`
- Spanner background compactions have permanently purged historical MVCC row versions
- The team must execute a full database restore from Thursday night’s backup
- All valid customer transactions processed over Friday, Saturday, and Sunday are lost!

<!-- below-columns -->

> [!CAUTION]
> Always increase `version_retention_period` to `7d` on production databases immediately after creation. The incremental storage cost for MVCC tombstones is trivial compared to data loss risk.

---

<!-- layout: navigation -->
# Chapter 5

- Managing Compute Capacity with Nodes and Processing Units
- Configuring Cloud Spanner Autoscaling
- Monitoring Metrics, Key Visualizer, and Query Insights
- Identity and Access Management and Data Security
- Backups, Restores, and Point-in-Time Recovery
- **Lab: Monitoring, Scaling, and Backing Up a Spanner Database**

---

# Lab: Monitoring, Scaling, and Backing Up a Spanner Database

Lab link: TODO

---

# What You Learned

- Monitored performance, configured autoscaling, and managed backup and recovery
- Adjusted compute capacity dynamically using nodes and processing units
- Configured autoscaling policies to maintain performance and optimize costs
- Identified performance bottlenecks using Key Visualizer and Query Insights
- Implemented least-privilege access with IAM and secured data at rest and in transit
- Protected data assets using on-demand backups and point-in-time recovery
- Monitored instance health, configured autoscaling, and executed backup workflows

---

# Quiz 1 of 3

**Why is it critical to configure the Cloud Spanner Autoscaler high-priority CPU target to no higher than 45% for multi-region instances, whereas 65% is recommended for regional instances?**

- A. Multi-region instances run on slower hardware cores that cannot sustain more than 45% CPU utilization
- B. The 55% reserve headroom is required to absorb failover traffic and cross-region Paxos coordination if an entire region becomes unavailable
- C. Google Cloud limits billing SLA credits on multi-region instances if high-priority CPU exceeds 45%
- D. Autoscaling in multi-region instances takes 24 hours to provision additional compute nodes

---

# Quiz 1: Answer

**Why is it critical to configure the Cloud Spanner Autoscaler high-priority CPU target to no higher than 45% for multi-region instances, whereas 65% is recommended for regional instances?**

**Correct: B.** The 55% reserve headroom is required to absorb failover traffic and cross-region Paxos coordination if an entire region becomes unavailable

- Multi-region Spanner topologies distribute data across multiple geographic regions with Paxos quorums
- If an entire region experiences an outage, surviving regions must absorb all read and write traffic immediately
- Running above 45% in multi-region leaves inadequate headroom during regional failover, triggering cascading CPU saturation
- Regional instances only need to absorb single-zone failover, allowing a higher target threshold of 65%

---

# Quiz 2 of 3

**An operations team notices that 99th percentile write latency has spiked to 2 seconds, but the Cloud Spanner instance overall CPU utilization is only 18%. When inspecting Key Visualizer, they observe a single, persistent bright horizontal line across the heatmap. What is the root cause?**

- A. The instance has exceeded its storage quota and requires additional processing units
- B. A severe key hotspot is overloading a single node split, while the remaining cluster nodes sit idle
- C. Cloud Spanner has automatically throttled the instance due to excessive backup frequency
- D. A multi-region failover event has redirected all client traffic to an offline witness replica

---

# Quiz 2: Answer

**An operations team notices that 99th percentile write latency has spiked to 2 seconds, but the Cloud Spanner instance overall CPU utilization is only 18%. When inspecting Key Visualizer, they observe a single, persistent bright horizontal line across the heatmap. What is the root cause?**

**Correct: B.** A severe key hotspot is overloading a single node split, while the remaining cluster nodes sit idle

- Key Visualizer maps time on the X-axis and primary key splits on the Y-axis
- A bright horizontal line represents intense, concentrated traffic directed at a single narrow key range or split
- The node hosting the Paxos leader for that specific split reaches 100% CPU, while other cluster nodes sit idle
- Adding more nodes will not resolve this bottleneck; the schema primary key must be modified (such as hash prefixing or UUIDs)

---

<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
A developer accidentally executed an unconstrained `UPDATE Orders SET Status = 'CANCELLED'` in production without a `WHERE` clause. The incident was detected 30 minutes after execution. The database has `version_retention_period` configured to `7d`, and a full backup was taken 12 hours ago.

### Discuss
- Should the team restore the database from the 12-hour-old backup or use Point-in-Time Recovery (PITR)? Why?
- How should the team surgically reconstruct the corrupted rows without dropping new valid orders?
- What database permissions and guardrails should be put in place to prevent similar incidents in the future?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**A developer accidentally executed an unconstrained UPDATE in production 30 minutes ago on a database with 7-day PITR.**

### Strong Answers Mention
- Use PITR (`FOR SYSTEM_TIME AS OF`) rather than restoring the 12-hour-old backup
- Restoring from backup creates a new database and loses all valid transactions from the last 12 hours
- PITR allows querying table state at TrueTime `CURRENT_TIMESTAMP() - 35 MINUTES` directly in the live database
- Surgical recovery: update only the affected rows from the historical snapshot using SQL DML
- Guardrails: Implement Fine-Grained Access Control (FGAC), revoke `databaseAdmin` and direct DML permissions from interactive user accounts, and enforce code reviews for manual queries

### Watch For
- Proposing a full database restore from backup when PITR retention is active
- Assuming PITR requires provisioning a separate instance and rewriting application connection strings
- Believing Spanner has an interactive transaction rollback command after commit

---

# Questions and Answers

Questions?
