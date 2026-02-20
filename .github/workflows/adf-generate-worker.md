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
  bash: ["jq", "mkdir"]
---

# ADF Pipeline Generation Worker

Generate an Azure Data Factory pipeline based on the issue requirements.

## Task

**CRITICAL: You must actually invoke the safe-output tools — do not just describe what you would do.**

All required information is already provided below — do NOT re-read the issue or explore the repository structure via GitHub API.

**Issue**: #${{ inputs.issue_number }} — "${{ inputs.issue_title }}"

**Requirements**:
${{ inputs.issue_body }}

**Fix cycle PR** (if provided): #${{ inputs.pr_number }}
**Review feedback** (if fix cycle): ${{ inputs.review_feedback }}

### If this is initial generation (no `pr_number`):

1. Use `bash` to read `templates/copy_activity.json` or `templates/dataflow_activity.json` and `rules/best_practices.json` from the local checkout
2. Generate the complete pipeline JSON (use local tools only — no GitHub API reads needed)
3. Use `bash` to create the output directory: `mkdir -p pipelines`
4. Write the pipeline file to `pipelines/<pipeline-name>.json` using `edit`
5. Call `create_pull_request` with title and body (include `Resolves #${{ inputs.issue_number }}` in the body)
6. Call `add_comment` on issue #${{ inputs.issue_number }} to confirm the PR was created

### If this is a fix cycle (`pr_number` provided):

1. Use `bash` to read the current pipeline from `pipelines/` in the local checkout
2. Apply the review feedback changes using `edit`
3. Call `push_to_pull_request_branch` to push the fixes
4. Call `add_comment` on PR #${{ inputs.pr_number }} with a summary of fixes applied

If you cannot complete the task, call `noop` or `missing_data` to explain why.
