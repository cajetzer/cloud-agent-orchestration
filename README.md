# GitHub Agentic Workflows — Multi-Agent ADF Pipeline Orchestration

A **learning and demo repository** showing how to use **GitHub Agentic Workflows** (technical preview) for multi-agent orchestration of Azure Data Factory pipeline generation and review.

This demonstrates:
- **Custom Agents** (`.github/agents/`) - Reusable, manually-assignable agents
- **Agentic Workflows** (`.github/workflows/*.md`) - Automated orchestration that invokes those agents
- **Orchestrator/Worker Pattern** - Coordinator dispatches specialized workers

> ⚠️ **Technical Preview**: GitHub Agentic Workflows launched February 13, 2026. This is cutting-edge functionality that may change.

## What This Repository Demonstrates

| Concept | Files | Purpose |
|---------|-------|---------|
| **Custom Agents** | `.github/agents/adf-generate.agent.md` | Manually assignable pipeline generator |
| | `.github/agents/adf-review.agent.md` | Manually assignable pipeline reviewer |
| **Orchestrator Workflow** | `.github/workflows/adf-orchestrator.md` | Automated coordination |
| **Worker Workflows** | `.github/workflows/adf-generate-worker.md` | Invokes generate agent with tools |
| | `.github/workflows/adf-review-worker.md` | Invokes review agent with KB access |

### Two Ways to Use the Agents

| Method | How | When |
|--------|-----|------|
| **Manual** | Assign Copilot to issue → Select agent from dropdown | Ad-hoc work, testing |
| **Automated** | Label issue → Orchestrator dispatches workers | Production automation |

---

## Architecture: Multi-Agent Orchestration

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
│  2. Dispatch generation worker → Creates PR                     │
│  3. Dispatch review worker → Reviews PR                         │
│  4. Handle review results:                                      │
│     • approved → Done                                           │
│     • errors → Re-dispatch generation with feedback (up to 3x)  │
│     • 3 failures → Escalate to human                            │
└─────────────────────────────────────────────────────────────────┘
          │                                       │
          │ dispatch-workflow                     │ dispatch-workflow
          ▼                                       ▼
┌─────────────────────────┐         ┌─────────────────────────────┐
│   GENERATION WORKER     │         │      REVIEW WORKER          │
│ adf-generate-worker.md  │         │  adf-review-worker.md       │
│                         │         │                             │
│ Modes:                  │         │ Invokes:                    │
│ • Initial: Create PR    │         │  adf-review.agent.md        │
│ • Fix: Update PR        │         │                             │
│                         │         │ Tools: github, bash         │
│ Tools: github, edit,    │         │ + Knowledge Base JSON       │
│        bash [jq]        │         │                             │
└─────────────────────────┘         └─────────────────────────────┘
          │                                       │
          │                                       │
          └──────────────┬────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Pull Request                             │
│  • Pipeline JSON generated/updated by worker                    │
│  • Review findings with knowledge base references               │
│  • Labels: approved / changes-requested / approved-with-warnings│
└─────────────────────────────────────────────────────────────────┘
                         │
      ┌──────────────────┼──────────────────┐
      │                  │                  │
      ▼                  ▼                  ▼
  [approved]      [warnings only]    [errors found]
      │                  │                  │
      ▼                  ▼                  ▼
    Done            Done (with       Re-dispatch
                    suggestions)     generation
                                          │
                                    ┌─────┴─────┐
                                    │  < 3x?    │
                                    └─────┬─────┘
                                    yes   │   no
                                    ↓     │    ↓
                               Fix cycle  │  Escalate
                               (loop) ◄───┘
```

---

## Custom Agents (Manually Assignable)

The agents in `.github/agents/` can be used **manually** by assigning Copilot to an issue/PR:

### `adf-generate.agent.md`
```yaml
---
name: ADF Pipeline Generator
description: Generates Azure Data Factory pipeline JSON definitions
tools: ["read", "edit", "search"]
---
```

### `adf-review.agent.md`
```yaml
---
name: ADF Pipeline Review Agent
description: Reviews ADF pipelines for best practices and common issues
tools: ["read", "search"]
---
```

**Manual usage:**
1. Open an issue describing pipeline requirements
2. Click **Assignees** → Add **Copilot**
3. Select **ADF Pipeline Generator** from the dropdown
4. Copilot works using the agent's instructions

---

## Agentic Workflows (Automated Orchestration)

The workflows in `.github/workflows/` provide **automated** orchestration:

### 1. Orchestrator (`adf-orchestrator.md`)

**Role**: Coordinator that dispatches work to specialized workers and manages the fix cycle

```yaml
safe-outputs:
  dispatch-workflow:
    workflows: [adf-generate-worker, adf-review-worker]
    max: 5
```

**Responsibilities**:
- Validates issue requirements
- Dispatches generation worker with issue context
- Dispatches review worker with PR context
- **Manages fix cycles**: Re-dispatches generation with review feedback (up to 3x)
- Escalates to human review after 3 failed cycles

### 2. Generation Worker (`adf-generate-worker.md`)

**Role**: Invokes the ADF Generate agent for both initial generation AND fix cycles

```yaml
# Inputs determine mode:
inputs:
  issue_number: required    # Always provided
  pr_number: optional       # If provided → FIX mode
  review_feedback: optional # Errors to address

