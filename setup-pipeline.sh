#!/bin/bash
# Helper script to create pipelines directory and move the pipeline JSON file
# Run this script from the repository root

mkdir -p pipelines
mv /tmp/copy_blob_to_sql_sales_data.json pipelines/copy_blob_to_sql_sales_data.json
echo "Pipeline JSON file moved to pipelines/copy_blob_to_sql_sales_data.json"
