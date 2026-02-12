# GitHub Copilot (cloud) Coding Agent Orchestration

A **learning and testing repository** demonstrating how to orchestrate GitHub Copilot Coding Agent custom agents with automated handoffs using GitHub Actions workflows and the GraphQL API.

Two custom agents for Azure Data Factory pipeline development — defined entirely as markdown files in `.github/agents/`. No servers, no Docker, no deployment.

| Agent | File | Purpose |
|-------|------|---------|
| **ADF Generation Agent** | `.github/agents/adf-generate.agent.md` | Generates ADF pipeline JSON from natural language descriptions in GitHub Issues |
| **ADF Review Agent** | `.github/agents/adf-review.agent.md` | Reviews generated pipelines for functionality, best practices, and common issues |

---

## 📚 Understanding Copilot Coding Agent

### What is Copilot Coding Agent?

**Copilot Coding Agent** is an AI-powered software engineering agent that can autonomously work on GitHub issues and pull requests. Unlike Copilot Chat (which responds to questions) or Copilot code completion (which suggests code as you type), the Coding Agent:

- **Works autonomously** — You assign it an issue, and it works independently
- **Creates branches and PRs** — It commits code and opens pull requests
- **Reads and writes files** — It can explore your codebase and make changes
- **Follows instructions** — It reads issue descriptions and custom agent definitions

