# Assetronics - API Specification
**Version:** 1.0 (v1)
**Last Updated:** 2025-11-17
**Base URL:** `https://api.assetronics.com/v1`

## Table of Contents
1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Common Patterns](#common-patterns)
4. [Assets API](#assets-api)
5. [Workflows API](#workflows-api)
6. [Employees API](#employees-api)
7. [Integrations API](#integrations-api)
8. [Reports API](#reports-api)
9. [Notifications API](#notifications-api)
10. [Webhooks](#webhooks)
11. [Error Handling](#error-handling)
12. [Rate Limiting](#rate-limiting)

---

## API Overview

### Design Principles
- **RESTful**: Resource-oriented URLs, HTTP methods (GET, POST, PUT, DELETE)
- **JSON**: All requests and responses use JSON
- **Versioning**: API version in URL (`/v1/`, `/v2/`)
- **Pagination**: Cursor-based pagination for lists
- **Filtering**: Query parameters for filtering
- **Idempotency**: POST/PUT requests support idempotency keys
- **HATEOAS**: Links to related resources

### Base URL
```
Production: https://api.assetronics.com/v1
Staging: https://api-staging.assetronics.com/v1
```

### Content Type
All requests must include:
```
Content-Type: application/json
Accept: application/json
```

---

## Authentication

### API Key Authentication
For server-to-server integrations:
```
Authorization: Bearer <API_KEY>
```

**Example:**
```bash
curl -H "Authorization: Bearer asst_live_abc123xyz" \
     https://api.assetronics.com/v1/assets
```

### JWT (User Sessions)
For web/mobile apps:
```
Authorization: Bearer <JWT_TOKEN>
```

**Login Endpoint:**
```http
POST /v1/auth/login
Content-Type: application/json

{
  "email": "user@company.com",
  "password": "SecurePassword123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh_abc123xyz",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

### OAuth 2.0 (Third-Party Apps)
For third-party integrations:
- **Authorization URL:** `https://auth.assetronics.com/oauth/authorize`
- **Token URL:** `https://auth.assetronics.com/oauth/token`
- **Scopes:** `assets:read`, `assets:write`, `workflows:read`, etc.

---

## Common Patterns

### Pagination
All list endpoints support pagination:

**Request:**
```http
GET /v1/assets?limit=50&cursor=abc123
```

**Response:**
```json
{
  "data": [ /* array of resources */ ],
  "pagination": {
    "next_cursor": "def456",
    "previous_cursor": "abc123",
    "has_more": true,
    "total_count": 150
  }
}
```

### Filtering
Use query parameters:
```http
GET /v1/assets?status=assigned&category=laptop&department=engineering
```

### Sorting
```http
GET /v1/assets?sort_by=purchase_date&sort_order=desc
```

### Field Selection (Sparse Fields)
```http
GET /v1/assets?fields=id,asset_tag,serial_number,status
```

### Includes (Expand Related Resources)
```http
GET /v1/assets/:id?include=assigned_employee,location
```

### Idempotency
To prevent duplicate requests (e.g., creating the same asset twice):
```http
POST /v1/assets
Idempotency-Key: unique-key-123
Content-Type: application/json

{ /* asset data */ }
```

---

## Assets API

### Data Model

```typescript
interface Asset {
  id: string;  // UUID
  tenant_id: string;
  asset_tag: string;  // Unique, e.g., "ASST-001"
  serial_number: string | null;
  make: string;  // e.g., "Apple"
  model: string;  // e.g., "MacBook Pro 16"
  category: "laptop" | "desktop" | "monitor" | "phone" | "tablet" | "accessory";
  purchase_date: string;  // ISO 8601 date
  purchase_cost: number;  // USD cents
  vendor: string;
  po_number: string | null;
  warranty_expiry: string | null;
  status: "ordered" | "in_transit" | "in_stock" | "assigned" | "under_repair" | "returned" | "decommissioned";
  location: Location;
  assigned_to: Employee | null;
  assigned_at: string | null;  // ISO 8601 timestamp
  metadata: Record<string, any>;  // Custom fields
  depreciation: {
    method: "straight_line" | "declining_balance";
    useful_life_years: number;
    salvage_value: number;
    current_book_value: number;
  };
  images: string[];  // URLs
  created_at: string;
  updated_at: string;
}
```

### Endpoints

#### List Assets
```http
GET /v1/assets
```

**Query Parameters:**
- `status`: Filter by status (comma-separated for multiple)
- `category`: Filter by category
- `assigned_to`: Filter by employee ID
- `location_id`: Filter by location
- `search`: Full-text search (serial number, model, asset tag)
- `limit`: Results per page (default: 50, max: 100)
- `cursor`: Pagination cursor

**Response:**
```json
{
  "data": [
    {
      "id": "ast_abc123",
      "asset_tag": "ASST-001",
      "serial_number": "ABC123XYZ",
      "make": "Apple",
      "model": "MacBook Pro 16\" M3 Max",
      "category": "laptop",
      "purchase_date": "2025-11-18",
      "purchase_cost": 349900,
      "status": "assigned",
      "assigned_to": {
        "id": "emp_xyz789",
        "name": "Jane Doe",
        "email": "jane@company.com"
      },
      "created_at": "2025-11-18T10:00:00Z",
      "updated_at": "2025-11-20T14:30:00Z"
    }
  ],
  "pagination": {
    "next_cursor": "cur_def456",
    "has_more": true,
    "total_count": 150
  }
}
```

---

#### Get Asset
```http
GET /v1/assets/:id
```

**Response:**
```json
{
  "id": "ast_abc123",
  "asset_tag": "ASST-001",
  "serial_number": "ABC123XYZ",
  "make": "Apple",
  "model": "MacBook Pro 16\" M3 Max",
  "category": "laptop",
  "purchase_date": "2025-11-18",
  "purchase_cost": 349900,
  "vendor": "Apple Inc.",
  "po_number": "PO-2025-456",
  "warranty_expiry": "2028-11-18",
  "status": "assigned",
  "location": {
    "id": "loc_123",
    "name": "San Francisco Office",
    "address": "123 Market St, San Francisco, CA 94103"
  },
  "assigned_to": {
    "id": "emp_xyz789",
    "employee_id": "EMP-12345",
    "name": "Jane Doe",
    "email": "jane@company.com",
    "department": "Engineering"
  },
  "assigned_at": "2025-11-20T14:30:00Z",
  "depreciation": {
    "method": "straight_line",
    "useful_life_years": 3,
    "salvage_value": 50000,
    "current_book_value": 340000
  },
  "metadata": {
    "ram": "32GB",
    "storage": "1TB SSD",
    "color": "Space Gray"
  },
  "images": [
    "https://cdn.assetronics.com/assets/ast_abc123_1.jpg"
  ],
  "created_at": "2025-11-18T10:00:00Z",
  "updated_at": "2025-11-20T14:30:00Z"
}
```

---

#### Create Asset
```http
POST /v1/assets
Content-Type: application/json

{
  "asset_tag": "ASST-002",
  "serial_number": "DEF456UVW",
  "make": "Dell",
  "model": "XPS 15",
  "category": "laptop",
  "purchase_date": "2025-11-20",
  "purchase_cost": 249900,
  "vendor": "Dell Inc.",
  "location_id": "loc_123",
  "metadata": {
    "ram": "16GB",
    "storage": "512GB SSD"
  }
}
```

**Response: `201 Created`**
```json
{
  "id": "ast_def456",
  "asset_tag": "ASST-002",
  /* ... full asset object ... */
}
```

---

#### Update Asset
```http
PUT /v1/assets/:id
Content-Type: application/json

{
  "status": "under_repair",
  "metadata": {
    "repair_reason": "Battery replacement"
  }
}
```

**Response: `200 OK`**
```json
{
  "id": "ast_abc123",
  "status": "under_repair",
  /* ... full asset object ... */
}
```

---

#### Assign Asset to Employee
```http
POST /v1/assets/:id/assign
Content-Type: application/json

{
  "employee_id": "emp_xyz789",
  "assigned_at": "2025-11-20T14:30:00Z",
  "notes": "New hire provisioning"
}
```

**Response: `200 OK`**
```json
{
  "id": "ast_abc123",
  "status": "assigned",
  "assigned_to": {
    "id": "emp_xyz789",
    "name": "Jane Doe"
  },
  "assigned_at": "2025-11-20T14:30:00Z"
}
```

---

#### Initiate Asset Return
```http
POST /v1/assets/:id/return
Content-Type: application/json

{
  "return_reason": "employee_termination",
  "expected_return_date": "2025-12-05",
  "shipping_address_id": "addr_123"
}
```

**Response: `200 OK`**
```json
{
  "id": "ast_abc123",
  "status": "return_pending",
  "return_workflow": {
    "id": "wf_return_123",
    "status": "pending",
    "tracking_number": "FDX123456789",
    "expected_return_date": "2025-12-05"
  }
}
```

---

#### Delete Asset
```http
DELETE /v1/assets/:id
```

**Response: `204 No Content`**

---

## Workflows API

### Data Model

```typescript
interface Workflow {
  id: string;
  tenant_id: string;
  workflow_type: "onboarding" | "offboarding" | "repair" | "refresh" | "custom";
  status: "pending" | "in_progress" | "completed" | "cancelled" | "failed";
  triggered_by: "hris_event" | "manual" | "scheduled" | "api";
  triggered_at: string;
  completed_at: string | null;
  steps: WorkflowStep[];
  context: {
    employee_id?: string;
    asset_id?: string;
    [key: string]: any;
  };
  created_at: string;
  updated_at: string;
}

interface WorkflowStep {
  id: string;
  name: string;
  type: "approval" | "task" | "integration" | "notification" | "wait";
  status: "pending" | "in_progress" | "completed" | "skipped" | "failed";
  assigned_to: string | null;  // User ID
  due_date: string | null;
  completed_at: string | null;
  metadata: Record<string, any>;
}
```

### Endpoints

#### List Workflows
```http
GET /v1/workflows?status=in_progress&workflow_type=onboarding
```

**Response:**
```json
{
  "data": [
    {
      "id": "wf_abc123",
      "workflow_type": "onboarding",
      "status": "in_progress",
      "triggered_at": "2025-11-20T10:00:00Z",
      "context": {
        "employee_id": "emp_xyz789",
        "employee_name": "Jane Doe",
        "start_date": "2025-12-01"
      },
      "steps": [
        {
          "id": "step_1",
          "name": "Manager Approval",
          "type": "approval",
          "status": "completed",
          "assigned_to": "user_mgr123",
          "completed_at": "2025-11-20T11:00:00Z"
        },
        {
          "id": "step_2",
          "name": "IT Approval",
          "type": "approval",
          "status": "pending",
          "assigned_to": "user_it456",
          "due_date": "2025-11-21T17:00:00Z"
        }
      ]
    }
  ],
  "pagination": { /* ... */ }
}
```

---

#### Get Workflow
```http
GET /v1/workflows/:id
```

---

#### Create Workflow
```http
POST /v1/workflows
Content-Type: application/json

{
  "workflow_type": "onboarding",
  "triggered_by": "manual",
  "context": {
    "employee_id": "emp_xyz789",
    "hardware_profile": "senior_engineer"
  }
}
```

**Response: `201 Created`**

---

#### Approve Workflow Step
```http
POST /v1/workflows/:workflow_id/steps/:step_id/approve
Content-Type: application/json

{
  "approved_by": "user_mgr123",
  "comments": "Approved for MacBook Pro"
}
```

**Response: `200 OK`**
```json
{
  "id": "step_1",
  "status": "completed",
  "approved_by": "user_mgr123",
  "completed_at": "2025-11-20T11:00:00Z"
}
```

---

#### Cancel Workflow
```http
POST /v1/workflows/:id/cancel
Content-Type: application/json

{
  "reason": "Employee declined offer"
}
```

**Response: `200 OK`**

---

## Employees API

### Data Model

```typescript
interface Employee {
  id: string;
  tenant_id: string;
  employee_id: string;  // From HRIS
  first_name: string;
  last_name: string;
  email: string;
  personal_email: string | null;
  department: string;
  job_title: string;
  manager: {
    id: string;
    name: string;
  } | null;
  location: Location;
  hire_date: string;
  termination_date: string | null;
  employment_status: "active" | "terminated" | "on_leave";
  cost_center: string | null;
  assigned_assets: Asset[];
  created_at: string;
  updated_at: string;
}
```

### Endpoints

#### List Employees
```http
GET /v1/employees?employment_status=active&department=engineering
```

---

#### Get Employee
```http
GET /v1/employees/:id?include=assigned_assets
```

**Response:**
```json
{
  "id": "emp_xyz789",
  "employee_id": "EMP-12345",
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane@company.com",
  "department": "Engineering",
  "job_title": "Senior Software Engineer",
  "hire_date": "2025-12-01",
  "employment_status": "active",
  "assigned_assets": [
    {
      "id": "ast_abc123",
      "asset_tag": "ASST-001",
      "model": "MacBook Pro 16\"",
      "assigned_at": "2025-11-20T14:30:00Z"
    }
  ]
}
```

---

#### Sync Employees from HRIS
```http
POST /v1/employees/sync
Content-Type: application/json

{
  "integration_id": "int_bamboohr_123"
}
```

**Response: `202 Accepted`**
```json
{
  "sync_job_id": "job_sync_456",
  "status": "queued",
  "message": "Employee sync job started"
}
```

---

## Integrations API

### Data Model

```typescript
interface Integration {
  id: string;
  tenant_id: string;
  integration_type: "hris" | "finance" | "itsm" | "mdm" | "procurement" | "communication";
  system_name: string;  // e.g., "BambooHR", "NetSuite"
  config: {
    api_endpoint: string;
    auth_type: "oauth" | "api_key" | "basic";
    credentials: Record<string, any>;  // Encrypted
    field_mappings: Record<string, string>;
  };
  status: "active" | "inactive" | "error";
  last_sync_at: string | null;
  last_sync_status: "success" | "failed" | "partial";
  last_sync_error: string | null;
  created_at: string;
  updated_at: string;
}
```

### Endpoints

#### List Integrations
```http
GET /v1/integrations
```

**Response:**
```json
{
  "data": [
    {
      "id": "int_bamboohr_123",
      "integration_type": "hris",
      "system_name": "BambooHR",
      "status": "active",
      "last_sync_at": "2025-11-17T08:00:00Z",
      "last_sync_status": "success"
    }
  ]
}
```

---

#### Get Integration
```http
GET /v1/integrations/:id
```

---

#### Create Integration
```http
POST /v1/integrations
Content-Type: application/json

{
  "integration_type": "hris",
  "system_name": "BambooHR",
  "config": {
    "api_endpoint": "https://api.bamboohr.com/api/gateway.php/company",
    "auth_type": "api_key",
    "credentials": {
      "api_key": "YOUR_BAMBOOHR_API_KEY"
    },
    "field_mappings": {
      "employee_id": "id",
      "email": "workEmail",
      "department": "department"
    }
  }
}
```

**Response: `201 Created`**

---

#### Trigger Manual Sync
```http
POST /v1/integrations/:id/sync
```

**Response: `202 Accepted`**
```json
{
  "sync_job_id": "job_sync_789",
  "status": "queued"
}
```

---

#### Get Sync Logs
```http
GET /v1/integrations/:id/logs?limit=50
```

**Response:**
```json
{
  "data": [
    {
      "id": "log_abc123",
      "sync_started_at": "2025-11-17T08:00:00Z",
      "sync_completed_at": "2025-11-17T08:05:00Z",
      "status": "success",
      "records_synced": 233,
      "errors": []
    }
  ]
}
```

---

#### Delete Integration
```http
DELETE /v1/integrations/:id
```

**Response: `204 No Content`**

---

## Reports API

### Endpoints

#### Get Asset Inventory Report
```http
GET /v1/reports/asset-inventory?format=json&group_by=category,status
```

**Response:**
```json
{
  "report_type": "asset_inventory",
  "generated_at": "2025-11-17T10:00:00Z",
  "data": {
    "total_assets": 150,
    "by_category": {
      "laptop": 80,
      "monitor": 50,
      "phone": 20
    },
    "by_status": {
      "assigned": 120,
      "in_stock": 20,
      "under_repair": 5,
      "decommissioned": 5
    },
    "total_value": 52000000
  }
}
```

---

#### Get Depreciation Report
```http
GET /v1/reports/depreciation?start_date=2025-01-01&end_date=2025-12-31&format=pdf
```

**Response: `200 OK` (Binary PDF)**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="depreciation_report_2025.pdf"
```

---

#### Get Workflow Performance Report
```http
GET /v1/reports/workflow-performance?workflow_type=onboarding&date_range=last_30_days
```

**Response:**
```json
{
  "report_type": "workflow_performance",
  "date_range": {
    "start": "2025-10-18",
    "end": "2025-11-17"
  },
  "data": {
    "total_workflows": 25,
    "completed": 22,
    "in_progress": 3,
    "average_completion_time_hours": 72,
    "on_time_completion_rate": 0.88
  }
}
```

---

#### Schedule Report
```http
POST /v1/reports/schedules
Content-Type: application/json

{
  "report_type": "asset_inventory",
  "frequency": "weekly",
  "format": "pdf",
  "delivery_method": "email",
  "recipients": ["finance@company.com", "it@company.com"]
}
```

**Response: `201 Created`**

---

## Notifications API

### Endpoints

#### Send Notification
```http
POST /v1/notifications
Content-Type: application/json

{
  "recipient": "jane@company.com",
  "channel": "email",
  "template": "asset_shipped",
  "data": {
    "employee_name": "Jane Doe",
    "asset_model": "MacBook Pro 16\"",
    "tracking_number": "FDX123456789",
    "expected_delivery": "2025-11-30"
  }
}
```

**Response: `202 Accepted`**
```json
{
  "notification_id": "ntf_abc123",
  "status": "queued"
}
```

---

#### Get Notification Status
```http
GET /v1/notifications/:id
```

**Response:**
```json
{
  "id": "ntf_abc123",
  "status": "sent",
  "sent_at": "2025-11-17T10:05:00Z",
  "channel": "email",
  "recipient": "jane@company.com"
}
```

---

## Webhooks

Assetronics can send webhook notifications to your server when events occur.

### Webhook Configuration

```http
POST /v1/webhooks
Content-Type: application/json

{
  "url": "https://your-app.com/webhooks/assetronics",
  "events": [
    "asset.created",
    "asset.assigned",
    "asset.returned",
    "workflow.completed"
  ],
  "secret": "your_webhook_secret"
}
```

### Webhook Payload

**Headers:**
```
Content-Type: application/json
X-Assetronics-Signature: sha256=abc123...
X-Assetronics-Event: asset.assigned
```

**Body:**
```json
{
  "event_id": "evt_abc123",
  "event_type": "asset.assigned",
  "timestamp": "2025-11-17T10:00:00Z",
  "tenant_id": "tenant_xyz",
  "data": {
    "asset_id": "ast_abc123",
    "asset_tag": "ASST-001",
    "employee_id": "emp_xyz789",
    "employee_name": "Jane Doe",
    "assigned_at": "2025-11-17T10:00:00Z"
  }
}
```

### Verifying Webhook Signatures

```python
import hmac
import hashlib

def verify_signature(payload, signature, secret):
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected_signature}", signature)
```

### Supported Events

**Asset Events:**
- `asset.created`
- `asset.updated`
- `asset.assigned`
- `asset.returned`
- `asset.decommissioned`

**Workflow Events:**
- `workflow.started`
- `workflow.step_completed`
- `workflow.completed`
- `workflow.cancelled`
- `workflow.failed`

**Integration Events:**
- `integration.sync.started`
- `integration.sync.completed`
- `integration.sync.failed`

**Employee Events:**
- `employee.created`
- `employee.updated`
- `employee.terminated`

---

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "invalid_request",
    "message": "The 'purchase_cost' field is required",
    "details": {
      "field": "purchase_cost",
      "expected": "number",
      "received": "null"
    },
    "request_id": "req_abc123"
  }
}
```

### Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `invalid_request` | Request validation failed |
| 401 | `authentication_failed` | Invalid or missing API key/token |
| 403 | `permission_denied` | Insufficient permissions |
| 404 | `resource_not_found` | Resource doesn't exist |
| 409 | `conflict` | Resource already exists or state conflict |
| 422 | `validation_error` | Business logic validation failed |
| 429 | `rate_limit_exceeded` | Too many requests |
| 500 | `internal_error` | Server error |
| 503 | `service_unavailable` | Service temporarily unavailable |

---

## Rate Limiting

### Limits

**By API Key:**
- **Standard:** 100 requests/minute, 10,000 requests/day
- **Professional:** 300 requests/minute, 50,000 requests/day
- **Enterprise:** 1,000 requests/minute, unlimited/day

**Response Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1700220000
```

**Rate Limit Exceeded Response (429):**
```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "You have exceeded your rate limit. Try again in 30 seconds.",
    "retry_after": 30
  }
}
```

---

## GraphQL API (Optional)

Assetronics also offers a GraphQL endpoint for complex queries:

**Endpoint:** `https://api.assetronics.com/graphql`

**Example Query:**
```graphql
query GetAssetWithEmployee {
  asset(id: "ast_abc123") {
    id
    assetTag
    model
    status
    assignedTo {
      id
      name
      email
      department
    }
    location {
      name
      address
    }
  }
}
```

**Example Mutation:**
```graphql
mutation AssignAsset {
  assignAsset(input: {
    assetId: "ast_abc123"
    employeeId: "emp_xyz789"
  }) {
    asset {
      id
      status
      assignedTo {
        name
      }
    }
  }
}
```

---

## Conclusion

The Assetronics API provides comprehensive programmatic access to all platform features. With RESTful design, flexible filtering, and robust error handling, developers can easily integrate Assetronics into their existing workflows and build custom automations.

**Key Features:**
- **RESTful design** for simplicity
- **GraphQL option** for complex queries
- **Webhooks** for real-time event notifications
- **Comprehensive error handling** for debugging
- **Rate limiting** to ensure fair usage
- **Versioning** for backward compatibility

For more examples and SDKs, visit: https://developers.assetronics.com
