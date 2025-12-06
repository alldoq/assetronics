# User Dashboard Metrics Guide

This document outlines what business metrics and operational data should be displayed on the user-facing application dashboard, organized by user role.

## Dashboard by User Role

### Employee Dashboard

**What employees need to see:**

1. **My Assets**
   - List of assets currently assigned to me
   - Asset details (name, type, serial number, asset tag)
   - Assignment date
   - Expected return date (if temporary)
   - Quick actions: Report issue, Request return

2. **My Workflows**
   - Active workflows assigned to me
   - Onboarding checklist with progress
   - Pending tasks requiring my action
   - Due dates and overdue indicators
   - Quick actions: Complete task, View details

3. **Recent Activity**
   - Assets recently assigned or returned
   - Workflow updates
   - Notifications (last 10)

4. **Quick Stats**
   - Total assets assigned: 3
   - Active workflows: 1
   - Pending tasks: 2

### Manager Dashboard

**What managers need to see:**

1. **Team Overview**
   - Number of direct reports
   - Team asset allocation
   - Active onboarding/offboarding workflows
   - Team members with overdue tasks

2. **Asset Distribution**
   - Pie chart: Assets by type (laptops, monitors, phones, etc.)
   - Bar chart: Assets by employee
   - Assets pending return
   - Assets in repair

3. **Workflow Status**
   - Active onboarding workflows (by employee)
   - Active offboarding workflows
   - Overdue workflows requiring attention
   - Average workflow completion time

4. **Approvals Pending**
   - Workflows awaiting manager approval
   - Asset requests pending
   - Transfer requests

5. **Key Metrics**
   - Team utilization: 85%
   - Onboarding completion rate: 92%
   - Average time to equipment: 2.3 days
   - Assets per employee: 2.4

### IT/Operations Dashboard

**What IT admins need to see:**

1. **Asset Inventory Overview**
   - Total assets: 1,247
   - By status:
     - In stock: 156
     - Assigned: 892
     - In repair: 23
     - Retired: 176
   - Asset utilization rate: 85%
   - Assets expiring warranty (next 90 days)

2. **Workflow Metrics**
   - Active workflows by type
     - Onboarding: 12
     - Offboarding: 3
     - Repair: 5
     - Maintenance: 8
   - Overdue workflows: 4 (need attention)
   - Average workflow completion:
     - Onboarding: 4.2 days
     - Offboarding: 2.1 days
     - Repair: 5.8 days

3. **Integration Health**
   - Last sync status by provider:
     - BambooHR: ✅ 2 hours ago (45 employees)
     - Jamf: ✅ 1 hour ago (234 devices)
     - NetSuite: ⚠️ Failed 6 hours ago
   - Sync success rate (last 24h): 94%
   - Failed syncs requiring attention: 2

4. **Employee Status**
   - Total employees: 458
   - Active: 445
   - New hires (last 30 days): 12
   - Terminations (last 30 days): 8
   - Pending onboarding: 3

5. **Recent Activity**
   - Assets assigned today: 8
   - Assets returned today: 5
   - Workflows completed today: 15
   - Notifications sent today: 247

6. **Alerts & Issues**
   - Failed integration syncs: 2
   - Overdue workflows: 4
   - Assets past expected return: 6
   - Warranty expiring soon: 18

### Super Admin Dashboard

**What super admins need to see:**

1. **System-Wide Metrics**
   - Total tenants: 15
   - Active tenants: 14
   - Total users: 1,847
   - Total assets: 4,521

2. **Tenant Health**
   - List of tenants with health indicators
   - Storage usage by tenant
   - API usage by tenant
   - Active users by tenant

3. **System Performance**
   - Average response time: 145ms
   - Database performance
   - Background job queue: 23 pending
   - Error rate: 0.3%

4. **Feature Usage**
   - Most used features
   - Integration adoption by tenant
   - Workflow usage patterns

## Dashboard Widgets/Components