> 📖 **Learn more:** [GitHub Copilot coding agent](https://docs.github.com/en/copilot/using-github-copilot/using-copilot-coding-agent)

### What are Custom Agents?

**Custom Agents** are markdown files that give Copilot specialized instructions for specific tasks. They live in `.github/agents/` and define:

- **When to activate** — What types of issues/PRs the agent handles
- **What to do** — Step-by-step instructions for the agent
- **What tools to use** — Templates, rules, and reference files
- **How to hand off** — When to pass work to another agent or human (not yet supported in cloud agents at publish time)

```markdown
# Example: .github/agents/my-agent.agent.md
---
name: My Custom Agent
description: Does a specific task
---

## Instructions
1. Read the issue description
2. Do the task
3. Create a PR with results
```

> 📖 **Learn more:** [Customizing Copilot coding agent](https://docs.github.com/en/copilot/customizing-copilot/customizing-the-behavior-of-copilot-coding-agent)

### How Does Agent Assignment Work?

At the time of this publish, there are two ways to assign Copilot (cloud) Coding Agent to an issue:

1. **Manual (UI):** Assign Copilot to an issue, then select a custom agent when starting
2. **Automatic (API):** GitHub Actions workflow calls GraphQL API with `agentAssignment`

This repository demonstrates **automatic assignment** as doable at this time — see [How Automatic Assignment Works](#how-automatic-assignment-works) for the GraphQL details.

> 📖 **Learn more:** [GitHub GraphQL API](https://docs.github.com/en/graphql)

### Why Use Workflows for Orchestration?

Custom agents for the cloud Coding Agent alone cannot yet automatically:
- Detect when they should start working
- Hand off work to other agents cloud agents
- Track state across multiple interactions
- Enforce retry limits or escalation policies
**Note: Many of these are available in local IDE agents, but not yet in the cloud agent.**

**GitHub Actions workflows** fill this gap by:
- Triggering on events (labels, PR creation, comments)
- Calling the GraphQL API to assign agents
- Parsing agent output to determine next steps
- Managing state via labels

This creates a **complete orchestration system** where multiple agents can work together on complex tasks.

---

## Quick Start (15 minutes)
See [Detailed Setup Instructions](#detailed-setup-instructions) below for step-by-step guidance.
1. **Fork or clone** this repository to your GitHub org
2. **Enable Copilot Coding Agent** in your org/repo settings
3. **Create labels** (see [Step 3](#step-3-create-required-labels))
4. **Create a PAT and add as secret** (see [Step 4](#step-4-create-personal-access-token-required))
5. **Create an issue** with the `adf-generate` label
6. **Watch the magic** — Copilot is automatically assigned and starts working!

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

In this example, the custom agents are **automatically assigned** by GitHub Actions workflows using the GraphQL API with `agentAssignment` parameters. This enables fully automated orchestration:

1. **Detect** when an issue needs ADF pipeline generation (labeled `adf-generate`)
2. **Assign** Copilot with the specific custom agent via GraphQL API
3. **Monitor** for the PR and automatically assign the review agent
4. **Parse** review results and hand back to generation agent if issues found
5. **Count** retry cycles and escalate to human review after 3 attempts

> **Important:** Fully automated assignment requires a Personal Access Token (PAT) — see [Step 4](#step-4-create-personal-access-token-required).

### Workflow Files

The repository includes four GitHub Actions workflows that orchestrate this flow:

| Workflow | File | Purpose |
|----------|------|---------|
| **Issue Assignment** | `.github/workflows/assign-adf-generate-agent.yml` | Detects `adf-generate` label → Assigns Copilot with generation agent |
| **PR Review Assignment** | `.github/workflows/assign-adf-review-agent.yml` | Detects `adf-pipeline` PR → Assigns Copilot with review agent |
| **Review Handoff** | `.github/workflows/handle-adf-review-results.yml` | Parses review comment → Routes back to generation agent (if errors) or approves |
| **Escalation** | `.github/workflows/escalate-to-human-review.yml` | After 3 cycles → Adds `needs-human-review` label and alerts maintainers |
| **Auto-Approve** | `.github/workflows/auto-approve-copilot-runs.yml` | Automatically approves workflow runs triggered by Copilot (see note below) |

> **Note on Auto-Approval:** GitHub requires manual approval for workflows triggered by bot accounts, including Copilot. This is a [known platform limitation](https://github.com/orgs/community/discussions/162826). The `auto-approve-copilot-runs.yml` workflow uses the GitHub API to programmatically approve these runs, enabling fully automatic agent-to-agent handoffs.

> **Note:** Assignment workflows use `concurrency` groups to prevent duplicate agent sessions when multiple events fire simultaneously (e.g., issue created with label already applied).

### How Automatic Assignment Works

The workflows use the GitHub GraphQL API with the `agentAssignment` input to assign Copilot with a specific custom agent:

```graphql
mutation {
  addAssigneesToAssignable(input: {
    assignableId: "<ISSUE_OR_PR_NODE_ID>",
    assigneeIds: ["<COPILOT_BOT_ID>"],
    agentAssignment: {
      targetRepositoryId: "<REPO_NODE_ID>",
      baseRef: "main",
      customAgent: "adf-generate",  # or "adf-review"
      customInstructions: "Task-specific guidance here"
    }
  }) {
    assignable { ... }
  }
}
```

**Key requirement:** The default `GITHUB_TOKEN` in workflows does **not** have permission to assign Copilot via GraphQL. You must create a Personal Access Token (PAT) and add it as a repository secret — see [Step 4](#step-4-create-personal-access-token-required).

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
│       ├── escalate-to-human-review.yml       # Escalation after max retries
│       └── auto-approve-copilot-runs.yml      # Auto-approve Copilot workflow runs
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

**Trigger Labels:**

| Label | Color (suggested) | Description |
|-------|-------------------|-------------|
| `adf-generate` | `#1D76DB` (blue) | Marks issues that request ADF pipeline generation |
| `adf-pipeline` | `#0E8A16` (green) | Marks PRs containing ADF pipelines |

**Status Labels:**

| Label | Color (suggested) | Description |
|-------|-------------------|-------------|
| `agent-in-progress` | `#FBCA04` (yellow) | Generation agent is working |
| `review-in-progress` | `#FBCA04` (yellow) | Review agent is working |
| `generation-in-progress` | `#FBCA04` (yellow) | Generation agent is fixing issues |
| `changes-requested` | `#E11D48` (red) | Review agent found issues to fix |
| `approved` | `#0E8A16` (green) | Pipeline passed review |
| `approved-with-warnings` | `#F9A825` (amber) | Pipeline approved with minor suggestions |
| `needs-human-review` | `#B60205` (red) | Max review cycles reached; human needed |
| `escalated` | `#B60205` (red) | Issue has been escalated |

**Retry Counter Labels** (create all three):

| Label | Color (suggested) | Description |
|-------|-------------------|-------------|
| `retry-count-1` | `#C5DEF5` (light blue) | First review cycle |
| `retry-count-2` | `#C5DEF5` (light blue) | Second review cycle |
| `retry-count-3` | `#C5DEF5` (light blue) | Third review cycle (triggers escalation) |

---

### Step 4: Create Personal Access Token (Required)

**⚠️ This step is required for fully automated agent assignment.**

The default `GITHUB_TOKEN` in GitHub Actions workflows does **not** have permission to assign Copilot via the GraphQL API. You must create a Personal Access Token (PAT) and add it as a repository secret.

#### 4a: Create the PAT

1. Go to [github.com/settings/tokens?type=beta](https://github.com/settings/tokens?type=beta) (Fine-grained tokens)
2. Click **"Generate new token"**
3. Configure:
   - **Token name:** `copilot-agent-orchestration`
   - **Expiration:** 90 days (or your preference)
   - **Repository access:** Select **"Only select repositories"** → choose your repository
   - **Permissions:**
     - Repository permissions → **Actions:** Read and write *(required for auto-approving Copilot workflow runs)*
     - Repository permissions → **Contents:** Read and write
     - Repository permissions → **Issues:** Read and write  
     - Repository permissions → **Pull requests:** Read and write
4. Click **"Generate token"**
5. **Copy the token** (you won't see it again!)

#### 4b: Add as Repository Secret

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Configure:
   - **Name:** `COPILOT_PAT`
   - **Value:** Paste the token you copied
4. Click **"Add secret"**

#### Why is this needed?

The GraphQL API mutation `addAssigneesToAssignable` with `agentAssignment` requires elevated permissions that the default workflow `GITHUB_TOKEN` doesn't have. The PAT provides:
- Permission to assign Copilot to issues/PRs
- Permission to specify the custom agent to use
- Permission to pass custom instructions to the agent
- Permission to auto-approve workflow runs triggered by Copilot (see [Known Limitation](#known-limitation-workflow-approval))

Without the PAT, workflows will still run but will fail to assign Copilot automatically. They will post instructions guiding you to manually open the issue/PR in Copilot Workspace instead.

---

### Step 5: Verify Workflows Are Active

1. Go to your repository's **Actions** tab
2. You should see the four workflows listed:
   - `Assign ADF Generate Agent to Issue`
   - `Assign ADF Review Agent to PR`
   - `Handle ADF Review Results & Agent Handoff`
   - `Escalate ADF Pipeline to Human Review`
3. Workflows are enabled by default when pushed to the repo

---

### Step 6: Test the Full Automated Flow

Once the PAT is configured, the entire flow is **fully automated**.

#### 6a: Create an Issue

1. **Create a new issue** with the label `adf-generate`
   - Title: `Create a copy pipeline from Azure Blob Storage to Azure SQL Database`
   - Body: Use the template from [examples/sample-issue.md](examples/sample-issue.md)
   - Add label: `adf-generate`

#### 6b: Watch the Automation

2. **The workflow triggers automatically:**
   - Detects the `adf-generate` label
   - Posts comment: `🤖 ADF Pipeline Generation Agent Assigned`
   - Calls GraphQL API to assign Copilot with `customAgent: "adf-generate"`
   - Adds label: `agent-in-progress`
   
3. **Copilot starts working automatically:**
   - Reads the issue requirements
   - Generates ADF pipeline JSON using templates
   - Creates a branch and commits the pipeline
   - Opens a PR with the `adf-pipeline` label

4. **Review workflow triggers automatically:**
   - Detects the new PR with `adf-pipeline` label
   - Calls GraphQL API to assign Copilot with `customAgent: "adf-review"`
   - Posts comment: `🔍 ADF Pipeline Review Agent Assigned`
   - Adds labels: `review-in-progress`, `retry-count-1`

5. **Review agent works automatically:**
   - Reviews the pipeline for correctness and best practices
   - Posts detailed findings as a comment

6. **Routing based on review results:**

   **If errors found:**
   - Workflow parses review, detects errors
   - Re-assigns Copilot with `customAgent: "adf-generate"` to fix issues
   - Labels: `changes-requested`, `generation-in-progress`
   - Retry counter increments
   - Agent fixes issues and pushes to branch
   - Review cycle repeats automatically

   **If warnings only:**
   - Labels PR as `approved-with-warnings`
   - Ready for human merge decision

   **If no issues:**
   - Labels PR as `approved`
   - Ready to merge immediately

7. **Escalation after 3 retries:**
   - If errors persist through 3 cycles
   - Labels: `needs-human-review`, `escalated`
   - Posts escalation comment
   - Human maintainer must intervene

---

## Workflow Diagram

```
┌─ Issue labeled "adf-generate"
│
├─ Workflow: assign-adf-generate-agent.yml
│  ├─ Posts: "🤖 ADF Pipeline Generation Agent Assigned"
│  ├─ Adds label: agent-in-progress
│  └─ GraphQL: Assign Copilot with customAgent: "adf-generate"
│
└─ Copilot starts automatically
   ├─ Reads issue requirements
   ├─ Generates pipeline JSON
   └─ Creates PR with label "adf-pipeline"
      │
      ├─ Workflow: assign-adf-review-agent.yml
      │  ├─ Posts: "🔍 ADF Pipeline Review Agent Assigned"
      │  ├─ Adds labels: review-in-progress, retry-count-1
      │  └─ GraphQL: Assign Copilot with customAgent: "adf-review"
      │
      └─ Review agent starts automatically
         ├─ Reviews pipeline
         └─ Posts findings
            │
            ├─ Workflow: handle-adf-review-results.yml
            │  │
            │  ├─ If ERRORS:
            │  │  ├─ GraphQL: Re-assign Copilot with customAgent: "adf-generate"
            │  │  ├─ Labels: changes-requested, retry-count-N
            │  │  └─ Agent fixes issues → Review cycle repeats
            │  │
            │  ├─ If WARNINGS only:
            │  │  └─ Labels: approved-with-warnings
            │  │
            │  └─ If CLEAN:
            │     └─ Labels: approved
            │
            └─ If retry-count >= 3:
               └─ Workflow: escalate-to-human-review.yml
                  └─ Labels: needs-human-review, escalated
```

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

## Known Limitation: Workflow Approval

GitHub requires manual approval for workflows triggered by bot accounts, including the Copilot coding agent (`copilot-swe-agent[bot]`). This is a [known platform limitation](https://github.com/orgs/community/discussions/162826) with no official workaround—it applies regardless of:
- Trigger type (`pull_request`, `pull_request_target`, `workflow_run`)
- Repository settings ("Require approval for first-time contributors")
- Whether the branch is in the same repo vs. a fork

**How this repository solves it:**

The `auto-approve-copilot-runs.yml` workflow runs on a schedule (every 2 minutes) and automatically approves pending workflow runs triggered by Copilot:
1. Queries for workflow runs with `action_required` status
2. Filters to only runs from `copilot-swe-agent[bot]`
3. Calls the GitHub API to approve each pending run

Why scheduled polling? The `workflow_run` trigger itself requires approval when triggered by a Copilot-initiated workflow (chicken-and-egg problem). Scheduled workflows run from the main branch and don't require approval.

This enables fully automatic agent-to-agent handoffs without manual intervention.

**Security note:** This workflow only approves runs from the official Copilot bot for specific workflows in this repository. The `COPILOT_PAT` secret requires `Actions: Read and write` permission.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Workflow runs but Copilot isn't assigned** | The `COPILOT_PAT` secret is missing or invalid. See [Step 4](#step-4-create-personal-access-token-required) to create and configure it. |
| **Workflows waiting for approval** | Ensure `COPILOT_PAT` has `Actions: Read and write` permission. See [Known Limitation](#known-limitation-workflow-approval). |
| **GraphQL error: "target repository is not writable"** | The PAT doesn't have correct permissions. Ensure it has `Actions`, `Contents`, `Issues`, and `Pull requests` read/write access. |
| **Copilot doesn't use the agent instructions** | Make sure the `.github/agents/` directory is on the default branch. Verify Copilot Coding Agent is enabled for the repo. |
| **Copilot isn't available as an assignee** | Confirm your org/plan has Copilot Coding Agent enabled. Check organization Copilot policies. |
| **Review/fix cycle runs too long** | The workflows enforce a maximum of 3 review cycles before escalating to `needs-human-review`. |
| **Agent doesn't follow the templates** | The agent instructions reference `templates/` and `rules/` directories — make sure those files exist on the branch Copilot is working from. |
| **PAT expired** | Fine-grained PATs have expiration dates. Regenerate the token and update the `COPILOT_PAT` secret. |

---

## Fallback: Manual Agent Triggering

If you don't configure the `COPILOT_PAT` secret, the workflows will still run but cannot automatically assign Copilot. Instead:

1. Workflow posts a comment with instructions
2. You manually click **"Open in Workspace"** on the issue/PR
3. Select the appropriate agent (`adf-generate` or `adf-review`) from the dropdown
4. Copilot starts working with the selected agent

This fallback mode is useful for:
- Testing without creating a PAT
- Environments where PATs are restricted
- Learning how Copilot Workspace manual triggering works

---

## 🎓 What You'll Learn

This repository teaches the following concepts through working examples:

### 1. Custom Agent Design
**Files:** `.github/agents/*.agent.md`

- How to structure agent instructions with clear steps
- Defining agent activation conditions
- Referencing templates and rules for consistency
- Implementing handoff patterns between agents

### 2. GraphQL API for Agent Assignment
**Files:** `.github/workflows/*.yml`

- Using `addAssigneesToAssignable` mutation
- The `agentAssignment` input structure
- Required GraphQL feature flags
- Handling API errors gracefully

### 3. Workflow-Based Orchestration
**Concept:** Using GitHub Actions as the "conductor" for agent collaboration

- Event-driven triggers (labels, PRs, comments)
- State management via labels
- Parsing agent output to determine next steps
- Implementing retry logic and escalation

### 4. Multi-Agent Collaboration Patterns
**Pattern:** Generator → Reviewer → Fix cycle

```
[Generation Agent] → creates PR → [Review Agent] → finds issues → [Generation Agent] → fixes → [Review Agent] → approves
```

This pattern is applicable to many scenarios:
- Code generation → Code review
- Documentation → Editorial review
- Test generation → Test validation
- Infrastructure as Code → Security review

---

## 📖 Further Reading

| Topic | Resource |
|-------|----------|
| **Copilot Coding Agent** | [Using Copilot coding agent](https://docs.github.com/en/copilot/using-github-copilot/using-copilot-coding-agent) |
| **Customizing Coding Agent** | [Customizing the behavior of Copilot coding agent](https://docs.github.com/en/copilot/customizing-copilot/customizing-the-behavior-of-copilot-coding-agent) |
| **GitHub GraphQL API** | [GitHub GraphQL API documentation](https://docs.github.com/en/graphql) |
| **GitHub Actions** | [GitHub Actions documentation](https://docs.github.com/en/actions) |
| **Fine-grained PATs** | [Managing personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) |

---

## 🤝 Contributing

This is a learning repository! Contributions welcome:
- Improve agent instructions
- Add new pipeline templates
- Enhance review rules
- Fix bugs in workflows
- Improve documentation

---

## License

MIT License - feel free to use this as a starting point for your own agent orchestration projects.
