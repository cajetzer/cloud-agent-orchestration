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

engine:
  id: adf-generate

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

## Expected Output

### For Initial Generation:
- A new PR created with the generated pipeline JSON in `pipelines/<pipeline-name>.json`
- PR description with pipeline summary and self-review checklist
- Comment on the original issue with PR link

### For Fix Cycle:
- Commits pushed to the existing PR branch with fixes applied
- Comment on the PR summarizing the fixes

---

_The agent will follow the detailed instructions in `.github/agents/adf-generate.agent.md` to complete these tasks._
