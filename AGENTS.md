# AGENTS.md

Instructions for AI coding agents working in this repository.

## Repository Purpose

This is a **learning and demo repository** showing how to use **GitHub Agentic Workflows** for Azure Data Factory pipeline generation. It demonstrates the new technical preview feature that runs coding agents inside GitHub Actions with built-in guardrails.

## What Are Agentic Workflows?

Agentic Workflows are a new GitHub feature (technical preview Feb 2026) that:
- Define automation in **Markdown** (not YAML)
- Execute using **coding agents** (Copilot, Claude, Codex)
- Run inside **GitHub Actions** with sandboxing
- Use **safe outputs** for controlled write operations

## Build & Test Commands

This repository contains no application code. It contains:
- Agentic workflow definitions (`.github/workflows/*.md`)
- JSON templates (`templates/`)
- Review rules (`rules/`)

## File Organization

| Directory | Purpose |
|-----------|---------|
| `.github/workflows/` | Agentic workflow markdown files |
| `.github/agents/` | Custom agent definitions (can be assigned manually via Copilot UI) |
| `templates/` | ADF pipeline JSON templates |
| `rules/` | Best practices rules and knowledge base |
| `pipelines/` | Generated pipelines (created by workflow) |
| `examples/` | Sample issues and expected outputs |

## Workflow Execution

When the agentic workflow runs:
1. It reads issue requirements
2. Uses templates from `templates/` as starting points
3. Validates against `rules/best_practices.json`
4. Creates a PR via safe-outputs (controlled write operation)

## Code Style for Generated JSON

- Use 2-space indentation
- Include descriptive `description` fields
- Use lowercase_underscore naming for pipelines
- Always include `annotations` array
- Always include `folder` property

## Important Conventions

- **Never hardcode** connection strings, server names, or file paths
- **Always use parameters** for environment-specific values
- **Include retry policies** on all non-trivial activities
- **Set explicit timeouts** (max 7 days)
- **Use secureInput/secureOutput** for credential-handling activities
