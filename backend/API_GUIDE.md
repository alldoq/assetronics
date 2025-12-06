# Assetronics API Guide

**Complete REST API Documentation**

Base URL: `http://localhost:4000/api/v1`

---

## Authentication

All API requests (except public endpoints) require JWT authentication and tenant identification.

### Public Endpoints (No Authentication Required)

- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Refresh access token
- `POST /auth/password/reset` - Request password reset
- `POST /auth/password/confirm` - Confirm password reset
- `POST /auth/email/verify` - Verify email address
- `GET /health` - Health check

### Tenant Identification

**Header:** `X-Tenant-ID: <tenant_slug>`

Example:
```bash
curl -H "X-Tenant-ID: acme" http://localhost:4000/api/v1/assets
```

Alternatively, use subdomain:
```bash
curl http://acme.localhost:4000/api/v1/assets
```

### JWT Authentication

Protected endpoints require a Bearer token in the Authorization header:

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     http://localhost:4000/api/v1/assets
```

### Token Management

#### Login

**POST /auth/login**

Authenticate with email and password to receive access and refresh tokens.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: acme" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123"
  }' \
  http://localhost:4000/api/v1/auth/login
```

Response:
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "employee",
      "status": "active",
      "email_verified": true
    }
  }
}
```

#### Logout

**POST /auth/logout** (Requires Authentication)

```bash
curl -X POST \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/auth/logout
```

#### Refresh Token

**POST /auth/refresh**

Use a refresh token to obtain a new access token.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }' \
  http://localhost:4000/api/v1/auth/refresh
```

Response:
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

#### Get Current User

**GET /auth/me** (Requires Authentication)

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     http://localhost:4000/api/v1/auth/me
```

---

## User Management

### Register User

**POST /auth/register**

Create a new user account.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: acme" \
  -d '{
    "user": {
      "email": "newuser@example.com",
      "password": "SecurePassword123",
      "first_name": "Jane",
      "last_name": "Smith",
      "role": "employee"
    }
  }' \
  http://localhost:4000/api/v1/auth/register
```

### List Users

**GET /users** (Requires Authentication - Admin/Manager only)

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     "http://localhost:4000/api/v1/users?role=employee"
```

### Get User

**GET /users/:id** (Requires Authentication)

Users can view their own profile. Admins and managers can view any profile.

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     http://localhost:4000/api/v1/users/uuid
```

### Update User

**PATCH /users/:id** (Requires Authentication)

Users can update their own profile. Admins can update any profile.

```bash
curl -X PATCH \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Jane",
      "phone": "+1234567890"
    }
  }' \
  http://localhost:4000/api/v1/users/uuid
```

### Update User Role

**PATCH /users/:id/role** (Requires Authentication - Admin only)

```bash
curl -X PATCH \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "manager"
  }' \
  http://localhost:4000/api/v1/users/uuid/role
```

### Delete User

**DELETE /users/:id** (Requires Authentication - Admin only)

```bash
curl -X DELETE \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/users/uuid
```

---

## Password Management

### Request Password Reset

**POST /auth/password/reset**

Request a password reset email.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: acme" \
  -d '{
    "email": "user@example.com"
  }' \
  http://localhost:4000/api/v1/auth/password/reset
```

### Confirm Password Reset

**POST /auth/password/confirm**

Reset password using the token from email.

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: acme" \
  -d '{
    "token": "reset_token_from_email",
    "password": "NewSecurePassword123"
  }' \
  http://localhost:4000/api/v1/auth/password/confirm
```

### Change Password

**PATCH /auth/password/change** (Requires Authentication)

Change password for the authenticated user.

```bash
curl -X PATCH \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "OldPassword123",
    "password": "NewSecurePassword123"
  }' \
  http://localhost:4000/api/v1/auth/password/change
```

---

## User Roles and Permissions

### Available Roles

