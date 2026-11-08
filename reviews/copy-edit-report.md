# Copy Edit Report: Google Spanner: Hands-On

## Pass: 2026-11-08

| Field | Value |
| :--- | :--- |
| Editor model | Claude 3.5 Sonnet / Copy Editor |
| Session | Fresh (yes) |
| Scope | Slides and labs (`course/*.md`, `labs/**/lab.md`) |

### Glossary

| Term | Form used | Notes |
| :--- | :--- | :--- |
| Cloud Spanner | `Cloud Spanner` / `Spanner` | Standardized official product name |
| GoogleSQL | `GoogleSQL` | Standardized dialect name |
| PostgreSQL | `PostgreSQL` | Standardized dialect and database name |
| Processing Units | `Processing Units` (PUs) | Standardized capitalization across slides and labs |
| hands-on | `hands-on` / `Hands-On` | Standardized hyphenated compound |
| TrueTime | `TrueTime` | Standardized Spanner hardware-synchronized clock API name |
| Colossus | `Colossus` | Standardized Google distributed storage layer name |
| Paxos | `Paxos` | Standardized consensus protocol name |
| Key Visualizer | `Key Visualizer` | Standardized diagnostic tool name |
| Query Insights | `Query Insights` | Standardized telemetry feature name |
| Spanner Migration Tool | `Spanner Migration Tool` (SMT) | Standardized open-source migration tool name |
| Change Data Capture | `Change Data Capture` (CDC) | Standardized data engineering term |
| gcloud | `gcloud` | Command-style name preserved in prose and code |

### Fix counts

| Type | Count |
| :--- | :--- |
| Spelling | 1 |
| Grammar | 6 |
| Smart quotes | 5 |
| Em-dashes / ampersands | 0 |
| Consistency | 5 |

### Representative fixes

- `course/01-introduction-and-architecture.md` / Resolving the Traditional CAP Dilemma: "Google private fiber-optic network infrastructure" → "Google’s private fiber-optic network infrastructure"
- `course/01-introduction-and-architecture.md` / Compute and Storage Disaggregation: "Google global distributed file system" → "Google’s global distributed file system"
- `course/01-introduction-and-architecture.md` / Provisioning via the gcloud CLI: duplicate word "in Google Cloud Cloud Billing reports" → "in Google Cloud Billing reports"
- `course/02-schema-design-and-data-modeling.md` / Eliminating Back-Joins with Stored Columns: straight quotes `"covering indexes"` → smart quotes `“covering indexes”`
- `course/03-querying-and-data-manipulation.md` / Distributed Query Execution Architecture: missing article "node receiving client query" → "node receiving the client query"
- `course/03-querying-and-data-manipulation.md` / Transaction Mode Decision Framework: capitalization consistency "Read-Write transaction" → "read-write transaction"
- `course/05-database-administration-and-operations.md` / Heading consistency: "Scale-Up vs. Scale-Down Mechanics" → "Scale-Up vs Scale-Down Mechanics"
- `course/05-database-administration-and-operations.md` / Heading consistency: "Data Protection Strategies: Backups vs. PITR" → "Data Protection Strategies: Backups vs PITR"
- `course/06-migrating-databases.md` / Heading consistency: "Migration Methodology: Offline vs. Online" → "Migration Methodology: Offline vs Online"
- `course/06-migrating-databases.md` / Heading consistency: "Dialect Selection: GoogleSQL vs. PostgreSQL" → "Dialect Selection: GoogleSQL vs PostgreSQL"
- `course/06-migrating-databases.md` / Quiz 1: Answer: missing possessive apostrophe "leverages Spanner asynchronous backfill engine" → "leverages Spanner’s asynchronous backfill engine"
- `labs/lab-03-lab-querying-mutating-and-tuning-sql-queries/lab.md` / Task 3: straight quotes `"read-your-writes"` → smart quotes `“read-your-writes”`
- `labs/lab-03-lab-querying-mutating-and-tuning-sql-queries/lab.md` / Bonus Task 8: straight quotes `"Unbounded Root Aggregation"` → smart quotes `“Unbounded Root Aggregation”`
- `labs/lab-04-lab-building-a-python-application-with-the-cloud-spanner-api/lab.md` / Task 3: straight apostrophe in prose `customer partition's Paxos split` → smart apostrophe `customer partition’s Paxos split`

### Left unchanged

- `gcloud`, `pip3`, and `python3` kept as command-style names
- Inline code and fenced code samples untouched
- `Lab link: TODO` left intact on all lab transition slides
- Architecture directives (`<!-- layout: ... -->`) and course metadata intact
