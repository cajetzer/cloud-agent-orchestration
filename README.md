# ADF Agent Orchestration

Two **Copilot Coding Agent custom agents** for Azure Data Factory pipeline development — defined entirely as markdown files in `.github/agents/`. No servers, no Docker, no deployment.

| Agent | File | Purpose |
|-------|------|---------|
| **ADF Generation Agent** | `.github/agents/adf-generate.agent.md` | Generates ADF pipeline JSON from natural language descriptions in GitHub Issues |
| **ADF Review Agent** | `.github/agents/adf-review.agent.md` | Reviews generated pipelines for functionality, best practices, and common issues |

## Architecture

```
Issue created + labeled "adf-generate"
  │
  └─ Workflow: assign-adf-generate-agent.yml
     │
     └─ GraphQL API: Assign Copilot with customAgent: "adf-generate"
        │
        └─ Copilot with ADF Generate Agent starts automatically
           ├─ Reads issue requirements
           ├─ Generates ADF pipeline JSON
           └─ Opens PR with label "adf-pipeline"
              │
              └─ Workflow: assign-adf-review-agent.yml triggers
                 │
                 └─ GraphQL API: Assign Copilot with customAgent: "adf-review"
                    │
                    └─ Copilot with ADF Review Agent starts automatically
                       ├─ Reviews pipeline for correctness & best practices
                       └─ Posts findings
                          │
                          ├─ ✅ No issues → Labels PR "approved"
                          │
                          ├─ ⚠️ Warnings only → Labels PR "approved-with-warnings"
                          │
                          └─ ❌ Errors found → Workflow: handle-adf-review-results.yml
                             │
                             └─ GraphQL API: Re-assign Copilot with customAgent: "adf-generate"
                                │
                                └─ Copilot fixes issues, pushes to branch
                                   └─ Triggers review cycle again...
                                      (up to 3 retries, then escalates to human)
```

## How Agent Orchestration Works

The custom agents alone **cannot automatically orchestrate** the generation → review → fix cycle. GitHub Actions workflows are required to:

1. **Detect** when an issue needs ADF pipeline generation (labeled `adf-generate`)
2. **Trigger** the generation agent to create a PR
3. **Monitor** for the PR and automatically request the review agent
4. **Parse** review results and hand back to generation agent if issues found
5. **Count** retry cycles and escalate to human review after 3 attempts

### Workflow Files

The repository includes four GitHub Actions workflows that orchestrate this flow:

| Workflow | File | Purpose |
|----------|------|---------|
| **Issue Assignment** | `.github/workflows/assign-adf-generate-agent.yml` | Detects `adf-generate` label → Assigns generation agent to issue |
| **PR Review Assignment** | `.github/workflows/assign-adf-review-agent.yml` | Detects `adf-pipeline` PR → Assigns review agent → Tracks retry count |
| **Review Handoff** | `.github/workflows/handle-adf-review-results.yml` | Parses review comment → Routes back to generation agent (if errors) or approves (if warnings/clean) |
| **Escalation** | `.github/workflows/escalate-to-human-review.yml` | Counts retries → After 3 cycles, adds `needs-human-review` label and alerts maintainers |

### Agent Assignment Mechanisms

**This repository uses fully automated API-driven agent assignment via GitHub Actions workflows:**

**Workflow-Triggered Automatic Assignment** (orchestration)
- Workflows trigger on events (label detection, PR creation)
- Workflows call GraphQL API with `agentAssignment` input
- Specified `customAgent` is automatically assigned to the issue/PR
- Copilot starts working immediately, no manual steps needed
- State tracked via labels (`agent-in-progress`, `review-in-progress`, etc.)
- Complete generation → review → fix cycles execute without human intervention

**API Details:**
- **GraphQL Mutations Used**: `replaceActorsForAssignable`, `addAssigneesToAssignable`, `updateIssue`, `createIssue`
- **Key Parameters**: 
  - `agentAssignment` object with `customAgent` field specifies which agent to use
  - `customInstructions` field provides task-specific guidance
  - Requires `GraphQL-Features` header: `issues_copilot_assignment_api_support,coding_agent_model_selection`

