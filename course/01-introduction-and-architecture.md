<!-- course-title: Google Spanner: Hands-On -->
<!-- course-theme: roi-alt-theme -->

<!-- layout: title -->
![ROI Logo](images/roi-logo-with-name.png)

Google Spanner: Hands-On

# Chapter 1: Introduction to Google Cloud Spanner and Architecture

---

# Chapter 1: Objectives

- Evaluate Spanner architecture and provision regional or multi-region database instances
- Explain core concepts and features of Google Cloud Spanner
- Describe how TrueTime, Paxos, and distributed storage ensure external consistency
- Compare Spanner capabilities with traditional relational databases and NoSQL systems
- Select appropriate regional and multi-region deployment configurations
- Size instances using node counts and processing units
- Provision and configure a Cloud Spanner instance and database in Google Cloud

---

<!-- layout: navigation -->
# Chapter 1

- **Cloud Spanner Overview and Core Concepts**
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- Comparing Spanner with Traditional RDBMS and NoSQL
- Regional and Multi-Region Deployment Options
- Instance Topologies, Nodes, and Processing Units
- Lab: Creating and Configuring a Spanner Instance and Database

---

# What is Google Cloud Spanner?

- Fully managed, mission-critical relational database service designed for unbounded horizontal scale
- Combines standard SQL and ACID transactions with automatic global sharding and replication
- Guarantees external consistency (the strongest consistency model) across rows, regions, and continents
- Eliminates manual administrative overhead through automatic resharding, replication, and failover

> [!NOTE]
> Google developed Spanner internally in 2012 to power critical global infrastructure including Google Ads, Google Play, and Gmail.

---

<!-- layout: card-layout -->
# Core Capabilities and Guarantees

### Relational Rigor
- Enforces relational schemas, strong data types, primary keys, and secondary indexes.
- Provides standard ANSI SQL query execution with rich optimizer support.

### Global ACID Scale
- Executes distributed read-write transactions across tables and regions transparently.
- Eliminates application-level sharding logic and complex multi-phase commit management.

### Unmatched Availability
- Delivers up to a 99.999% availability SLA for multi-region configurations.
- Survives zone and entire region outages with zero data loss and automated failover.

---

<!-- layout: 2-column -->
# The Spanner Resource Hierarchy

### Administrative Hierarchy
- **Google Cloud Project**: Identity boundary, API enablement, and billing container
- **Instance Configuration**: Regional or multi-region topology defining replica locations
- **Instance**: Dedicated compute capacity allocation measured in Processing Units or nodes
- **Database**: Relational container hosting tables, views, and dialect configuration

### Storage and Data Structure
- **Database Dialect**: GoogleSQL or PostgreSQL syntax selected at database creation
- **Tables and Interleaving**: Relational structures defining data locality
- **Splits**: Dynamic, contiguous ranges of rows partitioned by primary key
- **Colossus**: Underneath compute, Google’s distributed file system persists all data

<!-- below-columns -->

> [!IMPORTANT]
> Billing reflects allocated compute capacity (Processing Units) and storage consumed, regardless of how many individual databases exist in the instance.

---

<!-- layout: 2-column -->
# Resolving the Traditional CAP Dilemma

### The Classical CAP Dilemma
- Eric Brewer’s CAP theorem states distributed systems can guarantee only two of Consistency, Availability, and Partition tolerance.
- Traditional NoSQL chose AP: high availability with eventual consistency and weak isolation.
- Traditional clustered RDBMS chose CP: strict consistency restricted to a single primary write node.

### The Spanner Operational Reality
- Spanner is technically a CP system under formal definitions, prioritizing consistency during partitions.
- Google’s private fiber-optic network infrastructure makes network partitions vanishingly rare in practice.
- Paxos quorums maintain continuous read and write availability even during physical server or zone failures.

---

# Pitfall: Single-Server Relational Habits

- Monotonically increasing primary keys (like auto-increment integers) create severe write hotspots
  - All sequential inserts route to the exact same split, overwhelming one server
  - Solution: Use universally unique identifiers (UUIDv4) or bit-reversed keys to distribute writes
- Monolithic batch mutations lock excessive key ranges and degrade Paxos throughput
  - Running unbounded updates in one transaction exhausts memory and blocks concurrent operations
  - Solution: Batch writes into partitioned, bounded chunks under 4,000 mutations