- **super_admin** - Full system access across all tenants
- **admin** - Full access within their tenant
- **manager** - Can manage employees, assets, and workflows
- **employee** - Can view assigned assets and complete workflows
- **viewer** - Read-only access to resources

### Permission Matrix

| Action | super_admin | admin | manager | employee | viewer |
|--------|-------------|-------|---------|----------|--------|
| Manage Users | ✓ | ✓ | - | - | - |
| Manage Assets | ✓ | ✓ | ✓ | - | - |
| View Assets | ✓ | ✓ | ✓ | ✓ | ✓ |
| Manage Employees | ✓ | ✓ | ✓ | - | - |
| Manage Workflows | ✓ | ✓ | ✓ | - | - |
| Complete Tasks | ✓ | ✓ | ✓ | ✓ | - |
| Manage Integrations | ✓ | ✓ | - | - | - |

---

## File Management

### Upload File

**POST /files** (Requires Authentication)

Upload a file with multipart/form-data.

```bash
curl -X POST \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -F "file=@/path/to/document.pdf" \
  -F "category=document" \
  http://localhost:4000/api/v1/files
```

**Parameters:**
- `file` - The file to upload (required)
- `category` - File category: `avatar`, `asset_photo`, `document`, `attachment`, `other` (optional, default: `other`)
- `attachable_type` - Resource type (optional)
- `attachable_id` - Resource ID (optional)

Response:
```json
{
  "data": {
    "id": "uuid",
    "filename": "document_timestamp_random.pdf",
    "original_filename": "document.pdf",
    "content_type": "application/pdf",
    "file_size": 1024000,
    "category": "document",
    "storage_provider": "local",
    "url": "/uploads/acme/document/document_timestamp_random.pdf",
    "uploaded_by_id": "uuid",
    "inserted_at": "2025-11-17T12:00:00Z"
  }
}
```

### List Files

**GET /files** (Requires Authentication)

List all files for the tenant.

**Query Parameters:**
- `category` - Filter by category
- `attachable_type` - Filter by attachable type
- `attachable_id` - Filter by attachable ID
- `uploaded_by_id` - Filter by uploader

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     "http://localhost:4000/api/v1/files?category=document"
```

### Get File

**GET /files/:id** (Requires Authentication)

Get file details and download URL.

```bash
curl -H "Authorization: Bearer <access_token>" \
     -H "X-Tenant-ID: acme" \
     http://localhost:4000/api/v1/files/uuid
```

### Delete File

**DELETE /files/:id** (Requires Authentication)

Delete a file from storage and database.

```bash
curl -X DELETE \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/files/uuid
```

### Upload User Avatar

**POST /users/:id/avatar** (Requires Authentication)

Upload or update a user's avatar. Users can upload their own avatar, admins can upload for any user.

```bash
curl -X POST \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -F "file=@/path/to/avatar.jpg" \
  http://localhost:4000/api/v1/users/uuid/avatar
```

**File Restrictions:**
- Max size: 5 MB
- Allowed types: JPEG, PNG, WebP, GIF

### Upload Asset Photo

**POST /assets/:id/photos** (Requires Authentication - Manager/Admin only)

Upload a photo for an asset.

```bash
curl -X POST \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -F "file=@/path/to/laptop.jpg" \
  http://localhost:4000/api/v1/assets/uuid/photos
```

**File Restrictions:**
- Max size: 10 MB
- Allowed types: JPEG, PNG, WebP

### Upload Workflow Attachment

**POST /workflows/:id/attachments** (Requires Authentication)

Upload an attachment to a workflow execution.

```bash
curl -X POST \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Tenant-ID: acme" \
  -F "file=@/path/to/receipt.pdf" \
  http://localhost:4000/api/v1/workflows/uuid/attachments
