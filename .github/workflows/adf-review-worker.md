---
description: "Worker workflow that invokes the ADF Review agent with knowledge base access"

on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: "Original issue number (used to find the PR if pr_number not provided)"
        required: true
        type: number
      pr_number:
        description: "Pull request number to review (optional — if not provided, PR is found by issue_number)"
        required: false
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
  remove-labels:
    max: 2
  create-pull-request-review-comment:
    max: 10
  # Dispatch generate worker directly for fix cycles (avoids workflow_run limitation with GITHUB_TOKEN)
  dispatch-workflow:
    workflows: [adf-generate-worker]
    max: 1

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

Review the ADF pipeline PR for issue #${{ inputs.issue_number }}:

- **PR number (if provided)**: ${{ inputs.pr_number }}
- If the PR number above is empty or 0, find the PR using the GitHub API:
  - Search open pull requests: `GET /repos/{owner}/{repo}/pulls?state=open&labels=adf-pipeline,auto-generated`
  - Or search via: `GET /search/issues?q=repo:{owner}/{repo}+is:pr+is:open+label:adf-pipeline+label:auto-generated+Resolves+#${{ inputs.issue_number }}`
  - Select the most recently opened PR from the results

1. Determine the PR number (from input or by searching as described above)
2. Read the pipeline JSON files in `pipelines/` directory
3. Validate against `rules/best_practices.json` and check for issues in `rules/common_issues.json`
4. Post a structured review comment with your findings (errors, warnings, suggestions)
5. Add the appropriate label based on the outcome:
   - `changes-requested` if errors found
   - `approved-with-warnings` if only warnings  
   - `approved` if clean

### After labeling — handle fix cycles directly:

**If you added `changes-requested`:**

1. Use the GitHub API to list the current labels on the PR
2. Count the existing `retry-count-N` labels (e.g., `retry-count-1`, `retry-count-2`, `retry-count-3`)
3. If retry count < 3:
   - Remove the `changes-requested` label from the PR
   - Add the next `retry-count-N` label (e.g., if no retry labels exist, add `retry-count-1`; if `retry-count-1` exists, add `retry-count-2`, etc.)
   - Use the GitHub API to read issue #${{ inputs.issue_number }} to get its title and body
   - Extract the review errors from your review comment
   - Call `adf_generate_worker` to dispatch the generate worker with:
     - `issue_number`: ${{ inputs.issue_number }}
     - `issue_title`: the issue title you read
     - `issue_body`: the issue body you read
     - `pr_number`: the PR number you determined in step 1
     - `review_feedback`: the errors you found
   - Add a comment on the PR: "🔄 **Fix Cycle** - Re-dispatching generation agent to address review errors."
4. If retry count >= 3:
   - Add label `needs-human-review` to the PR
   - Add a comment: "⚠️ **Escalation** - Pipeline failed review 3 times. Human review required."

**If you added `approved-with-warnings`:**
- Add a comment: "Pipeline approved with minor suggestions. Ready for human review and merge."

**If you added `approved`:**
- Add a comment: "✅ Pipeline passed all checks. Ready for human review and merge."

If you cannot complete the task, call `noop` or `missing_data` to report why.
