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
     │ (Posts comment, attempts Copilot assignment)
     │
     └─ User opens issue in Copilot Workspace
        │ (Selects "adf-generate" agent from dropdown)
        │
        └─ Copilot with ADF Generate Agent works on issue
           ├─ Reads issue requirements
           ├─ Generates ADF pipeline JSON
           └─ Opens PR with label "adf-pipeline"
              │
              └─ Workflow: assign-adf-review-agent.yml triggers
                 │ (Attempts to assign review agent)
                 │
                 └─ User opens PR in Copilot Workspace (optional)
                    │ (Selects "adf-review" agent from dropdown)
                    │
                    └─ Copilot with ADF Review Agent reviews PR
                       ├─ Reviews pipeline for correctness & best practices
                       └─ Posts findings
                          │
                          ├─ ✅ No issues → Labels PR "approved"
                          │
                          ├─ ⚠️ Warnings only → Labels PR "approved-with-warnings"
                          │
                          └─ ❌ Errors found → Workflow: handle-adf-review-results.yml
                             │ (Parses errors, posts instructions)
                             │
                             └─ User re-opens PR in Workspace with "adf-generate"
                                │
                                └─ Copilot fixes issues, pushes to branch
                                   └─ Triggers review cycle again...
                                      (up to 3 retries, then escalates to human)
