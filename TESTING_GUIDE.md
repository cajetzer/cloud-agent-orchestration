# Testing Guide for ADF Agent Orchestration

This guide walks through testing the complete agent orchestration workflow after the fixes have been applied.

## Prerequisites

1. Repository with Copilot Coding Agent enabled
2. Custom agents (`adf-generate` and `adf-review`) deployed in `.github/agents/`
3. All four workflows active in `.github/workflows/`
4. Required labels created (see README.md Step 3)

## Test Scenario 1: Complete Generation → Review → Approval Cycle

### Step 1: Create Test Issue

1. Go to your repository on GitHub
2. Click **Issues** → **New issue**
3. Fill in:
   - **Title**: `Create a copy pipeline from Azure Blob Storage to Azure SQL Database`
   - **Body**: Use content from `examples/sample-issue.md`
   - **Labels**: Add `adf-generate`
4. Click **Create issue**

### Step 2: Verify Workflow Triggers

1. Check the **Actions** tab
2. You should see `Assign ADF Generate Agent to Issue` workflow running
3. Return to the issue
4. Verify a comment was posted: `🤖 ADF Pipeline Generation Agent Assigned`
5. Verify label `agent-in-progress` was added

### Step 3: Trigger Generation Agent in Workspace

1. On the issue page, click **"Open in Workspace"** button (top right)
2. Copilot Workspace opens
3. From the custom agents dropdown, select **"adf-generate"**
4. Click **Start** or equivalent button
5. Monitor the agent's progress:
   - It should read the issue requirements
   - Generate a pipeline JSON file
   - Create a new branch
   - Open a pull request
   - Add the `adf-pipeline` label to the PR

### Step 4: Verify Review Workflow Triggers

1. Navigate to the newly created PR
2. Check the **Actions** tab - `Assign ADF Review Agent to PR` should be running
3. Return to the PR
4. Verify comment: `🔍 ADF Pipeline Review Agent Assigned`
5. Verify labels: `review-in-progress`, `retry-count-1`

### Step 5: Trigger Review Agent in Workspace

1. On the PR page, click **"Open in Workspace"** button
2. From the custom agents dropdown, select **"adf-review"**
3. Click **Start**
4. Monitor the agent's review process
5. Agent should post a formatted review comment with findings

### Step 6: Verify Routing Based on Results

**If review found NO errors:**
- Workflow should post: `✅ Pipeline Approved` or `✅ Approved with Minor Suggestions`
- Label added: `approved` or `approved-with-warnings`
- **Test passes** - ready to merge

**If review found errors:**
- Continue to Step 7

### Step 7: Test Fix Cycle (If Errors Found)

1. Verify workflow posted: `🔧 Issues Found - Routing Back to Generation Agent`
2. Verify labels updated:
   - `changes-requested` added
   - `generation-in-progress` added
   - `retry-count-2` added (old retry label removed)
3. Go back to the PR page
4. Click **"Open in Workspace"** again
5. Select **"adf-generate"** agent
6. Agent should:
   - Read the review feedback
   - Fix the identified issues
   - Push updates to the branch
7. Review cycle repeats automatically
8. Verify labels update correctly with each cycle

### Step 8: Verify Escalation (If 3 Cycles Reached)

If errors persist through 3 cycles:
1. Verify workflow posts: `⚠️ Maximum Review Cycles Reached`
2. Verify labels: `needs-human-review`, `escalated`
3. Verify comment on linked issue notifying of escalation
4. **Manual intervention** now required

## Test Scenario 2: Direct Manual Agent Triggering

### Without Issue Label

1. Create an issue without the `adf-generate` label
2. Workflows should NOT trigger
3. Manually click **"Open in Workspace"**
4. Select **"adf-generate"** from dropdown
5. Agent should still work correctly (reads issue, generates pipeline)
6. Verify PR is created with `adf-pipeline` label
7. Review workflow should trigger on PR label

This tests that agents work independently of workflows.

## Test Scenario 3: Workflow State Recovery

### Simulate Interrupted Cycle

1. Create issue with `adf-generate` label
2. Trigger generation agent in Workspace
3. Let it create a PR
4. **Manually** add label `retry-count-2` to the PR
5. Trigger review agent
6. If errors found, workflow should:
   - Increment to `retry-count-3`
   - On next cycle, escalate to human review

This tests that workflows correctly track state across sessions.

## Expected Outcomes

### ✅ Success Criteria

- [ ] Workflows trigger automatically when labels are added
- [ ] Workflow comments provide clear instructions
- [ ] GraphQL assignment attempts (may fail gracefully)
- [ ] Labels update correctly at each stage
- [ ] Retry counter increments properly
- [ ] Review results parsed correctly
- [ ] Routing logic works (errors → fix cycle, warnings → approval)
- [ ] Escalation triggers after 3 retry cycles
- [ ] Agents can be manually triggered in Workspace
- [ ] Agents read correct custom agent instructions

### ❌ Common Issues

**Issue**: Workflow doesn't trigger
- **Check**: Labels configured correctly?
- **Check**: Workflows enabled in Actions tab?
- **Fix**: Verify label names match workflow conditions

**Issue**: Agent doesn't start
- **Cause**: Copilot Workspace requires manual click
- **Fix**: User must click "Open in Workspace" and select agent

**Issue**: Wrong agent selected
- **Cause**: User picked wrong agent from dropdown
- **Fix**: Select correct agent (`adf-generate` for generation, `adf-review` for review)

**Issue**: GraphQL assignment fails
- **Expected**: This is normal if API not fully available
- **Result**: Workflow posts instructions for manual trigger
- **Action**: User follows instructions to open in Workspace

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
gh run view <run-id> --repo <owner>/<repo>

# Check labels on issue
gh issue view <issue-number> --repo <owner>/<repo> --json labels

# Check labels on PR
gh pr view <pr-number> --repo <owner>/<repo> --json labels

# List comments on issue/PR
gh issue view <issue-number> --repo <owner>/<repo> --comments

# Check if Copilot bot exists (for GraphQL)
gh api graphql -f query='query { user(login: "copilot") { id login } }'
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
