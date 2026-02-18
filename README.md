# GitHub Agentic Workflows — ADF Pipeline Generator

A **learning and demo repository** showing how to use **GitHub Agentic Workflows** (technical preview) for Azure Data Factory pipeline generation.

This demonstrates the newest approach to repository automation: **Markdown-defined workflows executed by AI coding agents** inside GitHub Actions with built-in security guardrails.

> ⚠️ **Technical Preview**: GitHub Agentic Workflows launched February 13, 2026. This is cutting-edge functionality that may change.

## What Are GitHub Agentic Workflows?

Agentic Workflows are a new paradigm for repository automation:

| Traditional Workflows | Agentic Workflows |
|----------------------|-------------------|
| YAML syntax | Markdown + YAML frontmatter |
| Deterministic steps | AI agent reasoning |
| Explicit commands | Natural language instructions |
| Limited to scripted actions | Can handle judgment-based tasks |

**Key features:**
- **Markdown-defined**: Write what you want in plain language
- **Agent-executed**: Copilot, Claude, or Codex runs the workflow
- **Safe by default**: Read-only permissions, sandboxed execution
- **Safe outputs**: Controlled write operations (create PR, add comment, etc.)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Issue                            │
│  "Create a pipeline to copy data from Blob to SQL Database"     │
│  Label: adf-pipeline                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │  Issue labeled event triggers
                              │  agentic workflow
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Actions: Agentic Workflow                   │
│              .github/workflows/adf-pipeline-generator.md        │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Coding Agent                           │  │
│  │                    (Copilot/Claude/Codex)                 │  │
│  │                                                           │  │
│  │  • Reads issue requirements                               │  │
│  │  • Selects appropriate template                           │  │
│  │  • Generates pipeline JSON                                │  │
│  │  • Self-reviews against best practices                    │  │
│  │  • Requests safe-output: create-pull-request              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Safe Output Handler                          │  │
│  │              (Separate job with write permissions)        │  │
│  │                                                           │  │
│  │  • Validates agent's output                               │  │
│  │  • Creates PR with specified content                      │  │
│  │  • Adds labels and comments                               │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Pull Request                             │
│  • Pipeline JSON in pipelines/                                  │
│  • Self-review summary in description                           │
│  • Ready for human review and merge                             │
└─────────────────────────────────────────────────────────────────┘
```

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

3. **Compile the workflow** (generates lock file):
   ```bash
   gh aw compile
   ```

4. **Add required secrets** for your coding agent:
   - For Copilot: Uses your GitHub token automatically
   - For Claude: Add `ANTHROPIC_API_KEY` secret
   - For Codex: Add `OPENAI_API_KEY` secret

5. **Commit and push** the workflow files:
   ```bash
   git add .github/workflows/
   git commit -m "Add agentic workflow for ADF pipeline generation"
   git push
   ```

6. **Create the `adf-pipeline` label** in your repository

7. **Test it**: Create an issue describing a pipeline, add the `adf-pipeline` label

### Running Manually

```bash
# Trigger the workflow manually
gh aw run adf-pipeline-generator

# Check workflow status
gh aw status
```

---

## Repository Structure

```
├── .github/
│   └── workflows/
│       ├── adf-pipeline-generator.md       # Agentic workflow (Markdown)
│       └── adf-pipeline-generator.lock.yml # Compiled workflow (generated)
├── templates/                               # ADF pipeline JSON templates
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/
│   └── best_practices.json                 # Review rules for validation
├── examples/
│   └── sample-issue.md                     # Example issue to try
├── AGENTS.md                               # Repo-wide agent instructions
└── README.md
```

---

## The Agentic Workflow

### Workflow Definition

The workflow is defined in `.github/workflows/adf-pipeline-generator.md`:

```markdown
---
on:
  issues:
    types: [labeled]

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  create-pull-request:
    title-prefix: "[ADF Pipeline] "
    labels: [adf-pipeline]
  add-comment:
    max: 2

tools:
  github:
  edit:
---

# ADF Pipeline Generator

Generate an Azure Data Factory pipeline based on the issue requirements...

## Phase 1: Understand Requirements
...

## Phase 2: Generate Pipeline
...

## Phase 3: Self-Review
...

