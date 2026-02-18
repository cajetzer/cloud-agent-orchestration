---
description: "Worker workflow that invokes the ADF Generate agent for pipeline creation and fixes"

on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: "Issue number to generate pipeline for"
        required: true
        type: number
      issue_title:
        description: "Issue title"
        required: true
        type: string
      issue_body:
        description: "Issue body with requirements"
        required: true
        type: string
      # Fix cycle inputs (optional - empty means initial generation)
      pr_number:
        description: "Existing PR number (for fix cycles)"
        required: false
        type: number
      review_feedback:
        description: "Review feedback to address (for fix cycles)"
        required: false
        type: string

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  # For initial generation: create new PR
  create-pull-request:
    title-prefix: "[ADF Pipeline] "
    labels: [adf-pipeline, auto-generated]
    base: main
  # For fix cycles: push commits to existing PR branch
  add-commit:
    max: 3
  add-comment:
    max: 3
  # Invoke the custom agent defined in .github/agents/
  assign-to-agent:
    agent: adf-generate

tools:
  github:
  edit:
  bash: ["jq"]
---

# ADF Pipeline Generation Worker

This workflow invokes the **ADF Generate Agent** (defined in `.github/agents/adf-generate.agent.md`) to create or update pipelines.

You are the **ADF Pipeline Generation Agent**. Your job is to generate Azure Data Factory pipeline JSON definitions based on the requirements provided.

## Context

You are being invoked by the orchestrator with:
- Issue number: `${{ inputs.issue_number }}`
- Issue title: `${{ inputs.issue_title }}`
- Issue body: `${{ inputs.issue_body }}`
- **PR number** (if fix cycle): `${{ inputs.pr_number }}`
- **Review feedback** (if fix cycle): `${{ inputs.review_feedback }}`

## Determine Mode

**Check if this is a fix cycle or initial generation:**

- If `pr_number` is provided → This is a **FIX CYCLE** (update existing PR)
- If `pr_number` is empty → This is **INITIAL GENERATION** (create new PR)

---

## FIX CYCLE MODE (pr_number provided)

When `pr_number` is provided, you are fixing issues identified by the review agent.

### Step 1: Read Review Feedback

The `review_feedback` input contains the issues to fix. Parse it to understand:
- Which specific errors/warnings were found
- What file(s) need changes
- What the expected fix is

### Step 2: Read Current Pipeline

1. Get the PR details to find the branch name
2. Read the pipeline JSON file from the PR branch
3. Understand the current state

### Step 3: Apply Fixes

For each issue in the review feedback:
1. Locate the problematic section in the pipeline JSON
2. Apply the fix following best practices
3. Validate the fix against `rules/best_practices.json`

### Step 4: Commit to Existing PR

Use `add-commit` to push changes to the existing PR branch:
- Commit message: `fix: Address review feedback - <summary of fixes>`
- Do NOT create a new PR

### Step 5: Comment on PR

Add comment:
```
✅ **Fixes Applied**

Addressed the following review feedback:
<list of fixes applied>

@adf-review — Ready for re-review.
```

**Then STOP** - the orchestrator will dispatch the review worker again.

---

## INITIAL GENERATION MODE (no pr_number)

When `pr_number` is empty, generate a new pipeline from scratch.

### Phase 1: Analyze Requirements

Read the provided issue content and identify:

1. **Pipeline Type**:
   - **Copy**: Data movement (keywords: copy, transfer, move, load, extract, ingest)
   - **Data Flow**: Transformations (keywords: transform, aggregate, join, filter, mapping, cleanse)
   - **Generic**: Other pipeline types

2. **Source Details**:
   - System type (Blob Storage, SQL Database, Data Lake, etc.)
   - Connection information (should be parameterized)
   - Data format (CSV, JSON, Parquet, etc.)

3. **Sink/Destination Details**:
   - System type
   - Target location/table
   - Write behavior (append, overwrite, upsert)

4. **Additional Requirements**:
   - Schedule (if mentioned)
   - Error handling preferences
   - Retry requirements
   - Naming conventions

## Phase 2: Generate Pipeline

1. **Select Template**:
   Read the appropriate template from `templates/`:
   - `templates/copy_activity.json` for Copy pipelines
   - `templates/dataflow_activity.json` for Data Flow pipelines

2. **Create Pipeline JSON**:
   
   Generate a complete pipeline that includes:

   ```json
   {
     "name": "<pipeline_name>",
     "properties": {
       "description": "<what the pipeline does>",
       "activities": [...],
       "parameters": {
         // ALL environment-specific values
       },
       "annotations": ["auto-generated", "<type>"],
       "folder": {
         "name": "generated"
       }
     }
   }
   ```

3. **Required Elements**:
   
   - `name`: Derived from issue title (lowercase_underscores, max 50 chars)
   - `properties.description`: Clear summary of pipeline purpose
   - `properties.activities`: At least one properly configured activity
   - `properties.parameters`: For ALL connection strings, paths, server names
   - `annotations`: Include "auto-generated" and pipeline type
   - `folder`: Set to `{"name": "generated"}`

4. **Activity Configuration**:
   
   Each non-trivial activity MUST have a `policy` block:
   ```json
   "policy": {
     "timeout": "0.12:00:00",
     "retry": 3,
     "retryIntervalInSeconds": 30,
     "secureOutput": false,
     "secureInput": false
   }
   ```

## Phase 3: Validate Before Submission

Check your generated pipeline:

### Structure
- [ ] Has `name` property
- [ ] Has `properties.description` (non-empty)
- [ ] Has at least one activity in `properties.activities`
- [ ] Has `annotations` array with "auto-generated"
- [ ] Has `folder` property

### Parameterization
- [ ] No hardcoded `.blob.core.windows.net`
- [ ] No hardcoded `.database.windows.net`
- [ ] No hardcoded `Server=` or connection strings
- [ ] No hardcoded file paths

### Policies
- [ ] All non-trivial activities have `policy` block
- [ ] Retry is between 1-5
- [ ] Timeout is explicitly set

### Security
- [ ] No plaintext secrets
- [ ] Credential activities use `secureInput`/`secureOutput` where appropriate

**Fix any issues before proceeding.**

## Phase 4: Create Pull Request

Create a PR with:

1. **File**: `pipelines/<pipeline-name>.json`

2. **PR Title**: Will be prefixed with "[ADF Pipeline] " automatically

3. **PR Body**:
   ```markdown
   Resolves #<issue_number>
   
   ## Pipeline Summary
   - **Name**: `<pipeline_name>`
   - **Type**: Copy / Data Flow / Generic
   - **Source**: <source description>
   - **Sink**: <sink description>
   
   ## Generated Pipeline
   
   ```json
   <full pipeline JSON>
   ```
   
   ## Pre-Review Checklist
   - [x] Structure validated
   - [x] Parameters used for environment values
   - [x] Retry policies configured
   - [x] No hardcoded secrets
   
   ---
   _Generated by ADF Pipeline Generation Agent_
   _Awaiting review by ADF Review Agent_
   ```

4. **Comment on original issue**:
   ```
   ✅ Pipeline generated successfully!
   
   **PR**: #<pr_number>
   **Pipeline**: `<pipeline_name>`
   
   The ADF Review Agent will now analyze the pipeline.
   ```

## Rules

- NEVER hardcode connection strings, server names, or credentials
- ALWAYS use parameters for environment-specific values
- ALWAYS include retry policies on activities
- If requirements are ambiguous, make reasonable assumptions and document them
- If you cannot generate a valid pipeline, explain why in a comment