```

**File Restrictions:**
- Max size: 50 MB
- Allowed types: All types accepted

### File Categories and Limits

| Category | Max Size | Allowed Types |
|----------|----------|---------------|
| avatar | 5 MB | JPEG, PNG, WebP, GIF |
| asset_photo | 10 MB | JPEG, PNG, WebP |
| document | 50 MB | PDF, Excel, PowerPoint, Word, CSV |
| attachment | 50 MB | All types |
| other | 25 MB | All types |

---

## Endpoints

### Health Check

#### GET /health
Public endpoint to check API health.

```bash
curl http://localhost:4000/api/v1/health
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2025-11-17T12:00:00Z",
  "version": "0.1.0"
}
```

---

## Assets

### List Assets

#### GET /assets
List all assets for the tenant.

**Query Parameters:**
- `status` - Filter by status (in_stock, assigned, in_transit, in_repair, retired, lost, stolen)
- `category` - Filter by category (laptop, desktop, monitor, phone, tablet, peripheral, other)
- `employee_id` - Filter by assigned employee

```bash
curl -H "X-Tenant-ID: acme" \
  "http://localhost:4000/api/v1/assets?status=assigned"
```

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "asset_tag": "MBP-001",
      "name": "MacBook Pro 16-inch",
      "category": "laptop",
      "make": "Apple",
      "model": "MacBook Pro 16-inch 2024",
      "serial_number": "C02XY1234567",
      "purchase_cost": "3499.00",
      "status": "assigned",
      "condition": "new",
      "employee": {
        "id": "uuid",
        "email": "john@acme.com",
        "first_name": "John",
        "last_name": "Doe"
      }
    }
  ]
}
```

### Create Asset

#### POST /assets

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "asset": {
      "name": "MacBook Pro 16-inch",
      "asset_tag": "MBP-001",
      "category": "laptop",
      "make": "Apple",
      "model": "MacBook Pro 16-inch 2024",
      "serial_number": "C02XY1234567",
      "purchase_date": "2024-01-10",
      "purchase_cost": "3499.00",
      "vendor": "Apple",
      "status": "in_stock",
      "condition": "new"
    }
  }' \
  http://localhost:4000/api/v1/assets
```

### Get Asset

#### GET /assets/:id

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/assets/<asset_id>
```

### Update Asset

#### PATCH /assets/:id

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "asset": {
      "condition": "good",
      "notes": "Minor scratches on lid"
    }
  }' \
  http://localhost:4000/api/v1/assets/<asset_id>
```

### Delete Asset

#### DELETE /assets/:id

```bash
curl -X DELETE \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/assets/<asset_id>
```

### Assign Asset

#### POST /assets/:id/assign

Assigns an asset to an employee.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "employee_id": "employee-uuid",
    "assignment_type": "permanent"
  }' \
  http://localhost:4000/api/v1/assets/<asset_id>/assign
```

**Parameters:**
- `employee_id` (required) - Employee UUID
- `assignment_type` (optional) - permanent, temporary, loaner (default: permanent)
- `expected_return_date` (optional) - ISO date string

### Return Asset

#### POST /assets/:id/return

Returns an asset from an employee.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "employee_id": "employee-uuid"
  }' \
  http://localhost:4000/api/v1/assets/<asset_id>/return
```

### Transfer Asset

#### POST /assets/:id/transfer

Transfers an asset between employees.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "from_employee_id": "employee-uuid-1",
    "to_employee_id": "employee-uuid-2"
  }' \
  http://localhost:4000/api/v1/assets/<asset_id>/transfer
```

### Get Asset History

#### GET /assets/:id/history

Gets complete transaction history for an asset.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/assets/<asset_id>/history
```

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "transaction_type": "assignment",
      "description": "Asset assigned to john@acme.com",
      "from_status": "in_stock",
      "to_status": "assigned",
      "performed_by": "admin@acme.com",
      "performed_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### Search Assets

#### GET /assets/search

Search assets by query string.

```bash
curl -H "X-Tenant-ID: acme" \
  "http://localhost:4000/api/v1/assets/search?q=macbook&category=laptop"