## Phase 4: Create Pull Request
...
```

### Key Concepts

#### Frontmatter (YAML)
```yaml
on:              # Standard GitHub Actions triggers
permissions:     # Read-only by default (security)
safe-outputs:    # Controlled write operations
tools:           # What the agent can use
```

#### Markdown Body
Natural language instructions for the coding agent. Describe:
- **What** you want (outcomes)
- **How** to validate (checks)
- **When** to escalate (error handling)

#### Safe Outputs
The agent runs read-only. Write operations happen through **safe outputs**:

| Safe Output | What It Does |
|-------------|--------------|
| `create-pull-request` | Creates a PR with agent's code |
| `add-comment` | Posts comments on issues/PRs |
| `add-labels` | Adds labels to issues/PRs |
| `create-issue` | Creates new issues |
| `dispatch-workflow` | Triggers other workflows |

---

## Why Agentic Workflows vs Other Approaches?

### Compared to Custom Agents + GraphQL Workflows

| Aspect | Custom Agents + Workflows | Agentic Workflows |
|--------|---------------------------|-------------------|
| Trigger mechanism | GraphQL API (undocumented) | Native Actions trigger |
| Write permissions | Requires PAT | Safe outputs (no PAT) |
| Agent selection | Manual or API call | Automatic |
| Security model | You manage it | Built-in sandboxing |
| Complexity | 5+ workflow files | 1 markdown file |

### Compared to Single Custom Agent

| Aspect | Single Custom Agent | Agentic Workflows |
|--------|---------------------|-------------------|
| Trigger | Manual assignment | Automatic on events |
| Execution | Copilot cloud session | GitHub Actions runner |
| Cost model | Premium requests | Actions minutes + agent calls |
| Guardrails | Trust the agent | Enforced safe outputs |

---

## Extending: Multi-Agent Orchestration

Agentic Workflows support the **orchestrator/worker pattern** for multi-agent scenarios:

```markdown
---
safe-outputs:
  dispatch-workflow:
    workflows: [adf-review-worker]
    max: 3
---

# ADF Pipeline Orchestrator

1. Generate the pipeline
2. Dispatch to adf-review-worker for independent review
3. Collect results and create final PR
```

Worker workflows run as separate jobs with their own agent context, enabling true multi-agent orchestration in the cloud.

---

## Comparison: Three Approaches

This repository has three branches demonstrating different approaches:

| Branch | Approach | Complexity | Automation Level |
|--------|----------|------------|------------------|
| `main` | Custom Agents + GraphQL Workflows | High | Partial (API issues) |
| `feature/single-agent-approach` | Single Custom Agent | Low | Manual trigger |
| `feature/agentic-workflows` | Agentic Workflows | Medium | Full automation |

### When to Use Each

| Use Case | Recommended Approach |
|----------|---------------------|
| Simple, reliable, works today | Single Agent |
| Full cloud automation | Agentic Workflows |
| Learning/teaching orchestration concepts | Any (compare all three) |
| Production with strict guardrails | Agentic Workflows |

---

## Further Reading

| Topic | Resource |
|-------|----------|
| **Agentic Workflows Docs** | [github.github.com/gh-aw](https://github.github.com/gh-aw/) |
| **Announcement Blog** | [GitHub Blog](https://github.blog/ai-and-ml/automate-repository-tasks-with-github-agentic-workflows/) |
| **Workflow Patterns** | [Orchestration Pattern](https://github.github.com/gh-aw/patterns/orchestration/) |
| **Safe Outputs Reference** | [Safe Outputs](https://github.github.com/gh-aw/reference/safe-outputs/) |
| **Frontmatter Reference** | [Frontmatter](https://github.github.com/gh-aw/reference/frontmatter/) |

---

## Setup Notes

### Compiling Workflows

The `.md` file is human-readable. GitHub Actions needs a `.lock.yml` file:

```bash
# Install the extension
gh extension install github/gh-aw

# Compile all workflows in .github/workflows/
gh aw compile

# The lock file is auto-generated - commit both files
git add .github/workflows/*.md .github/workflows/*.lock.yml
```

### Engine Configuration

Default engine is Copilot. To use others, add to frontmatter:

```yaml
engine: claude  # or: codex
```

And add the appropriate API key as a repository secret.

---

## License

MIT License - use this as a starting point for your own agentic workflows.
