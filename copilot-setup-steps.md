# Copilot Setup Steps

This file tells GitHub Copilot Coding Agent how to set up the development environment when manually assigned to an issue or PR.

## Environment Setup

No dependencies to install. This repository contains only markdown agent definitions, JSON templates, and JSON rules — no build step is required.

## Key Files

- `.github/agents/adf-generate.agent.md` — Instructions for the ADF pipeline generation agent.
- `.github/agents/adf-review.agent.md` — Instructions for the ADF pipeline review agent.
- `templates/copy_activity.json` — Reference template for Copy activity pipelines.
- `templates/dataflow_activity.json` — Reference template for Data Flow pipelines.
- `rules/best_practices.json` — Review rules and thresholds used by the review agent.
- `rules/common_issues.json` — Knowledge base of common ADF issues and resolutions.

## Working with Pipelines

Generated pipelines should be committed to a `pipelines/` directory as JSON files.
Pipeline JSON must follow the Azure Data Factory ARM template schema.