- Unindexed cross-split joins saturate inter-node network bandwidth and spike query latency
  - Distributed queries across unaligned tables force massive data movement between compute nodes
  - Solution: Co-locate related child data using Spanner table interleaving

---

<!-- layout: navigation -->
# Chapter 1

- Cloud Spanner Overview and Core Concepts
- **Spanner Architecture: TrueTime, Paxos, and Distributed Storage**
- Comparing Spanner with Traditional RDBMS and NoSQL
- Regional and Multi-Region Deployment Options
- Instance Topologies, Nodes, and Processing Units
- Lab: Creating and Configuring a Spanner Instance and Database

---

<!-- layout: 2-column -->
# Compute and Storage Disaggregation

### Stateless Compute Layer
- Spanner compute servers execute query optimization, transaction routing, and lock management.
- Nodes hold no persistent data on local disks, keeping compute entirely stateless.
- Instances can scale compute up or down in minutes without data rebalancing.

### Colossus Storage Layer
- Google’s global distributed file system stores all data blocks redundantly across disks.
- Write operations commit durable write-ahead log records directly to Colossus.
- If a compute node fails, an alternate node immediately assumes ownership of its splits.

<!-- below-columns -->

> [!NOTE]
> Decoupling compute from storage allows Spanner to split, merge, and migrate key ranges in milliseconds without physical data movement.

---

<!-- layout: card-layout -->
# Splits and Paxos Groups

### Dynamic Table Splits
- Tables are partitioned into ordered, contiguous primary key ranges called splits.
- Spanner automatically subdivides a split when it approaches 4 GB or detects concentrated CPU load.

### Independent Paxos Groups
- Every split is managed by an independent Paxos consensus group spanning multiple zones or regions.
- A write requires consensus from a majority quorum of Paxos replicas, never waiting for all replicas.

### Seamless Split Rebalancing
- Splits migrate between compute nodes dynamically to distribute CPU load and eliminate hotspots.
- Split movements update in-memory routing tables without blocking active client transactions.

---

# TrueTime: Hardware-Bound Clock Uncertainty

- Physical server clocks inevitably drift due to temperature fluctuations and oscillator variations
- TrueTime API replaces naive clock timestamps with an explicit time interval: `[earliest, latest]`
  - The real current time is guaranteed to fall inside the returned interval: `now() ± ε`
  - Uncertainty `ε` (epsilon) typically ranges between 1 and 7 milliseconds across Google data centers
- Google deploys atomic clocks and GPS receivers in every data center cluster
  - Atomic clocks have no shared failure modes with GPS antennae, ensuring continuous reference checks
  - Fail-safe design rejects drifting clocks before they pollute the TrueTime consensus

> [!IMPORTANT]
> Standard NTP over the public internet exhibits clock drift ranging from 50 to 500+ milliseconds, making global timestamp ordering impossible.

---

<!-- layout: 2-column -->
# External Consistency and Commit Wait

### Linearizability and Causality
- External consistency guarantees that if transaction T2 begins after transaction T1 commits, T2 receives a higher timestamp.
- Every client worldwide observes transactions in true real-time causal order.
- Eliminates stale reads without requiring cross-region synchronization on read paths.

### The Commit-Wait Rule
- The transaction coordinator picks a commit timestamp `s` equal to `TrueTime.now().latest`.
- The coordinator deliberately holds locks until `TrueTime.now().earliest > s` before returning success.
- Waiting out `2 * ε` ensures no subsequent transaction anywhere in the world can obtain an earlier timestamp.

<!-- below-columns -->

> [!TIP]
> Because commit wait runs concurrently with Paxos logging round trips, low-latency networks frequently absorb the wait without added overhead.

---

<!-- layout: 3-column -->
# Concurrency and Transaction Coordination

### Single-Split Writes
- Contained within one Paxos group
- Leader acquires two-phase locks (2PL)
- Replicates log to Paxos quorum
- Commits without two-phase commit overhead

### Multi-Split Writes
- Coordinates across multiple Paxos groups
- Uses Two-Phase Commit (2PC) protocol
- Paxos leaders act as 2PC participants
- Avoids single-point-of-failure bottlenecks

