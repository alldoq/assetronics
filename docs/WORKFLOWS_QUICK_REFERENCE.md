# Workflows Quick Reference

Quick reference guide for developers working with the Assetronics workflow system.

---

## Available Templates

| Template Key | Name | Type | Steps | Duration | Use Case |
|-------------|------|------|-------|----------|----------|
| `incoming_hardware` | Incoming Hardware Setup | procurement | 8 | 3 days | New equipment receiving & deployment |
| `new_employee` | New Employee IT Onboarding | onboarding | 9 | 7 days | IT setup for new hires |
| `equipment_return` | Equipment Return & Offboarding | offboarding | 6 | 2 days | Employee departure, asset recovery |
| `emergency_replacement` | Emergency Hardware Replacement | repair | 5 | 1 day | Urgent device failure replacement |

---

## API Endpoints Cheat Sheet

### Templates
```bash
# List all templates
GET /api/v1/workflows/templates

# Response
{
  "data": [
    {
      "key": "incoming_hardware",
      "name": "Incoming Hardware Setup",
      "type": "procurement",
      "description": "...",
      "estimated_duration_days": 3,
      "step_count": 8
    }
  ]
}
```

### Create Workflow from Template
```bash
POST /api/v1/workflows/from-template
Content-Type: application/json

{
  "template_key": "incoming_hardware",
  "asset_id": "uuid-of-asset",
  "employee_id": "uuid-of-employee",  # optional
  "assigned_to": "it@company.com",
  "due_date": "2025-12-15",           # optional
  "priority": "high"                   # low, normal, high, urgent
}
```

### List Workflows
```bash
# All workflows
GET /api/v1/workflows

# Filter by type
GET /api/v1/workflows?workflow_type=onboarding

# Filter by status
GET /api/v1/workflows?status=in_progress

# Filter by priority
GET /api/v1/workflows?priority=urgent

# Combine filters
GET /api/v1/workflows?workflow_type=onboarding&status=pending&priority=high
```

### Get Workflow
```bash
GET /api/v1/workflows/{id}
```

### Update Workflow
```bash
PATCH /api/v1/workflows/{id}
Content-Type: application/json

{
  "workflow": {
    "assigned_to": "newperson@company.com",
    "priority": "urgent",
    "due_date": "2025-12-10"
  }
}
```

### Workflow Actions
```bash
# Start workflow (pending → in_progress)
POST /api/v1/workflows/{id}/start

# Advance to next step
POST /api/v1/workflows/{id}/advance

# Complete workflow (all steps must be done)
POST /api/v1/workflows/{id}/complete

# Cancel workflow
POST /api/v1/workflows/{id}/cancel
Content-Type: application/json
{
  "reason": "Employee left before onboarding"
}

# Delete workflow
DELETE /api/v1/workflows/{id}
```

### Special Queries
```bash
# Get overdue workflows
GET /api/v1/workflows/overdue

# Get workflows for specific employee
GET /api/v1/workflows?employee_id={uuid}

# Get workflows for specific asset
GET /api/v1/workflows?asset_id={uuid}
```

---

## Workflow Status Flow

```
pending → in_progress → completed
   ↓           ↓
cancelled   cancelled
```

**Status Values**: `pending`, `in_progress`, `completed`, `cancelled`, `failed`

**Priority Values**: `low`, `normal`, `high`, `urgent`

**Type Values**: `onboarding`, `offboarding`, `procurement`, `repair`, `maintenance`, `transfer`, `audit`

---

## Elixir Functions Quick Reference

### Creating Workflows (Backend)

```elixir
# Using templates module
alias Assetronics.Workflows

# Create incoming hardware workflow
{:ok, workflow} = Workflows.create_incoming_hardware_workflow(
  "tenant_slug",
  asset,
  assigned_to: "it@company.com",
  due_date: Date.add(Date.utc_today(), 3)
)

# Create new employee workflow
{:ok, workflow} = Workflows.create_new_employee_workflow(
  "tenant_slug",
  employee,
  asset_id: asset.id,
  assigned_to: "it@company.com"
)

# Create equipment return workflow
{:ok, workflow} = Workflows.create_equipment_return_workflow(
  "tenant_slug",
  employee,
  asset,
  assigned_to: "it@company.com"
)

# Create emergency replacement workflow
{:ok, workflow} = Workflows.create_emergency_replacement_workflow(
  "tenant_slug",
  employee,
  asset,
  assigned_to: "it@company.com"
)

# Generic: create from template key
{:ok, workflow} = Workflows.create_from_template(
  "tenant_slug",
  :incoming_hardware,
  %{
    asset_id: asset.id,
    assigned_to: "it@company.com",
    priority: "high"
  }
)
```

### Managing Workflows