### 1. KPI Cards
```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Total Assets    │  │ In Stock        │  │ Assigned        │
│      1,247      │  │      156        │  │      892        │
│   ↑ 5% vs LM    │  │   ↓ 12% vs LM   │  │   ↑ 8% vs LM    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### 2. Asset Status Pie Chart
```
Assets by Status
┌──────────────┐
│ ●●●●●● 71.5% │ Assigned
│ ●●   12.5%   │ In Stock
│ ●     1.8%   │ In Repair
│ ●    14.2%   │ Retired
└──────────────┘
```

### 3. Workflow Timeline
```
Active Workflows
┌────────────────────────────────────┐
│ John Doe Onboarding    [====  ] 80%│
│ Jane Smith Offboarding [======] 95%│
│ Laptop #1234 Repair    [==    ] 40%│
└────────────────────────────────────┘
```

### 4. Integration Status List
```
Integration Health
┌──────────────────────────────────┐
│ ✅ BambooHR      2h ago  45 recs │
│ ✅ Jamf          1h ago  234 recs│
│ ⚠️  NetSuite     Failed 6h ago   │
│ ✅ Okta          30m ago 445 recs│
└──────────────────────────────────┘
```

### 5. Recent Activity Feed
```
Recent Activity
┌──────────────────────────────────────┐
│ 🔔 Laptop assigned to John Doe       │
│    2 minutes ago                     │
│                                      │
│ ✅ Onboarding workflow completed     │
│    15 minutes ago • Jane Smith       │
│                                      │
│ 🔄 Integration synced: BambooHR     │
│    1 hour ago • 45 employees updated│
└──────────────────────────────────────┘
```

### 6. Alert Banner
```
⚠️ Alerts (2)
┌──────────────────────────────────────┐
│ 🔴 NetSuite integration failing      │
│    Last successful sync: 6 hours ago │
│                                      │
│ 🟡 4 workflows overdue               │
│    Requires immediate attention      │
└──────────────────────────────────────┘
```

## Data Queries Needed

### Asset Metrics
```sql
-- Total assets by status
SELECT status, COUNT(*) as count
FROM assets
WHERE tenant_id = ?
GROUP BY status;

-- Asset utilization rate
SELECT
  COUNT(CASE WHEN status = 'assigned' THEN 1 END)::float /
  COUNT(*)::float * 100 as utilization_rate
FROM assets
WHERE tenant_id = ? AND status IN ('assigned', 'in_stock');

-- Assets expiring warranty
SELECT COUNT(*)
FROM assets
WHERE tenant_id = ?
  AND warranty_expiration BETWEEN NOW() AND NOW() + INTERVAL '90 days';
```

### Workflow Metrics
```sql
-- Active workflows by type
SELECT workflow_type, COUNT(*) as count
FROM workflows
WHERE tenant_id = ?
  AND status IN ('pending', 'in_progress')
GROUP BY workflow_type;

-- Overdue workflows
SELECT COUNT(*)
FROM workflows
WHERE tenant_id = ?
  AND status IN ('pending', 'in_progress')
  AND due_date < NOW();

-- Average completion time by workflow type
SELECT
  workflow_type,
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/3600) as avg_hours
FROM workflows
WHERE tenant_id = ?
  AND status = 'completed'
  AND completed_at > NOW() - INTERVAL '30 days'
GROUP BY workflow_type;
```

### Integration Health
```sql
-- Last sync status by integration
SELECT
  i.provider,
  i.name,
  i.last_sync_at,
  i.last_sync_status,
  i.last_sync_records_count
FROM integrations i
WHERE i.tenant_id = ?
ORDER BY i.last_sync_at DESC;

-- Sync success rate (last 24h)
SELECT
  COUNT(CASE WHEN last_sync_status = 'success' THEN 1 END)::float /
  COUNT(*)::float * 100 as success_rate
FROM integrations
WHERE tenant_id = ?
  AND last_sync_at > NOW() - INTERVAL '24 hours';
