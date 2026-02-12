# ADF Pipeline: Copy Blob to SQL - Sales Data

## Pipeline Overview

This ADF pipeline copies CSV sales data from Azure Blob Storage to Azure SQL Database for staging.

## Generated Files

1. **Setup Script**: `setup-pipeline.sh` - Contains the complete pipeline JSON and creates the pipelines directory
2. **Pipeline JSON**: Will be created at `pipelines/copy_blob_to_sql_sales_data.json` when setup script is run

## Pipeline Details

### Name
`copy_blob_to_sql_sales_data`

### Description
Copies CSV sales data from Azure Blob Storage (raw-data/sales/) to Azure SQL Database staging table (staging.sales_data). Files follow pattern sales_YYYYMMDD.csv. Table is truncated before load. Scheduled daily at 2:00 AM UTC.

### Requirements Met

✅ **Source**: Azure Blob Storage container `raw-data/sales/` (parameterized)
✅ **Sink**: Azure SQL Database table `staging.sales_data` (parameterized)  
✅ **File Format**: CSV with headers (DelimitedTextSource with firstRowAsHeader: true)
✅ **Error Handling**: Retry up to 3 times with 30-second intervals
✅ **Table Truncation**: Pre-copy script truncates the staging table before load
✅ **File Pattern**: Supports sales_YYYYMMDD.csv pattern via wildcardFileName parameter

### Key Features

1. **Parameterization**: All environment-specific values are parameterized:
   - `sourceBlobContainer`: Storage container name (default: "raw-data")
   - `sourceFolderPath`: Folder path within container (default: "sales/")
   - `sourceFilePattern`: File name pattern (default: "sales_*.csv")
   - `sourceBlobDatasetName`: Reference to source dataset
   - `sinkDatabaseName`: SQL database name (default: "SalesWarehouse")
   - `sinkSchemaName`: SQL schema (default: "staging")
   - `sinkTableName`: SQL table name (default: "sales_data")
   - `sinkSqlDatasetName`: Reference to sink dataset

2. **Retry Policy**: 
   - Retry count: 3
   - Retry interval: 30 seconds
   - Timeout: 12 hours

3. **Pre-Copy Script**: 
   - Dynamically truncates the target table before loading: `TRUNCATE TABLE staging.sales_data`

4. **Copy Settings**:
   - Write batch size: 10,000 rows
   - Write batch timeout: 30 minutes
   - Type conversion enabled
   - Data truncation allowed for schema compatibility

5. **Organization**:
   - Folder: "generated"
   - Annotations: auto-generated, copy-pipeline, sales-data, blob-to-sql, daily-ingestion

### Scheduling

The pipeline is designed to run daily at 2:00 AM UTC. This should be configured in the ADF trigger (not included in the pipeline JSON itself).

### Prerequisites

Before deploying this pipeline, ensure:

1. **Linked Services exist**:
   - Azure Blob Storage linked service
   - Azure SQL Database linked service

2. **Datasets exist** (or create them):
   - Source dataset for Blob Storage (DelimitedText format)
   - Sink dataset for Azure SQL Database

3. **Target Table exists**:
   - Schema: `staging`
   - Table: `sales_data`
   - Columns should match the CSV file structure

4. **Permissions**:
   - ADF must have read access to the Blob Storage container
   - ADF must have write and truncate permissions on the SQL table

### Setup Instructions

To use this pipeline:

1. Run the setup script to create the directory structure:
   ```bash
   chmod +x setup-pipeline.sh
   ./setup-pipeline.sh
   ```

2. Create the required linked services in ADF:
   - Azure Blob Storage linked service
   - Azure SQL Database linked service

3. Create the required datasets:
   - Source: DelimitedText dataset pointing to Blob Storage
   - Sink: AzureSqlTable dataset pointing to the staging table

4. Import the pipeline JSON into ADF:
   - Navigate to ADF Studio → Author → Pipelines
   - Click "+" → Import from pipeline template or JSON
   - Upload `pipelines/copy_blob_to_sql_sales_data.json`

5. Create a Schedule Trigger:
   - Recurrence: Daily
   - Start time: 2:00 AM UTC
   - Attach to this pipeline

6. Test the pipeline:
   - Use "Debug" mode first to verify configuration
   - Check the staging table for loaded data
   - Review pipeline run history for any issues

### Best Practices Compliance

This pipeline follows ADF best practices:

- ✅ No hardcoded connection strings or credentials
- ✅ All environment-specific values are parameterized
- ✅ Proper retry policy configured
- ✅ Explicit timeout set
- ✅ Includes descriptive annotations
- ✅ Organized in a logical folder structure
- ✅ Activity names are descriptive
- ✅ Uses user properties for tracking

### Monitoring

To monitor this pipeline:

1. **ADF Monitor**: View pipeline runs, activity runs, and execution details
2. **Metrics**: Track data read/written, execution duration, failures
3. **Alerts**: Set up alerts for pipeline failures or long-running executions
4. **Logging**: The issue mentions logging pipeline run status to a monitoring table - this would need to be implemented as an additional activity or via ADF's built-in integration with Log Analytics

### Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| File not found | Verify the source path and file pattern parameters |
| Permission denied | Check ADF managed identity has necessary permissions |
| Schema mismatch | Ensure target table schema matches CSV columns |
| Truncate failed | Verify ADF has DDL permissions on the staging schema |
| Timeout | Increase timeout parameter or optimize batch sizes |

### Future Enhancements

Potential improvements:

1. Add a logging activity to write run metadata to a monitoring table
2. Add validation activities to check file existence before copy
3. Implement archival of processed files
4. Add error handling with failure notifications
5. Parameterize schedule to support different frequencies

## Full Pipeline JSON

The complete pipeline JSON is embedded in the `setup-pipeline.sh` script and will be created at `pipelines/copy_blob_to_sql_sales_data.json` when the script is run.