```elixir
# List workflows
workflows = Workflows.list_workflows("tenant_slug")

# List with filters
workflows = Workflows.list_workflows("tenant_slug",
  workflow_type: "onboarding",
  status: "in_progress"
)

# Get specific workflow
workflow = Workflows.get_workflow!("tenant_slug", workflow_id)

# Update workflow
{:ok, workflow} = Workflows.update_workflow(
  "tenant_slug",
  workflow,
  %{priority: "urgent"}
)

# Start workflow
{:ok, workflow} = Workflows.start_workflow("tenant_slug", workflow)

# Advance step
{:ok, workflow} = Workflows.advance_workflow_step("tenant_slug", workflow)

# Complete workflow
{:ok, workflow} = Workflows.complete_workflow("tenant_slug", workflow)

# Cancel workflow
{:ok, workflow} = Workflows.cancel_workflow(
  "tenant_slug",
  workflow,
  "Employee withdrew"
)
```

### Queries

```elixir
# Active workflows (pending or in_progress)
active = Workflows.list_active_workflows("tenant_slug")

# Workflows by type
onboarding = Workflows.list_workflows_by_type("tenant_slug", "onboarding")

# Workflows for employee
employee_wf = Workflows.list_workflows_for_employee("tenant_slug", employee_id)

# Workflows for asset
asset_wf = Workflows.list_workflows_for_asset("tenant_slug", asset_id)

# Overdue workflows
overdue = Workflows.list_overdue_workflows("tenant_slug")
```

---

## Frontend Component Usage

### Import Components
```typescript
import WorkflowsView from '@/views/WorkflowsView.vue'
import WorkflowDetailView from '@/views/WorkflowDetailView.vue'
import CreateWorkflowModal from '@/components/workflows/CreateWorkflowModal.vue'
import WorkflowCard from '@/components/workflows/WorkflowCard.vue'
```

### Routes
```typescript
{
  path: '/workflows',
  name: 'workflows',
  component: WorkflowsView
}

{
  path: '/workflows/:id',
  name: 'workflow-detail',
  component: WorkflowDetailView
}
```

### Using CreateWorkflowModal
```vue
<template>
  <CreateWorkflowModal
    v-if="showModal"
    @close="showModal = false"
    @created="handleCreated"
  />
</template>

<script setup>
import { ref } from 'vue'
import CreateWorkflowModal from '@/components/workflows/CreateWorkflowModal.vue'

const showModal = ref(false)

const handleCreated = () => {
  showModal.value = false
  // Refresh workflow list
}
</script>
```

### Using WorkflowCard
```vue
<template>
  <WorkflowCard
    :workflow="workflow"
    @click="viewDetails(workflow.id)"
    @start="startWorkflow"
    @complete="completeWorkflow"
  />
</template>

<script setup>
import WorkflowCard from '@/components/workflows/WorkflowCard.vue'

const viewDetails = (id) => {
  router.push(`/workflows/${id}`)
}

const startWorkflow = async (workflowId) => {
  await fetch(`${API_URL}/api/v1/workflows/${workflowId}/start`, {
    method: 'POST',
    headers: { ... }
  })
}
</script>
```

---

## Database Schema Quick Reference

### workflows Table

```sql
CREATE TABLE workflows (
  id UUID PRIMARY KEY,
  tenant_id VARCHAR NOT NULL,

  -- Type & Status
  workflow_type VARCHAR NOT NULL,  -- onboarding, offboarding, etc.
  status VARCHAR DEFAULT 'pending', -- pending, in_progress, completed, cancelled
  priority VARCHAR DEFAULT 'normal', -- low, normal, high, urgent

  -- Content
  title VARCHAR NOT NULL,
  description TEXT,
  steps JSONB,  -- Array of step objects
  current_step INTEGER DEFAULT 0,

  -- Assignment
  assigned_to VARCHAR,
  approver VARCHAR,

  -- Relationships
  employee_id UUID REFERENCES employees(id),
  asset_id UUID REFERENCES assets(id),
  integration_id UUID REFERENCES integrations(id),

  -- Temporal
  due_date DATE,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,

  -- Metadata
  triggered_by VARCHAR,  -- manual, hris_sync, scheduled, etc.
  metadata JSONB,
  notes TEXT,

  -- Audit
  inserted_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_workflows_type ON workflows(workflow_type);
CREATE INDEX idx_workflows_status ON workflows(status);
CREATE INDEX idx_workflows_employee ON workflows(employee_id);
CREATE INDEX idx_workflows_asset ON workflows(asset_id);
CREATE INDEX idx_workflows_due_date ON workflows(due_date);
```

### Step Object Structure (JSONB)

```json
{
  "order": 1,
  "name": "Receive Shipment",
  "description": "Verify shipment contents match purchase order",
  "completed": false,
  "assigned_to": "receiving@company.com",
  "completed_at": null,
  "instructions": "- Verify tracking number\n- Inspect packaging\n- Check serial numbers"
}
```

---

## PubSub Events

### Event Channel
```
workflows:{tenant_id}
```

### Events Broadcasted
- `workflow_created`: New workflow instantiated
- `workflow_updated`: Workflow attributes changed
- `workflow_started`: Status changed to in_progress
- `workflow_completed`: All steps completed
- `workflow_cancelled`: Workflow cancelled
- `workflow_step_advanced`: Current step completed

