# ADF Pipeline: Copy Blob to Data Lake Events

## Overview

This pipeline copies JSON event files from Azure Blob Storage to Azure Data Lake Storage Gen2, preserving the folder structure as part of the data lake ingestion layer.

## Pipeline Details

- **Name**: `copy_blob_to_data_lake_events`
- **Type**: Copy Activity Pipeline
- **File**: `copy_blob_to_data_lake_events.json`

## Requirements Addressed

| Requirement | Implementation |
|------------|----------------|
| **Source** | Azure Blob Storage container `incoming/events/` (parameterized as `sourceFolderPath`) |
| **Sink** | ADLS Gen2 path `bronze/events/` (parameterized as `sinkFolderPath`) |
| **Schedule** | Every 4 hours (Note: Configured via pipeline trigger, not in pipeline JSON) |
| **File format** | JSON files with pattern `events_*.json` |
| **Error handling** | Retry up to 2 times with 60-second intervals |
| **Preserve folder structure** | Yes, using `copyBehavior: "PreserveHierarchy"` |

## Pipeline Structure

### Activity: CopyEventsToDataLake

**Type**: Copy Activity

**Source Configuration**:
- Type: `BinarySource` (preserves JSON file format)
- Storage: Azure Blob Storage with recursive read
- Wildcard pattern: `events_*.json`
- Folder path: Parameterized via `@pipeline().parameters.sourceFolderPath`

**Sink Configuration**:
- Type: `BinarySink` 
- Storage: Azure Data Lake Storage Gen2
- Copy behavior: `PreserveHierarchy` (maintains folder structure)
- Folder path: Parameterized via `@pipeline().parameters.sinkFolderPath`

**Policy**:
- Timeout: 12 hours (`0.12:00:00`)
- Retry: 2 attempts
- Retry interval: 60 seconds
- Data validation: Enabled

### Parameters

| Parameter | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| `sourceFolderPath` | String | `incoming/events/` | Source folder path in Blob Storage |
| `sinkFolderPath` | String | `bronze/events/` | Destination folder path in Data Lake |
| `sourceContainerName` | String | `` | Source container name (to be configured) |
| `sinkContainerName` | String | `` | Sink container name (to be configured) |

## Best Practices Compliance

✅ **Retry Policy**: Configured with 2 retries and 60-second intervals (within 1-5 range)  
✅ **Timeout**: Explicit 12-hour timeout (under 7-day maximum)  
✅ **Naming**: Clear, descriptive names following conventions  
✅ **Parameterization**: All environment-specific values are parameterized  
✅ **Security**: No hardcoded credentials or connection strings  
✅ **Organization**: Includes description, annotations, and folder structure  

## Dataset References

This pipeline requires two datasets to be configured in Azure Data Factory:

1. **BlobStorageSourceDataset**: 
   - Linked Service: Azure Blob Storage connection
   - Parameters: folderPath

2. **DataLakeSinkDataset**:
   - Linked Service: Azure Data Lake Gen2 connection  
   - Parameters: folderPath

## Trigger Configuration

To run this pipeline every 4 hours, create a Schedule Trigger:

```json
{
  "name": "EventsIngestionTrigger",
  "properties": {
    "type": "ScheduleTrigger",
    "typeProperties": {
      "recurrence": {
        "frequency": "Hour",
        "interval": 4,
        "startTime": "2024-01-01T00:00:00Z",
        "timeZone": "UTC"
      }
    },
    "pipelines": [
      {
        "pipelineReference": {
          "referenceName": "copy_blob_to_data_lake_events",
          "type": "PipelineReference"
        }
      }
    ]
  }
}
```

## Deployment Notes

1. Ensure the source Blob Storage linked service is configured
2. Ensure the Data Lake Gen2 linked service is configured  
3. Create the required datasets (BlobStorageSourceDataset, DataLakeSinkDataset)
4. Deploy the pipeline JSON to Azure Data Factory
5. Create and enable the schedule trigger
6. Test with sample event files matching the `events_*.json` pattern

## Monitoring

The pipeline includes:
- Data consistency validation
- Standard ADF monitoring via pipeline runs
- Activity-level logging for the Copy operation

## File Location Note

**Note**: This pipeline JSON file is currently in the repository root. In a production setup, it should be organized in a `pipelines/` directory structure for better organization.
