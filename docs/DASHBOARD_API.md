# Dashboard API Documentation

This document describes the dashboard API endpoint that provides role-based dashboard metrics and analytics.

## Overview

The dashboard API provides a single endpoint that returns role-specific data based on the authenticated user's role. The data is automatically cached for 5 minutes to optimize performance.

## Endpoint

```
GET /api/v1/dashboard
```

## Authentication

This endpoint requires authentication via Bearer token in the Authorization header.

```bash
curl -X GET http://localhost:4000/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Tenant: acme"
```

## Response Format

The response structure varies based on the user's role:

```json
{
  "data": {
    // Role-specific dashboard data
  },
  "role": "admin"
}
```

## Role-Based Dashboard Data

### Employee Dashboard

**Role:** `employee`

Returns personal assets, active workflows, recent activity, and quick stats.

**Response Example:**

```json
{
  "data": {
    "employee": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@acme.com",
      "department": "Engineering",
      "job_title": "Software Engineer"
    },
    "my_assets": [
      {
        "id": "uuid",
        "name": "MacBook Pro 16\"",
        "asset_tag": "LAPTOP-001",
        "serial_number": "C02ABC123",
        "category": "laptop",
        "assigned_at": "2024-01-15T10:30:00Z",
        "expected_return_date": null,
        "assignment_type": "permanent"
      }
    ],
    "my_workflows": [
      {
        "id": "uuid",
        "title": "New Hire Onboarding",
        "workflow_type": "onboarding",
        "status": "in_progress",
        "progress": 80,
        "due_date": "2024-02-01",
        "total_steps": 5,
        "completed_steps": 4
      }
    ],
    "recent_activity": [
      {
        "id": "uuid",
        "transaction_type": "assign",
        "performed_at": "2024-01-15T10:30:00Z",
        "asset_name": "MacBook Pro 16\"",
        "employee_name": "John Doe"
      }
    ],
    "stats": {
      "total_assets": 3,
      "active_workflows": 1,
      "pending_tasks": 2
    }
  },
  "role": "employee"
}
```

### Manager Dashboard

**Role:** `manager`

Returns team overview, asset distribution, workflow status, and key metrics.

**Response Example:**

```json
{
  "data": {
    "manager": {
      "id": "uuid",
      "name": "Jane Smith",
      "department": "Engineering"
    },
    "team_overview": {
      "team_size": 15,
      "total_assets": 42,
      "active_workflows": 5
    },
    "asset_distribution": [
      {
        "category": "laptop",
        "count": 18
      },
      {
        "category": "monitor",
        "count": 24
      }
    ],
    "workflow_status": [
      {
        "workflow_type": "onboarding",
        "count": 3
      },
      {
        "workflow_type": "offboarding",
        "count": 1
      }
    ],
    "key_metrics": {
      "team_utilization": 85.0,
      "onboarding_completion_rate": 92.0,
      "avg_time_to_equipment": 2.3,
      "assets_per_employee": 2.4
    }
  },
  "role": "manager"
}
```

### Admin Dashboard

**Role:** `admin` or `super_admin`

Returns comprehensive system-wide metrics including asset inventory, workflow metrics, integration health, employee status, recent activity, and alerts.

**Response Example:**

```json
{
  "data": {
    "asset_inventory": {
      "total": 1247,
      "by_status": {
        "in_stock": 156,
        "assigned": 892,
        "in_repair": 23,
        "retired": 176,
        "on_order": 0,
        "in_transit": 0,
        "lost": 0,
        "stolen": 0
      },
      "utilization_rate": 85.1,
      "warranty_expiring_soon": 18
    },
    "workflow_metrics": {
      "active_by_type": {
        "onboarding": 12,
        "offboarding": 3,
        "repair": 5,
        "maintenance": 8,
        "procurement": 2
      },
      "overdue": 4,
      "avg_completion_time": {
        "onboarding": 4.2,
        "offboarding": 2.1,
        "repair": 5.8
      }
    },
    "integration_health": {
      "integrations": [
        {
          "id": "uuid",
          "provider": "bamboohr",
          "name": "BambooHR Sync",
          "last_sync_at": "2024-01-20T14:30:00Z",
          "last_sync_status": "success",
          "last_sync_records_count": 45,
          "last_sync_error": null
        },
        {
          "id": "uuid",
          "provider": "jamf",
          "name": "Jamf MDM",
          "last_sync_at": "2024-01-20T15:00:00Z",
          "last_sync_status": "success",
          "last_sync_records_count": 234,
          "last_sync_error": null
        }
      ],
      "success_rate_24h": 94.5,
      "failed_syncs": 2
    },
    "employee_status": {
      "total": 458,
      "active": 445,
      "new_hires": 12,
      "terminations": 8
    },
    "recent_activity": [
      {
        "id": "uuid",
        "transaction_type": "assign",
        "performed_at": "2024-01-20T16:45:00Z",
        "asset_name": "MacBook Pro 16\"",
        "employee_name": "John Doe"
      }
    ],
    "alerts": [
      {
        "severity": "error",
        "type": "integration_failure",
        "message": "2 integration(s) failing",
        "count": 2
      },
      {
        "severity": "warning",
        "type": "overdue_workflows",
        "message": "4 workflow(s) overdue",
        "count": 4
      }
    ]
  },
  "role": "admin"
}
```