### Subscribe (Phoenix Channel)
```javascript
import { Socket } from 'phoenix'

const socket = new Socket('/socket', {
  params: { token: authToken }
})

socket.connect()

const channel = socket.channel(`workflows:${tenantId}`, {})

channel.on('workflow_updated', (payload) => {
  console.log('Workflow updated:', payload)
  // Refresh UI
})

channel.join()
```

---

## Testing

### Unit Tests (ExUnit)

```elixir
defmodule Assetronics.WorkflowsTest do
  use Assetronics.DataCase

  alias Assetronics.Workflows

  describe "create_from_template/3" do
    test "creates workflow from incoming_hardware template" do
      tenant = insert(:tenant)
      asset = insert(:asset, tenant: tenant)

      {:ok, workflow} = Workflows.create_from_template(
        tenant.slug,
        :incoming_hardware,
        %{asset_id: asset.id}
      )

      assert workflow.workflow_type == "procurement"
      assert workflow.status == "pending"
      assert length(workflow.steps) == 8
      assert workflow.asset_id == asset.id
    end
  end
end
```

### Integration Tests (Phoenix)

```elixir
defmodule AssetronicsWeb.WorkflowControllerTest do
  use AssetronicsWeb.ConnCase

  describe "POST /api/v1/workflows/from-template" do
    test "creates workflow from template", %{conn: conn} do
      user = insert(:user)
      asset = insert(:asset, tenant: user.tenant)

      conn = conn
        |> authenticate(user)
        |> post("/api/v1/workflows/from-template", %{
          template_key: "incoming_hardware",
          asset_id: asset.id,
          assigned_to: "it@test.com"
        })

      assert %{"data" => workflow} = json_response(conn, 201)
      assert workflow["workflow_type"] == "procurement"
      assert workflow["total_steps"] == 8
    end
  end
end
```

---

## Environment Variables

```bash
# Required for workflows
DATABASE_URL=postgres://user:pass@localhost/assetronics
SECRET_KEY_BASE=your-secret-key-base
ENCRYPTION_KEY=your-encryption-key  # For Cloak

# Email notifications (optional)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
FROM_EMAIL=noreply@assetronics.com

# Background jobs
OBAN_QUEUES=default:10,integrations:20,notifications:5

# Optional: Redis for caching
REDIS_URL=redis://localhost:6379/0
```

---

## Common Patterns

### Auto-create workflow when employee hired

```elixir
defmodule Assetronics.Employees do
  def create_employee(tenant, attrs) do
    with {:ok, employee} <- insert_employee(attrs),
         {:ok, _workflow} <- auto_create_onboarding(tenant, employee) do
      {:ok, employee}
    end
  end

  defp auto_create_onboarding(tenant, employee) do
    Workflows.create_new_employee_workflow(
      tenant,
      employee,
      assigned_to: "it@company.com",
      triggered_by: "hris_sync"
    )
  end
end
```

### Send email when workflow assigned

```elixir
defmodule Assetronics.Workflows do
  def create_workflow(tenant, attrs) do
    %Workflow{}
    |> Workflow.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> tap(&send_assignment_email/1)
  end

  defp send_assignment_email({:ok, workflow}) do
    if workflow.assigned_to do
      WorkflowEmail.workflow_assigned(workflow, workflow.assigned_to)
      |> Mailer.deliver()
    end
  end
  defp send_assignment_email(_), do: :ok
end
```

---

## Troubleshooting

### Workflow not advancing
**Check**: `current_step` value and ensure it's less than `total_steps`
```elixir
workflow = Workflows.get_workflow!(tenant, id)
IO.inspect(workflow.current_step, label: "Current")
IO.inspect(length(workflow.steps), label: "Total")
```

### Templates not loading in UI
**Check**: Browser console for API errors, fallback templates should always load
```javascript
console.log('Templates:', templates.value)
console.log('Error:', templateError.value)
```

### Workflow not found
**Check**: Correct tenant scope and UUID
```elixir
# Wrong - missing tenant prefix
Repo.get(Workflow, id)

# Right - with tenant prefix
Repo.get(Workflow, id, prefix: Triplex.to_prefix(tenant))
```

---

## Performance Tips

1. **Use indexes**: Queries on `status`, `workflow_type`, `due_date` are indexed
2. **Preload associations**: Use `preload: [:employee, :asset]` to avoid N+1
3. **Limit results**: Always paginate with `LIMIT` in production
4. **Cache templates**: Templates rarely change, cache in ETS or Redis
5. **Background jobs**: Move heavy processing to Oban workers

---

## Additional Resources

- **Full Guide**: [WORKFLOWS_GUIDE.md](./WORKFLOWS_GUIDE.md)
- **Architecture**: [WORKFLOWS_ARCHITECTURE.md](./WORKFLOWS_ARCHITECTURE.md)
- **API Docs**: `/api/docs` (when server running)
- **Code Location**:
  - Backend: `backend/lib/assetronics/workflows/`
  - Frontend: `frontend/src/views/` and `frontend/src/components/workflows/`

---

**Last Updated**: 2025-11-30
