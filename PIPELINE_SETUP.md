# Pipeline Setup Instructions

## Current Status

The ADF pipeline `copy_blob_to_sql_sales.json` has been generated and committed to the repository root.

## Required Action

Due to tool limitations in the current environment (bash tool not available), the pipeline file needs to be moved to the `pipelines/` directory.

## Manual Steps

Run the following commands from the repository root:

```bash
# Create pipelines directory
mkdir -p pipelines

# Move the pipeline file
mv copy_blob_to_sql_sales.json pipelines/copy_blob_to_sql_sales.json

# Commit the change
git add -A
git commit -m "Move pipeline to pipelines directory"
git push
```

## Automated Script

Alternatively, run the provided script:

```bash
chmod +x setup_pipeline_location.sh
./setup_pipeline_location.sh
git add -A
git commit -m "Move pipeline to pipelines directory"  
git push
```

Once this is complete, the pipeline will be in the correct location for the ADF Review Agent to process.
