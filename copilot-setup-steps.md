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

The repository uses **hybrid automation combining GitHub Actions with manual Copilot Workspace triggers**:

- **Issue labeled `adf-generate`** → `assign-adf-generate-agent.yml` → Posts instructions → **User opens in Workspace** → Selects "adf-generate" agent → Agent starts working
- **PR labeled `adf-pipeline`** → `assign-adf-review-agent.yml` → Posts instructions → **User opens PR in Workspace** → Selects "adf-review" agent → Agent reviews
- **Review with errors** → `handle-adf-review-results.yml` → Posts fix instructions → **User re-opens in Workspace** → Selects "adf-generate" → Fix cycle continues
- **Retry count >= 3** → `escalate-to-human-review.yml` → Escalates to human review

Workflows provide orchestration logic (state tracking, routing, escalation) while Copilot Workspace provides execution. This teaches users the complete Copilot workflow including both automation and agent capabilities.

## Working with Pipelines

Generated pipelines should be committed to a `pipelines/` directory as JSON files.
Pipeline JSON must follow the Azure Data Factory ARM template schema.