```

## How Agent Orchestration Works

Custom agents must be **manually triggered** through GitHub Copilot Workspace UI. GitHub Actions workflows **facilitate** the orchestration by:

1. **Detecting** when an issue needs ADF pipeline generation (labeled `adf-generate`)
2. **Posting instructions** and attempting to assign Copilot to the issue
3. **Monitoring** for the PR and attempting to assign the review agent
4. **Parsing** review results and posting clear instructions for fix cycles
5. **Counting** retry cycles and escalating to human review after 3 attempts

### Workflow Files

The repository includes four GitHub Actions workflows that orchestrate this flow:

| Workflow | File | Purpose |
|----------|------|---------|
| **Issue Assignment** | `.github/workflows/assign-adf-generate-agent.yml` | Detects `adf-generate` label → Assigns generation agent to issue |
| **PR Review Assignment** | `.github/workflows/assign-adf-review-agent.yml` | Detects `adf-pipeline` PR → Assigns review agent → Tracks retry count |
| **Review Handoff** | `.github/workflows/handle-adf-review-results.yml` | Parses review comment → Routes back to generation agent (if errors) or approves (if warnings/clean) |
| **Escalation** | `.github/workflows/escalate-to-human-review.yml` | Counts retries → After 3 cycles, adds `needs-human-review` label and alerts maintainers |

### Agent Assignment Mechanisms

**This repository uses a hybrid approach combining GitHub Actions automation with Copilot Workspace manual triggering:**

**Workflow Automation** (labels, comments, state tracking)
- Workflows trigger on events (label detection, PR creation)
- Workflows attempt to assign Copilot via GraphQL API (when API is available)
- Workflows post clear instructions and guidance for next steps
- State tracked via labels (`agent-in-progress`, `review-in-progress`, `retry-count-N`)
- Automated parsing of review results and routing logic

**Manual Copilot Workspace Trigger** (actual agent execution)
- User opens issue/PR in Copilot Workspace (click "Open in Workspace" button)
- User selects the appropriate custom agent from dropdown (`adf-generate` or `adf-review`)
- Copilot reads the agent instructions from `.github/agents/` directory
- Agent executes the task following its defined instructions
- Agent creates/updates PRs and posts comments with results

**Why Both Are Needed:**
- GitHub Copilot Workspace requires manual triggering from the UI
- Workflows automate the orchestration logic (routing, retry counting, escalation)
- This combination enables a mostly-automated generation → review → fix cycle
- Clear workflow comments guide users on which agent to select at each step

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

### Step 5: Test the Agent Orchestration Flow

The flow combines workflow automation with manual Copilot Workspace triggers.

#### Step 5a: Create an Issue

1. **Create a new issue** with the label `adf-generate`
   - Title: `Create a copy pipeline from Azure Blob Storage to Azure SQL Database`
   - Body: Use the template from [examples/sample-issue.md](examples/sample-issue.md)
   - Add label: `adf-generate`

#### Step 5b: Workflow Triggers and You Open in Workspace

2. **The `assign-adf-generate-agent.yml` workflow triggers automatically:**
   - Detects the `adf-generate` label
   - Attempts to assign Copilot via GraphQL API
   - Posts comment: `🤖 ADF Pipeline Generation Agent Assigned` with instructions
   - Adds label: `agent-in-progress`
   
3. **You trigger the agent manually:**
   - Click the **"Open in Workspace"** button on the issue (top right corner)
   - In Copilot Workspace, select **"adf-generate"** from the custom agents dropdown
   - Copilot reads the agent instructions and starts working
   - Agent generates the pipeline JSON and creates a PR
   - Agent adds the label `adf-pipeline` to the PR

#### Step 5c: Review Agent Assignment

4. **The `assign-adf-review-agent.yml` workflow triggers on PR creation:**
   - Detects the `adf-pipeline` label on the new PR
   - Attempts to assign Copilot for review
   - Posts comment: `🔍 ADF Pipeline Review Agent Assigned` with instructions
   - Adds labels: `review-in-progress`, `retry-count-1`

5. **You trigger the review agent manually:**
   - Go to the PR created by the generation agent
   - Click **"Open in Workspace"** button on the PR
   - Select **"adf-review"** from the custom agents dropdown
   - Review agent analyzes the pipeline and posts findings

#### Step 5d: Automated Routing Based on Review Results

6. **The `handle-adf-review-results.yml` workflow parses the review automatically:**

   **If errors found:**
   - Workflow parses the review comment for `ERRORS:` section
   - Posts: `🔧 Issues Found - Routing Back to Generation Agent`
   - Labels: `changes-requested`, `generation-in-progress`
   - Increments: `retry-count-2`
   - **You re-open the PR in Workspace** and select `adf-generate` to fix
   - Generation agent reads the review feedback and fixes issues
   - Review cycle can repeat (up to 3 times)

   **If warnings only:**
   - Workflow posts approval comment
   - Labels: `approved-with-warnings`
   - PR is ready for human review and merge

   **If no issues:**
   - Workflow posts approval comment
   - Labels: `approved`
   - PR is ready to merge

#### Step 5e: Automatic Escalation After Max Retries

7. **If errors persist after 3 review cycles:**
   - The `escalate-to-human-review.yml` workflow detects `retry-count-3`
   - Posts escalation comment with context
   - Adds labels: `needs-human-review`, `escalated`
   - **Human maintainer** reviews the requirements and PR
   - Decides whether to fix manually, clarify requirements, or close

#### Workflow Diagram

```
┌─ Issue labeled "adf-generate"
│
└─ Workflow: Posts instructions → YOU open in Workspace
   │
   ├─ Select "adf-generate" agent
   │  └─ Agent: Generate pipeline → Create PR with "adf-pipeline" label
   │
   └─ Workflow: Detects PR, posts instructions
      │
      ├─ YOU open PR in Workspace → Select "adf-review" agent
      │  └─ Agent: Review pipeline → Post findings
      │
      └─ Workflow: Parses review results automatically
         │
         ├─ If ERRORS found:
         │  ├─ Posts fix instructions
         │  ├─ YOU re-open in Workspace → Select "adf-generate"
         │  ├─ Agent: Fix issues → Push to branch
         │  └─ Loop back to review (up to 3 retries)
         │
         ├─ If WARNINGS only:
         │  └─ Label "approved-with-warnings" → Human merge decision
         │
         ├─ If CLEAN:
         │  └─ Label "approved" → Ready to merge
         │
         └─ If retry-count >= 3:
            └─ Workflow: Escalate to human review
