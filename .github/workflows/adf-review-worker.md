---
description: "Worker workflow that invokes the ADF Review agent with knowledge base access"

on:
  workflow_dispatch:
    inputs:
      pr_number:
        description: "Pull request number to review"
        required: true
        type: number
      issue_number:
        description: "Original issue number"
        required: true
        type: number

permissions:
  contents: read
  issues: read
  pull-requests: read

safe-outputs:
  add-comment:
    max: 3
  add-labels:
    max: 3
  create-pull-request-review-comment:
    max: 10

engine:
  id: copilot
  agent: adf-review

tools:
  github:
  bash: ["jq", "cat"]
---

# ADF Pipeline Review Worker

This workflow invokes the **ADF Review Agent** (defined in `.github/agents/adf-review.agent.md`) to review Azure Data Factory pipeline JSON files.

## Workflow Context

The agent receives the following inputs from the orchestrator:
- **PR number**: `${{ inputs.pr_number }}`
- **Original issue**: `${{ inputs.issue_number }}`

## Available Resources

The agent has access to:
- **GitHub tools**: Read PR files, post comments and reviews, access repository content
- **bash tools**: `jq` and `cat` commands for JSON parsing
- **Knowledge Base**: `rules/common_issues.json` contains known ADF issues and resolutions
- **Best Practices**: `rules/best_practices.json` defines validation rules

## Knowledge Base Access

The agent can read the knowledge base using bash commands:

```bash
# Read the knowledge base
cat rules/common_issues.json | jq '.issues'

# Search for specific issue
cat rules/common_issues.json | jq '.issues["KB-010"]'

# Get all anti-patterns
cat rules/common_issues.json | jq '.antipatterns'
```

In a production environment, this could be enhanced with:
- An MCP server connected to a vector database
- A web-fetch call to a knowledge base API
- Azure AI Search or similar service

## Expected Output

The agent will:
1. Read the PR description and changed files
2. Review pipeline JSON files in `pipelines/` directory
3. Check against best practices and the knowledge base
4. Post structured review comments with findings categorized as:
   - ❌ **ERROR** - Must be fixed before merging
   - ⚠️ **WARNING** - Should be fixed
   - ℹ️ **INFO** - Suggestions
5. Add appropriate labels to the PR:
   - `changes-requested` if errors found
   - `approved-with-warnings` if only warnings
   - `approved` if clean

---

_The agent will follow the detailed instructions in `.github/agents/adf-review.agent.md` to complete these tasks._