safe-outputs:
  create-pull-request: ...        # Used in INITIAL mode
  push-to-pull-request-branch: ...  # Used in FIX mode (updates existing PR)
```

**Two Modes**:
| Mode | Trigger | Action |
|------|---------|--------|
| **Initial** | No `pr_number` | Creates new PR with pipeline JSON |
| **Fix** | `pr_number` provided | Commits fixes to existing PR branch |

### 3. Review Worker (`adf-review-worker.md`)

**Role**: Invokes the ADF Review agent with knowledge base access

```yaml
engine:
  id: copilot
  agent: adf-review  # References .github/agents/adf-review.agent.md

tools:
  github:
  bash: ["jq", "cat"]  # For reading knowledge base JSON
```

The review agent reads `rules/common_issues.json` directly for domain knowledge. In production, this could be replaced with an MCP server, external API, or vector database.

---

## Why Multi-Agent vs Single Agent?

| Aspect | Single Agent | Multi-Agent Orchestration |
|--------|--------------|---------------------------|
| **Separation of concerns** | One agent does everything | Specialized agents per task |
| **Tool access** | All tools to one agent | Right tools to right agent |
| **Context management** | Long context, may drift | Fresh context per worker |
| **Failure isolation** | One failure stops all | Workers can retry independently |
| **Extensibility** | Modify one big agent | Add new workers easily |
| **Security** | Broad permissions | Scoped permissions per worker |

### The Review Agent's Knowledge Base

The review agent reads `rules/common_issues.json` for domain expertise:

```json
{
  "issues": {
    "KB-010": {
      "name": "Small File Iteration Anti-Pattern",
      "severity": "warning",
      "resolution": "Use wildcard file paths with bulk copy"
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

---

## Quick Start

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

   **For Claude**: Add your Anthropic API key:
   ```bash
   gh aw secrets set ANTHROPIC_API_KEY --value "your-api-key"
   ```

   **For Codex**: Add your OpenAI API key:
   ```bash
   gh aw secrets set OPENAI_API_KEY --value "your-api-key"
   ```

5. **Commit and push** the workflow files:
   ```bash
   git add .github/workflows/
   git commit -m "Add agentic workflows for ADF pipeline orchestration"
   git push
   ```

6. **Create the `adf-pipeline` label** in your repository

7. **Test it**: Create an issue describing a pipeline, add the `adf-pipeline` label

### Running Manually

```bash
# Trigger the orchestrator manually
gh aw run adf-orchestrator

# Check workflow status
gh aw status
```

---

## Repository Structure

```
├── .github/
│   ├── agents/                            # Custom agents (manually assignable)
│   │   ├── adf-generate.agent.md          # Pipeline generation agent
│   │   └── adf-review.agent.md            # Pipeline review agent
│   └── workflows/                         # Agentic workflows (automated)
│       ├── adf-orchestrator.md            # Orchestrator (coordinates workers)
│       ├── adf-generate-worker.md         # Invokes generate agent
│       ├── adf-review-worker.md           # Invokes review agent + KB
│       └── *.lock.yml                     # Compiled workflows (generated)
├── templates/                             # ADF pipeline JSON templates
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/
│   ├── best_practices.json                # Review rules
│   └── common_issues.json                 # Knowledge base for review agent
├── examples/
│   └── sample-issue.md                    # Example issue to try
├── AGENTS.md                              # Repo-wide agent instructions
└── README.md
```

---

## Key Concepts

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

## Why Agentic Workflows vs Other Approaches?

### Compared to Custom Agents + GraphQL Workflows (main branch)

| Aspect | Custom Agents + Workflows | Agentic Workflows |
|--------|---------------------------|-------------------|
| Trigger mechanism | GraphQL API (undocumented) | Native Actions trigger |
| Write permissions | Requires PAT | Safe outputs (no PAT) |
| Agent orchestration | Manual or unreliable API | `dispatch-workflow` |
| Security model | You manage it | Built-in sandboxing |
| Complexity | 5 YAML + 2 agents | 3 markdown files |

### Compared to Single Agent (feature/single-agent-approach)

| Aspect | Single Agent | Multi-Agent Orchestration |
|--------|--------------|---------------------------|
| Separation | All in one | Specialized workers |
| Tool scoping | All tools everywhere | Right tools per worker |
| Failure handling | Entire agent fails | Individual workers retry |
| Extensibility | Modify one agent | Add new workers |

---

## Comparison: Three Approaches

This repository has three branches demonstrating different approaches:

| Branch | Approach | Agents | Workflows | Automation |
|--------|----------|--------|-----------|------------|
| `main` | Custom Agents + GraphQL | 2 agents | 5 YAML | Partial (API issues) |
| `feature/single-agent-approach` | Single Custom Agent | 1 agent | 0 | Manual trigger |
| `feature/agentic-workflows` | **Agentic Workflows** | 2 agents | 3 markdown | **Full orchestration** |

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