## Repository Structure

```
├── .github/
│   ├── agents/
│   │   ├── adf-generate.agent.md    # Copilot custom agent — pipeline generation
│   │   └── adf-review.agent.md      # Copilot custom agent — pipeline review
│   └── workflows/
│       ├── assign-adf-generate-agent.yml      # Trigger generation agent
│       ├── assign-adf-review-agent.yml        # Trigger review agent
│       ├── handle-adf-review-results.yml      # Handoff coordination
│       └── escalate-to-human-review.yml       # Escalation after max retries
├── templates/                 # ADF pipeline JSON templates
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/                     # Review rules used by the review agent
│   └── best_practices.json
├── examples/
│   └── sample-issue.md        # Example issue to trigger the workflow
├── copilot-setup-steps.md
└── README.md
```

---

## Setup on GitHub.com — Step by Step

### Prerequisites

- A GitHub organization or personal account with **Copilot Coding Agent** enabled (requires a GitHub Copilot Enterprise or Copilot Business plan with the coding agent feature turned on)
- Repository-level permission to manage labels and settings

---

### Step 1: Create the Repository on GitHub

1. Go to [github.com/new](https://github.com/new).
2. Name the repository (e.g., `adf-agent-orchestration`).
3. Set visibility to **Private** (recommended) or Public.
4. **Do not** initialize with a README (you already have one).
5. Click **Create repository**.
6. Push this code to the new repository:

```bash
cd cloud-agent-orchestration
git remote add origin https://github.com/<your-org>/<your-repo>.git
git branch -M main
git push -u origin main
```

---

### Step 2: Enable Copilot Coding Agent on the Repository

1. Go to your **organization settings** → **Copilot** → **Policies** (or `https://github.com/organizations/<your-org>/settings/copilot/coding_agent`).
2. Enable **Copilot coding agent** for the organization (or for selected repositories).
3. In your **repository settings** → **General** → **Features**, confirm that **Issues** and **Pull Requests** are enabled.
4. Under **Settings → Copilot → Coding agent**, ensure the repo is opted in.

> **Note:** Copilot Coding Agent is available with GitHub Copilot Enterprise and GitHub Copilot Business plans. Confirm your plan has access to this feature.

---

### Step 3: Create Required Labels

The agents use labels for routing and status tracking. Create them in your repository:

1. Go to **Issues → Labels** (or navigate to `https://github.com/<owner>/<repo>/labels`).
2. Create the following labels:

| Label | Color (suggested) | Description |
|-------|-------------------|-------------|
| `adf-generate` | `#1D76DB` (blue) | Marks issues that request ADF pipeline generation |
| `adf-pipeline` | `#0E8A16` (green) | Marks PRs containing ADF pipelines |
| `changes-requested` | `#E11D48` (red) | Review agent found issues to fix |
| `approved` | `#0E8A16` (green) | Pipeline passed review |
| `approved-with-warnings` | `#F9A825` (amber) | Pipeline approved with minor suggestions |
| `needs-human-review` | `#B60205` (red) | Max review cycles reached; human needed |

---

### Step 4a: GitHub Actions Workflows for Fully Automated Agent Orchestration

The workflows fully automate the agent coordination using GitHub's GraphQL API. Once you've pushed the repo, the workflows in `.github/workflows/` are automatically enabled.

**Key workflow triggers and actions:**

| Event | Workflow | Action |
|-------|----------|--------|
| Issue labeled `adf-generate` | `assign-adf-generate-agent.yml` | Calls GraphQL API to assign Copilot with `customAgent: "adf-generate"` → Agent starts automatically |
| PR labeled `adf-pipeline` | `assign-adf-review-agent.yml` | Calls GraphQL API to assign Copilot with `customAgent: "adf-review"` → Agent reviews automatically |
| Review comment with errors | `handle-adf-review-results.yml` | Parses review, calls GraphQL API to re-assign generation agent with fixes → Automatic cycle continues |
| Retry count reaches 3 | `escalate-to-human-review.yml` | Adds `needs-human-review` label, posts escalation alert → Awaits human decision |

**No manual steps required:**

The complete flow is now fully automated:
1. Create issue with `adf-generate` label
2. Workflow automatically assigns generation agent via GraphQL API
3. Agent generates pipeline and opens PR with `adf-pipeline` label
4. Workflow automatically assigns review agent via GraphQL API
5. Agent reviews and posts findings
6. If errors: Workflow automatically re-assigns generation agent for fixes
7. If no errors: Labels PR as `approved` and ready to merge
8. If 3+ retry cycles: Escalates to human review

**API-Based Assignment:**
All agent assignments now use GraphQL mutations with `agentAssignment` input that specifies the custom agent. This eliminates the need for manual dropdown selection or `@mention` comments.

---

### Step 4b: Verify the Workflows Are Active

1. Go to your repository's **Actions** tab
2. You should see the four workflows listed:
   - `assign-adf-generate-agent.yml`
   - `assign-adf-review-agent.yml`
   - `handle-adf-review-results.yml`
   - `escalate-to-human-review.yml`
3. Workflows are enabled by default when pushed to the repo

---

### Step 5: Test the Full Automated Flow

The entire flow is now **fully automated** with no manual agent assignment needed.

#### Step 5a: Create an Issue - Workflow Does the Rest

1. **Create a new issue** labeled `adf-generate`
   - Title: `Create a copy pipeline from Azure Blob Storage to Azure SQL Database`
   - Body: Use template from [examples/sample-issue.md](examples/sample-issue.md)

#### Step 5b: Automatic Generation Agent Assignment

2. **The `assign-adf-generate-agent.yml` workflow triggers automatically:**
   - Detects the `adf-generate` label
   - Calls GraphQL API to assign Copilot with `customAgent: "adf-generate"`
   - **ADF Generation Agent starts immediately** (no human click needed)
   - Posts status comment: `🤖 ADF Pipeline Generation Agent Assigned`
   - Adds label: `agent-in-progress`
   - Agent generates the pipeline and creates a PR with label `adf-pipeline`

#### Step 5c: Automatic Review Agent Assignment

3. **The `assign-adf-review-agent.yml` workflow triggers automatically:**
   - Detects the PR with `adf-pipeline` label
   - Calls GraphQL API to assign Copilot with `customAgent: "adf-review"`
   - **ADF Review Agent starts immediately** (no human click needed)
   - Posts status comment: `🔍 ADF Pipeline Review Agent Assigned`
   - Adds labels: `review-in-progress`, `retry-count-1`
   - Agent reviews and posts detailed findings

#### Step 5d: Automatic Routing Based on Review Results

4. **The `handle-adf-review-results.yml` workflow parses review findings automatically:**

   **If errors found:**
   - Calls GraphQL API to re-assign Copilot with `customAgent: "adf-generate"`
   - Posts: `🔧 Issues Found - Routing Back to Generation Agent`
   - Labels: `changes-requested`, `generation-in-progress`
   - Increments: `retry-count-2`
   - **Generation agent automatically continues fixing** (no human clicks needed)
   - Review cycle repeats automatically

   **If warnings only:**
   - Posts approval comment
   - Labels: `approved-with-warnings`
   - Ready for human merge decision (optional fixes)

   **If no issues:**
   - Posts approval comment
   - Labels: `approved`
   - Ready to merge immediately

#### Step 5e: Automatic Escalation After Max Retries

5. **If errors persist through 3 retry cycles:**
   - The `escalate-to-human-review.yml` workflow detects `retry-count-3`
   - Posts escalation comment
   - Adds labels: `needs-human-review`, `escalated`
   - **Human intervention required:**
     - A maintainer reviews the issue requirements and PR
     - Decides whether to fix manually, clarify requirements, or close
     - Closes the issue when resolved

#### Full Automated Workflow Diagram

```
┌─ Issue labeled "adf-generate"
│
└─ Workflow: assign-adf-generate-agent.yml
   │
   ├─ GraphQL API: Assign Copilot with customAgent: "adf-generate"
   │  └─ Agent: Generate pipeline → Create PR "adf-pipeline"
   │
   └─ Workflow: assign-adf-review-agent.yml (triggers on PR label)
      │
      ├─ GraphQL API: Assign Copilot with customAgent: "adf-review"
      │  └─ Agent: Review pipeline → Post findings
      │
      └─ Workflow: handle-adf-review-results.yml (parses results)
         │
         ├─ If ERRORS:
         │  ├─ GraphQL API: Re-assign Copilot with customAgent: "adf-generate"
         │  ├─ Agent: Fix issues → Push to branch
         │  └─ Loop back to review (up to 3 retries)
         │
         ├─ If WARNINGS or CLEAN:
         │  └─ Label PR "approved" or "approved-with-warnings"
         │
         └─ If retry-count >= 3:
            └─ Workflow: escalate-to-human-review.yml
               └─ Add "needs-human-review" label → Await human decision
```

---

## Workflow Orchestration: Full Automation via GraphQL API

### Why Workflows Are Needed

Workflows handle the complete orchestration by:

1. **Detecting events** — Issue labels, PR creation
2. **Calling GraphQL APIs** — Assigning Copilot with specific custom agents via `agentAssignment` input
3. **Parsing responses** — Reading agent output to detect errors/approvals
4. **Routing handoffs** — Automatically re-assigning agents for generation → review → fix cycles
5. **Tracking state** — Using retry counter labels to enforce max cycles (3)
6. **Escalating** — Adding `needs-human-review` when max retries exceeded

### Workflow Mechanics

#### `assign-adf-generate-agent.yml`
- **Trigger**: Issue labeled `adf-generate`
- **Action**: Calls GraphQL API to assign Copilot with `customAgent: "adf-generate"` and `customInstructions`
- **Result**: ADF Generation Agent starts automatically, reads issue, generates pipeline, opens PR
- **Why needed**: Detects when generation is requested and starts agent without manual intervention

#### `assign-adf-review-agent.yml`
- **Trigger**: PR labeled `adf-pipeline` is created
- **Action**: Calls GraphQL API to assign Copilot with `customAgent: "adf-review"` and `customInstructions`
- **Result**: ADF Review Agent starts automatically, analyzes pipeline, posts findings
- **Why needed**: Automatically requests review when PR is created, without manual ticket tracking

#### `handle-adf-review-results.yml`
- **Trigger**: Comment containing `ADF Pipeline Review Results` is posted
- **Parsing**: Looks for `ERRORS:` and `❌` or `WARNINGS:` and `⚠️` in the review comment
- **Actions on errors**: Calls GraphQL API to re-assign Copilot with `customAgent: "adf-generate"` and error-fix instructions
- **Actions on warnings/clean**: Posts approval comment, adds appropriate label
- **Why needed**: Automatically detects review outcome and routes appropriately without human decision-making

#### `escalate-to-human-review.yml`
- **Trigger**: Retry count reaches 3 after fix cycles
- **Action**: Adds `needs-human-review` and `escalated` labels, posts escalation alert
- **Why needed**: Prevents infinite agent loops; enforces fallback to human judgment
- **Manual step**: Maintainer reviews and decides on next action (fix, clarify, close)

### What Works Fully Automated

✅ **Agent assignment via GraphQL API** — Custom agents assigned without manual dropdown clicks  
✅ **State tracking via labels** — (`retry-count-*`, `agent-in-progress`, `review-in-progress`, etc.)  
✅ **Review result detection** — Parsing agent comments to identify errors/warnings/clean status  
✅ **Automatic agent handoffs** — Generation → review → fix cycles continue without human intervention  
✅ **Retry cycle counting** — Enforced via labels across generation→review→fix loops  
✅ **Escalation enforcement** — Automatic handoff to human after 3 cycles  

### What Still Requires Human Judgment

⚠️ **Escalation resolution** — After max retries, maintainer must review and decide:  
  - Fix the pipeline manually  
  - Update requirements for clarity  
  - Close the issue if not feasible  

### API Implementation Details

Workflows use GitHub GraphQL API with the following approach:

```bash
gh api graphql \
  -H 'GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection' \
  -f query='mutation {
    replaceActorsForAssignable(input: {
      assignableId: "<ISSUE_OR_PR_NODE_ID>",
      actorIds: ["<COPILOT_BOT_ID>"],
      agentAssignment: {
        targetRepositoryId: "<REPO_NODE_ID>",
        baseRef: "main",
        customInstructions: "Task-specific guidance here",
        customAgent: "adf-generate"  # or "adf-review"
      }
    }) {
      assignable {
        ... on Issue { id title }
	... on PullRequest { id title }
      }
    }
  }'
```

**Key endpoints:**
- `createIssue` — Create issue and assign agent in one call
- `updateIssue` — Update issue and assign agent
- `addAssigneesToAssignable` — Add agent to existing issue/PR
- `replaceActorsForAssignable` — Replace agent assignments

**Required GraphQL headers:**
- `GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection`

---

## How the Agents Work

### `adf-generate` Agent

Defined in `.github/agents/adf-generate.agent.md`. When Copilot follows this agent:

1. Reads the issue description to understand the pipeline requirements.
2. Detects the pipeline type (Copy, Data Flow, or Generic).
3. Uses templates from `templates/` as starting points.
4. Generates a complete ADF pipeline JSON with proper structure, policies, parameters, and naming.
5. Opens a PR with the pipeline and hands off to the review agent.
6. If review feedback comes back, reads the feedback, applies fixes, and re-requests review.

### `adf-review` Agent

Defined in `.github/agents/adf-review.agent.md`. When Copilot follows this agent:

1. Reads the pipeline JSON files in the PR.
2. Checks against six categories of rules (structure, activities, policies, parameterization, naming, security).
3. Posts a formatted review with findings classified as **error**, **warning**, or **info**.
4. Decides the outcome:
   - **Errors** → hands back to `adf-generate` for fixes.
   - **Warnings only** → approves with notes.
   - **Clean** → approves.

---

## Review Rules

The review agent checks pipelines against rules defined in `rules/best_practices.json`:

| Category | What it checks |
|----------|---------------|
| **Structure** | Pipeline has `name`, `properties`, `description`, `activities`, `annotations`, and `folder` |
| **Activities** | Activities have names; Copy activities have `source`, `sink`, `inputs`, and `outputs` |
| **Policies** | Non-trivial activities have retry policies (1–5 retries) and explicit timeouts (max 7 days) |
| **Parameters** | Flags hardcoded connection strings, server names, and file paths |
| **Naming** | Names start with a letter, are under 120 characters, and are unique |
| **Security** | Flags plaintext secrets and recommends `secureInput`/`secureOutput` for sensitive activities |

Findings are categorized as **error** (blocks approval), **warning** (approved with notes), or **info** (suggestions).

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Copilot doesn't use the agent instructions | Make sure the `.github/agents/` directory is on the default branch. Verify Copilot Coding Agent is enabled for the repo. |
| Copilot doesn't pick the right agent | Mention the agent explicitly in your comment: `@adf-generate` or `@adf-review`. Use the `adf-generate` label on issues. |
| Copilot isn't available as an assignee | Confirm your org/plan has Copilot Coding Agent enabled. Check organization Copilot policies. |
| Review/fix cycle runs too long | The agents are instructed to stop after 3 round-trips and add the `needs-human-review` label. |
| Agent doesn't follow the templates | The agent instructions reference `templates/` and `rules/` directories — make sure those files exist on the branch Copilot is working from. |
