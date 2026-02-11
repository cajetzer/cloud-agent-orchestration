# ADF Agent Orchestration

Two **Copilot Coding Agent custom agents** for Azure Data Factory pipeline development — defined entirely as markdown files in `.github/agents/`. No servers, no Docker, no deployment.

| Agent | File | Purpose |
|-------|------|---------|
| **ADF Generation Agent** | `.github/agents/adf-generate.md` | Generates ADF pipeline JSON from natural language descriptions in GitHub Issues |
| **ADF Review Agent** | `.github/agents/adf-review.md` | Reviews generated pipelines for functionality, best practices, and common issues |

## Architecture

```
Issue created + labeled "adf-generate"
  → Assign Copilot to the issue
    → Copilot uses adf-generate agent instructions
      → Generates pipeline JSON, opens PR
        → Comments: "@adf-review please review"
          → Assign Copilot to the PR (or re-assign on the comment)
            → Copilot uses adf-review agent instructions
              → Reviews the pipeline
                ├── ✅ Approved → labels PR "approved"
                └── ❌ Issues found → comments "@adf-generate please fix"
                  → Copilot uses adf-generate agent instructions
                    → Fixes issues, pushes to same branch
                      → Re-triggers review cycle...
```

## Repository Structure

```
├── .github/
│   └── agents/
│       ├── adf-generate.md    # Copilot custom agent — pipeline generation
│       └── adf-review.md      # Copilot custom agent — pipeline review
├── templates/                 # ADF pipeline JSON templates (used by adf-generate)
│   ├── copy_activity.json
│   └── dataflow_activity.json
├── rules/                     # Review rules (used by adf-review)
│   └── best_practices.json
├── examples/
│   └── sample-issue.md        # Example issue to test the flow
├── copilot-setup-steps.md
└── README.md
```

---

## Setup on GitHub.com — Step by Step

### Prerequisites

- A GitHub organization or personal account with **Copilot Coding Agent** enabled (requires a GitHub Copilot Enterprise or Copilot Business plan with the coding agent feature turned on)
- Repository-level permission to manage labels and settings

---

### Step 1: Create the Repository on GitHub