```

**Query Parameters:**
- `q` - Search query (searches name, asset_tag, make, model)
- `category` - Filter by category
- `status` - Filter by status
- `tags` - Comma-separated tags

---

## Employees

### List Employees

#### GET /employees

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/employees
```

### Create Employee

#### POST /employees

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "employee": {
      "email": "john@acme.com",
      "first_name": "John",
      "last_name": "Doe",
      "job_title": "Software Engineer",
      "department": "Engineering",
      "employment_status": "active",
      "hire_date": "2024-01-15"
    }
  }' \
  http://localhost:4000/api/v1/employees
```

### Get Employee

#### GET /employees/:id

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/employees/<employee_id>
```

### Update Employee

#### PATCH /employees/:id

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "employee": {
      "job_title": "Senior Software Engineer",
      "department": "Engineering"
    }
  }' \
  http://localhost:4000/api/v1/employees/<employee_id>
```

### Delete Employee

#### DELETE /employees/:id

```bash
curl -X DELETE \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/employees/<employee_id>
```

### Terminate Employee

#### POST /employees/:id/terminate

Terminates an employee and records termination details.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "termination_date": "2024-12-31",
    "reason": "Resignation",
    "notes": "Two weeks notice provided"
  }' \
  http://localhost:4000/api/v1/employees/<employee_id>/terminate
```

### Reactivate Employee

#### POST /employees/:id/reactivate

Reactivates a terminated employee.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/employees/<employee_id>/reactivate
```

### Get Employee Assets

#### GET /employees/:id/assets

Gets all assets assigned to an employee.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/employees/<employee_id>/assets
```

Response:
```json
{
  "data": {
    "id": "uuid",
    "email": "john@acme.com",
    "first_name": "John",
    "last_name": "Doe",
    "assets": [
      {
        "id": "uuid",
        "asset_tag": "MBP-001",
        "name": "MacBook Pro 16-inch",
        "category": "laptop",
        "status": "assigned",
        "assigned_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

---

## Locations

### List Locations

#### GET /locations

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations
```

### Create Location

#### POST /locations

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "location": {
      "name": "San Francisco Office",
      "location_type": "office",
      "city": "San Francisco",
      "state_province": "CA",
      "country": "USA"
    }
  }' \
  http://localhost:4000/api/v1/locations
```

### Get Location

#### GET /locations/:id

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>
```

### Update Location

#### PATCH /locations/:id

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "location": {
      "contact_name": "Jane Smith",
      "contact_email": "jane@acme.com"
    }
  }' \
  http://localhost:4000/api/v1/locations/<location_id>
```

### Delete Location

#### DELETE /locations/:id

```bash
curl -X DELETE \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>
```

### Activate Location

#### POST /locations/:id/activate

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>/activate
```

### Deactivate Location

#### POST /locations/:id/deactivate

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>/deactivate
```

### Get Location Assets

#### GET /locations/:id/assets

Gets all assets at a location.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>/assets
```

### Get Location Employees

#### GET /locations/:id/employees

Gets all employees at a location.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/locations/<location_id>/employees
```

---

## Workflows

### List Workflows

#### GET /workflows

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows
```

### Create Workflow

#### POST /workflows

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "workflow": {
      "workflow_type": "onboarding",
      "title": "Onboarding: John Doe",
      "employee_id": "employee-uuid",
      "priority": "high",
      "due_date": "2024-01-22"
    }
  }' \
  http://localhost:4000/api/v1/workflows
```

### Get Workflow

#### GET /workflows/:id

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/<workflow_id>
```

### Update Workflow

#### PATCH /workflows/:id

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "workflow": {
      "priority": "urgent",
      "assigned_to": "admin@acme.com"
    }
  }' \
  http://localhost:4000/api/v1/workflows/<workflow_id>
```

### Delete Workflow

#### DELETE /workflows/:id

```bash
curl -X DELETE \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/<workflow_id>
```

### Start Workflow

#### POST /workflows/:id/start

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/<workflow_id>/start
```

