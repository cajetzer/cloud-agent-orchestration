# ADF Pipeline: Blob to SQL Sales Copy

## Pipeline Overview

This pipeline copies CSV sales data from Azure Blob Storage to Azure SQL Database staging table with pre-load truncation and run logging.

## Generated Pipeline Details

**Name:** `blob_to_sql_sales_copy`

**Type:** Copy Activity Pipeline

**Source:** Azure Blob Storage
- Container/Folder: `raw-data/sales/`
- File Pattern: `sales_*.csv` (e.g., `sales_20260212.csv`)
- Format: CSV with headers

**Sink:** Azure SQL Database
- Schema: `staging`
- Table: `sales_data`
- Behavior: Truncate before load

## Activities

### 1. TruncateStagingTable (Script Activity)
- Truncates the target table before data load
- Retry: 2 attempts, 30-second intervals
- Timeout: 5 minutes
- Parameterized table reference

### 2. CopySalesData (Copy Activity)
- Copies CSV files from Blob Storage to SQL Database
- Retry: 3 attempts, 30-second intervals (as required)
- Timeout: 12 hours
- Dependency: Runs after TruncateStagingTable succeeds
- Features:
  - Wildcard file pattern matching
  - Automatic type conversion
  - CSV header handling

### 3. LogPipelineRun (Script Activity)
- Logs pipeline execution details to monitoring table
- Runs after CopySalesData (on success OR failure)
- Retry: 1 attempt, 30-second intervals
- Logs: Pipeline name, run ID, status, timestamps, rows copied

## Parameters

All environment-specific values are parameterized (no hardcoded values):

| Parameter | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| `sourceFolderPath` | String | `raw-data/sales` | Blob storage folder path |
| `sourceFilePattern` | String | `sales_*.csv` | File name pattern |
| `sourceDataset` | String | - | Source dataset reference |
| `sinkDataset` | String | - | Sink dataset reference |
| `sinkLinkedService` | String | - | SQL database linked service |
| `sinkSchema` | String | `staging` | Target schema name |
| `sinkTable` | String | `sales_data` | Target table name |
| `loggingTable` | String | `monitoring.pipeline_run_log` | Logging table name |

## Schedule (To Be Configured)

The pipeline is designed to run daily at 2:00 AM UTC. The schedule trigger should be configured separately in Azure Data Factory as:

```json
{
  "name": "DailyTrigger",
  "properties": {
    "type": "ScheduleTrigger",
    "typeProperties": {
      "recurrence": {
        "frequency": "Day",
        "interval": 1,
        "startTime": "2026-01-01T02:00:00Z",
        "timeZone": "UTC"
      }
    },
    "pipelines": [
      {
        "pipelineReference": {
          "referenceName": "blob_to_sql_sales_copy",
          "type": "PipelineReference"
        }
      }
    ]
  }
}
```

## Best Practices Compliance

✓ All activities have retry policies (1-3 retries as appropriate)
✓ All activities have explicit timeouts (5 min - 12 hours, under 7-day max)
✓ No hardcoded connection strings or credentials
✓ All environment-specific values parameterized
✓ Descriptive names for pipeline and activities
✓ Pipeline includes description, annotations, and folder organization
✓ Error handling with appropriate retry intervals
✓ Logging for observability

## Setup Required

⚠️ **Important:** The pipeline file needs to be moved to the `pipelines/` directory. Run the setup script:

```bash
chmod +x setup-pipeline.sh
./setup-pipeline.sh
```

Or manually:
```bash
mkdir -p pipelines
mv blob_to_sql_sales_copy.json pipelines/
```

## Deployment Prerequisites

Before deploying this pipeline to Azure Data Factory:

1. Create linked services:
   - Azure Blob Storage linked service
   - Azure SQL Database linked service

2. Create datasets:
   - Source dataset (DelimitedText) pointing to Blob Storage
   - Sink dataset (AzureSqlTable) pointing to SQL Database

3. Create the monitoring table in SQL Database:
   ```sql
   CREATE TABLE monitoring.pipeline_run_log (
       PipelineName NVARCHAR(255),
       RunId NVARCHAR(255),
       Status NVARCHAR(50),
       StartTime DATETIME,
       EndTime DATETIME,
       RowsCopied INT
   );
   ```

4. Configure the schedule trigger (see Schedule section above)

## Issue Reference

Resolves #[issue-number]

This pipeline addresses all requirements from the issue:
- ✓ Source: Azure Blob Storage container `raw-data/sales/`
- ✓ Sink: Azure SQL Database table `staging.sales_data`
- ✓ File format: CSV with headers
- ✓ Error handling: Retry up to 3 times with 30-second intervals
- ✓ File naming pattern: `sales_YYYYMMDD.csv` (via wildcard `sales_*.csv`)
- ✓ Sink table truncation before each load
- ✓ Logging: Pipeline run status logged to monitoring table
- ⚠ Schedule: Daily at 2:00 AM UTC (trigger configuration provided above)
