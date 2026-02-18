# GitHub Copilot Custom Agent — ADF Pipeline Generator

A **learning and demo repository** showing how to use a GitHub Copilot custom agent for Azure Data Factory pipeline generation.

This demonstrates the **single-agent pattern** — one custom agent that handles multiple phases of work (generation + self-review) without requiring workflow orchestration or agent handoffs.

## What This Repository Demonstrates

| Concept | Implementation |
|---------|----------------|
| **Custom Agent** | `.github/agents/adf-pipeline.agent.md` |
| **Multi-phase workflow** | Generate → Self-Review → Open PR |
| **Template-based generation** | `templates/copy_activity.json`, `templates/dataflow_activity.json` |
| **Automated quality checks** | Self-review against `rules/best_practices.json` |
| **Repo-wide agent context** | `AGENTS.md` |

---

## Quick Start (5 minutes)

### Prerequisites

- GitHub organization with **Copilot Coding Agent** enabled
- Repository with Issues enabled

### Steps

1. **Fork or clone** this repository
2. **Enable Copilot Coding Agent** in repository settings
3. **Create the `adf-pipeline` label** in your repository
4. **Create an issue** describing the pipeline you need
5. **Assign Copilot** to the issue and select the `adf-pipeline` agent
6. **Wait** — Copilot generates the pipeline, self-reviews it, and opens a PR

That's it. No PAT required. No workflows to configure. No secrets to manage.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Issue                            │
│  "Create a pipeline to copy data from Blob to SQL Database"     │
│  Label: adf-pipeline                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │  User assigns Copilot
                              │  and selects "adf-pipeline" agent
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ADF Pipeline Agent                           │
│                                                                 │
│  PHASE 1: Generate                                              │
│    • Read issue requirements                                    │
│    • Select appropriate template                                │
│    • Generate pipeline JSON with proper structure               │
│                                                                 │
│  PHASE 2: Self-Review                                           │
│    • Check against rules/best_practices.json                    │
│    • Verify structure, policies, naming, security               │
│    • Fix any issues found                                       │
│                                                                 │
│  PHASE 3: Deliver                                               │
│    • Create branch and commit pipeline                          │
│    • Open PR with self-review summary                           │
│    • Request human review                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Pull Request                             │
│  • Pipeline JSON in pipelines/                                  │
│  • Self-review checklist in description                         │
│  • Ready for human review and merge                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
├── .github/
│   └── agents/
│       └── adf-pipeline.agent.md    # The custom agent definition
├── templates/                        # ADF pipeline JSON templates
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/
│   └── best_practices.json          # Review rules for self-validation
├── examples/
│   └── sample-issue.md              # Example issue to try
├── AGENTS.md                        # Repo-wide agent instructions
└── README.md
```

---

## How the Single-Agent Pattern Works

### Why One Agent Instead of Two?

The previous version of this repository used **two agents** (generate + review) with GitHub Actions workflows to orchestrate handoffs. That approach was complex:

- 5 workflows required
- GraphQL API calls with undocumented behavior
- Personal Access Token (PAT) required
- Auto-approval hacks for bot-triggered workflows
- Complex label-based state machine

The **single-agent pattern** eliminates all of that:

| Two-Agent Approach | Single-Agent Approach |
|--------------------|-----------------------|
| 5 workflows | 0 workflows |
| PAT required | No PAT |
| GraphQL API calls | No API calls |
| Handoff orchestration | No handoffs |
| Complex state management | No state management |

### When to Use Which Pattern

| Pattern | Best For |
|---------|----------|
| **Single Agent** | Most use cases. Simpler, reliable, works in cloud and IDE |
| **Multi-Agent with Workflows** | When you need different expertise/tools per phase, or strict separation of concerns |
| **Multi-Agent with runSubagent (IDE only)** | Full automation in VS Code/JetBrains. Not available in cloud. |

---

## The Custom Agent Definition

The agent is defined in `.github/agents/adf-pipeline.agent.md`:

```markdown
---
name: ADF Pipeline Agent
description: Generates and self-reviews ADF pipeline JSON
tools: ["read", "edit", "search"]
---

# ADF Pipeline Agent

Work in three phases: Generate → Self-Review → Deliver

## Phase 1: Generate
- Read issue requirements
- Use templates from templates/
- Generate pipeline JSON

## Phase 2: Self-Review  
- Check against rules/best_practices.json
- Fix any issues found

## Phase 3: Deliver
- Open PR with self-review summary
- Request human review
```

The agent reads `AGENTS.md` for repo-wide context (build commands, conventions) and its own `.agent.md` file for task-specific instructions.

---

## Customizing for Your Use Case

### 1. Fork and Adapt the Agent

Edit `.github/agents/adf-pipeline.agent.md` to match your domain:

- Change the pipeline structure for your needs
- Add/remove review checks
- Adjust naming conventions
- Reference your own templates

### 2. Create Your Own Templates

Add templates to `templates/` for common patterns:

```json
// templates/my_template.json
{
  "name": "template_name",
  "properties": {
    "activities": [...]
  }
}
```

### 3. Define Your Review Rules

Edit `rules/best_practices.json` with your organization's standards.

### 4. Add Repo Context

Edit `AGENTS.md` with build commands, conventions, and any context agents need.

---

## Example: Creating a Pipeline

### 1. Create an Issue

**Title:** Create copy pipeline from Azure Blob Storage to Azure SQL Database

**Body:**
```markdown
## Requirements

Create an ADF pipeline that:
- Copies CSV files from Azure Blob Storage container `raw-data`
- Loads into Azure SQL Database table `dbo.SalesData`
- Runs daily at 2:00 AM UTC
- Includes error handling with 3 retries

## Source Details
- Storage Account: (parameterized)
- Container: raw-data
- File pattern: sales_*.csv

## Sink Details  
- SQL Server: (parameterized)
- Database: SalesDB
- Table: dbo.SalesData
- Write behavior: Upsert on SalesId column
```

**Label:** `adf-pipeline`

### 2. Assign Copilot

- Click **Assignees** → Add **Copilot**
- Select **adf-pipeline** from the custom agent dropdown
- Click **Assign**

### 3. Wait for Results

Copilot will:
1. Read your requirements
2. Generate pipeline JSON
3. Self-review against best practices
4. Open a PR with the pipeline and review summary

---

## Labels

Only one label is needed:

| Label | Purpose |
|-------|---------|
| `adf-pipeline` | Marks issues that request pipeline generation |

---

## Comparison with Multi-Agent Approach

The original `main` branch contains the multi-agent approach with workflow orchestration. Compare:

| Aspect | `main` (Multi-Agent) | `feature/single-agent-approach` |
|--------|----------------------|----------------------------------|
| Agents | 2 (generate + review) | 1 (combined) |
| Workflows | 5 | 0 |
| PAT Required | Yes | No |
| Complexity | High | Low |
| Cloud Support | Partial (GraphQL issues) | Full |
| IDE Support | Full | Full |

---

## Further Reading

| Topic | Resource |
|-------|----------|
| **Copilot Coding Agent** | [GitHub Docs](https://docs.github.com/en/copilot/using-github-copilot/using-copilot-coding-agent) |
| **Custom Agents** | [GitHub Docs](https://docs.github.com/en/copilot/customizing-copilot/customizing-the-behavior-of-copilot-coding-agent) |
| **Custom Agent Configuration** | [GitHub Docs](https://docs.github.com/en/copilot/reference/custom-agents-configuration) |
| **AGENTS.md Standard** | [agents.md](https://agents.md/) |

---

## License

MIT License - use this as a starting point for your own custom agents.
