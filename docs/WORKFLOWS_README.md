# Workflows Documentation

Complete documentation for the Assetronics Workflow & Templates system.

---

## 📚 Documentation Index

### 1. [**Workflows Guide**](./WORKFLOWS_GUIDE.md) - **START HERE**
Complete user and developer guide covering:
- System overview and key concepts
- All 4 workflow templates in detail
- Step-by-step usage instructions
- API reference with examples
- Best practices and troubleshooting
- **Recommended for**: First-time users, product managers, IT admins

### 2. [**Workflows Architecture**](./WORKFLOWS_ARCHITECTURE.md)
Technical architecture documentation with diagrams:
- System component diagrams
- Data flow sequences
- State machine diagrams
- Multi-tenant isolation architecture
- Integration trigger flows
- Real-time event broadcasting
- Deployment architecture
- **Recommended for**: Engineers, architects, DevOps

### 3. [**Workflows Quick Reference**](./WORKFLOWS_QUICK_REFERENCE.md)
Cheat sheet for developers:
- API endpoints quick reference
- Elixir function examples
- Frontend component usage
- Database schema reference
- Testing examples
- Environment variables
- Common code patterns
- **Recommended for**: Developers (daily reference)

---

## 🚀 Quick Start

### For Users (UI)
1. Navigate to **Workflows** in the sidebar
2. Click **"Create Workflow"**
3. Select a template (e.g., "Incoming Hardware Setup")
4. Fill in details (asset, due date, priority)
5. Click **"Create Workflow"**
6. Manage steps in the workflow detail view

### For Developers (API)
```bash
# List available templates
curl -X GET http://localhost:4000/api/v1/workflows/templates \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: acme"

# Create workflow from template
curl -X POST http://localhost:4000/api/v1/workflows/from-template \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: acme" \
  -d '{
    "template_key": "incoming_hardware",
    "asset_id": "uuid-here",
    "assigned_to": "it@company.com",
    "priority": "high"
  }'
```

### For Backend Developers (Elixir)
```elixir
alias Assetronics.Workflows

# Create workflow from template
{:ok, workflow} = Workflows.create_from_template(
  "tenant_slug",
  :incoming_hardware,
  %{
    asset_id: asset.id,
    assigned_to: "it@company.com",
    priority: "high"
  }
)

# Start and manage
{:ok, workflow} = Workflows.start_workflow("tenant_slug", workflow)
{:ok, workflow} = Workflows.advance_workflow_step("tenant_slug", workflow)
{:ok, workflow} = Workflows.complete_workflow("tenant_slug", workflow)
```

---

## 📋 Available Templates

| Template | Type | Steps | Duration | Use Case |
|----------|------|-------|----------|----------|
| **Incoming Hardware Setup** | Procurement | 8 | 3 days | New equipment receiving & deployment |
| **New Employee IT Onboarding** | Onboarding | 9 | 7 days | Complete IT setup for new hires |
| **Equipment Return & Offboarding** | Offboarding | 6 | 2 days | Asset recovery when employee departs |
| **Emergency Hardware Replacement** | Repair | 5 | 1 day | Urgent device failure replacement |

---

## 🏗️ System Architecture Overview

```
┌─────────────┐
│   User UI   │ (Vue.js Frontend)
└──────┬──────┘
       │ HTTP/WebSocket
       ▼
┌─────────────────────────────────┐
│   Workflow Controller (API)     │
└──────┬──────────────────────────┘
       │
       ├─► Templates Module ─────► Returns template definitions
       │
       ├─► Workflows Context ─────► Business logic
       │
       └─► Database (PostgreSQL) ─► Stores workflows (multi-tenant)
```

**Key Features**:
- ✅ Multi-tenant (schema-per-tenant isolation)
- ✅ Real-time updates (Phoenix PubSub)
- ✅ Background jobs (Oban)
- ✅ Email notifications
- ✅ Audit trails
- ✅ Integration triggers (HRIS, MDM, etc.)

---

## 📊 Workflow Lifecycle

```
Template Selection
        ↓
  Configuration
        ↓
    [PENDING] ──► Start ──► [IN PROGRESS] ──► Complete ──► [COMPLETED]
        │                          │
        └─────► Cancel ◄───────────┘
                  ↓
             [CANCELLED]
```

