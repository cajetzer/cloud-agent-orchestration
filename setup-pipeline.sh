#!/bin/bash
# Setup script to create pipelines directory and move the generated pipeline

# Create pipelines directory if it doesn't exist
mkdir -p pipelines

# Move the pipeline file to the correct location
if [ -f "blob_to_sql_sales_copy.json" ]; then
    mv blob_to_sql_sales_copy.json pipelines/
    echo "✓ Moved blob_to_sql_sales_copy.json to pipelines/"
else
    echo "✗ Pipeline file not found in root directory"
    exit 1
fi

# Clean up the setup note
if [ -f "PIPELINE_SETUP_NOTE.md" ]; then
    rm PIPELINE_SETUP_NOTE.md
    echo "✓ Removed PIPELINE_SETUP_NOTE.md"
fi

echo "✓ Pipeline setup complete"
