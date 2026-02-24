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
    workflows: [adf-generate-worker]
    max: 2
  add-comment:
    max: 3
  add-labels:
    max: 3
  remove-labels:
    max: 3

tools:
  github:
---

# ADF Pipeline Orchestrator

Validate ADF pipeline generation requests and dispatch the generation worker.

> **Architecture Note**: This orchestrator handles only the initial entry point (issue validation + dispatch).
> The workers handle subsequent handoffs directly:
> - Generate worker → dispatches review worker after creating/updating the PR
> - Review worker → dispatches generate worker for fix cycles (up to 3 retries), then escalates

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
- Review will follow automatically

_Track progress in the Actions tab._
```

Add label `generation-in-progress`.

**Stop here.** The generation worker runs asynchronously. When it completes, it will directly dispatch the review worker. The review worker handles fix cycles and final outcomes without needing the orchestrator to be re-triggered.

If the generation worker fails, the gh-aw framework automatically creates a failure issue labeled `agentic-workflows` — no additional error handling is needed in this orchestrator.

---

## Orchestration Flow

```
[Issue Labeled]
      │
      ▼
[Orchestrator validates & dispatches generate worker]
      │
      ▼
[Generate Worker runs → creates PR → directly dispatches review worker]
      │
      ▼
[Review Worker runs → posts findings → labels PR]
      │
      ├─ approved / approved-with-warnings → comments "Ready for review" → DONE
      │
      └─ changes-requested + retry < 3 → directly dispatches generate worker with feedback
                  │
                  ▼
        [Generate Worker applies fixes → dispatches review worker]
                  │
                  ▼
             [... repeat up to 3 cycles ...]
                  │
                  └─ retry >= 3 → adds needs-human-review label → ESCALATE
```

## Error Handling

If any worker fails:
- The gh-aw framework automatically creates a failure issue labeled `agentic-workflows`
- Check the Actions tab for detailed logs