**Status Values**:
- `pending`: Created but not started
- `in_progress`: Active, working through steps
- `completed`: All steps finished
- `cancelled`: Cancelled with reason

---

## 🔧 Key Components

### Backend (Elixir/Phoenix)
- **Location**: `backend/lib/assetronics/workflows/`
- **Files**:
  - `templates.ex` - Template definitions (4 templates)
  - `workflow.ex` - Schema and validation
  - `../workflows.ex` - Context with business logic
  - `../../assetronics_web/controllers/workflow_controller.ex` - API endpoints

### Frontend (Vue 3/TypeScript)
- **Location**: `frontend/src/`
- **Files**:
  - `views/WorkflowsView.vue` - List view with filters
  - `views/WorkflowDetailView.vue` - Individual workflow management
  - `components/workflows/CreateWorkflowModal.vue` - Template selection & configuration
  - `components/workflows/WorkflowCard.vue` - Workflow summary card

### Database
- **Table**: `workflows` (in each tenant schema)
- **Key Fields**: `workflow_type`, `status`, `priority`, `steps` (JSONB), `current_step`, `employee_id`, `asset_id`

---

## 🔌 Integration Points

### Automatic Workflow Creation

**HRIS Integration** (BambooHR, Workday):
```
New Employee Hired → Auto-create Onboarding Workflow
Employee Terminated → Auto-create Offboarding Workflow
```

**Procurement Integration** (Dell, CDW):
```
Order Confirmed → Auto-create Incoming Hardware Workflow
```

**Support Ticket** (Manual):
```
Device Failure Reported → Create Emergency Replacement Workflow
```

---

## 📖 Documentation Structure

```
docs/
├── WORKFLOWS_README.md          ← You are here
├── WORKFLOWS_GUIDE.md           ← Complete user & developer guide
├── WORKFLOWS_ARCHITECTURE.md    ← Technical architecture with diagrams
└── WORKFLOWS_QUICK_REFERENCE.md ← Developer cheat sheet
```

**Read in this order**:
1. **README** (this file) - Get oriented
2. **GUIDE** - Understand the system
3. **ARCHITECTURE** - Deep dive into design
4. **QUICK REFERENCE** - Daily development

---

## 🎯 Common Use Cases

### Use Case 1: New Laptop Arrives
1. Procurement team receives Dell shipment
2. IT creates "Incoming Hardware Setup" workflow
3. Assigns to asset and IT technician
4. Technician follows 8 steps:
   - Receive & inspect
   - Register asset
   - Configure (OS, MDM, security)
   - Test
   - Assign to employee
   - Hand off with training
5. Workflow marked complete, audit trail saved

### Use Case 2: Employee Starts Monday
1. HR adds employee to BambooHR on Friday
2. HRIS integration triggers "New Employee Onboarding" workflow automatically
3. IT receives notification with pre-start tasks:
   - Day -3: Create accounts (email, Slack, VPN)
   - Day -1: Setup laptop with company image
4. Employee starts, IT completes Day 1 tasks:
   - Hardware handoff
   - IT orientation
5. Week 1: Grant app access, training, follow-up
6. Workflow completed, employee fully onboarded

### Use Case 3: Employee Departs
1. HR terminates employee in Workday
2. HRIS integration auto-creates "Equipment Return" workflow
3. IT follows 6 steps:
   - Schedule return with employee
   - Backup data if needed
   - Receive equipment back
   - Revoke all access
   - Wipe device
   - Update records
4. Asset now available for redeployment

### Use Case 4: Laptop Breaks
1. Employee reports MacBook screen cracked
2. IT support creates "Emergency Replacement" workflow (urgent priority)
3. IT follows 5 fast-track steps:
   - Assess and approve
   - Provision replacement from stock
   - Deploy to user same day
   - Collect broken device
   - File warranty claim
4. Employee back to work, minimal downtime

---

## 🛠️ Development

### Running Locally

**Backend**:
```bash
cd backend
mix deps.get
mix ecto.create
mix ecto.migrate
iex -S mix phx.server
```

**Frontend**:
```bash
cd frontend
npm install
npm run dev
```