### Lock-Free Reads
- Reads at a historical timestamp require no locks
- Served directly by the nearest Paxos replica
- Read-only queries never block incoming writes
- Immune to deadlocks and read lock contention

---

# Failure Mode: Clock Drift and Uncertainty Spikes

- When GPS or reference hardware degrades, clock uncertainty `ε` expands dynamically
- Spanner enforces safety over speed by extending the commit-wait duration proportionally
  - If `ε` spikes from 2 ms to 50 ms, commit wait expands to 100 ms to guarantee external consistency
  - Write latency rises visibly across the cluster while operations wait out the uncertainty window
  - Correctness is never compromised: transactions never commit out of causal order
- Contrast with traditional databases relying on unsynchronized local clocks:
  - NTP drift causes silent data corruption, lost updates, or out-of-order replication logs
  - Distributed read-after-write anomalies appear without warning in standard primary-replica setups

---

<!-- layout: navigation -->
# Chapter 1

- Cloud Spanner Overview and Core Concepts
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- **Comparing Spanner with Traditional RDBMS and NoSQL**
- Regional and Multi-Region Deployment Options
- Instance Topologies, Nodes, and Processing Units
- Lab: Creating and Configuring a Spanner Instance and Database

---

<!-- layout: 3-column -->
# Comparing Database Paradigms

### Traditional RDBMS
- Single primary write node
- Read replicas suffer replication lag
- Strict ACID on single node
- Manual application-tier sharding
- Operational limits around 10 TB

### Distributed NoSQL
- Horizontal scale across clusters
- Eventual consistency or partition locks
- Key-value or document query models
- No multi-table relational joins
- Application handles referential integrity

### Cloud Spanner
- Horizontal scale across regions
- Global external consistency
- Standard ANSI SQL and rich joins
- Multi-row, multi-table ACID
- Fully automated sharding and failover

---

# Architectural Comparison Matrix

| Architectural Dimension | Traditional RDBMS (PostgreSQL / MySQL) | Distributed NoSQL (Cassandra / DynamoDB) | Google Cloud Spanner |
| :--- | :--- | :--- | :--- |
| **Horizontal Write Scale** | No (vertical primary scaling only) | Yes (partitioned key hashing) | Yes (transparent primary key splits) |
| **Consistency Guarantee** | Strict serializability (single node) | Eventual or single-partition ACID | Global external consistency (linearizable) |
| **Multi-Table Transactions** | Fully supported on single instance | Rare, constrained, or unsupported | Full multi-table, multi-split ACID |
| **Secondary Indexes** | Synchronous and strongly consistent | Often asynchronous or local-only | Synchronous and globally consistent |
| **Availability SLA** | Up to 99.95% (failover downtime) | Up to 99.99% | Up to 99.999% (multi-region) |
| **Schema Modifications** | Locks tables or blocks writes | Flexible, schema-free JSON/documents | Online, non-blocking schema updates |

---

<!-- layout: card-layout -->
# Ideal Workloads for Spanner

### Global Financial Services
- Demands zero data loss, exact multi-currency balancing, and real-time transaction ordering.
- Cryptographic-grade causal commit timestamps provide an auditable global ledger out of the box.

### Scale-Out Relational Apps
- Replaces complex application-level database sharding layers and brittle cross-shard aggregation code.
- Allows existing engineering teams to leverage SQL expertise while scaling without hardware ceilings.

### Always-On Global Platforms
- Powers retail, gaming, and telecom platforms requiring continuous 99.999% uptime.
- Endures localized disasters and maintenance windows without application connection resets.

---

<!-- layout: 2-column -->
# When NOT to Choose Cloud Spanner

### Modest Single-Node Workloads
- Databases under 1 TB with modest QPS are served more cost-effectively by Cloud SQL.
- A single-node PostgreSQL or MySQL instance costs a fraction of a Spanner deployment.
- Avoid deploying Spanner when data fits easily on one database server without scaling pressure.

### Sub-Millisecond Latency Demands
- Paxos consensus across multi-zone networks incurs physical fiber round trips (typically 5 - 10 ms).
- Write paths requiring microsecond latency require in-memory tiers like Memorystore or Redis.
- High-volume, unstructured append-only streaming data is better suited for Bigtable or BigQuery.

<!-- below-columns -->