### Complete Workflow

#### POST /workflows/:id/complete

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/<workflow_id>/complete
```

### Cancel Workflow

#### POST /workflows/:id/cancel

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "No longer needed"
  }' \
  http://localhost:4000/api/v1/workflows/<workflow_id>/cancel
```

### Advance Workflow Step

#### POST /workflows/:id/advance

Advances the workflow to the next step.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/<workflow_id>/advance
```

### Get Overdue Workflows

#### GET /workflows/overdue

Gets all workflows that are past their due date.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/workflows/overdue
```

---

## Integrations

### List Integrations

#### GET /integrations

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations
```

### Create Integration

#### POST /integrations

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "integration": {
      "name": "BambooHR",
      "integration_type": "hris",
      "provider": "bamboohr",
      "auth_type": "api_key",
      "api_key": "your-api-key-here",
      "base_url": "https://api.bamboohr.com",
      "sync_enabled": true,
      "sync_frequency": "hourly"
    }
  }' \
  http://localhost:4000/api/v1/integrations
```

### Get Integration

#### GET /integrations/:id

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>
```

### Update Integration

#### PATCH /integrations/:id

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "integration": {
      "sync_frequency": "daily",
      "api_key": "new-api-key"
    }
  }' \
  http://localhost:4000/api/v1/integrations/<integration_id>
```

### Delete Integration

#### DELETE /integrations/:id

```bash
curl -X DELETE \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>
```

### Trigger Sync

#### POST /integrations/:id/sync

Manually triggers a sync for an integration.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>/sync
```

### Test Connection

#### POST /integrations/:id/test

Tests connection to an integration.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>/test
```

### Enable Sync

#### POST /integrations/:id/enable-sync

Enables automatic syncing for an integration.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>/enable-sync
```

### Disable Sync

#### POST /integrations/:id/disable-sync

Disables automatic syncing for an integration.

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/integrations/<integration_id>/disable-sync
```

### Get Sync History

#### GET /integrations/:id/sync-history

Gets sync history and logs for an integration.

**Query Parameters:**
- `limit` - Number of records to return (default: 50)

```bash
curl -H "X-Tenant-ID: acme" \
  "http://localhost:4000/api/v1/integrations/<integration_id>/sync-history?limit=20"
```

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "status": "success",
      "started_at": "2024-01-15T10:00:00Z",
      "completed_at": "2024-01-15T10:05:00Z",
      "records_synced": 25,
      "error_message": null
    }
  ]
}
```

---

## Tenants

### Get Tenant Info

#### GET /tenants/:id

Returns information about the current tenant.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/tenants/<tenant_id>
```

Response:
```json
{
  "data": {
    "id": "uuid",
    "name": "Acme Corp",
    "slug": "acme",
    "status": "active",
    "plan": "professional",
    "billing_cycle": "monthly",
    "subscription_status": "active",
    "features": ["asset_management", "integrations", "workflows"],
    "is_trial": false,
    "subscription_health": "healthy"
  }
}
```

### Update Tenant

#### PATCH /tenants/:id

Updates tenant settings.

```bash
curl -X PATCH \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "tenant": {
      "contact_name": "John Doe",
      "contact_email": "john@acme.com",
      "timezone": "America/Los_Angeles"
    }
  }' \
  http://localhost:4000/api/v1/tenants/<tenant_id>
```

### Get Tenant Usage

#### GET /tenants/:id/usage

Returns current usage statistics for the tenant.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/tenants/<tenant_id>/usage
```

Response:
```json
{
  "data": {
    "tenant_id": "uuid",
    "tenant_name": "Acme Corp",
    "plan": "professional",
    "usage": {
      "assets": 45,
      "employees": 12,
      "integrations": 3,
      "workflows": 28,
      "storage_gb": 2.5
    },
    "plan_limits": {
      "assets": 500,
      "employees": 100,
      "integrations": 10,
      "workflows": 500,
      "storage_gb": 50
    }
  }
}
```

### Get Tenant Features

#### GET /tenants/:id/features

Returns enabled features for the tenant.

```bash
curl -H "X-Tenant-ID: acme" \
  http://localhost:4000/api/v1/tenants/<tenant_id>/features