**Access**:
- Frontend: http://localhost:5173
- Backend API: http://localhost:4000
- Workflows UI: http://localhost:5173/workflows

### Testing

**Backend tests**:
```bash
cd backend
mix test test/assetronics/workflows_test.exs
mix test test/assetronics_web/controllers/workflow_controller_test.exs
```

**Frontend tests**:
```bash
cd frontend
npm run test:unit
```

---

## 📈 Metrics & Monitoring

**Key Metrics to Track**:
- Total workflows by status
- Average completion time by template type
- Overdue rate (% of workflows past due date)
- Time per step (identify bottlenecks)
- Workflow creation sources (manual vs automated)

**Monitoring**:
- Phoenix LiveDashboard: http://localhost:4000/dashboard
- Logs: `tail -f backend/logs/dev.log`
- PubSub events: Real-time updates in browser console

---

## 🐛 Troubleshooting

### Templates Not Showing
**Problem**: Modal shows "Choose a Workflow Template" but no templates listed
**Solution**: Fallback templates now load automatically. Check browser console for API errors. Backend may not be running.

### Workflow Won't Advance
**Problem**: "Complete Current Step" button doesn't work
**Solution**: Ensure workflow status is "in_progress" and current_step < total_steps

### Permissions Error
**Problem**: 403 Forbidden when creating workflow
**Solution**: Check JWT token is valid and user belongs to correct tenant

### Steps Not Saving
**Problem**: Step completion not persisting
**Solution**: Check JSONB column update, ensure steps array properly structured

---

## 🔐 Security Considerations

- **Multi-tenant isolation**: Each tenant's workflows stored in separate PostgreSQL schema
- **Authentication**: All API endpoints require valid JWT token
- **Authorization**: Users can only access workflows in their tenant
- **Encryption**: Sensitive data encrypted with Cloak (AES-256-GCM)
- **Audit trail**: All actions logged with timestamps and user info
- **Input validation**: Ecto changesets validate all workflow attributes

---

## 🚢 Deployment

**Production Requirements**:
- PostgreSQL 14+ with multiple schemas (one per tenant)
- Elixir 1.15+ / Erlang 26+
- Node.js 18+ (for frontend build)
- Redis (optional, for caching)
- SMTP server (for email notifications)

**Environment Setup**:
```bash
# Required
export DATABASE_URL="postgres://..."
export SECRET_KEY_BASE="..."
export ENCRYPTION_KEY="..."

# Optional
export SMTP_HOST="smtp.sendgrid.net"
export SMTP_PORT="587"
export FROM_EMAIL="noreply@assetronics.com"
```

**Deploy**:
```bash
# Build frontend
cd frontend && npm run build

# Build backend release
cd backend && MIX_ENV=prod mix release

# Run
_build/prod/rel/assetronics/bin/assetronics start
```

---

## 📞 Support & Contributing

**Questions?**
- Documentation: This folder (`docs/`)
- Code: `backend/lib/assetronics/workflows/`
- Issues: GitHub Issues

**Contributing**:
1. Fork the repository
2. Create feature branch
3. Add tests
4. Update documentation
5. Submit pull request

---

## 📝 Changelog

### v1.0.0 (2025-11-30)
- ✅ 4 workflow templates (Incoming Hardware, New Employee, Equipment Return, Emergency Replacement)
- ✅ Full CRUD API with template instantiation
- ✅ Vue.js frontend with create/list/detail views
- ✅ Real-time updates via Phoenix PubSub
- ✅ Email notifications
- ✅ Multi-tenant support
- ✅ Comprehensive documentation

### Planned Features (v1.1.0)
- [ ] Custom workflow templates (user-defined)
- [ ] Conditional branching in steps
- [ ] SLA tracking and escalation
- [ ] Bulk operations
- [ ] Advanced analytics dashboard

---

## 🙏 Acknowledgments

Built with:
- Phoenix Framework (Elixir)
- Vue.js 3 (TypeScript)
- PostgreSQL + Triplex (multi-tenancy)
- Oban (background jobs)
- Tailwind CSS

---

**Documentation Version**: 1.0.0
**Last Updated**: 2025-11-30
**Maintainer**: Assetronics Team