> [!CAUTION]
> Do not treat Cloud Spanner as a high-throughput key-value logging cache. Running simple append streams through Spanner wastes compute budget on unnecessary transactional consensus.

---

<!-- layout: navigation -->
# Chapter 1

- Cloud Spanner Overview and Core Concepts
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- Comparing Spanner with Traditional RDBMS and NoSQL
- **Regional and Multi-Region Deployment Options**
- Instance Topologies, Nodes, and Processing Units
- Lab: Creating and Configuring a Spanner Instance and Database

---

<!-- layout: 2-column -->
# Regional Instance Configurations

### Topology Characteristics
- Distributes read-write replicas across three separate zones within a single Google Cloud region.
- Backed by an industry-standard 99.99% availability SLA.
- Provides the lowest write commit latency because Paxos round trips remain within a local metro network.

### Recommended Workloads
- Applications where all consuming services and users reside within one geographic boundary.
- Compliance and data sovereignty mandates requiring data to remain within a specific territory.
- Latency-sensitive workloads requiring single-digit millisecond write round trips.

<!-- below-columns -->

> [!NOTE]
> Regional instances seamlessly absorb the complete loss of an entire availability zone without human intervention or data loss.

---

<!-- layout: card-layout -->
# Multi-Region Topologies and the 99.999% SLA

### Global Geographic Footprint
- Replicates data across multiple Google Cloud regions and across continents.
- Provides an industry-leading 99.999% availability SLA (less than 5 minutes of downtime per calendar year).

### Asymmetric Latency Profile
- Local reads execute within milliseconds from the nearest regional replica.
- Writes coordinate across inter-region Paxos quorums, incurring 30 to 60 milliseconds of WAN latency.

### Multi-Region Outage Immunity
- Automatically survives the catastrophic loss of an entire cloud region without administrator intervention.
- Paxos quorums elect a new leader in an operational region and resume writes in seconds.

---

<!-- layout: 3-column -->
# Multi-Region Replica Types

### Read-Write Replicas
- Store a complete copy of the database
- Participate in Paxos write consensus and leader votes
- Serve local reads and coordinate transactions
- Located in primary and backup leader regions

### Read-Only Replicas
- Store a complete copy of the database
- Do not vote in Paxos quorums or leader elections
- Serve fast, local low-latency reads
- Placed near distant user bases without adding write latency

### Witness Replicas
- Do NOT store any database table data
- Vote in Paxos quorums to achieve quorum consensus
- Provide tie-breaking votes without storage costs
- Prevent split-brain scenarios during network isolation

---

<!-- layout: 2-column -->
# Leader Placement and Dual-Region Configurations

### Default Leader Region
- Multi-region instances designate a default leader region where Paxos leaders reside.
- Colocating write-heavy application microservices in the leader region minimizes write latency.
- The leader region can be changed dynamically without downtime to match time-of-day traffic shifts.

### Dual-Region Configurations
- Topologies such as `nam3` (Iowa and South Carolina) or `eur3` (Belgium and Netherlands).
- Pair two operational regions with a third witness-only region for quorum arbitration.
- Delivers multi-region disaster recovery while bounding cross-region round trip write latency.

---

# Topology Decision Framework

- Step 1: Identify legal and regulatory data residency requirements
  - If data cannot physically leave a sovereign jurisdiction, choose Regional or a country-bounded multi-region configuration
- Step 2: Evaluate read versus write geographic distribution
  - If users are worldwide and require local read speeds (<10 ms), choose Multi-Region
  - If write latency is critical (<5 ms) and traffic originates locally, choose Regional
- Step 3: Check availability and disaster recovery requirements
  - Choose Multi-Region if your business demands a 99.999% availability SLA and zero-RPO region disaster recovery
  - Regional configurations deliver 99.99% availability, which permits up to 52 minutes of downtime annually

> [!TIP]
> Benchmark write latency from your target Google Kubernetes Engine (GKE) or Compute Engine zones to the planned Spanner leader region before finalizing configuration choices.

---

<!-- layout: navigation -->
# Chapter 1

- Cloud Spanner Overview and Core Concepts
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- Comparing Spanner with Traditional RDBMS and NoSQL
- Regional and Multi-Region Deployment Options
- **Instance Topologies, Nodes, and Processing Units**
- Lab: Creating and Configuring a Spanner Instance and Database

