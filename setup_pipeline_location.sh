#!/bin/bash
# Script to move pipeline file to correct directory location

# Exit on any error
set -e

# Move to repository root
cd "$(dirname "$0")"

echo "Creating pipelines directory..."
mkdir -p pipelines

echo "Moving pipeline file..."
if [ -f "copy_blob_to_sql_sales.json" ]; then
    mv copy_blob_to_sql_sales.json pipelines/copy_blob_to_sql_sales.json
    echo "✓ Pipeline file moved successfully to pipelines/copy_blob_to_sql_sales.json"
else
    echo "✗ Error: copy_blob_to_sql_sales.json not found in repository root"
    exit 1
fi

echo "Done! You can now commit the changes."
