# Sample Issue: ADF Pipeline Request

> This is a reference example of a well-formed issue. See [`.github/prompts/create-test-issue.prompt.md`](../.github/prompts/create-test-issue.prompt.md) for the prompt that generates new, unique issues for testing.

---

**Title:** Create a copy pipeline from Azure Blob Storage to Azure SQL Database

---

### Pipeline Description

I need an ADF pipeline that copies daily CSV files from an Azure Blob Storage container into a staging table in Azure SQL Database.

### Requirements

- **Source:** Azure Blob Storage container `raw-data/sales/`
- **Sink:** Azure SQL Database table `staging.sales_data`
- **Schedule:** Daily at 2:00 AM UTC
- **Data format:** CSV with headers, UTF-8 encoding
- **Error handling:** Retry up to 3 times with 30-second intervals
- **Additional:** Log pipeline run status to a monitoring table

### Additional Context

- Source files follow the naming pattern `sales_YYYYMMDD.csv`
- The sink table should be truncated before each load
- Part of the sales data warehouse ingestion process
- Expected volume: ~500K rows / ~50 MB per file
