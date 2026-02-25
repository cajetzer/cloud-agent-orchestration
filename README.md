# GitHub Agentic Workflows — Multi-Agent Orchestration Test Implementation

A **learning and demo repository** showing how to use **GitHub Agentic Workflows** (technical preview) for cloud-based multi-agent orchestration of custom agents defined in agent.md files.

This includes:
- **Custom Agents** (`.github/agents/`) - Reusable, for both manual-assignment through Coding Agent and our Agentic Workflow test implementation
- **Agentic Workflows** (`.github/workflows/*.md`) - Automated orchestration that invokes those agents through sandboxed GitHub Copilot CLI, built purely by describing the desired behavior in natural language (markdown) 
- **Orchestrator/Worker Pattern** - Coordinator dispatches specialized workers

> ⚠️ **Technical Preview**: GitHub Agentic Workflows launched February 13, 2026. This is cutting-edge functionality that may change.
>
> - [Blog: GitHub Agentic Workflows are now in technical preview](https://github.blog/changelog/2026-02-13-github-agentic-workflows-are-now-in-technical-preview/)
> - [Open Source gh-aw repository](https://github.com/github/gh-aw)
> - [Automate repository tasks with GitHub Agentic Workflows](https://github.blog/ai-and-ml/automate-repository-tasks-with-github-agentic-workflows/)

### What This Repository Includes

| Concept | Files | Purpose |
|---------|-------|---------|
| **Custom Agents** | `.github/agents/adf-generate.agent.md` | Specialized in generating ADF pipelines |
| | `.github/agents/adf-review.agent.md` | Specialized in reviewing ADF pipeline definitions for functionality, best practices, and common issues |
|  **Orchestrator Workflow Definition** | `.github/workflows/adf-orchestrator.md` | Automated agent coordination |
| **Worker Workflow Definitions** | `.github/workflows/adf-generate-worker.md` | Invokes generate agent with tools |
| | `.github/workflows/adf-review-worker.md` | Invokes review agent with KB access |

> **Note**: also included is a `.github/agents/agentic-workflows.agent.md` installed via the `gh-aw` extension with `gh aw init`. This agent helps to create, debug, and upgrade AI-powered workflows with intelligent prompt routing, and was heavily used to generate and iterate on this example.

### Two Ways to Use the Agents in this Project

| Method | How | When |
|--------|-----|------|
| **Manual** | Assign Copilot to issue → Select agent from dropdown | Ad-hoc work, testing |
| **Automated** | Label issue → Orchestrator dispatches workers | Automated agentic dev/review workflow |


---

## 📚 Foundational Concepts



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
- **How to hand off** — When to pass work to another agent or human

>**Note: When to activate and handoff are not yet supported in cloud Coding Agent at the time of this publish, although they are supported in some local IDE agents.**

```markdown
# Example: .github/agents/my-agent.agent.md
---
name: My Custom Agent
description: Does a specific task
tools: ["read", "edit", "search"]
---

## Instructions
1. Read the issue description
2. Do the task
3. Create a PR with results
```
> 📖 **Learn more:** [Customizing Copilot coding agent](https://docs.github.com/en/copilot/customizing-copilot/customizing-the-behavior-of-copilot-coding-agent)

### How Does Agent Assignment Work Today?

At the time of this publish, agents defined in `.github/agents/` can be assigned to issues manually through the GitHub UI. This will invoke Coding Agent to use the custom agent selected. Track the work in the Agents panel. 

**Assign Copilot to an issue:**
   1. Click **Assign to Copilot**
   1. Select a custom agent and desired model
   1. Add any additional instructions
   1. Click **Assign**


Custom agents for the cloud Coding Agent alone cannot yet automatically:
- Detect when they should start working
- Hand off work to other agents cloud agents
- Track state across multiple interactions
- Enforce retry limits or escalation policies

>**Note: Many of these are available in local IDE agents, but not yet in the cloud agent.**

In the meantime, we are testing the use of **GitHub Agentic Workflows** to achieve multi-agent orchestration in the cloud, using the safe outputs and workflow dispatch capabilities to coordinate work across multiple specialized agents.

### What are GitHub Agentic Workflows?

**GitHub Agentic Workflows** are AI-powered repository automation that runs inside GitHub Actions. Instead of writing complex YAML with fixed if/then logic, you describe what you want in **markdown** and an AI coding agent figures out how to do it.

Each workflow is a `.md` file in `.github/workflows/` with two parts:
- **Frontmatter (YAML)** — Configures triggers, permissions, tools, and safe outputs
- **Markdown body** — Natural language instructions the agent follows

The `gh aw compile` CLI converts these into standard GitHub Actions `.lock.yml` files with security hardening. At runtime, a coding agent (Copilot CLI, Claude, or Codex) executes your instructions in a sandboxed container.

**Key design principles:**
- **Read-only by default** — Agents have no write access unless granted through safe outputs
- **Safe outputs** — Pre-approved write operations (create PRs, add comments, add labels, dispatch workflows) that are sanitized before execution
- **Sandboxed execution** — Network isolation, tool allowlisting, and containerized environments
- **Workflow dispatch** — Workflows can trigger other workflows, enabling multi-agent orchestration

```yaml
# Minimal example: triage new issues
---
on:
  issues:
    types: [opened]
permissions: read-all
safe-outputs:
  add-comment:
  add-labels:
---

Analyze the new issue and add appropriate labels. If the issue is unclear,
post a comment asking for more details.
```

> 📖 **Learn more:** [GitHub Agentic Workflows documentation](https://github.github.com/gh-aw/) · [Announcement blog post](https://github.blog/ai-and-ml/automate-repository-tasks-with-github-agentic-workflows/) · [Open source repo](https://github.com/github/gh-aw)

---

## 🛠️ Test Implementation: Agentic Workflows for Multi-Agent Orchestration

The workflows in `.github/workflows/` attempt to provide **automated** agent orchestration:

### 1. Orchestrator (`adf-orchestrator.md`)

**Role**: Entry point — validates issue and dispatches the generation worker. Workers self-chain after this.

```yaml
safe-outputs:
  dispatch-workflow:
    workflows: [adf-generate-worker]
    max: 2
```

**Responsibilities**:
- Validates issue requirements
- Dispatches generation worker with issue context
- Stops — the workers handle all subsequent handoffs directly

> **Why workers self-chain?** GitHub Actions has a key limitation: workflows dispatched via `GITHUB_TOKEN` do not fire `workflow_run` events that can re-trigger other workflows. Since gh-aw's `dispatch-workflow` safe output uses `GITHUB_TOKEN` by default, the `workflow_run` trigger cannot be used for worker-to-orchestrator callbacks. Instead, each worker directly dispatches the next step using `dispatch-workflow`.

### 2. Generation Worker (`adf-generate-worker.md`)

**Role**: Invokes the ADF Generate agent for both initial generation AND fix cycles. Directly dispatches the review worker when done.

```yaml
# Inputs determine mode:
inputs:
  issue_number: required    # Always provided
  issue_title: required     # Issue title
  issue_body: required      # Issue body with requirements
  pr_number: optional       # If provided → FIX mode
  review_feedback: optional # Errors to address

engine:
  id: copilot
  agent: adf-generate  # References .github/agents/adf-generate.agent.md

tools:
  github:
  edit:
  bash: ["jq", "mkdir"]

safe-outputs:
  create-pull-request: ...        # Used in INITIAL mode
  push-to-pull-request-branch: ...  # Used in FIX mode (updates existing PR)
  dispatch-workflow:              # NEW: directly chains to review worker
    workflows: [adf-review-worker]
```

**Two Modes**:
| Mode | Trigger | Action |
|------|---------|--------|
| **Initial** | No `pr_number` | Creates new PR → dispatches review worker with `issue_number` |
| **Fix** | `pr_number` provided | Commits fixes to PR → dispatches review worker with `pr_number` |

### 3. Review Worker (`adf-review-worker.md`)

**Role**: Invokes the ADF Review agent. Handles fix cycle dispatch directly.

```yaml
safe-outputs:
  dispatch-workflow:              # NEW: directly chains to generate worker for fix cycles
    workflows: [adf-generate-worker]
  remove-labels:                  # For removing changes-requested after fix dispatch
```

**Post-review actions** (handled directly by the review worker):
| Outcome | Action |
|---------|--------|
| `approved` | Posts "Ready for review" comment |
| `approved-with-warnings` | Posts "Ready with suggestions" comment |
| `changes-requested` + retry < 3 | Removes label → dispatches generate worker with feedback |
| `changes-requested` + retry >= 3 | Adds `needs-human-review` label → escalates |

The review agent reads `rules/common_issues.json` directly for domain knowledge.

#### The Review Agent's Knowledge Base

The review agent reads `rules/common_issues.json` for domain expertise:

```json
{
  "issues": {
    "KB-001": {
      "name": "Missing Retry Policy",
      "severity": "warning",
      "resolution": "Add a policy block with retry: 3 and retryIntervalInSeconds: 30"
    },
    "KB-002": {
      "name": "Hardcoded Connection String",
      "severity": "error",
      "resolution": "Move connection details to linked service and use parameters"
    }
  }
}
```

**In production**, this could be enhanced with:

| Approach | Implementation | Best For |
|----------|---------------|----------|
| **JSON file** (current) | Read file directly | Simple, version-controlled knowledge |
| **MCP Server** | Custom server with `tools:` config | Complex queries, real-time data |
| **Vector Database** | MCP server + embeddings | Semantic search over large KB |
| **External API** | `web-fetch` tool | Enterprise knowledge base integration |
| **Azure AI Search** | MCP server + Azure SDK | Enterprise search with AI ranking |

Example MCP configuration (for production):
```yaml
tools:
  knowledge-base:
    type: stdio
    command: "node"
    args: ["./mcp-servers/kb-server.js"]
    env:
      KB_CONNECTION_STRING: ${{ secrets.KB_CONNECTION }}
```

### Architecture: Multi-Agent Orchestration
> **Key Design Pattern**: Workers use **direct `dispatch-workflow` calls** to chain to the next step. This avoids the `workflow_run` trigger limitation where workflows dispatched via `GITHUB_TOKEN` do not fire `workflow_run` events in other workflows.

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Issue                            │
│  "Create a pipeline to copy data from Blob to SQL Database"     │
│  Label: adf-pipeline                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │  Issue labeled triggers orchestrator
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ADF ORCHESTRATOR                            │
│                  adf-orchestrator.md                            │
│                                                                 │
│  1. Validate issue has requirements                             │
│  2. Dispatch generation worker (then stops — workers self-chain)│
└─────────────────────────────────────────────────────────────────┘
          │
          │ dispatch-workflow
          ▼
┌─────────────────────────┐
│   GENERATION WORKER     │
│ adf-generate-worker.md  │
│                         │
│ Modes:                  │
│ • Initial: Create PR    │──────────────────────────────────────┐
│ • Fix: Update PR        │──────────────────────────────────────┐
│                         │                                      │
│ Tools: github, edit,    │                                      │
│        bash [jq]        │                                      │
└─────────────────────────┘                                      │
                                      dispatch-workflow          │
                                      (with issue_number)        │
                                               │                 │
                                               ▼                 │
                              ┌─────────────────────────────┐    │
                              │      REVIEW WORKER          │    │
                              │  adf-review-worker.md       │    │
                              │                             │    │
                              │ Invokes:                    │    │
                              │  adf-review.agent.md        │    │
                              │                             │    │
                              │ Tools: github, bash         │    │
                              │ + Knowledge Base JSON       │    │
                              └─────────────────────────────┘    │
                                               │                 │
                               ┌───────────────┼──────────┐      │
                               ▼               ▼          ▼      │
                          [approved]    [warnings]  [errors]      │
                               │               │          │       │
                               ▼               ▼          │       │
                             Done            Done    dispatch-workflow
                                                    (with pr_number
                                                     + review_feedback)
                                                          │       │
                                                          └───────┘
                                                     [Fix Cycle]
                                              (up to 3x, then escalate)
```
---

## 🚀 Quick Start

### Prerequisites

- GitHub organization with **Copilot** (or Claude/Codex API access)
- Repository with **GitHub Actions** enabled
- `gh` CLI with agentic workflows extension

### Setup Steps

1. **Fork or clone** this repository

2. **Install the gh-aw extension**:
   ```bash
   gh extension install github/gh-aw
   ```

3. **Compile all workflows** (generates lock files):
   ```bash
   gh aw compile
   ```

4. **Add required secrets** for your AI engine:

   **For Copilot (recommended)**: Create a Fine-Grained PAT with the `Copilot Requests` permission:
   1. Go to [GitHub Personal Access Tokens](https://github.com/settings/personal-access-tokens/new)
   2. Select your **user account** as the resource owner (not an organization)
   3. Under Repository Access, select **"Public repositories"** (required to see Copilot permissions)
   4. Under Account Permissions, enable **"Copilot Requests"**
   5. Create the token and add it as a repository secret:
      ```bash
      gh aw secrets set COPILOT_GITHUB_TOKEN --value "your-pat-here"
      ```

5. **Commit and push** the workflow files:
   ```bash
   git add .github/workflows/
   git commit -m "Add agentic workflows for ADF pipeline orchestration"
   git push
   ```

6. **Create the `adf-pipeline` label** in your repository

7. **Test it**: Create an issue describing a pipeline, add the `adf-pipeline` label
> 📌 **Hint:** use the `examples\sample-issue.md` or ask Copilot to create the issue with the `/create-test-issue` saved prompt.
---

## Key Concepts used in this Example

### Frontmatter (YAML)
```yaml
on:              # Standard GitHub Actions triggers
permissions:     # Read-only by default (security)
safe-outputs:    # Controlled write operations
tools:           # What the agent can use
```

### Markdown Body
Natural language instructions for the coding agent. Describe:
- **What** you want (outcomes)
- **How** to validate (checks)
- **When** to escalate (error handling)

### Safe Outputs
The agent runs read-only. Write operations happen through **safe outputs**:

| Safe Output | What It Does |
|-------------|--------------|
| `create-pull-request` | Creates a PR with agent's code |
| `add-comment` | Posts comments on issues/PRs |
| `add-labels` | Adds labels to issues/PRs |
| `dispatch-workflow` | **Triggers other workflows (orchestration!)** |

### The dispatch-workflow Safe Output

This is the key to multi-agent orchestration:

```yaml
safe-outputs:
  dispatch-workflow:
    workflows: [adf-generate-worker, adf-review-worker]
    max: 5
```

The orchestrator can trigger worker workflows, passing context via inputs.

---

## Observability & Troubleshooting

### Understanding What Runs Where

**Key distinction**: Agentic Workflows use **Copilot CLI** (not Coding Agent) inside GitHub Actions. This affects where you look for information:

| What You're Looking For | Where to Find It |
|-------------------------|------------------|
| Workflow execution status | **Actions tab** → workflow runs |
| Agent conversation/reasoning | **Actions logs** → `agent` job → step logs |
| Safe output results (PRs, comments) | **PRs/Issues** created by the workflow |
| Compilation errors | Run `gh aw compile` locally |
| Workflow dispatch inputs | **Actions tab** → run → "Summary" |
| Failure issues | Issues labeled `agentic-workflows` |

### Viewing Workflow Runs

1. Go to **Actions** tab in your repository
2. Find runs by workflow name:
   - `ADF Pipeline Orchestrator` - Main coordinator
   - `ADF Pipeline Generation Worker` - Creates pipelines
   - `ADF Pipeline Review Worker` - Reviews pipelines

3. Click a run to see:
   - **Summary**: Inputs passed to the workflow
   - **Jobs**: `activation` → `agent` → `conclusion` (the 3 main jobs)
   - **Logs**: Expand each job to see detailed output

### Reading Agent Logs

Inside a workflow run, expand the **`agent`** job to see:

```
┌─ Setup phase
│  - Copilot CLI installation
│  - MCP server startup (safe-outputs, github tools)
│  - Gateway configuration
│
├─ Agent execution
│  - Copilot CLI receives the prompt
│  - Agent reads files, makes decisions
│  - Tool calls (if any) appear here
│
└─ Conclusion phase
    - Safe output processing
    - PR/comment creation
    - Failure reporting
```

**Important**: The actual agent "thinking" is inside a sandboxed container. You'll see:
- Tool invocations and results
- File operations
- But NOT the full conversation (that's in artifact logs if uploaded)

### Common Failure Patterns

| Symptom | Cause | Solution |
|---------|-------|----------|
| "Secret Verification Failed" | Missing `COPILOT_GITHUB_TOKEN` | Add the PAT secret |
| "No safe outputs generated" | Agent didn't call safe-output tools | Check workflow instructions |
| Workflow compiles but agent does nothing | Missing tool permissions | Check `tools:` in frontmatter |
| "dispatch-workflow: workflow must be compiled first" | Lock file missing | Run `gh aw compile` and commit |
| Review worker never triggered | `workflow_run` doesn't fire for `GITHUB_TOKEN` dispatches | ✅ Fixed: workers now use direct `dispatch-workflow` |

> **Known GitHub Actions Limitation**: The `workflow_run` trigger does NOT fire when the triggering workflow was dispatched via `GITHUB_TOKEN`. Only `workflow_dispatch` and `repository_dispatch` are exceptions to this rule. This is why this repo uses direct `dispatch-workflow` calls between workers instead of relying on `workflow_run` for worker-to-worker handoffs.

### Debugging with gh aw CLI

```bash
# Check which workflows are compiled
gh aw status

# Download and view logs from a run
gh aw logs <workflow-run-url>

# Audit a specific run for issues
gh aw audit <run-id>

# Interactive debug (if available)
gh aw debug <workflow-name>
```

### What You WON'T See

Unlike the GitHub Coding Agent:
- **No agent session UI** - The work happens inside Actions, not a separate session
- **No live streaming** - You see results after the job completes
- **No "Copilot is working" indicator** - It's a batch job, not interactive

### Automatic Failure Issues

When workflows fail, the system automatically creates issues labeled `agentic-workflows`:
- **Parent issue**: `[agentics] Failed runs` - Tracks all failures
- **Child issues**: Individual failure reports with run links

To debug a failure:
1. Find the failure issue
2. Click the workflow run URL
3. Expand the `agent` job logs
4. Look for error messages or missing tool calls

---

## Repository Structure

```
├── .github/
│   ├── agents/                            # Custom agents (manually assignable)
│   │   ├── adf-generate.agent.md          # Pipeline generation agent
│   │   ├── adf-review.agent.md            # Pipeline review agent
│   │   └── agentic-workflows.agent.md     # gh-aw workflow helper (dispatcher)
│   ├── aw/
│   │   └── actions-lock.json              # Pinned Actions used by compiled workflows
│   ├── copilot-instructions.md            # Repo-level Copilot instructions
│   ├── prompts/
│   │   └── create-test-issue.prompt.md    # Reusable prompt for creating test issues
│   └── workflows/                         # Agentic workflows (automated)
│       ├── adf-orchestrator.md            # Orchestrator (coordinates workers)
│       ├── adf-generate-worker.md         # Invokes generate agent
│       ├── adf-review-worker.md           # Invokes review agent + KB
│       ├── copilot-setup-steps.yml        # Environment setup for Coding Agent
│       └── *.lock.yml                     # Compiled workflows (generated)
├── templates/                             # ADF pipeline JSON templates
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/
│   ├── best_practices.json                # Review rules
│   └── common_issues.json                 # Knowledge base for review agent
├── examples/
│   └── sample-issue.md                    # Example issue to try
├── .env.example                           # Local dev environment template
├── AGENTS.md                              # Repo-wide agent instructions
├── copilot-setup-steps.md                 # Coding Agent environment setup
└── README.md
```

---

## Further Reading

| Topic | Resource |
|-------|----------|
| **Agentic Workflows Docs** | [github.github.com/gh-aw](https://github.github.com/gh-aw/) |
| **Orchestration Pattern** | [Orchestration](https://github.github.com/gh-aw/patterns/orchestration/) |
| **Safe Outputs Reference** | [Safe Outputs](https://github.github.com/gh-aw/reference/safe-outputs/) |
| **dispatch-workflow** | [Workflow Dispatch](https://github.github.com/gh-aw/reference/safe-outputs/#workflow-dispatch-dispatch-workflow) |

---

## License

MIT License - use this as a starting point for your own agentic workflows.
