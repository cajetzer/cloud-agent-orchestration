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
  # For fix cycles: push commits to existing PR branch (target "*" allows agent to provide pr_number via workflow_dispatch)
  push-to-pull-request-branch:
    target: "*"
  add-comment:
    max: 3
  add-labels:
    max: 1
  # Dispatch review worker directly after PR creation/update
  dispatch-workflow:
    workflows: [adf-review-worker]
    max: 1

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
3. Write the pipeline file to `pipelines/<pipeline-name>.json` using `edit`
4. Call `create_pull_request` with title and body (include `Resolves #${{ inputs.issue_number }}` in the body)
5. Call `add_comment` on issue #${{ inputs.issue_number }} to confirm the PR was created
6. Call `adf_review_worker` to dispatch the review worker with `issue_number: ${{ inputs.issue_number }}` (the review worker will find the PR by the issue number)

### If this is a fix cycle (`pr_number` provided and greater than 0):

1. **Switch to the PR branch first.** The workspace defaults to `main`, which does not have the pipeline files. Use `bash` to fetch and checkout the PR's head branch:
   - Run: `git fetch origin pull/${{ inputs.pr_number }}/head:pr-branch && git checkout pr-branch`
   - This ensures the existing pipeline file from the PR is in `pipelines/` before you edit it.
2. Use `bash` to read the current pipeline from `pipelines/` in the local checkout
3. Apply the review feedback changes using `edit`
4. Call `push_to_pull_request_branch` with `pull_request_number: ${{ inputs.pr_number }}` to push the fixes
5. Call `add_comment` on PR #${{ inputs.pr_number }} with a summary of fixes applied
6. Call `adf_review_worker` to dispatch the review worker with `pr_number: ${{ inputs.pr_number }}` and `issue_number: ${{ inputs.issue_number }}`

If you cannot complete the task, call `noop` or `missing_data` to explain why.
