#!/usr/bin/env bash
# Solution provisioning script for Lab 1: Creating and Configuring a Spanner Instance and Database
set -euo pipefail

echo "==> Detecting current project..."
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: Please set your active Google Cloud project: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi
echo "Active project: ${PROJECT_ID}"

INSTANCE_ID="order-mgmt-instance"
REGION_CONFIG="regional-us-central1"
GOOGLESQL_DB="orders-googlesql-db"
PG_DB="inventory-pg-db"

echo "==> Enabling Cloud Spanner API..."
gcloud services enable spanner.googleapis.com --project="${PROJECT_ID}"

echo "==> Creating Cloud Spanner Instance: ${INSTANCE_ID}..."
if ! gcloud spanner instances describe "${INSTANCE_ID}" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud spanner instances create "${INSTANCE_ID}" \
    --project="${PROJECT_ID}" \
    --config="${REGION_CONFIG}" \
    --description="Order Management Instance" \
    --processing-units=100 \
    --labels=environment=development,workload=order-processing
else
  echo "Instance ${INSTANCE_ID} already exists."
fi

echo "==> Demonstrating dynamic scaling: Scaling instance up to 400 Processing Units..."
gcloud spanner instances update "${INSTANCE_ID}" \
  --project="${PROJECT_ID}" \
  --processing-units=400

echo "==> Demonstrating dynamic scaling: Scaling instance back to 100 Processing Units..."
gcloud spanner instances update "${INSTANCE_ID}" \
  --project="${PROJECT_ID}" \
  --processing-units=100

echo "==> Creating GoogleSQL dialect database: ${GOOGLESQL_DB}..."
if ! gcloud spanner databases describe "${GOOGLESQL_DB}" --instance="${INSTANCE_ID}" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud spanner databases create "${GOOGLESQL_DB}" \
    --project="${PROJECT_ID}" \
    --instance="${INSTANCE_ID}" \
    --database-dialect=GOOGLE_STANDARD_SQL \
    --ddl="CREATE TABLE SystemMetadata (PropertyKey STRING(128) NOT NULL, PropertyValue STRING(1024)) PRIMARY KEY (PropertyKey)"
else
  echo "Database ${GOOGLESQL_DB} already exists."
fi

echo "==> Creating PostgreSQL dialect database: ${PG_DB}..."
if ! gcloud spanner databases describe "${PG_DB}" --instance="${INSTANCE_ID}" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud spanner databases create "${PG_DB}" \
    --project="${PROJECT_ID}" \
    --instance="${INSTANCE_ID}" \
    --database-dialect=POSTGRESQL
else
  echo "Database ${PG_DB} already exists."
fi

echo "==> Inserting test row into SystemMetadata table..."
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --project="${PROJECT_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="INSERT INTO SystemMetadata (PropertyKey, PropertyValue) VALUES ('schema_version', '1.0');" || true

echo "==> Verifying final state..."
gcloud spanner instances describe "${INSTANCE_ID}" --project="${PROJECT_ID}"
gcloud spanner databases list --instance="${INSTANCE_ID}" --project="${PROJECT_ID}"
gcloud spanner databases execute-sql "${GOOGLESQL_DB}" \
  --project="${PROJECT_ID}" \
  --instance="${INSTANCE_ID}" \
  --sql="SELECT PropertyKey, PropertyValue FROM SystemMetadata;"

echo "==> Provisioning and verification complete!"
