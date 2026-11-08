# Solution: Building a Python Application with the Cloud Spanner API

## End State

- A fully operational Python application (`order_service.py`) integrating with Cloud Spanner.
- Singleton client initialized with Application Default Credentials (ADC) and a customized `PingingPool` session pool (size 10, max_opened 20).
- Lock-free snapshot read queries supporting both strong consistency and bounded staleness (`max_staleness=timedelta(seconds=15)`).
- Fast primary key lookups using `spanner.KeySet` that bypass SQL optimizer compilation.
- Atomic read-write checkout transactions using `database.run_in_transaction()` with parameterized DML statements, balance verification, and interleaved order insertion.
- Batch customer data ingestion using low-level Spanner mutations and TrueTime commit timestamps (`spanner.COMMIT_TIMESTAMP`).
- Configured custom exponential backoff `Retry` policy and timeout settings for idempotent read RPCs, with proper `Aborted` exception propagation.
- Distributed query partitioning executed via `spanner.BatchClient` across cluster splits.

## How to Verify

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export INSTANCE_ID="order-mgmt-instance"
export DATABASE_ID="orders-googlesql-db"

python3 order_service.py
```

Or run the automated verification script:

```bash
./verify.sh
```

Expected output:
- Successful database connection and session pool pre-warming confirmation.
- Output from strong and bounded staleness snapshot reads for customer details.
- Primary key KeySet query output bypassing SQL compilation.
- Confirmed transaction commit with generated UUID `OrderId` and updated customer balance.
- Successful trap and log of an intentional insufficient funds validation error.
- Successful batch insertion of customer records via mutations.
- Query execution with custom `Retry` policy returning platinum customer records.
- Distributed partition generation and simulated worker execution reporting scanned row counts.

## Built With

- Google Cloud Spanner Python SDK (`google-cloud-spanner >= 3.40.0`, `google-api-core >= 2.15.0`)
- Python 3.10+, Google Cloud Shell or standard Linux environment
- Cloud Spanner Instance: `order-mgmt-instance`, Regional `us-central1`, 100 Processing Units
- Database: `orders-googlesql-db` (GoogleSQL dialect)
- Checked: 2026-11-08
- Unverified: None (verified against official Cloud Spanner Python client API specifications)
