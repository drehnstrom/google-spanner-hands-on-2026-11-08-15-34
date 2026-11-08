#!/usr/bin/env bash
set -euo pipefail

# Verification script for Lab 4: Building a Python Application with the Cloud Spanner API

export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
export INSTANCE_ID="order-mgmt-instance"
export DATABASE_ID="orders-googlesql-db"

echo "=== Verifying Lab 4 Solution ==="
echo "Project:  ${PROJECT_ID}"
echo "Instance: ${INSTANCE_ID}"
echo "Database: ${DATABASE_ID}"

# 1. Verify Spanner instance and database exist
echo "Checking instance readiness..."
gcloud spanner instances describe "${INSTANCE_ID}" --format="value(state)"

echo "Checking database readiness..."
gcloud spanner databases describe "${DATABASE_ID}" \
  --instance="${INSTANCE_ID}" \
  --format="value(databaseDialect,state)"

# 2. Check Python version and dependencies
echo "Checking Python environment..."
python3 --version
python3 -c "import google.cloud.spanner; print('google-cloud-spanner version:', google.cloud.spanner.__version__)"

# 3. Execute the Python application
echo "Executing order_service.py..."
python3 order_service.py

echo "=== Verification complete! ==="
