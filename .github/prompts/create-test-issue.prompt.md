---
description: Create a unique test issue to trigger the ADF Generation Agent
---

# Goal

Create a new GitHub issue that requests an Azure Data Factory pipeline. Each time this prompt is run, **invent a new, realistic ADF pipeline scenario**. The issue must be detailed enough for the ADF Generation Agent to produce a valid pipeline JSON.

Use `gh issue create` in the `cajetzer/cloud-agent-orchestration` repo with the label `adf-generate`.

# How to generate the scenario

Pick a **unique combination** from the categories below. Do not reuse the same combination across runs. Vary complexity—some issues should be simple single-activity pipelines, others should involve multiple steps or conditional logic.

**Source types** (pick one or combine):
- Azure Blob Storage (CSV, Parquet, JSON, Avro)
- Azure Data Lake Storage Gen2
- Azure SQL Database
- Azure Cosmos DB
- REST API / HTTP endpoint
- On-premises SQL Server (via Self-Hosted IR)
- Azure Table Storage
- Amazon S3 (cross-cloud)

**Sink types** (pick one, different from source):
- Azure SQL Database / Azure Synapse Analytics
- Azure Data Lake Storage Gen2
- Azure Cosmos DB
- Azure Blob Storage
- Azure SQL Managed Instance
- Snowflake
- Azure Data Explorer (Kusto)

**Pipeline patterns** (pick one):
- Simple copy (single source → single sink)
- Multi-step ETL (copy → transform → load)
- Incremental load (watermark or change tracking)
- File-triggered processing (event-based)
- Parameterized/reusable pipeline (parent calls child)
- Data validation then conditional load (If/Switch)
- Fan-out processing (ForEach over partitions)
- Slowly changing dimension (SCD Type 1 or 2)

**Schedule variations:**
- Cron-based (daily, hourly, weekly)
- Tumbling window
- Event-triggered (blob created, message on queue)
- Manual / on-demand only

# Issue structure

Format the issue body in Markdown with these sections. Be specific and realistic—use plausible container names, table names, file patterns, and business context.

```markdown
### Pipeline Description
One or two sentences describing what the pipeline does and why.

### Requirements
- **Source:** <type, location, format details>
- **Sink:** <type, location, table/container details>
- **Schedule:** <trigger type and timing>
- **Data format:** <file format, encoding, schema notes>
- **Error handling:** <retry count, intervals, dead-letter behavior>
- **Additional:** <any extra requirements like logging, notifications, pre/post scripts>

### Additional Context
Bullet list of business context, file naming patterns, volume estimates, dependencies, or edge cases that affect implementation.
```

# Rules

1. **Title** must be a concise action phrase (e.g., "Incremental load from Cosmos DB to Synapse Analytics").
2. **Do not** copy the example from [examples/sample-issue.md](../../examples/sample-issue.md)—use it only as a structural reference.
3. **Do not** include connection strings, passwords, or real server names. Use parameter placeholders or generic names.
4. **Include** at least one detail that will exercise the review agent (e.g., a large timeout, a nuanced error-handling requirement, cross-region copy, secure inputs needed).
5. **Label:** `adf-generate`
