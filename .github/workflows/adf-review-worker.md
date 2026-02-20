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

## Required Actions (Safe Outputs)

**CRITICAL**: This workflow runs in a sandboxed environment. You MUST call the safe-output MCP tools to post review results. Do not just describe what you would do; actually invoke the tools listed below.

### Post Review Results:

1. **Call `add_comment`** via the safeoutputs MCP server to post your findings on the PR:
   - `item_number`: `${{ inputs.pr_number }}`
   - `body`: Structured review results with errors, warnings, and suggestions

2. **Call `add_labels`** via the safeoutputs MCP server based on review outcome:
   - `item_number`: `${{ inputs.pr_number }}`
   - `labels`: `["changes-requested"]` OR `["approved-with-warnings"]` OR `["approved"]`

3. **Optionally call `create_pull_request_review_comment`** via the safeoutputs MCP server for specific inline issues:
   - `pr_number`: `${{ inputs.pr_number }}`
   - `body`: Specific feedback
   - `path`: File path
   - `line`: Line number

## Workflow Steps

1. Read the PR description and changed files using GitHub tools
2. Read each pipeline JSON file in `pipelines/` directory
3. Check against `rules/best_practices.json`
4. Query `rules/common_issues.json` for known anti-patterns
5. Compile findings into errors, warnings, and suggestions
6. **Call the safe-output tools** to post review and add labels

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

_The agent will follow the detailed instructions in `.github/agents/adf-review.agent.md` for review logic, and use the safe-output MCP tools above to publish results. If no tools can be called due to missing data or a limitation, call the `noop` or `missing_data` tool to report the status._
