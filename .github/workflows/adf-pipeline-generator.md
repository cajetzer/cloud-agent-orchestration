---
description: "Generates ADF pipeline JSON from issue requirements, self-reviews against best practices, and creates a PR"

on:
  issues:
    types: [labeled]

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  create-pull-request:
    title-prefix: "[ADF Pipeline] "
    labels: [adf-pipeline]
    base: main
  add-comment:
    max: 2
  add-labels:
    max: 3

tools:
  github:
  edit:
  bash: ["jq"]
---

# ADF Pipeline Generator

Generate an Azure Data Factory pipeline based on the issue requirements, self-review it against best practices, and create a pull request.

## Activation

Only process issues that have the `adf-pipeline` label.

## Phase 1: Understand Requirements

1. Read the issue title and body carefully
2. Identify the pipeline type:
   - **Copy**: Data movement between sources (look for keywords: copy, transfer, move, load, extract)
   - **Data Flow**: Transformations (look for keywords: transform, aggregate, join, filter, mapping)
   - **Generic**: Other pipeline types
3. Extract key details:
   - Source system and configuration
   - Sink/destination system and configuration  
   - Schedule requirements (if mentioned)
   - Error handling preferences
   - Any specific naming requirements

## Phase 2: Generate Pipeline

1. Read the appropriate template from `templates/`:
   - `templates/copy_activity.json` for Copy pipelines
   - `templates/dataflow_activity.json` for Data Flow pipelines

2. Generate the pipeline JSON file. The pipeline MUST include:
   - `name`: Descriptive name derived from issue title (lowercase_underscores, max 50 chars)
   - `properties.description`: Summary of what the pipeline does
   - `properties.activities`: At least one properly configured activity
   - `properties.parameters`: For ALL environment-specific values (connection strings, paths, credentials)
   - `annotations`: Array including "auto-generated"
   - `folder`: Object with name property (use "generated")

3. For each non-trivial activity, include a `policy` block with:
   - `timeout`: Explicit value, max "7.00:00:00"
   - `retry`: Between 1 and 5
   - `retryIntervalInSeconds`: Reasonable interval (e.g., 30)

4. NEVER hardcode:
   - Connection strings
   - Server names or URLs
   - File paths
   - Credentials or secrets

## Phase 3: Self-Review

Before creating the PR, validate the pipeline against `rules/best_practices.json`:

### Structure Checks
- [ ] Has `name` property
- [ ] Has `properties.description` (non-empty)
- [ ] Has at least one activity
- [ ] Has `annotations` array
- [ ] Has `folder` property

### Policy Checks  
- [ ] All non-trivial activities have `policy` block
- [ ] Retry count is 1-5
- [ ] Timeout is set and ≤ 7 days

### Parameterization Checks
- [ ] No hardcoded `.blob.core.windows.net`
- [ ] No hardcoded `.database.windows.net`
- [ ] No hardcoded `Server=` or `Initial Catalog=`
- [ ] No hardcoded file paths like `C:\`

### Security Checks
- [ ] No plaintext secrets (password, secret, apikey, token)
- [ ] Credential-handling activities use `secureInput`/`secureOutput`

### Naming Checks
- [ ] Names start with a letter
- [ ] Names under 120 characters
- [ ] Activity names are unique

If any check fails, fix the issue before proceeding.

## Phase 4: Create Pull Request

Create a pull request with:

1. **Files to include**:
   - `pipelines/<pipeline-name>.json` - The generated pipeline

2. **PR body** should contain:
   - `Resolves #<issue-number>`
   - Summary of what the pipeline does
   - Source and sink description
   - Self-review results (checklist showing what was verified)
   - The full pipeline JSON in a code block

3. **Comment on the issue** with a summary:
   ```
   ✅ Pipeline generated and PR created!
   
   **Pipeline**: `<pipeline-name>`
   **Type**: Copy / Data Flow / Generic
   **PR**: #<pr-number>
   
   The pipeline has been self-reviewed against ADF best practices.
   ```

## Error Handling

If requirements are ambiguous:
- Make reasonable assumptions
- Document assumptions in PR description
- Add label `needs-clarification` if critical information is missing

If pipeline cannot be generated:
- Comment on issue explaining the blocker
- Add label `needs-human-review`
