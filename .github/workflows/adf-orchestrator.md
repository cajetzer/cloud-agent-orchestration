---
description: "Orchestrates ADF pipeline generation and review using separate worker agents"

on:
  issues:
    types: [labeled]

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

## Activation

Only process issues that have the `adf-pipeline` label.

## Orchestration Flow

```
Issue (adf-pipeline label)
    │
    ├─► Dispatch: adf-generate-worker
    │       │
    │       └─► Creates pipeline JSON, opens draft PR
    │
    └─► When PR ready, Dispatch: adf-review-worker
            │
            └─► Reviews pipeline, posts findings
                    │
                    ├─► If errors: Comment with fix instructions
                    │
                    └─► If clean: Label PR as approved
```

## Step 1: Validate Issue

1. Check the issue has label `adf-pipeline`
2. Read the issue title and body
3. Validate it contains pipeline requirements (source, sink, or transformation description)

If requirements are missing or unclear:
- Add comment asking for clarification
- Add label `needs-clarification`
- Stop orchestration

## Step 2: Dispatch Generation Worker

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

## Step 3: Monitor for PR Creation

The generation worker will create a PR. When a PR is created that:
- References this issue (`Resolves #<issue_number>`)
- Has label `adf-pipeline`

Then dispatch the review worker.

## Step 4: Dispatch Review Worker

Dispatch the `adf-review-worker` workflow with inputs:
- `pr_number`: The pull request number
- `issue_number`: The original issue number

Add comment on PR:
```
🔍 **Pipeline Review Started**

Dispatching to ADF Review Agent...
- Will validate against best practices
- Will check common issues knowledge base
- Will post detailed findings

_Track progress in the Actions tab._
```

Remove label `generation-in-progress`, add label `review-in-progress`.

## Step 5: Handle Review Results

Based on review worker output:

**If errors found (label: `changes-requested`):**
1. Read the review comment to extract the specific errors
2. Track retry count (check for `retry-count-N` labels)
3. If retry count < 3:
   - Increment retry label (`retry-count-1` → `retry-count-2`)
   - Re-dispatch `adf-generate-worker` with fix inputs:
     - `issue_number`: Original issue
     - `issue_title`: Original title
     - `issue_body`: Original body
     - `pr_number`: **The existing PR number**
     - `review_feedback`: **The review errors to fix**
   - Comment: "🔄 **Fix Cycle {N}/3** - Re-dispatching generation agent to address errors."
4. If retry count >= 3:
   - Add label `needs-human-review`
   - Comment: "⚠️ **Escalation** - Pipeline failed review 3 times. Human review required."

**If warnings only (label: `approved-with-warnings`):**
- Comment: "Pipeline approved with minor suggestions. Ready for human review."

**If clean (label: `approved`):**
- Comment: "✅ Pipeline passed all checks. Ready for merge."

## Orchestration State Machine

```
         ┌──────────────────────────────────────────────────────┐
         │                                                      │
         ▼                                                      │
   [Issue Created]                                              │
         │                                                      │
         ▼                                                      │
   [Dispatch Generate]──────►[PR Created]──────►[Dispatch Review]
                                                      │
                              ┌────────────────────────┼─────────────────┐
                              │                        │                 │
                              ▼                        ▼                 ▼
                         [approved]           [warnings only]      [errors found]
                              │                        │                 │
                              ▼                        ▼                 │
                          [DONE]              [approved-with-warnings]   │
                                                      │                 │
                                                      ▼                 │
                                                   [DONE]               │
                                                                        │
                              ┌──────────────────────────────────────────┘
                              │
                              ▼
                        retry < 3? ──yes──► [Re-dispatch Generate with feedback]
                              │                        │
                              no                       │
                              │                        └───────────────────┘
                              ▼                              (back to review)
                    [needs-human-review]
                              │
                              ▼
                          [ESCALATE]
```

## Error Handling

If any worker fails:
- Add label `workflow-error`
- Comment with error details
- Tag maintainers for manual intervention