```

---

## Workflow Orchestration: Hybrid Automation + Manual Triggers

### Why Workflows Are Needed

Workflows provide the orchestration logic while Copilot Workspace provides the execution:

1. **Detecting events** — Issue labels, PR creation, review comments
2. **Attempting Copilot assignment** — Tries to assign via GraphQL API (gracefully fails if unavailable)
3. **Posting clear instructions** — Guides users on which agent to select in Workspace
4. **Parsing responses** — Reading agent output to detect errors/approvals
5. **Routing handoffs** — Automatically determining next steps and posting instructions
6. **Tracking state** — Using retry counter labels to enforce max cycles (3)
7. **Escalating** — Adding `needs-human-review` when max retries exceeded

### Workflow Mechanics

#### `assign-adf-generate-agent.yml`
- **Trigger**: Issue labeled `adf-generate`
- **Actions**: 
  - Attempts GraphQL API Copilot assignment (may not be supported yet)
  - Posts clear instructions for opening issue in Copilot Workspace
  - Adds `agent-in-progress` label for state tracking
- **User action**: Open issue in Workspace, select "adf-generate" agent
- **Why needed**: Detects when generation is requested and guides user to correct agent

#### `assign-adf-review-agent.yml`
- **Trigger**: PR labeled `adf-pipeline` is created or updated
- **Actions**:
  - Attempts GraphQL API Copilot assignment (may not be supported yet)
  - Posts instructions for opening PR in Copilot Workspace
  - Adds `review-in-progress` and `retry-count-1` labels
- **User action**: Open PR in Workspace, select "adf-review" agent
- **Why needed**: Automatically detects PRs needing review and guides user

#### `handle-adf-review-results.yml`
- **Trigger**: Comment containing `ADF Pipeline Review Results` is posted
- **Parsing**: Looks for `ERRORS:` and `❌` or `WARNINGS:` and `⚠️` in the review comment
- **Actions on errors**: 
  - Posts instructions for re-opening in Workspace with "adf-generate" agent
  - Increments retry counter label
  - Adds `changes-requested` label
- **Actions on warnings/clean**: Posts approval comment, adds appropriate label
- **Why needed**: Automatically detects review outcome and routes appropriately

#### `escalate-to-human-review.yml`
- **Trigger**: Any comment on a PR with `retry-count-3` label
- **Action**: Adds `needs-human-review` and `escalated` labels, posts escalation alert
- **Why needed**: Prevents infinite loops; enforces fallback to human judgment after 3 cycles
- **Manual step**: Maintainer reviews and decides on next action (fix, clarify, close)

### What Is Automated

✅ **State tracking via labels** — (`retry-count-*`, `agent-in-progress`, `review-in-progress`, etc.)  
✅ **Review result detection** — Parsing agent comments to identify errors/warnings/clean status  
✅ **Routing logic** — Determining which agent should work next based on review results  
✅ **Retry cycle counting** — Enforced via labels across generation→review→fix loops  
✅ **Escalation enforcement** — Automatic escalation to human after 3 cycles  
✅ **Clear instructions** — Workflow comments guide users on which agent to select

### What Requires Manual Steps

⚠️ **Opening issues/PRs in Copilot Workspace** — User clicks "Open in Workspace" button  
⚠️ **Selecting the custom agent** — User selects correct agent from dropdown  
⚠️ **Escalation resolution** — After max retries, maintainer must review and decide

### API Implementation Details

Workflows attempt to use GitHub GraphQL API for Copilot assignment:

```bash
# Get Copilot bot user ID
COPILOT_ID=$(gh api graphql -f query='
query {
  user(login: "copilot") {
    id
  }
}' --jq '.data.user.id')

# Assign Copilot to issue/PR
gh api graphql \
  -H 'GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection' \
  -f query='
  mutation($issueId: ID!, $actorIds: [ID!]!) {
    addAssigneesToAssignable(input: {
      assignableId: $issueId,
      assigneeIds: $actorIds
    }) {
      assignable {
        ... on Issue { id title }
        ... on PullRequest { id title }
      }
    }
  }' \
  -f issueId="$ISSUE_NODE_ID" \
  -f actorIds="[$COPILOT_ID]"
```

**Note**: The GraphQL API for automated Copilot agent assignment may not be fully available yet. The workflows gracefully fall back to posting instructions when the API is unavailable, guiding users to manually trigger agents in Copilot Workspace.

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
| Agent never starts working | After labeling the issue with `adf-generate`, you must manually click "Open in Workspace" and select the agent from the dropdown. |
| Copilot doesn't pick the right agent | In Copilot Workspace, ensure you select the correct custom agent (`adf-generate` or `adf-review`) from the dropdown menu. |
| Copilot isn't available as an assignee | Confirm your org/plan has Copilot Coding Agent enabled. Check organization Copilot policies. |
| Review/fix cycle runs too long | The workflows enforce a maximum of 3 review cycles before escalating to `needs-human-review`. |
| Agent doesn't follow the templates | The agent instructions reference `templates/` and `rules/` directories — make sure those files exist on the branch Copilot is working from. |