```

Response:
```json
{
  "data": {
    "tenant_id": "uuid",
    "plan": "professional",
    "features": ["asset_management", "integrations", "workflows"],
    "available_features": [
      "asset_management",
      "employee_management",
      "advanced_workflows",
      "custom_fields",
      "api_access",
      "integrations"
    ]
  }
}
```

### Add Feature

#### POST /tenants/:id/features/add

Adds a feature to the tenant (admin only).

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "feature": "advanced_reporting"
  }' \
  http://localhost:4000/api/v1/tenants/<tenant_id>/features/add
```

### Remove Feature

#### POST /tenants/:id/features/remove

Removes a feature from the tenant (admin only).

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "feature": "advanced_reporting"
  }' \
  http://localhost:4000/api/v1/tenants/<tenant_id>/features/remove
```

### Update Subscription

#### POST /tenants/:id/subscription

Updates tenant subscription plan (admin only).

```bash
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "enterprise",
    "billing_cycle": "annual"
  }' \
  http://localhost:4000/api/v1/tenants/<tenant_id>/subscription
```

---

## Error Responses

### Validation Errors (422)

```json
{
  "errors": {
    "email": ["can't be blank"],
    "name": ["can't be blank"]
  }
}
```

### Not Found (404)

```json
{
  "errors": {
    "detail": "Not Found"
  }
}
```

### Bad Request (400)

```json
{
  "errors": {
    "detail": "Employee ID is required"
  }
}
```

---

## Testing the API

### 1. Start the server

```bash
cd backend
export CLOAK_KEY="Q0FPM043eFRsVnUvU2I5bG5EVFk0aUt0L2dmdGlSdkEK"
mix phx.server
```

### 2. Create a tenant (in IEx)

```elixir
iex -S mix

# Create tenant
{:ok, tenant} = Assetronics.Accounts.create_tenant(%{
  name: "Acme Corp",
  slug: "acme"
})

# Outputs: tenant created with schema tenant_acme
```

### 3. Create sample data

```elixir
# Create employee
{:ok, employee} = Assetronics.Employees.create_employee("acme", %{
  email: "john@acme.com",
  first_name: "John",
  last_name: "Doe",
  employment_status: "active"
})

# Create asset
{:ok, asset} = Assetronics.Assets.create_asset("acme", %{
  name: "MacBook Pro",
  asset_tag: "MBP-001",
  category: "laptop",
  status: "in_stock"
})
```

### 4. Test with curl

```bash
# Health check
curl http://localhost:4000/api/v1/health

# List assets
curl -H "X-Tenant-ID: acme" http://localhost:4000/api/v1/assets

# Assign asset
curl -X POST \
  -H "X-Tenant-ID: acme" \
  -H "Content-Type: application/json" \
  -d "{\"employee_id\": \"${employee_id}\"}" \
  http://localhost:4000/api/v1/assets/${asset_id}/assign
```

---

## CORS Configuration

CORS is configured to allow requests from:
- `http://localhost:3000` (React default)
- `http://localhost:5173` (Vite default)

Update in `lib/assetronics_web/router.ex` for production domains.

---

## Next Steps

1. **Authentication** - Add Guardian JWT authentication
2. **Authorization** - Add Bodyguard RBAC policies
3. **Rate Limiting** - Add rate limiting per tenant
4. **Pagination** - Add pagination to list endpoints
5. **Filtering** - Add more advanced filtering options
6. **Documentation** - Generate OpenAPI/Swagger docs

---

**Happy coding!** 🚀
