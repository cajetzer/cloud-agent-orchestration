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
    base-branch: main
  # For fix cycles: push commits to existing PR branch
  push-to-pull-request-branch:
  add-comment:
    max: 3

engine:
  id: copilot
  agent: adf-generate

tools:
  github:
  edit:
  bash: ["jq"]
---

# ADF Pipeline Generation Worker

This workflow invokes the **ADF Generate Agent** (defined in `.github/agents/adf-generate.agent.md`) to create or update Azure Data Factory pipelines.

## Workflow Context

The agent receives the following inputs from the orchestrator:
- **Issue number**: `${{ inputs.issue_number }}`
- **Issue title**: `${{ inputs.issue_title }}`
- **Issue body**: `${{ inputs.issue_body }}`
- **PR number** (if fix cycle): `${{ inputs.pr_number }}`
- **Review feedback** (if fix cycle): `${{ inputs.review_feedback }}`

## Operation Mode

The agent will automatically determine the mode based on inputs:
- **Initial Generation**: When `pr_number` is empty, create a new PR with a pipeline from scratch
- **Fix Cycle**: When `pr_number` is provided, update the existing PR to address review feedback

## Available Resources

The agent has access to:
- `templates/` directory with ADF pipeline JSON templates
- `rules/best_practices.json` for validation rules
- GitHub tools to read issues, create/update PRs, and post comments
- Edit tools to create/modify pipeline JSON files
- `jq` for JSON parsing and validation

## Required Actions (Safe Outputs)

**IMPORTANT**: This workflow runs in a sandboxed environment. To create or modify GitHub resources, you MUST call the safe-output tools via the `safeoutputs` MCP server. Simply writing files is not enough - you must explicitly call these tools.

### For Initial Generation (no `pr_number`):

1. **Create the pipeline file** using the `edit` tool to write to `pipelines/<pipeline-name>.json`

2. **Create a Pull Request** by calling the `safeoutputs` MCP tool:
   ```
   Tool: safeoutputs.create_pull_request
   Parameters:
   - title: "<descriptive title for the pipeline>"
   - body: "<PR description with Resolves #issue_number, pipeline summary, and checklist>"
   - branch: "<new-branch-name>" (e.g., "adf/pipeline-name")
   ```

3. **Add a comment** on the original issue:
   ```
   Tool: safeoutputs.add_comment
   Parameters:
   - issue_number: ${{ inputs.issue_number }}
   - body: "<message with PR link>"
   ```

### For Fix Cycle (`pr_number` provided):

1. **Update the pipeline file** using the `edit` tool

2. **Push changes** to the existing PR branch:
   ```
   Tool: safeoutputs.push_to_pull_request_branch
   Parameters:
   - pr_number: ${{ inputs.pr_number }}
   - commit_message: "fix: <description of fixes>"
   ```

3. **Add a comment** on the PR:
   ```
   Tool: safeoutputs.add_comment
   Parameters:
   - issue_number: ${{ inputs.pr_number }}
   - body: "<summary of fixes applied>"
   ```

## Workflow Steps

1. Read the issue requirements from the inputs
2. Read templates from `templates/` directory
3. Generate the pipeline JSON following best practices in `rules/best_practices.json`
4. Validate the pipeline (no hardcoded values, has retry policies, etc.)
5. **Call the appropriate safe-output tools** to create/update the PR

---

_The agent will follow the detailed instructions in `.github/agents/adf-generate.agent.md` for pipeline generation logic, and use the safe-output tools above to publish results._