---

<!-- layout: 2-column -->
# Sizing Compute: Nodes and Processing Units

### Processing Units (PUs)
- Spanner compute capacity is provisioned and billed using Processing Units (PUs).
- Fractional sizing starts at 100 PUs and scales in increments of 100 up to 1,000 PUs.
- 1,000 PUs equals exactly 1 Spanner Node; sizing above 1,000 scales in 1,000 PU increments.

### Granular Cost and Capacity Control
- Fractional PUs make Spanner cost-effective for non-production environments and smaller workloads.
- Provides predictable, linear throughput scaling as workload requirements grow.
- Scaling from 100 PUs to hundreds of nodes requires no application downtime or migration.

<!-- below-columns -->

> [!NOTE]
> 1 Node and 1,000 Processing Units represent identical compute performance and storage limits across Google Cloud interfaces.

---

<!-- layout: card-layout -->
# Capacity Sizing Rules and Quotas

### Storage per Compute Unit
- Every 1,000 PUs (1 Node) provides an allowance of up to 4 TB of storage.
- Sub-node allocations scale proportionally: 100 PUs supports up to 409.6 GB of storage.
- If storage exceeds quota, compute capacity must be expanded even if CPU is idle.

### CPU Utilization Headroom
- Maintain average high-priority CPU utilization below 65% for regional instances.
- Maintain CPU utilization below 45% for multi-region instances to ensure regional failover headroom.
- Operating above 80% causes request queueing, increased latencies, and transaction aborts.

### Throughput Baselines per Node
- A single regional node typically delivers approximately 10,000 read QPS (1 KB rows).
- Write capacity reaches approximately 2,000 write QPS per regional node.
- Real-world throughput depends on transaction size, secondary indexes, and row key distributions.

---

<!-- layout: 2-column -->
# Selecting a Database Dialect

### GoogleSQL Dialect
- Google’s native relational dialect adhering to ANSI SQL:2011 standards.
- Consistent syntax and data types with BigQuery, streamlining analytics workflows.
- Native data types include `INT64`, `FLOAT64`, `STRING`, `BYTES`, `TIMESTAMP`, and `JSON`.
- Recommended for greenfield cloud applications designed natively on Google Cloud.

### PostgreSQL Dialect
- Implements a substantial subset of the PostgreSQL core dialect and type system.
- Supported by popular PostgreSQL client libraries, ORMs, and developer tooling.
- Uses PostgreSQL data types such as `bigint`, `text`, `bytea`, and `timestamptz`.
- Lowers friction and retraining overhead when migrating existing PostgreSQL workloads.

<!-- below-columns -->

> [!WARNING]
> Database dialect is established permanently at database creation time. A database cannot be converted between GoogleSQL and PostgreSQL dialects after initialization.

---

# Provisioning via the gcloud CLI

- Cloud Spanner instances and databases can be provisioned via Console, Terraform, or CLI
- Command parameters specify configuration topology, compute capacity, and dialect

```bash
# Provision a regional Spanner instance with 500 Processing Units
gcloud spanner instances create prod-spanner-inst \
  --config=regional-us-central1 \
  --description="Production Central Instance" \
  --processing-units=500

# Create a database using the GoogleSQL dialect
gcloud spanner databases create orders-db \
  --instance=prod-spanner-inst \
  --database-dialect=GOOGLE_STANDARD_SQL
```

> [!TIP]
> Apply labels during instance creation (`--labels=env=prod,team=billing`) to enable granular cost tracking in Google Cloud Billing reports.

---

# Dynamic Compute Scaling and Operations

- Modifying compute capacity executes dynamically in minutes without database interruption
- Stateless compute architecture decouples node scaling from storage replication
  - Scaling up allocates additional compute containers that immediately share split processing
  - Scaling down safely drains active transactions before releasing compute resources
  - Storage remains intact and fully available throughout all scaling actions
- Production instances leverage Spanner autoscaling to respond to diurnal traffic patterns
  - Cloud Spanner Autoscaler automatically adjusts PUs based on high-priority CPU metrics
  - Prevents over-provisioning during off-peak hours and protects SLAs during demand surges

---

<!-- layout: navigation -->
# Chapter 1

