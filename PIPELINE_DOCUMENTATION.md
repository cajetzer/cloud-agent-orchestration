# ADF Pipeline: Copy Blob Storage to SQL Database

## Pipeline Overview

**Name:** `copy_blob_storage_to_sql_database`

**Purpose:** Copy CSV files from Azure Blob Storage to Azure SQL Database staging table with pre-copy truncation and logging.

## Pipeline Details

### Source Configuration
- **Type:** Azure Blob Storage (DelimitedText/CSV)
- **Location:** `raw-data/sales/` container
- **File Pattern:** `sales_*.csv` (matches `sales_YYYYMMDD.csv` format)
- **Format:** CSV with first row as headers

### Sink Configuration
- **Type:** Azure SQL Database (SqlSink)
- **Schema:** `staging`
- **Table:** `sales_data`
- **Pre-copy Action:** TRUNCATE TABLE before load
- **Write Batch Size:** 10,000 rows
- **Write Batch Timeout:** 30 minutes

### Activities

#### 1. CopySalesDataFromBlobToSQL (Copy Activity)
- **Retry Policy:** 3 retries with 30-second intervals
- **Timeout:** 12 hours
- **Source:** Blob Storage with wildcard pattern matching
- **Sink:** SQL Database with pre-copy truncation
- **Translation:** Automatic type conversion with truncation allowed

#### 2. LogPipelineRunStatus (Stored Procedure Activity)
- **Purpose:** Log pipeline execution to monitoring table
- **Dependency:** Runs after Copy activity (on Success or Failure)
- **Retry Policy:** 1 retry with 30-second interval
- **Timeout:** 5 minutes
- **Logged Information:**
  - Pipeline Name
  - Run ID
  - Status (Succeeded/Failed)
  - Rows Copied
  - Execution Time
  - Timestamp

### Parameterization

All environment-specific values are parameterized (no hardcoded values):

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `sourceDataset` | Source dataset reference | `BlobStorageCsvDataset` |
| `sinkDataset` | Sink dataset reference | `SqlDatabaseDataset` |
| `sourceFolderPath` | Blob container path | `raw-data/sales/` |
| `sourceFilePattern` | File name pattern | `sales_*.csv` |
| `sinkSchema` | Target schema name | `staging` |
| `sinkTable` | Target table name | `sales_data` |
| `sinkLinkedService` | SQL linked service | `AzureSqlDatabaseLinkedService` |
| `loggingStoredProcedure` | Monitoring SP | `monitoring.LogPipelineRun` |

### Scheduling

**Note:** The issue requested a daily schedule at 2:00 AM UTC. In ADF, triggers are defined separately from pipelines. To implement this schedule, create a Schedule Trigger with the following configuration:

```json
{
  "name": "DailySalesDataTrigger",
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
          "referenceName": "copy_blob_storage_to_sql_database",
          "type": "PipelineReference"
        }
      }
    ]
  }
}
```

## Best Practices Compliance

✅ **Retry Policy**: Copy activity has 3 retries with 30-second intervals as requested
✅ **Timeout**: All activities have explicit timeouts
✅ **Parameterization**: No hardcoded connection strings or paths
✅ **Security**: Appropriate security settings for data movement
✅ **Organization**: Clear naming, descriptions, annotations, and folder structure
✅ **Error Handling**: Logging activity captures both success and failure cases

## Prerequisites

Before deploying this pipeline, ensure the following resources exist:

1. **Datasets:**
   - `BlobStorageCsvDataset` - Configured for DelimitedText format with parameters for folderPath and fileName
   - `SqlDatabaseDataset` - Configured for Azure SQL Database with parameters for schemaName and tableName

2. **Linked Services:**
   - Azure Blob Storage linked service (referenced by BlobStorageCsvDataset)
   - `AzureSqlDatabaseLinkedService` - Azure SQL Database linked service

3. **SQL Objects:**
   - `staging.sales_data` table (can be auto-created by pipeline)
   - `monitoring.LogPipelineRun` stored procedure with the following signature:
     ```sql
     CREATE PROCEDURE monitoring.LogPipelineRun
       @PipelineName NVARCHAR(200),
       @RunId NVARCHAR(200),
       @Status NVARCHAR(50),
       @RowsCopied INT,
       @ExecutionTime INT,
       @Timestamp DATETIME2
     AS
     -- Your logging logic here
     ```

## Testing Recommendations

1. **Unit Test:** Run pipeline with a small test file to verify CSV parsing and SQL insertion
2. **Error Test:** Test with malformed CSV to verify retry logic
3. **Logging Test:** Verify monitoring table receives correct entries
4. **Schedule Test:** Verify trigger fires at correct time (2:00 AM UTC)

## Assumptions Made

1. The source Blob Storage container and sink SQL Database are in the same Azure region (or staging is not required for performance)
2. The `sales_data` table schema matches the CSV file structure
3. A monitoring infrastructure exists with the `LogPipelineRun` stored procedure
4. The CSV files have consistent column headers
5. The TRUNCATE TABLE operation is acceptable for the staging table (all data is replaced on each run)
