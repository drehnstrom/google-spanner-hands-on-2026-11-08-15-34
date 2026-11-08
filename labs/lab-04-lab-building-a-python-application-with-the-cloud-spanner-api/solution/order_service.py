#!/usr/bin/env python3
"""
Cloud Spanner Order Management Service
Demonstrates Cloud Spanner Python SDK patterns:
- Singleton client and custom PingingPool session management
- Lock-free snapshot reads (strong and bounded staleness)
- Fast primary key lookups using KeySet
- Read-write transactions with parameterized DML using run_in_transaction
- High-throughput mutations with commit timestamps
- Custom retry policies and proper Aborted exception propagation
- Parallel distributed batch partitioning using BatchClient
"""

import datetime
import json
import os
import sys
import uuid
from google.api_core.exceptions import Aborted, DeadlineExceeded, ServiceUnavailable
from google.api_core.retry import Retry
from google.cloud import spanner
from google.cloud.spanner_v1.pool import PingingPool


class SpannerOrderService:
    """Application service managing Spanner database operations."""

    def __init__(self, project_id: str, instance_id: str, database_id: str):
        self.project_id = project_id
        self.instance_id = instance_id
        self.database_id = database_id

        # Configure custom session pool
        self.pool = PingingPool(
            size=10,             # Target number of pre-warmed sessions
            default_timeout=10,  # Seconds to wait for a session before timing out
            ping_interval=1800,  # Ping idle sessions every 30 minutes (1800s)
            max_opened=20        # Hard ceiling on total concurrent sessions
        )

        # Singleton client, instance, and database handles
        self.client = spanner.Client(project=self.project_id)
        self.instance = self.client.instance(self.instance_id)
        self.database = self.instance.database(self.database_id, pool=self.pool)

    def verify_connection(self) -> bool:
        """Verify database connectivity and existence."""
        if not self.database.exists():
            raise RuntimeError(
                f"Database '{self.database_id}' does not exist on instance '{self.instance_id}'."
            )
        # Execute a lightweight ping query within a snapshot context
        with self.database.snapshot() as snapshot:
            results = list(snapshot.execute_sql("SELECT 1"))
            return len(results) == 1

    def get_customer_by_email(self, email: str, max_staleness_seconds: int = 0) -> dict:
        """
        Read customer record using a lock-free snapshot.
        Supports strong consistency (default) or bounded staleness.
        """
        snapshot_kwargs = {}
        if max_staleness_seconds > 0:
            snapshot_kwargs["max_staleness"] = datetime.timedelta(seconds=max_staleness_seconds)

        with self.database.snapshot(**snapshot_kwargs) as snapshot:
            sql = (
                "SELECT CustomerId, FullName, Email, Balance, CustomerTier "
                "FROM Customers WHERE Email = @email"
            )
            results = snapshot.execute_sql(
                sql,
                params={"email": email},
                param_types={"email": spanner.param_types.STRING}
            )
            rows = list(results)
            if not rows:
                return {}
            row = rows[0]
            return {
                "customer_id": row[0],
                "full_name": row[1],
                "email": row[2],
                "balance": float(row[3]) if row[3] is not None else 0.0,
                "customer_tier": row[4]
            }

    def get_customers_by_keyset(self, customer_ids: list) -> list:
        """
        Read multiple customer records by primary key using KeySet.
        Bypasses SQL compilation and query plan optimization for maximum efficiency.
        """
        keyset = spanner.KeySet(keys=[[cid] for cid in customer_ids])
        with self.database.snapshot() as snapshot:
            results = snapshot.read(
                table="Customers",
                columns=["CustomerId", "FullName", "Email", "Balance", "CustomerTier"],
                keyset=keyset
            )
            customers = []
            for row in results:
                customers.append({
                    "customer_id": row[0],
                    "full_name": row[1],
                    "email": row[2],
                    "balance": float(row[3]) if row[3] is not None else 0.0,
                    "customer_tier": row[4]
                })
            return customers

    def place_order(self, customer_id: int, total_amount: float, line_items: list) -> dict:
        """
        Execute an atomic read-write transaction using run_in_transaction.
        Reads customer balance with shared lock, validates funds, updates balance,
        and inserts order and line items.
        """
        order_id = str(uuid.uuid4())

        def _transaction_callback(transaction):
            # Step 1: Read current balance with shared read lock
            query = "SELECT Balance FROM Customers WHERE CustomerId = @cid"
            results = list(transaction.execute_sql(
                query,
                params={"cid": customer_id},
                param_types={"cid": spanner.param_types.INT64}
            ))
            if not results:
                raise ValueError(f"Customer {customer_id} not found.")

            current_balance = float(results[0][0])
            if current_balance < total_amount:
                raise ValueError(
                    f"Insufficient funds: Customer balance ({current_balance:.2f}) "
                    f"is less than order total ({total_amount:.2f})."
                )

            # Step 2: Deduct balance using parameterized DML
            update_sql = "UPDATE Customers SET Balance = Balance - @deduction WHERE CustomerId = @cid"
            transaction.execute_update(
                update_sql,
                params={"deduction": total_amount, "cid": customer_id},
                param_types={
                    "deduction": spanner.param_types.NUMERIC,
                    "cid": spanner.param_types.INT64
                }
            )

            # Step 3: Insert order row using parameterized DML
            insert_order_sql = (
                "INSERT INTO Orders (CustomerId, OrderId, OrderDate, TotalAmount, OrderStatus) "
                "VALUES (@cid, @oid, CURRENT_TIMESTAMP(), @total, 'PROCESSING')"
            )
            transaction.execute_update(
                insert_order_sql,
                params={"cid": customer_id, "oid": order_id, "total": total_amount},
                param_types={
                    "cid": spanner.param_types.INT64,
                    "oid": spanner.param_types.STRING,
                    "total": spanner.param_types.NUMERIC
                }
            )

            # Step 4: Insert interleaved order items
            insert_item_sql = (
                "INSERT INTO OrderItems (CustomerId, OrderId, LineItem, ProductId, Quantity, UnitPrice) "
                "VALUES (@cid, @oid, @line, @pid, @qty, @price)"
            )
            for item in line_items:
                transaction.execute_update(
                    insert_item_sql,
                    params={
                        "cid": customer_id,
                        "oid": order_id,
                        "line": item["line_item"],
                        "pid": item["product_id"],
                        "qty": item["quantity"],
                        "price": item["unit_price"]
                    },
                    param_types={
                        "cid": spanner.param_types.INT64,
                        "oid": spanner.param_types.STRING,
                        "line": spanner.param_types.INT64,
                        "pid": spanner.param_types.STRING,
                        "qty": spanner.param_types.INT64,
                        "price": spanner.param_types.NUMERIC
                    }
                )

            return {
                "order_id": order_id,
                "customer_id": customer_id,
                "total_amount": total_amount,
                "status": "PROCESSING",
                "items_count": len(line_items)
            }

        # Execute within the transaction runner helper
        result = self.database.run_in_transaction(_transaction_callback)
        return result

    def batch_insert_customers_with_mutations(self, customers: list) -> int:
        """
        Insert customer records using low-level Spanner mutations and spanner.COMMIT_TIMESTAMP.
        Mutations bypass SQL compilation for maximum write throughput.
        """
        def _mutation_callback(transaction):
            values = []
            for cust in customers:
                metadata_val = spanner.JsonObject(cust["metadata"]) if cust.get("metadata") else None
                values.append((
                    cust["customer_id"],
                    cust["full_name"],
                    cust["email"],
                    cust["balance"],
                    metadata_val,
                    spanner.COMMIT_TIMESTAMP
                ))

            transaction.insert(
                table="Customers",
                columns=["CustomerId", "FullName", "Email", "Balance", "Metadata", "CreatedAt"],
                values=values
            )
            return len(values)

        return self.database.run_in_transaction(_mutation_callback)

    def execute_query_with_retry_and_timeout(self, query: str, params: dict, param_types: dict) -> list:
        """
        Execute an idempotent read query with custom Retry policy and RPC timeout.
        """
        custom_retry = Retry(
            predicate=lambda exc: isinstance(exc, (DeadlineExceeded, ServiceUnavailable)),
            initial=0.5,
            maximum=5.0,
            multiplier=2.0,
            deadline=15.0
        )

        with self.database.snapshot() as snapshot:
            results = snapshot.execute_sql(
                query,
                params=params,
                param_types=param_types,
                retry=custom_retry,
                timeout=10.0
            )
            return list(results)

    def execute_distributed_batch_scan(self, sql_query: str) -> int:
        """
        Partition a large table query across cluster splits using BatchClient.
        Simulates coordinator partition generation and distributed worker execution.
        """
        batch_client = self.client.batch_client(self.instance_id, self.database_id)
        total_rows_scanned = 0

        with batch_client.batch_snapshot() as snapshot:
            partitions = snapshot.generate_partitions_sql(sql_query)
            print(f"  [Coordinator] Generated {len(partitions)} parallel partitions across cluster splits.")

            for i, partition in enumerate(partitions):
                partition_rows = list(snapshot.process_partition(partition))
                print(f"  [Worker {i+1}] Processed partition: {len(partition_rows)} rows retrieved.")
                total_rows_scanned += len(partition_rows)

        return total_rows_scanned