- Cloud Spanner Overview and Core Concepts
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- Comparing Spanner with Traditional RDBMS and NoSQL
- Regional and Multi-Region Deployment Options
- Instance Topologies, Nodes, and Processing Units
- **Lab: Creating and Configuring a Spanner Instance and Database**

---

# Lab: Creating and Configuring a Spanner Instance and Database

Lab link: TODO

---

# What You Learned

- Evaluated Spanner architecture and provisioned regional or multi-region database instances
- Explained core concepts and features of Google Cloud Spanner
- Described how TrueTime, Paxos, and distributed storage ensure external consistency
- Compared Spanner capabilities with traditional relational databases and NoSQL systems
- Selected appropriate regional and multi-region deployment configurations
- Sized instances using node counts and processing units
- Provisioned and configured a Cloud Spanner instance and database in Google Cloud

---

# Quiz 1 of 3

**How does Cloud Spanner guarantee external consistency across globally distributed transactions?**

- A. By routing all global read and write operations through a single master coordinator server in us-central1
- B. By utilizing the TrueTime API and commit-wait to ensure commit timestamps reflect real-world causal ordering
- C. By relying on eventual consistency and resolving conflicting writes via last-write-wins timestamps
- D. By synchronizing server hardware clocks using standard public NTP servers over the internet

---

# Quiz 1: Answer

**How does Cloud Spanner guarantee external consistency across globally distributed transactions?**

**Correct: B.** By utilizing the TrueTime API and commit-wait to ensure commit timestamps reflect real-world causal ordering

- TrueTime bounds clock uncertainty using atomic clocks and GPS receivers across Google data centers
- The commit-wait rule delays releasing locks until the uncertainty window passes, ensuring causality
- Spanner distributes writes across Paxos groups without funneling traffic through a single master node
- Public NTP has unpredictable drift (50 - 500+ ms) that is far too loose for global serializability

---

# Quiz 2 of 3

**What is the primary architectural purpose of a witness replica in a multi-region Spanner configuration?**

- A. To store a complete copy of table data and serve low-latency read requests to regional clients
- B. To participate in Paxos quorums to achieve majority consensus without storing data or serving reads
- C. To act as the designated default write leader for all multi-region write transactions
- D. To maintain point-in-time recovery logs and export automated backups to Cloud Storage

---

# Quiz 2: Answer

**What is the primary architectural purpose of a witness replica in a multi-region Spanner configuration?**

**Correct: B.** To participate in Paxos quorums to achieve majority consensus without storing data or serving reads

- Witness replicas participate solely in Paxos voting rounds to satisfy majority quorum requirements
- They store no database table data, eliminating unnecessary storage costs in a third region
- Witness replicas never serve client read requests or execute query workloads
- Read-write replicas (not witnesses) maintain data and can be elected as write leaders

---

<!-- layout: 2-column -->
# Quiz 3 of 3: Discussion

### Prompt
An enterprise engineering team currently manages 16 sharded MySQL instances. They are planning to migrate their transactional billing service (12,000 write QPS) to Cloud Spanner.

### Discuss
- What architectural benefits does Spanner provide over their existing sharded MySQL cluster?
- What performance and latency trade-offs must the team evaluate when choosing between a regional and multi-region instance?
- How should the team size their initial compute capacity in Processing Units?

---

<!-- layout: 2-column -->
# Quiz 3: Discussion Points

**An enterprise engineering team currently manages 16 sharded MySQL instances. They are planning to migrate their transactional billing service (12,000 write QPS) to Cloud Spanner.**

### Strong Answers Mention
- Elimination of manual application-layer sharding logic, re-sharding maintenance, and cross-shard queries
- Regional instances deliver <5 ms writes, while multi-region writes incur 30 - 60 ms WAN latency
- Initial sizing requires ~6 nodes (6,000 PUs) based on ~2,000 write QPS per regional node baseline
- Target CPU utilization should remain under 65% for regional (or 45% for multi-region)

### Watch For
- Believing Spanner requires zero schema redesign (primary keys must avoid sequential hotspotting)
- Selecting multi-region solely for perceived prestige without considering cross-region write latency
- Overlooking the 4 TB storage quota per 1,000 PUs when sizing compute

---

# Questions and Answers

Questions?
