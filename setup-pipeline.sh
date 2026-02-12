#!/bin/bash
# Helper script to create pipelines directory and the pipeline JSON file
# Run this script from the repository root

mkdir -p pipelines

cat > pipelines/copy_blob_to_sql_sales_data.json << 'EOF'
{
  "name": "copy_blob_to_sql_sales_data",
  "properties": {
    "description": "Copies CSV sales data from Azure Blob Storage (raw-data/sales/) to Azure SQL Database staging table (staging.sales_data). Files follow pattern sales_YYYYMMDD.csv. Table is truncated before load. Scheduled daily at 2:00 AM UTC.",
    "activities": [
      {
        "name": "CopySalesDataToStaging",
        "type": "Copy",
        "dependsOn": [],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 3,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "userProperties": [
          {
            "name": "Source",
            "value": "@{concat(pipeline().parameters.sourceBlobContainer, '/', pipeline().parameters.sourceFolderPath)}"
          },
          {
            "name": "Destination",
            "value": "@{concat(pipeline().parameters.sinkDatabaseName, '.', pipeline().parameters.sinkSchemaName, '.', pipeline().parameters.sinkTableName)}"
          }
        ],
        "typeProperties": {
          "source": {
            "type": "DelimitedTextSource",
            "storeSettings": {
              "type": "AzureBlobStorageReadSettings",
              "recursive": false,
              "wildcardFolderPath": "@pipeline().parameters.sourceFolderPath",
              "wildcardFileName": "@pipeline().parameters.sourceFilePattern",
              "enablePartitionDiscovery": false
            },
            "formatSettings": {
              "type": "DelimitedTextReadSettings",
              "skipLineCount": 0,
              "firstRowAsHeader": true
            }
          },
          "sink": {
            "type": "AzureSqlSink",
            "preCopyScript": "@{concat('TRUNCATE TABLE ', pipeline().parameters.sinkSchemaName, '.', pipeline().parameters.sinkTableName)}",
            "writeBatchSize": 10000,
            "writeBatchTimeout": "00:30:00",
            "disableMetricsCollection": false
          },
          "enableStaging": false,
          "translator": {
            "type": "TabularTranslator",
            "typeConversion": true,
            "typeConversionSettings": {
              "allowDataTruncation": true,
              "treatBooleanAsNumber": false
            }
          }
        },
        "inputs": [
          {
            "referenceName": "@pipeline().parameters.sourceBlobDatasetName",
            "type": "DatasetReference",
            "parameters": {
              "containerName": "@pipeline().parameters.sourceBlobContainer",
              "folderPath": "@pipeline().parameters.sourceFolderPath"
            }
          }
        ],
        "outputs": [
          {
            "referenceName": "@pipeline().parameters.sinkSqlDatasetName",
            "type": "DatasetReference",
            "parameters": {
              "schemaName": "@pipeline().parameters.sinkSchemaName",
              "tableName": "@pipeline().parameters.sinkTableName"
            }
          }
        ]
      }
    ],
    "parameters": {
      "sourceBlobContainer": {
        "type": "String",
        "defaultValue": "raw-data"
      },
      "sourceFolderPath": {
        "type": "String",
        "defaultValue": "sales/"
      },
      "sourceFilePattern": {
        "type": "String",
        "defaultValue": "sales_*.csv"
      },
      "sourceBlobDatasetName": {
        "type": "String",
        "defaultValue": "SourceBlobDataset"
      },
      "sinkDatabaseName": {
        "type": "String",
        "defaultValue": "SalesWarehouse"
      },
      "sinkSchemaName": {
        "type": "String",
        "defaultValue": "staging"
      },
      "sinkTableName": {
        "type": "String",
        "defaultValue": "sales_data"
      },
      "sinkSqlDatasetName": {
        "type": "String",
        "defaultValue": "SinkAzureSqlDataset"
      }
    },
    "annotations": [
      "auto-generated",
      "copy-pipeline",
      "sales-data",
      "blob-to-sql",
      "daily-ingestion"
    ],
    "folder": {
      "name": "generated"
    }
  }
}
EOF

echo "✅ Pipeline JSON file created at pipelines/copy_blob_to_sql_sales_data.json"
echo ""
echo "Pipeline Details:"
echo "  Name: copy_blob_to_sql_sales_data"
echo "  Type: Copy Activity (Blob Storage → SQL Database)"
echo "  Source: Azure Blob Storage (raw-data/sales/)"
echo "  Sink: Azure SQL Database (staging.sales_data)"
echo "  Features: CSV with headers, pre-copy truncate, retry policy"
echo ""
echo "Next steps:"
echo "  1. Review the JSON file: cat pipelines/copy_blob_to_sql_sales_data.json"
echo "  2. Validate JSON syntax: python -m json.tool pipelines/copy_blob_to_sql_sales_data.json"
echo "  3. Import to ADF Studio"
echo "  4. Configure linked services and datasets"
echo "  5. Create schedule trigger (daily at 2:00 AM UTC)"
echo ""
echo "For detailed instructions, see PIPELINE_README.md"