1. Go to [github.com/new](https://github.com/new).
2. Name the repository (e.g., `adf-agent-orchestration`).
3. Set visibility to **Private** (recommended) or Public.
4. **Do not** initialize with a README (you already have one).
5. Click **Create repository**.
6. Push this code to the new repository:

```bash
cd cloud-agent-orchestration
git remote add origin https://github.com/<your-org>/<your-repo>.git
git branch -M main
git push -u origin main
```

---

### Step 2: Enable Copilot Coding Agent on the Repository

1. Go to your **organization settings** → **Copilot** → **Policies** (or `https://github.com/organizations/<your-org>/settings/copilot/coding_agent`).
2. Enable **Copilot coding agent** for the organization (or for selected repositories).
3. In your **repository settings** → **General** → **Features**, confirm that **Issues** and **Pull Requests** are enabled.
4. Under **Settings → Copilot → Coding agent**, ensure the repo is opted in.

> **Note:** Copilot Coding Agent is available with GitHub Copilot Enterprise and GitHub Copilot Business plans. Confirm your plan has access to this feature.

---

### Step 3: Create Required Labels

The agents use labels for routing and status tracking. Create them in your repository:

1. Go to **Issues → Labels** (or navigate to `https://github.com/<owner>/<repo>/labels`).
2. Create the following labels:

| Label | Color (suggested) | Description |
|-------|-------------------|-------------|
| `adf-generate` | `#1D76DB` (blue) | Marks issues that request ADF pipeline generation |
| `adf-pipeline` | `#0E8A16` (green) | Marks PRs containing ADF pipelines |
| `changes-requested` | `#E11D48` (red) | Review agent found issues to fix |
| `approved` | `#0E8A16` (green) | Pipeline passed review |
| `approved-with-warnings` | `#F9A825` (amber) | Pipeline approved with minor suggestions |
| `needs-human-review` | `#B60205` (red) | Max review cycles reached; human needed |

---

### Step 4: Verify the Custom Agents Are Detected

After pushing the repo, verify that Copilot recognizes the agent files:

1. The agent files live at `.github/agents/adf-generate.md` and `.github/agents/adf-review.md`.
2. These are automatically picked up by Copilot Coding Agent — no additional registration is needed.
3. When you assign Copilot to an issue and mention `@adf-generate` or `@adf-review` in the issue body or a comment, Copilot will follow the corresponding agent's instructions.

---

### Step 5: Test the Full Flow

#### Trigger the Generation Agent

1. **Create a new issue** in your repository with the label `adf-generate`.
2. Use a description like the one in [examples/sample-issue.md](examples/sample-issue.md):

   > **Title:** Create a copy pipeline from Azure Blob Storage to Azure SQL Database
   >
   > **Body:** I need an ADF pipeline that copies CSV files from an Azure Blob Storage container `raw-data/sales/` into a staging table `staging.sales_data` in Azure SQL Database. Schedule daily at 2:00 AM UTC with retry up to 3 times.

3. **Assign Copilot** to the issue. You can do this by:
   - Clicking "Assignees" on the issue and selecting **Copilot**, or
   - Commenting `@copilot` on the issue to get Copilot's attention.

4. Copilot will pick up the `adf-generate` agent instructions (based on the `adf-generate` label and/or `@adf-generate` mention) and:
   - Read the issue requirements
   - Use the templates in `templates/` as reference
   - Generate a pipeline JSON file
   - Create a branch and open a PR
   - Comment on the PR mentioning `@adf-review` to request a review

#### Trigger the Review Agent

5. On the PR, **assign Copilot** again (or it may pick up the `@adf-review` mention automatically).
6. Copilot will follow the `adf-review` agent instructions and:
   - Read the pipeline JSON files in the PR
   - Check against the rules in `rules/best_practices.json`
   - Post a structured review comment with findings
   - Either approve (adds `approved` label) or request changes (mentions `@adf-generate` for fixes)

#### Review/Fix Cycle

7. If the review agent requests changes, assign Copilot to address the feedback. It will follow the `adf-generate` agent instructions to fix the pipeline and request re-review.
8. This cycle continues up to 3 rounds. After that, the agent adds the `needs-human-review` label.

---

## How the Agents Work

### `adf-generate` Agent

Defined in `.github/agents/adf-generate.md`. When Copilot follows this agent:

1. Reads the issue description to understand the pipeline requirements.
2. Detects the pipeline type (Copy, Data Flow, or Generic).
3. Uses templates from `templates/` as starting points.
4. Generates a complete ADF pipeline JSON with proper structure, policies, parameters, and naming.
5. Opens a PR with the pipeline and hands off to the review agent.
6. If review feedback comes back, reads the feedback, applies fixes, and re-requests review.

### `adf-review` Agent

Defined in `.github/agents/adf-review.md`. When Copilot follows this agent:

1. Reads the pipeline JSON files in the PR.
2. Checks against six categories of rules (structure, activities, policies, parameterization, naming, security).
3. Posts a formatted review with findings classified as **error**, **warning**, or **info**.
4. Decides the outcome:
   - **Errors** → hands back to `adf-generate` for fixes.
   - **Warnings only** → approves with notes.
   - **Clean** → approves.

---

## Review Rules

The review agent checks pipelines against rules defined in `rules/best_practices.json`:

| Category | What it checks |
|----------|---------------|
| **Structure** | Pipeline has `name`, `properties`, `description`, `activities`, `annotations`, and `folder` |
| **Activities** | Activities have names; Copy activities have `source`, `sink`, `inputs`, and `outputs` |
| **Policies** | Non-trivial activities have retry policies (1–5 retries) and explicit timeouts (max 7 days) |
| **Parameters** | Flags hardcoded connection strings, server names, and file paths |
| **Naming** | Names start with a letter, are under 120 characters, and are unique |
| **Security** | Flags plaintext secrets and recommends `secureInput`/`secureOutput` for sensitive activities |

Findings are categorized as **error** (blocks approval), **warning** (approved with notes), or **info** (suggestions).

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Copilot doesn't use the agent instructions | Make sure the `.github/agents/` directory is on the default branch. Verify Copilot Coding Agent is enabled for the repo. |
| Copilot doesn't pick the right agent | Mention the agent explicitly in your comment: `@adf-generate` or `@adf-review`. Use the `adf-generate` label on issues. |
| Copilot isn't available as an assignee | Confirm your org/plan has Copilot Coding Agent enabled. Check organization Copilot policies. |
| Review/fix cycle runs too long | The agents are instructed to stop after 3 round-trips and add the `needs-human-review` label. |
| Agent doesn't follow the templates | The agent instructions reference `templates/` and `rules/` directories — make sure those files exist on the branch Copilot is working from. |
