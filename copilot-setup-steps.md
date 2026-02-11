# Copilot Setup Steps

This file tells GitHub Copilot Coding Agent how to set up the development environment.

## Environment Setup

No dependencies to install. This repository contains only markdown agent definitions, JSON templates, and JSON rules — no build step is required.

## Key Files

- `.github/agents/adf-generate.md` — Instructions for the ADF pipeline generation agent.
- `.github/agents/adf-review.md` — Instructions for the ADF pipeline review agent.
- `templates/copy_activity.json` — Reference template for Copy activity pipelines.
- `templates/dataflow_activity.json` — Reference template for Data Flow pipelines.
- `rules/best_practices.json` — Review rules and thresholds used by the review agent.

## Working with Pipelines

Generated pipelines should be committed to a `pipelines/` directory as JSON files.
Pipeline JSON must follow the Azure Data Factory ARM template schema.

