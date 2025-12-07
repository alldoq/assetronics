# Automatic Workflow Progression on Asset Assignment

## Overview

The system now automatically advances onboarding workflows when an asset is assigned to an employee. This eliminates the need for manual step completion when the "Assign hardware" step is satisfied.

## How It Works

### 1. Asset Assignment Event

When an asset is assigned to an employee via `Assets.assign_asset/4`:
- The system updates the asset status to "assigned"
- Associates the asset with the employee
- Broadcasts an `asset_assigned` event on the PubSub channel

### 2. Workflow Automation Listener

The `WorkflowAutomationListener` subscribes to asset events and:
- Listens for `asset_assigned` events
- Checks if the employee has any active onboarding workflows
- Determines if the current workflow step is "Assign hardware"
- Automatically advances the workflow if conditions are met

### 3. Workflow Progression Logic

The automatic progression occurs when ALL of these conditions are true:
1. An asset is assigned to an employee
2. The employee has at least one onboarding workflow
3. The workflow status is `pending` or `in_progress`
4. The current step name contains "assign" or "hardware" (case-insensitive)

### 4. Actions Performed

When conditions are met, the system:
- Marks the current "Assign hardware" step as completed
- Advances `current_step` to the next step
- Associates the asset with the workflow (if not already set)
- Logs all actions for audit purposes

## Example Flow

### Before Asset Assignment

```elixir
# Employee: John Doe (hired 5 days ago)
# Workflow: Onboarding workflow (status: "pending")
# Current step: 1 (index starts at 0)
# Steps:
#   0. Create accounts ✓ (completed)
#   1. Assign hardware ← (current step)
#   2. Provision software licenses
#   3. Setup software
#   4. Send welcome email
```

### After Asset Assignment

```elixir
Assets.assign_asset(tenant, macbook_asset, john_employee, "admin@company.com")
```

### Result

```elixir
# Workflow automatically updated:
# Current step: 2
# Steps:
#   0. Create accounts ✓ (completed)
#   1. Assign hardware ✓ (completed automatically)
#   2. Provision software licenses ← (new current step)
#   3. Setup software
#   4. Send welcome email
```

## Technical Implementation

### Modified File

**`lib/assetronics/listeners/workflow_automation_listener.ex`**

Added handler for `asset_assigned` events:

```elixir
@impl true
def handle_info({"asset_assigned", asset}, state) do
  Logger.info("[WorkflowAutomationListener] Asset #{asset.id} assigned to employee #{asset.employee_id}")

  if asset.employee_id do
    handle_asset_assignment_workflow_progression(state.tenant, asset)
  end

  {:noreply, state}
end
```

### Key Functions

#### `handle_asset_assignment_workflow_progression/2`

```elixir
defp handle_asset_assignment_workflow_progression(tenant, asset) do
  # 1. Find active onboarding workflows for employee
  employee_workflows = Workflows.list_workflows_for_employee(tenant, asset.employee_id)

  # 2. Filter for active onboarding workflows
  active_onboarding_workflows = Enum.filter(employee_workflows, fn workflow ->
    workflow.workflow_type == "onboarding" &&
      workflow.status in ["pending", "in_progress"]
  end)

  # 3. Check if current step is "Assign hardware"
  # 4. Advance workflow step if matched
  # 5. Associate asset with workflow if needed
end
```

## Logging

The system logs all workflow progression activities:

### Info Level
- Asset assignment events
- Workflow advancement success
- Asset association updates

### Debug Level
- Step name mismatches
- Already completed workflows

### Error Level
- Failed workflow advancements
- Asset association failures

## Benefits

### 1. Automation
- Eliminates manual step completion
- Reduces administrative overhead
- Ensures consistency

### 2. Real-time Updates
- Workflows progress immediately upon asset assignment
- No delay between assignment and workflow update
- Reduces time to completion

### 3. Accuracy
- Automatic updates prevent forgotten steps
- Ensures workflows reflect actual system state
- Maintains data integrity

### 4. Audit Trail
- All automatic progressions are logged
- Clear visibility into system behavior
- Easy troubleshooting

## Edge Cases Handled

### Multiple Workflows
If an employee has multiple active onboarding workflows, ALL matching workflows are progressed.

### No Asset in Workflow
If the workflow doesn't have an associated asset yet, the system automatically associates the newly assigned asset.

### Already Completed
If the workflow is already past the "Assign hardware" step, no action is taken.

### Non-matching Step Names
The system uses regex pattern matching (`/(assign|hardware)/`) to flexibly match step names like:
- "Assign hardware"
- "Hardware assignment"
- "Assign laptop"
- "Asset assignment"

## Configuration

No configuration is required. The feature is automatically enabled for all tenants via the `WorkflowAutomationListener`.

## Testing

### Manual Test Scenario

1. Create a new employee (hire date within 30 days)
2. Create an onboarding workflow or sync from HRIS
3. Verify workflow is at "Assign hardware" step
4. Assign an asset to the employee
5. Check that workflow automatically advanced to next step

### Expected Logs

```
[info] [WorkflowAutomationListener] Asset abc-123 assigned to employee def-456
[info] [WorkflowAutomationListener] Automatically advancing workflow ghi-789 - Asset assigned
[info] [WorkflowAutomationListener] Successfully advanced workflow ghi-789 from step 1 to 2
[info] [WorkflowAutomationListener] Updated workflow ghi-789 with asset_id abc-123
```

## Future Enhancements

Potential improvements for future consideration:

1. **Configurable Step Names**: Allow admins to define which step names trigger automatic progression
2. **Workflow Templates**: Support different onboarding templates with custom step names
3. **Conditional Progression**: Add rules engine for complex progression logic
4. **Notifications**: Send notifications when workflows auto-progress
5. **Rollback**: Ability to undo automatic progressions if asset is unassigned

## Related Files

- `/backend/lib/assetronics/listeners/workflow_automation_listener.ex` - Main implementation
- `/backend/lib/assetronics/workflows.ex` - Workflow context functions
- `/backend/lib/assetronics/assets.ex` - Asset assignment logic
- `/backend/lib/assetronics/workflows/workflow.ex` - Workflow schema

## See Also

- [Workflow Completion Listener](../backend/lib/assetronics/listeners/workflow_completion_listener.ex) - Handles workflow completion feedback loops
- [Workflow Automation](../backend/lib/assetronics/workflows.ex) - Workflow creation and management
- [Asset Management](../backend/lib/assetronics/assets.ex) - Asset assignment and tracking
