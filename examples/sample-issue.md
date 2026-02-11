# Example Issue: ADF Pipeline Request

Use this as a template when creating issues to trigger the ADF Generation Agent.

---

## Issue Title

> Create a copy pipeline from Azure Blob Storage to Azure SQL Database

## Issue Body

### Pipeline Description

I need an ADF pipeline that copies CSV files from an Azure Blob Storage container into a staging table in Azure SQL Database.

### Requirements

- **Source:** Azure Blob Storage container `raw-data/sales/`
- **Sink:** Azure SQL Database table `staging.sales_data`
- **Schedule:** Daily at 2:00 AM UTC
- **File format:** CSV with headers
- **Error handling:** Retry up to 3 times with 30-second intervals
- **Logging:** Log pipeline run status to a monitoring table

### Additional Context

- The source files follow the naming pattern `sales_YYYYMMDD.csv`
- The sink table should be truncated before each load
- This is part of the sales data warehouse ingestion process

### Labels

Add the `adf-generate` label to trigger the generation agent.

---

## What Happens Next

1. The `assign-adf-generate.yml` workflow detects the `adf-generate` label
2. It sends the issue to the ADF Generation Agent
3. The agent generates a pipeline JSON and opens a PR
4. The agent hands off to the ADF Review Agent via a `[handoff]` comment
5. The review agent checks the pipeline and either:
   - ✅ Approves it
   - ❌ Sends it back to the generation agent with feedback
6. The cycle continues until the pipeline passes review or the max round limit is hit
