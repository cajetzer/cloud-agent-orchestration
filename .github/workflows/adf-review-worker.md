---
description: "Worker workflow that invokes the ADF Review agent with knowledge base access"

on:
  workflow_dispatch:
    inputs:
      pr_number:
        description: "Pull request number to review"
        required: true
        type: number
      issue_number:
        description: "Original issue number"
        required: true
        type: number

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  add-comment:
    max: 3
  add-labels:
    max: 3
  create-pull-request-review-comment:
    max: 10

engine:
  id: copilot
  agent: adf-review

tools:
  github:
  bash: ["jq", "cat"]
---

# ADF Pipeline Review Worker

Review the Azure Data Factory pipeline in the specified pull request.

## Task

**CRITICAL: You must actually invoke the safe-output tools — do not just describe what you would do.**

Review PR #${{ inputs.pr_number }} (related to issue #${{ inputs.issue_number }}):

1. Read the pipeline JSON files in `pipelines/` directory
2. Validate against `rules/best_practices.json` and check for issues in `rules/common_issues.json`
3. Post a structured review comment with your findings (errors, warnings, suggestions)
4. Add the appropriate label based on the outcome:
   - `changes-requested` if errors found
   - `approved-with-warnings` if only warnings  
   - `approved` if clean

If you cannot complete the task, call `noop` or `missing_data` to report why.
