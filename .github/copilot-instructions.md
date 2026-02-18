# Copilot Instructions for Cloud Agent Orchestration

This repository demonstrates GitHub Copilot Coding Agent orchestration of custom sub-agents defined in agent.md files. There is no application code—only agent definitions, JSON templates/rules, documentation, and maybe workflow YAML depending on implementation. The focus is on showcasing how to structure agent instructions and orchestrate them through Coding Agent in the cloud using the latest capabilities patterns and best practices. The solution will change over time as the product and industry changes quickly. 

## Architecture Overview

**Two custom agents** work together via workflow-driven handoffs:

1. **ADF Generate Agent** (`.github/agents/adf-generate.agent.md`) — Generates Azure Data Factory pipeline JSON from issue descriptions
2. **ADF Review Agent** (`.github/agents/adf-review.agent.md`) — Reviews generated pipelines against best practices

**Orchestration flow:**
```
Issue defines the work to be done (e.g., "Create ADF pipeline to copy from Blob to SQL")
  → assign to adf-generate agent to do the initial work
  → when complete, hand off to adf-review agent for review and research for solutions to any issues found
  → hand back to adf-generate agent to fix issues
  → repeat cycle until review agent approves or 3 cycles are completed
  → After 3 failed cycles, escalate to human review with all context and agent findings
```

**Key concepts:**
- This repo is not about the specific ADF pipelines, or the custom agents themselves - but is intended to be a technical proof, education tool, and reference example for orchestrating custom agents through Coding Agent based on current capabilities and limitations. 
- The patterns and best practices demonstrated here can be applied to orchestrating agents for any use case, not just ADF.
- All documentation should be written as educational content for users who want to learn how to implement similar patterns in their own repos

## Branch and PR Policy

**Never commit directly to `main`.** All changes must be made on a feature branch and submitted via pull request.

When making changes:
1. If not already in a feature branch, create a new branch with a descriptive name (e.g., `fix/issue-description`, `feature/new-capability`)
2. Commit changes to the feature branch
3. Push the branch and wait for review and approval before creating a Pull Request
4. Never merge your own PR. This will always be done by a human after review.

## Conventions

- no conventions in this repo should be considered gold-standard or best practices. 
- always check the latest documentation and best practices when making changes, suggesting updates to any existing conventions or patterns as needed to reflect the current state of the art in agent orchestration and Coding Agent capabilities.