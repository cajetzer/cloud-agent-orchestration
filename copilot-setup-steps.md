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

The repository uses **fully automated agent orchestration via GitHub GraphQL API**:

- **Issue labeled `adf-generate`** → `assign-adf-generate-agent.yml` → GraphQL API assigns generation agent → Agent starts automatically
- **PR labeled `adf-pipeline`** → `assign-adf-review-agent.yml` → GraphQL API assigns review agent → Agent starts automatically
- **Review with errors** → `handle-adf-review-results.yml` → GraphQL API re-assigns generation agent → Fix cycle continues
- **Retry count >= 3** → `escalate-to-human-review.yml` → Escalates to human review

No manual agent assignment (dropdown clicks) is required. All agent assignments happen via `agentAssignment` GraphQL mutations with `customAgent` field.

## Working with Pipelines

Generated pipelines should be committed to a `pipelines/` directory as JSON files.
Pipeline JSON must follow the Azure Data Factory ARM template schema.


