# Pipeline Directory Setup Required

## Issue

The ADF Pipeline Generation Agent attempted to create the pipeline file in the `pipelines/` directory as specified in the agent instructions, but the directory does not exist and the agent's available tools (view, create, edit, report_progress) cannot create directories.

## Current State

The generated pipeline `blob_to_sql_sales_copy.json` has been created in the repository root directory.

## Quick Fix

Run the provided setup script:

```bash
chmod +x setup-pipeline.sh
./setup-pipeline.sh
```

This will:
1. Create the `pipelines/` directory
2. Move the pipeline file to the correct location
3. Clean up this note

## Manual Setup (Alternative)

If you prefer to set up manually:

```bash
mkdir -p pipelines
mv blob_to_sql_sales_copy.json pipelines/
rm PIPELINE_SETUP_NOTE.md setup-pipeline.sh
```

## Generated Pipeline

The pipeline has been successfully generated and includes all required components:
- Source: Azure Blob Storage (`raw-data/sales/sales_*.csv`)
- Sink: Azure SQL Database (`staging.sales_data`)
- Pre-copy table truncation
- Retry policy: 3 attempts with 30-second intervals
- Pipeline run logging
- All environment-specific values parameterized
