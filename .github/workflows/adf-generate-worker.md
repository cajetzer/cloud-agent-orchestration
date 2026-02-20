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

Generate an Azure Data Factory pipeline based on the issue requirements.

## Task

**CRITICAL: You must actually invoke the safe-output tools — do not just describe what you would do.**

Based on the inputs provided:
- **Issue**: #${{ inputs.issue_number }} — "${{ inputs.issue_title }}"
- **Requirements**: ${{ inputs.issue_body }}
- **Fix cycle PR** (if provided): #${{ inputs.pr_number }}
- **Review feedback** (if fix cycle): ${{ inputs.review_feedback }}

### If this is initial generation (no `pr_number`):
1. Generate the pipeline JSON following templates in `templates/` and rules in `rules/best_practices.json`
2. Write the pipeline to `pipelines/<pipeline-name>.json`
3. Create a pull request with the pipeline (include `Resolves #${{ inputs.issue_number }}` in the body)
4. Comment on the issue to confirm the PR was created

### If this is a fix cycle (`pr_number` provided):
1. Read the review feedback and update the pipeline accordingly
2. Push the changes to the existing PR branch
3. Comment on the PR with a summary of fixes applied

If you cannot complete the task, call `noop` or `missing_data` to report why.