## Caching

Dashboard data is cached for 5 minutes to improve performance and reduce database load. The cache key is based on:

- Tenant slug
- User role
- User ID

Cache is automatically invalidated after 5 minutes or can be manually cleared if needed.

### Cache Keys

- Employee: `{tenant}:employee:{user_id}`
- Manager: `{tenant}:manager:{user_id}`
- Admin: `{tenant}:admin:{user_id}`

## Error Responses

### 401 Unauthorized

```json
{
  "error": {
    "message": "Unauthorized"
  }
}
```

### 404 Not Found

```json
{
  "error": {
    "message": "Resource not found"
  }
}
```

### 500 Internal Server Error

```json
{
  "error": {
    "message": "Internal server error"
  }
}
```

## Implementation Details

### Backend Components

1. **Dashboard Context** (`lib/assetronics/dashboard.ex`)
   - Core business logic for fetching dashboard data
   - Role-specific query functions
   - Aggregation and calculation logic

2. **Dashboard Cache** (`lib/assetronics/dashboard/cache.ex`)
   - ETS-based caching system
   - Automatic expiration and cleanup
   - Pattern-based cache invalidation

3. **Dashboard Controller** (`lib/assetronics_web/controllers/dashboard_controller.ex`)
   - HTTP request handling
   - Role-based routing
   - Authentication and authorization

4. **Dashboard JSON View** (`lib/assetronics_web/controllers/dashboard_json.ex`)
   - JSON response formatting

### Database Queries

The dashboard executes optimized database queries that:

- Use aggregations (COUNT, AVG, SUM) to minimize data transfer
- Filter by tenant using Triplex prefixes
- Include proper indexes for performance
- Use date ranges for time-based metrics

### Performance Considerations

- **Caching**: 5-minute cache TTL reduces database load
- **Lazy Loading**: Data is only fetched when requested
- **Aggregations**: Database-level aggregations minimize data transfer
- **Indexes**: Ensure proper indexes exist on frequently queried columns

## Usage Examples

### Fetch Dashboard as Employee

```bash
# Login first
TOKEN=$(curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant: acme" \
  -d '{"email": "employee@acme.com", "password": "password123"}' \
  | jq -r '.data.token')

# Get dashboard
curl -X GET http://localhost:4000/api/v1/dashboard \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: acme" \
  | jq
```

### Fetch Dashboard as Admin

```bash
# Login first
TOKEN=$(curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant: acme" \
  -d '{"email": "admin@acme.com", "password": "password123"}' \
  | jq -r '.data.token')

# Get dashboard
curl -X GET http://localhost:4000/api/v1/dashboard \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant: acme" \
  | jq
```

## Related Documentation

- [User Dashboard Metrics Guide](USER_DASHBOARD_METRICS.md) - Detailed specification of dashboard metrics
- [Telemetry Dashboard Guide](TELEMETRY_DASHBOARD_GUIDE.md) - Technical metrics and monitoring
- [System Connectivity Analysis](SYSTEM_CONNECTIVITY_ANALYSIS.md) - Overall system architecture

## Future Enhancements

Potential improvements for the dashboard:

1. **Real-time Updates**: Use Phoenix Channels to push live updates
2. **Customizable Widgets**: Allow users to customize their dashboard layout
3. **Data Export**: Add ability to export dashboard data (CSV, PDF)
4. **Time Range Filters**: Add date range selectors for historical data
5. **Drill-down Views**: Click on metrics to view detailed breakdowns
6. **Comparative Analytics**: Show trends over time (week-over-week, month-over-month)
7. **Custom Alerts**: Allow users to configure custom alert thresholds
8. **Multi-tenant Comparison**: For super admins, compare metrics across tenants
