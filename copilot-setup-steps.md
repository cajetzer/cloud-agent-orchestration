# Copilot Setup Steps

This file tells GitHub Copilot Coding Agent how to set up the development environment.

## Environment Setup

No dependencies to install. This repository contains only markdown agent definitions, JSON templates, and JSON rules — no build step is required.

## Key Files

- `.github/agents/adf-generate.agent.md` — Instructions for the ADF pipeline generation agent.
- `.github/agents/adf-review.agent.md` — Instructions for the ADF pipeline review agent.
- `.github/workflows/` — GitHub Actions workflows that orchestrate agent assignments via GraphQL API
- `templates/copy_activity.json` — Reference template for Copy activity pipelines.
- `templates/dataflow_activity.json` — Reference template for Data Flow pipelines.
- `rules/best_practices.json` — Review rules and thresholds used by the review agent.

## Workflow Automation

The repository uses **fully automated agent orchestration via GitHub Actions and GraphQL API**:

- **Issue labeled `adf-generate`** → Workflow calls GraphQL API → Copilot assigned with `customAgent: "adf-generate"` → Agent starts automatically
- **PR labeled `adf-pipeline`** → Workflow calls GraphQL API → Copilot assigned with `customAgent: "adf-review"` → Agent reviews automatically  
- **Review with errors** → Workflow parses results → GraphQL API re-assigns Copilot with `customAgent: "adf-generate"` → Fix cycle continues
- **Retry count >= 3** → `escalate-to-human-review.yml` → Escalates to human review

## Required Setup

For fully automated agent assignment, the repository needs a Personal Access Token (PAT):

1. Create a fine-grained PAT at https://github.com/settings/tokens?type=beta
2. Grant permissions: Contents (read/write), Issues (read/write), Pull requests (read/write)
3. Add as repository secret named `COPILOT_PAT`

Without the PAT, workflows will still run but cannot automatically assign Copilot. They will post instructions for manual Workspace triggering instead.

## Working with Pipelines

Generated pipelines should be committed to a `pipelines/` directory as JSON files.
Pipeline JSON must follow the Azure Data Factory ARM template schema.