def main():
    project_id = os.environ.get("PROJECT_ID")
    if not project_id:
        if len(sys.argv) > 1:
            project_id = sys.argv[1]
        else:
            print("ERROR: Set PROJECT_ID environment variable or pass project ID as argument.")
            sys.exit(1)

    instance_id = os.environ.get("INSTANCE_ID", "order-mgmt-instance")
    database_id = os.environ.get("DATABASE_ID", "orders-googlesql-db")

    print("=" * 70)
    print("Cloud Spanner Python Application - Order Management Service")
    print(f"Project:  {project_id}")
    print(f"Instance: {instance_id}")
    print(f"Database: {database_id}")
    print("=" * 70)

    # 1. Initialize Service
    print("\n[Step 1] Initializing client and PingingPool session pool...")
    service = SpannerOrderService(project_id, instance_id, database_id)
    if service.verify_connection():
        print("  SUCCESS: Connected to Spanner database and session pool pre-warmed.")

    # 2. Snapshot Reads: Strong and Bounded Staleness
    print("\n[Step 2] Executing lock-free snapshot reads...")
    test_email = "sophia.rodriguez@example.com"
    customer = service.get_customer_by_email(test_email, max_staleness_seconds=0)
    if customer:
        print(f"  [Strong Snapshot] Found: {customer['full_name']} (ID: {customer['customer_id']})")
        print(f"    Tier: {customer['customer_tier']}, Balance: ${customer['balance']:.2f}")
    else:
        print(f"  Notice: Customer {test_email} not found. Running with available records.")

    stale_customer = service.get_customer_by_email(test_email, max_staleness_seconds=15)
    if stale_customer:
        print(f"  [Bounded Staleness 15s] Verified read: ${stale_customer['balance']:.2f}")

    # 3. KeySet Primary Key Lookup
    print("\n[Step 3] Executing fast primary key KeySet read...")
    if customer:
        customer_list = service.get_customers_by_keyset([customer["customer_id"]])
        print(f"  [KeySet Read] Retrieved {len(customer_list)} customer(s) bypassing SQL optimizer.")
        for c in customer_list:
            print(f"    Customer: {c['full_name']} | Balance: ${c['balance']:.2f}")

    # 4. Read-Write Transaction with Parameterized DML
    print("\n[Step 4] Executing read-write transaction (order checkout)...")
    if customer:
        cid = customer["customer_id"]
        order_items = [
            {"line_item": 1, "product_id": "prod-sku-98124", "quantity": 1, "unit_price": 45.00},
            {"line_item": 2, "product_id": "prod-sku-55412", "quantity": 2, "unit_price": 20.00}
        ]
        total_order_amount = 85.00

        try:
            order_result = service.place_order(cid, total_order_amount, order_items)
            print(f"  SUCCESS: Transaction committed.")
            print(f"    Order ID: {order_result['order_id']}")
            print(f"    Total Charged: ${order_result['total_amount']:.2f}")
            print(f"    Line Items: {order_result['items_count']}")

            # Verify balance deduction
            updated_customer = service.get_customer_by_email(test_email)
            print(f"    Updated Customer Balance: ${updated_customer['balance']:.2f}")
        except ValueError as err:
            print(f"  Business Validation Error: {err}")

        # Test Insufficient Funds Validation
        print("\n  Testing transaction validation (insufficient funds):")
        try:
            service.place_order(cid, 999999.00, order_items)
            print("  UNEXPECTED: Transaction should have failed.")
        except ValueError as err:
            print(f"  EXPECTED ERROR: {err}")

    # 5. Batch Ingestion with Mutations and COMMIT_TIMESTAMP
    print("\n[Step 5] Batch inserting customer records using Spanner mutations...")
    new_customers = [
        {
            "customer_id": 810000000000000001,
            "full_name": "Mateo Silva",
            "email": "mateo.silva@example.com",
            "balance": 500.00,
            "metadata": json.dumps({"loyalty": {"tier": "GOLD", "points": 1200}})
        },
        {
            "customer_id": 810000000000000002,
            "full_name": "Zara Chen",
            "email": "zara.chen@example.com",
            "balance": 250.00,
            "metadata": json.dumps({"loyalty": {"tier": "SILVER", "points": 600}})
        }
    ]
    try:
        inserted_count = service.batch_insert_customers_with_mutations(new_customers)
        print(f"  SUCCESS: Staged and committed {inserted_count} mutations with TrueTime commit timestamps.")
    except Exception as err:
        print(f"  Notice during mutation insert (may already exist): {err}")

    # 6. Retry Policies and Timeout
    print("\n[Step 6] Executing query with custom Retry policy and RPC timeout...")
    query = "SELECT CustomerId, FullName, Email FROM Customers WHERE CustomerTier = @tier"
    params = {"tier": "PLATINUM"}
    param_types = {"tier": spanner.param_types.STRING}
    platinum_customers = service.execute_query_with_retry_and_timeout(query, params, param_types)
    print(f"  SUCCESS: Retrieved {len(platinum_customers)} PLATINUM customer(s) with custom retry policy.")

    # 7. Distributed BatchClient Partitioning
    print("\n[Step 7] Generating and processing parallel partitions with BatchClient...")
    batch_sql = "SELECT CustomerId, OrderId, TotalAmount, OrderStatus FROM Orders"
    total_scanned = service.execute_distributed_batch_scan(batch_sql)
    print(f"  SUCCESS: Scanned {total_scanned} total order records across partitions.")

    print("\n" + "=" * 70)
    print("Application execution completed successfully.")
    print("=" * 70)


if __name__ == "__main__":
    main()
