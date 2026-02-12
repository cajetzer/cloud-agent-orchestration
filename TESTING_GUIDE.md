# Testing Guide for ADF Agent Orchestration

This guide walks through testing the complete agent orchestration workflow.

## Prerequisites

1. Repository forked/cloned to your GitHub org
2. Copilot Coding Agent enabled for your org and repo
3. Custom agents deployed in `.github/agents/`
4. All four workflows active in `.github/workflows/`
5. Required labels created (see README.md Step 3)
6. **`COPILOT_PAT` secret configured** (see README.md Step 4) — required for automatic assignment

## Test Scenario 1: Fully Automated Flow (with PAT)

This tests the complete automated orchestration when `COPILOT_PAT` is configured.

### Step 1: Create Test Issue

1. Go to your repository on GitHub
2. Click **Issues** → **New issue**
3. Fill in:
   - **Title**: `Create a copy pipeline from Azure Blob Storage to Azure SQL Database`
   - **Body**: Use content from `examples/sample-issue.md`
   - **Labels**: Add `adf-generate`
4. Click **Create issue**

### Step 2: Verify Automatic Assignment

1. Check the **Actions** tab — `Assign ADF Generate Agent to Issue` workflow should run
2. Return to the issue
3. Verify:
   - Comment posted: `🤖 ADF Pipeline Generation Agent Assigned`
   - Label added: `agent-in-progress`
   - **Copilot assigned** to the issue (check Assignees section)

### Step 3: Watch Copilot Work

1. Wait 1-2 minutes for Copilot to start
2. Copilot will:
   - Read the issue requirements
   - Generate a pipeline JSON file
   - Create a new branch
   - Open a pull request with `adf-pipeline` label

### Step 4: Verify Review Assignment

1. Navigate to the newly created PR
2. Check **Actions** tab — `Assign ADF Review Agent to PR` should run
3. Verify on PR:
   - Comment: `🔍 ADF Pipeline Review Agent Assigned`
   - Labels: `review-in-progress`, `retry-count-1`
   - **Copilot assigned** to the PR

### Step 5: Review Cycle

1. Copilot review agent analyzes the pipeline
2. Posts detailed findings as a comment
3. Workflow parses results and routes accordingly:
   - **No errors**: Labels `approved` or `approved-with-warnings`
   - **Errors found**: Re-assigns Copilot to fix, increments retry count

### Step 6: Verify Escalation (if needed)

If errors persist through 3 cycles:
1. Labels added: `needs-human-review`, `escalated`
2. Escalation comment posted
3. Human intervention required

## Test Scenario 2: Manual Fallback (without PAT)

This tests the workflow when `COPILOT_PAT` is not configured.

### Setup

1. Temporarily delete or rename the `COPILOT_PAT` secret
2. Or use a fresh repository without the secret

### Test Steps

1. Create issue with `adf-generate` label
2. Workflow runs and posts comment with instructions
3. **Copilot is NOT automatically assigned** (GraphQL fails gracefully)
4. Workflow logs show: `GraphQL assignment failed. Manual workspace trigger required.`
5. Manually click **"Open in Workspace"** on the issue
6. Select **"adf-generate"** from the dropdown
7. Agent works correctly

This verifies the fallback path works when automatic assignment isn't available.

## Test Scenario 3: Workflow State Recovery

### Simulate Interrupted Cycle

1. Create issue with `adf-generate` label
2. Let agent create a PR
3. **Manually** add label `retry-count-2` to the PR
4. Trigger review (automatic or manual)
5. If errors found, workflow should:
   - Increment to `retry-count-3`
   - On next error cycle, escalate to human review

This tests that workflows correctly track state via labels.

## Expected Outcomes

### ✅ Success Criteria (with PAT)

- [ ] Workflows trigger automatically when labels are added
- [ ] **Copilot is automatically assigned** to issues/PRs
- [ ] Custom agent is specified via `agentAssignment.customAgent`
- [ ] Labels update correctly at each stage
- [ ] Retry counter increments properly
- [ ] Review results parsed correctly
- [ ] Routing logic works (errors → fix cycle, warnings → approval)
- [ ] Escalation triggers after 3 retry cycles

### ✅ Success Criteria (without PAT)

- [ ] Workflows trigger and post instructions
- [ ] GraphQL assignment fails gracefully (no workflow failure)
- [ ] Users can manually open in Workspace and select agent
- [ ] Rest of the flow works normally

### ❌ Common Issues

**Issue**: Copilot not assigned automatically
- **Cause**: `COPILOT_PAT` secret missing or invalid
- **Fix**: Create PAT and add as repository secret (see README Step 4)

**Issue**: GraphQL error "target repository is not writable"
- **Cause**: PAT permissions insufficient
- **Fix**: Ensure PAT has Contents, Issues, Pull requests read/write

**Issue**: Workflow doesn't trigger
- **Check**: Labels configured correctly?
- **Check**: Workflows enabled in Actions tab?
- **Fix**: Verify label names match workflow conditions

**Issue**: Review not triggered
- **Check**: PR has `adf-pipeline` label?
- **Fix**: Generation agent should add this label; add manually if missing

**Issue**: Escalation doesn't trigger
- **Check**: PR has `retry-count-3` label?
- **Check**: Comment containing review results was posted?
- **Fix**: Verify `escalate-to-human-review.yml` workflow conditions

## Troubleshooting Commands

```bash
# Check workflow runs
gh run list --repo <owner>/<repo> --limit 10

# View specific workflow run logs  
gh run view <run-id> --repo <owner>/<repo> --log

# Check if Copilot bot ID can be retrieved
gh api /users/copilot-swe-agent[bot] --jq '.node_id'

# Check issue details including assignees
gh issue view <issue-number> --repo <owner>/<repo> --json assignees,labels

# Check PR details
gh pr view <pr-number> --repo <owner>/<repo> --json assignees,labels

# Test GraphQL mutation manually (replace IDs)
gh api graphql \
  -H 'GraphQL-Features: issues_copilot_assignment_api_support,coding_agent_model_selection' \
  -f query='mutation { 
    addAssigneesToAssignable(input: { 
      assignableId: "<ISSUE_NODE_ID>", 
      assigneeIds: ["<COPILOT_BOT_ID>"], 
      agentAssignment: { 
        targetRepositoryId: "<REPO_NODE_ID>", 
        customAgent: "adf-generate" 
      } 
    }) { assignable { ... on Issue { title } } } 
  }'
```

## Success Metrics

After testing, you should see:

1. **Automation**: Workflows detect events and post instructions automatically
2. **Guidance**: Clear instructions tell users which agent to select
3. **State Tracking**: Labels accurately reflect current state of the cycle
4. **Routing**: Review results correctly determine next steps
5. **Escalation**: After 3 cycles, human review is requested
6. **Resilience**: Workflow failures don't break the process

## Next Steps After Testing

1. Document any discovered issues
2. Adjust workflow triggers if needed
3. Refine instruction comments for clarity
4. Consider adding more detailed logging
5. Share this testing guide with team members
