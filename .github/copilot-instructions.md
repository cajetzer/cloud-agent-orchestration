# Copilot Instructions for Cloud Agent Orchestration

This repository demonstrates GitHub Copilot Coding Agent orchestration using custom agents and GitHub Actions workflows. There is no application code—only agent definitions, workflow YAML, JSON templates/rules, and documentation.

## Architecture Overview

**Two custom agents** work together via workflow-driven handoffs:

1. **ADF Generate Agent** (`.github/agents/adf-generate.agent.md`) — Generates Azure Data Factory pipeline JSON from issue descriptions
2. **ADF Review Agent** (`.github/agents/adf-review.agent.md`) — Reviews generated pipelines against best practices

**Orchestration flow:**
```
Issue + "adf-generate" label
  → assign-adf-generate-agent.yml (assigns Copilot via GraphQL)
  → Agent generates pipeline, opens PR with "adf-pipeline" label
  → assign-adf-review-agent.yml (assigns review agent)
  → Review agent posts findings
  → handle-adf-review-results.yml (routes: fix cycle or approve)
  → After 3 failed cycles → escalate-to-human-review.yml
```

**Key concepts:**
- Workflows use GraphQL API with `agentAssignment` to assign Copilot with specific custom agents
- Labels track state (`agent-in-progress`, `retry-count-N`, `approved`, `changes-requested`)
- `COPILOT_PAT` secret required for automated assignment (standard `GITHUB_TOKEN` lacks permission)

## Key Files

| Path | Purpose |
|------|---------|
| `.github/agents/*.agent.md` | Custom agent definitions (activation conditions, step-by-step instructions) |
| `.github/workflows/*.yml` | Orchestration workflows (event triggers, GraphQL calls, state management) |
| `templates/*.json` | ADF pipeline JSON templates (Copy, Data Flow) |
| `rules/best_practices.json` | Review rules (retry policies, naming, security, parameterization) |

## Conventions

### Agent Definition Structure
Agent files use YAML frontmatter + markdown body:
```markdown
---
name: Agent Name
description: What it does
tools: ["read", "edit", "search"]
---
# Agent Name
## When to Activate
## Instructions
```

### Pipeline JSON Requirements
Generated pipelines must include:
- `name`, `properties.description`, `annotations`, `folder`
- `policy` block on activities (retry 1-5, explicit timeout ≤ 7 days)
- Parameterized values—never hardcode connection strings, paths, or credentials
- `secureInput`/`secureOutput` on credential-handling activities

### Label Conventions
- Trigger labels: `adf-generate`, `adf-pipeline`
- Status: `agent-in-progress`, `review-in-progress`, `approved`, `changes-requested`
- Retry tracking: `retry-count-1`, `retry-count-2`, `retry-count-3`
- Escalation: `needs-human-review`, `escalated`

## GraphQL Agent Assignment Pattern

Workflows assign Copilot using this mutation structure:
```graphql
mutation {
  addAssigneesToAssignable(input: {
    assignableId: "<ISSUE_OR_PR_NODE_ID>",
    assigneeIds: ["<COPILOT_BOT_ID>"],
    agentAssignment: {
      targetRepositoryId: "<REPO_NODE_ID>",
      baseRef: "main",
      customAgent: "adf-generate",
      customInstructions: "..."
    }
  }) { ... }
}
```
Requires feature flags: `issues_copilot_assignment_api_support`, `coding_agent_model_selection`
