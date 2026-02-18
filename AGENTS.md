# AGENTS.md

Instructions for AI coding agents working in this repository.

## Repository Purpose

This is a **learning and demo repository** showing how to use GitHub Copilot custom agents for Azure Data Factory pipeline generation. It demonstrates the **single-agent pattern** — one agent that handles multiple phases of work (generation + self-review).

## Build & Test Commands

This repository contains no application code to build or test. It contains:
- Custom agent definitions (`.github/agents/`)
- JSON templates (`templates/`)
- Review rules (`rules/`)
- Documentation

## Working with This Repository

### When Generating Pipelines

1. Read the issue requirements thoroughly
2. Use templates in `templates/` as starting points
3. Follow rules in `rules/best_practices.json` for quality checks
4. Always parameterize environment-specific values
5. Self-review before opening PR

### File Organization

| Directory | Purpose |
|-----------|---------|
| `.github/agents/` | Custom agent definitions |
| `templates/` | ADF pipeline JSON templates |
| `rules/` | Best practices rules for validation |
| `pipelines/` | Generated pipelines (created by agent) |
| `examples/` | Sample issues and expected outputs |

### Code Style for Generated JSON

- Use 2-space indentation
- Include descriptive `description` fields
- Use lowercase_underscore naming for pipelines
- Always include `annotations` array
- Always include `folder` property

### Commit Message Format

```
[ADF Pipeline] <brief description>

- List key changes
- Reference issue number

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Important Conventions

- **Never hardcode** connection strings, server names, or file paths
- **Always use parameters** for environment-specific values
- **Include retry policies** on all non-trivial activities
- **Set explicit timeouts** (max 7 days)
- **Use secureInput/secureOutput** for credential-handling activities