```

### Employee Metrics
```sql
-- Employee counts
SELECT
  COUNT(*) as total,
  COUNT(CASE WHEN employment_status = 'active' THEN 1 END) as active,
  COUNT(CASE WHEN hire_date > NOW() - INTERVAL '30 days' THEN 1 END) as new_hires,
  COUNT(CASE WHEN termination_date > NOW() - INTERVAL '30 days' THEN 1 END) as terminations
FROM employees
WHERE tenant_id = ?;

-- Employees pending onboarding
SELECT COUNT(DISTINCT e.id)
FROM employees e
INNER JOIN workflows w ON w.employee_id = e.id
WHERE e.tenant_id = ?
  AND w.workflow_type = 'onboarding'
  AND w.status IN ('pending', 'in_progress')
  AND e.hire_date >= NOW() - INTERVAL '30 days';
```

### Activity Feed
```sql
-- Recent activity (transactions + workflow events)
SELECT
  t.transaction_type as event_type,
  t.performed_at as event_time,
  e.first_name || ' ' || e.last_name as employee_name,
  a.name as asset_name,
  t.metadata
FROM transactions t
LEFT JOIN employees e ON t.employee_id = e.id
LEFT JOIN assets a ON t.asset_id = a.id
WHERE t.tenant_id = ?
ORDER BY t.performed_at DESC
LIMIT 20;
```

## Implementation Approach

### 1. Create Dashboard Context

```elixir
# lib/assetronics/dashboard.ex
defmodule Assetronics.Dashboard do
  @moduledoc """
  Dashboard metrics and analytics for the user-facing dashboard.
  """

  def get_employee_dashboard(tenant, employee_id)
  def get_manager_dashboard(tenant, manager_id)
  def get_admin_dashboard(tenant, user_id)
  def get_super_admin_dashboard()
end
```

### 2. Create Dashboard API Endpoints

```elixir
# lib/assetronics_web/controllers/dashboard_controller.ex
defmodule AssetronicsWeb.DashboardController do
  use AssetronicsWeb, :controller

  def index(conn, _params) do
    tenant = conn.assigns.tenant
    user = conn.assigns.current_user

    data = case user.role do
      "employee" -> Dashboard.get_employee_dashboard(tenant, user.id)
      "manager" -> Dashboard.get_manager_dashboard(tenant, user.id)
      "admin" -> Dashboard.get_admin_dashboard(tenant, user.id)
      "super_admin" -> Dashboard.get_super_admin_dashboard()
    end

    render(conn, :show, data: data)
  end
end
```

### 3. Cache Dashboard Data

Since dashboard queries can be expensive, implement caching:

```elixir
# Cache for 5 minutes
defp get_cached_metrics(tenant, key, fun) do
  cache_key = "dashboard:#{tenant}:#{key}"

  case Cachex.get(:dashboard_cache, cache_key) do
    {:ok, nil} ->
      result = fun.()
      Cachex.put(:dashboard_cache, cache_key, result, ttl: :timer.minutes(5))
      result

    {:ok, cached} ->
      cached
  end
end
```

## Benefits

**For Employees:**
- Clear visibility into their assigned assets
- Track onboarding progress
- Stay on top of pending tasks

**For Managers:**
- Monitor team asset allocation
- Track onboarding/offboarding progress
- Identify bottlenecks

**For IT/Admins:**
- Comprehensive asset inventory view
- Integration health monitoring
- Proactive issue identification
- Workflow efficiency tracking

**For Everyone:**
- Real-time operational visibility
- Data-driven decision making
- Reduced manual reporting

## Next Steps

1. Implement Dashboard context module with queries
2. Add caching layer for performance
3. Create dashboard API endpoints
4. Build frontend components for each widget
5. Add real-time updates via Phoenix Channels
6. Implement data export functionality

Would you like me to implement any of these dashboard queries or create the Dashboard context module?
