# Pipelines Directory Setup

## Overview

This document explains how to set up the `pipelines/` directory for storing generated ADF pipeline JSON files.

## Background

The ADF Generation Agent creates pipeline JSON files that should be stored in a dedicated `pipelines/` directory. This directory should be created before the first pipeline generation or as part of the first PR merge.

## Setup Steps

### Option 1: Manual Creation (Recommended for First-Time Setup)

```bash
# From the repository root
mkdir -p pipelines

# Move any pipelines from examples/ if they exist
mv examples/copy_blob_to_sql_sales_data.json pipelines/ 2>/dev/null || true

# Commit the directory structure
git add pipelines/
git commit -m "Create pipelines directory for generated ADF pipelines"
```

### Option 2: Automated Setup Script

Create and run this setup script:

```bash
#!/bin/bash
# setup-pipelines.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINES_DIR="$REPO_ROOT/pipelines"

# Create pipelines directory
mkdir -p "$PIPELINES_DIR"

# Move any pipelines from examples/
if [ -d "$REPO_ROOT/examples" ]; then
    for file in "$REPO_ROOT/examples"/*.json; do
        if [ -f "$file" ] && grep -q '"type": "Copy"' "$file" 2>/dev/null; then
            echo "Moving $(basename "$file") to pipelines/"
            mv "$file" "$PIPELINES_DIR/"
        fi
    done
fi

echo "✓ Pipelines directory setup complete"
ls -la "$PIPELINES_DIR"
```

Make it executable and run:

```bash
chmod +x setup-pipelines.sh
./setup-pipelines.sh
```

## Directory Structure

After setup, your repository structure should include:

```
cloud-agent-orchestration/
├── .github/
│   ├── agents/
│   └── workflows/
├── templates/
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/
│   └── best_practices.json
├── pipelines/              # ← Generated pipeline files go here
│   └── *.json
└── examples/
    └── sample-issue.md
```

## Troubleshooting

**Issue:** Agent cannot create files in `pipelines/` directory

**Solution:** The directory must exist before files can be created there. Run one of the setup options above.

**Issue:** Directory exists but pipelines are still created in `examples/`

**Solution:** This might be a tooling limitation. Manually move the files:

```bash
mv examples/*.json pipelines/ 2>/dev/null
```

## Best Practices

1. **One pipeline per file**: Each ADF pipeline should be in its own JSON file
2. **Descriptive names**: Use lowercase with underscores (e.g., `copy_blob_to_sql_sales_data.json`)
3. **Track in Git**: The `.gitignore` explicitly allows tracking `pipelines/` directory
4. **Review before merge**: All generated pipelines should go through the ADF Review Agent

## Related Files

- Agent definition: `.github/agents/adf-generate.agent.md`
- Best practices: `rules/best_practices.json`
- Templates: `templates/copy_activity.json`, `templates/dataflow_activity.json`
