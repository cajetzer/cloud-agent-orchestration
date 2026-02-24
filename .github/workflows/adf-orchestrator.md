---
description: "Orchestrates ADF pipeline generation and review using separate worker agents"

on:
  issues:
    types: [labeled]
  pull_request:
    types: [opened, labeled]

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  dispatch-workflow:
    workflows: [adf-generate-worker, adf-review-worker]
    max: 5
  add-comment:
    max: 3
  add-labels:
    max: 3

tools:
  github:
---

# ADF Pipeline Orchestrator

Coordinate the ADF pipeline generation and review process by dispatching work to specialized worker agents.

This workflow is triggered by two different events. Handle each event differently:

---

## When triggered by an `issues` event (issue labeled)

### Step 1: Validate Issue

1. Check the issue has label `adf-generate` (the label used to trigger pipeline generation in this repo) or `adf-pipeline`
2. Read the issue title and body
3. Validate it contains pipeline requirements (source, sink, or transformation description)

If requirements are missing or unclear:
- Add comment asking for clarification
- Add label `needs-clarification`
- Stop orchestration

### Step 2: Dispatch Generation Worker

Dispatch the `adf-generate-worker` workflow with inputs:
- `issue_number`: The issue number
- `issue_title`: The issue title
- `issue_body`: The issue body content

Add comment on issue:
```
🚀 **Pipeline Generation Started**

Dispatching to ADF Generation Agent...
- Reading requirements from this issue
- Will generate pipeline JSON using templates
- Will open a PR when complete

_Track progress in the Actions tab._
```

Add label `generation-in-progress`.

**Stop here.** The generation worker runs asynchronously. When it creates a PR labeled `adf-pipeline` and `auto-generated`, this orchestrator will be re-triggered by the `pull_request: labeled` event to continue the process.

---

## When triggered by a `pull_request` event (PR opened or labeled)

### Step 3: Identify the PR and Dispatch Review Worker

1. Check the pull request has label `adf-pipeline` and label `auto-generated`.
2. If either label is missing, do nothing and stop — this PR was not created by the generation worker.
3. Check whether the pull request already has any review state labels:
   - `review-in-progress`, `changes-requested`, `approved-with-warnings`, or `approved`
   - If any of these are present, **do not** dispatch `adf-review-worker` again — proceed directly to **Step 4: Handle Review Results** below.
4. Extract the issue number from the PR body (look for `Resolves #<N>` or `Closes #<N>`)
5. Dispatch the `adf-review-worker` workflow with inputs:
   - `pr_number`: The pull request number
   - `issue_number`: The issue number extracted from the PR body

Add comment on the PR:
```
🔍 **Pipeline Review Started**

Dispatching to ADF Review Agent...
- Will validate against best practices
- Will check common issues knowledge base
- Will post detailed findings

_Track progress in the Actions tab._
```

Add label `review-in-progress` to the PR.

### Step 4: Handle Review Results (re-triggered after review completes)

After the review worker completes, the PR will have a review outcome label. If this orchestrator run is triggered on a PR that already has a review outcome label, handle it:

**If label `changes-requested` is present:**
1. Read the latest review comment to extract the specific errors
2. Count `retry-count-N` labels on the PR to determine the current retry number
3. If retry count < 3:
   - Add the next `retry-count-N` label
   - Look up the linked issue to get its title and body
   - Re-dispatch `adf-generate-worker` with fix inputs:
     - `issue_number`: Original issue number
     - `issue_title`: Original issue title
     - `issue_body`: Original issue body
     - `pr_number`: The existing PR number
     - `review_feedback`: The review errors extracted from the review comment
   - Comment on PR: "🔄 **Fix Cycle {N}/3** - Re-dispatching generation agent to address review errors."
4. If retry count >= 3:
   - Add label `needs-human-review`
   - Comment: "⚠️ **Escalation** - Pipeline failed review 3 times. Human review required."

**If label `approved-with-warnings` is present:**
- Comment: "Pipeline approved with minor suggestions. Ready for human review."

**If label `approved` is present:**
- Comment: "✅ Pipeline passed all checks. Ready for human review."

---

## Orchestration State Machine

```
         ┌──────────────────────────────────────────────────────┐
         │                                                      │
         ▼                                                      │
   [Issue Labeled]                                              │
         │                                                      │
         ▼                                                      │
   [Dispatch Generate]──────►[PR Created+Labeled]──────►[Dispatch Review]
          (stop, wait for PR)   (re-triggers orchestrator)       │
                                                      ┌──────────┼──────────────┐
                                                      │          │              │
                                                      ▼          ▼              ▼
                                                 [approved] [warnings only] [errors found]
                                                      │          │              │
                                                      ▼          ▼              │
                                                  [DONE]  [approved-with-    retry < 3?
                                                           warnings]            │
                                                               │          yes   │   no
                                                               ▼          ──────┘   ▼
                                                           [DONE]    [Re-dispatch] [needs-human-review]
                                                                      Generate        │
                                                                      with feedback   ▼
                                                                            │     [ESCALATE]
                                                                            └──► (back to review)
```

## Error Handling

If any worker fails:
- Add label `workflow-error`
- Comment with error details
- Tag maintainers for manual intervention
