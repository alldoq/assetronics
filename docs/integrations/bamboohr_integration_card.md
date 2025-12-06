# BambooHR Integration Card

## Overview

**Category:** HRIS (Human Resources Information System)
**Provider:** BambooHR
**Status:** ✅ Production Ready
**Adapter:** `Assetronics.Integrations.Adapters.BambooHR`

## Description

BambooHR is a cloud-based human resources platform designed for small and medium-sized businesses. This integration automatically syncs employee data from BambooHR into Assetronics, enabling automated asset assignment, onboarding workflows, and employee lifecycle management.

---

## Key Features

### ✅ Employee Data Synchronization
- Automated sync of employee records from BambooHR directory
- Creates new employees or updates existing records
- Handles employee terminations automatically
- Syncs on configurable schedule (hourly, daily, weekly)

### ✅ Onboarding Workflow Automation
- Automatically creates onboarding workflows for new hires
- Triggers for employees hired within last 30 days
- Integrates with Assetronics workflow engine

### ✅ Real-time Status Updates
- Tracks employment status changes (active, terminated, on leave)
- Handles termination dates from BambooHR
- Updates employee records in real-time

### ✅ Comprehensive Employee Fields
Syncs the following employee data:
- Basic Info: First name, last name, email
- Contact: Work phone, mobile phone
- Employment: Job title, department, division
- Dates: Hire date, termination date
- Location: Work location
- Reporting: Manager/supervisor information

---

## Authentication

**Method:** API Key (Basic Authentication)

### Required Credentials
- **API Key:** Your BambooHR API key
- **Subdomain:** Your company's BambooHR subdomain

### How to Get Credentials

1. **Log in to BambooHR** as an administrator
2. Go to **Account** → **API Keys**
3. Click **Add New Key**
4. Give it a name (e.g., "Assetronics Integration")
5. Copy the generated API key
6. Your subdomain is in your BambooHR URL: `https://[subdomain].bamboohr.com`

### API Documentation
- [BambooHR API Documentation](https://documentation.bamboohr.com/docs)
- Base URL: `https://api.bamboohr.com/api/gateway.php/{subdomain}/v1/`

---

## Configuration

### Setup via API

```bash
curl -X POST http://your-domain/api/v1/integrations \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "integration": {
      "name": "BambooHR",
      "adapter": "bamboo_hr",
      "provider": "bamboohr",
      "integration_type": "hris",
      "enabled": true,
      "api_key": "YOUR_BAMBOOHR_API_KEY",
      "auth_config": {
        "subdomain": "your-company"
      },
      "sync_frequency": "daily",
      "sync_time": "02:00"
    }
  }'
```

### Configuration Fields

| Field | Required | Description |
|-------|----------|-------------|
| `api_key` | Yes | BambooHR API key |
| `auth_config.subdomain` | Yes | Your BambooHR subdomain |
| `sync_frequency` | No | How often to sync (manual, hourly, daily, weekly) |
| `sync_time` | No | Time of day to run sync (for daily/weekly) |

---

## Data Mapping

### BambooHR → Assetronics Employee Fields

| BambooHR Field | Assetronics Field | Notes |
|----------------|-------------------|-------|
| `id` | `hris_id` | Unique identifier |
| `firstName` | `first_name` | - |
| `lastName` | `last_name` | - |
| `email` | `email` | Primary identifier for employee |
| `jobTitle` | `job_title` | - |
| `department` | `department` | - |
| `division` | `division` | - |
| `location` | `work_location` | Physical office location |
| `workPhone` | `phone` | Primary phone number |
| `mobilePhone` | `phone` | Used if workPhone is empty |
| `hireDate` | `hire_date` | ISO 8601 date |
| `terminationDate` | - | Used to trigger termination |
| `employmentStatus` | `employment_status` | Mapped to: active, terminated, on_leave |
| `supervisor` | `manager_email` | Supervisor's email |
| `status` | `employment_status` | Fallback if employmentStatus empty |

### Employment Status Mapping

| BambooHR Status | Assetronics Status |
|-----------------|-------------------|
| Active | active |
| Full-time | active |
| Part-time | active |
| Terminated | terminated |
| Inactive | terminated |
| On Leave | on_leave |
| Leave | on_leave |

---

## Sync Behavior

### Initial Sync
- Fetches all employees from BambooHR directory
- Creates new employee records in Assetronics
- Sets `sync_source` to "bamboohr"
- Enables sync for all imported employees

### Incremental Sync
- Updates existing employees by matching on email address
- Creates new employees if not found
- Updates all fields that have changed
- Handles terminations automatically

### Termination Handling
When an employee has:
- `employmentStatus` = "terminated" or "inactive", OR
- `terminationDate` is populated

The integration will:
1. Update employee status to "terminated"
2. Set termination date (or use current date if not provided)
3. Add termination reason: "Synced from BambooHR"
4. Trigger any configured offboarding workflows

### Onboarding Workflow Creation
For employees hired within the last 30 days:
- Automatically creates onboarding workflow
- Sets trigger as "hris_sync"
- Links to the integration for tracking
- Only creates workflow once per employee

---

## Sync Results

### Success Response
```json
{
  "status": "ok",
  "total": 150,
  "created": 5,
  "updated": 143,
  "terminated": 2,
  "errors": 0,
  "workflows_created": 3
}
```

### Response Fields
- `total` - Total employees in BambooHR
- `created` - New employees added to Assetronics
- `updated` - Existing employees updated
- `terminated` - Employees marked as terminated
- `errors` - Number of failed syncs
- `workflows_created` - Onboarding workflows created

---

## Common Use Cases

### 1. Automated Onboarding
**Scenario:** New employee joins the company

**Flow:**
1. HR adds new hire to BambooHR
2. Nightly sync detects new employee
3. Employee record created in Assetronics
4. Onboarding workflow automatically triggered
5. IT receives notification to prepare equipment
6. Assets can be pre-assigned before start date

### 2. Employee Offboarding
**Scenario:** Employee leaves the company

**Flow:**
1. HR marks employee as terminated in BambooHR
2. Sync detects termination status
3. Employee marked as terminated in Assetronics
4. Offboarding workflow triggered
5. IT notified to collect equipment
6. Assets unassigned and returned to inventory

### 3. Department Changes
**Scenario:** Employee transfers to different department

**Flow:**
1. HR updates department in BambooHR
2. Sync updates employee record
3. Department-specific assets can be reassigned
4. Reporting reflects new department allocation

### 4. Manager Updates
**Scenario:** Organizational restructuring

**Flow:**
1. HR updates supervisors in BambooHR
2. Sync updates manager relationships
3. Asset approval workflows updated
4. New manager has visibility to team's assets

---

## Testing

### Test Connection
```bash
curl -X POST http://your-domain/api/v1/integrations/{id}/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
{
  "status": "ok",
  "message": "Successfully connected to BambooHR"
}
```

### Trigger Manual Sync
```bash
curl -X POST http://your-domain/api/v1/integrations/{id}/sync \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### View Sync History
```bash
curl -X GET http://your-domain/api/v1/integrations/{id}/history \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Troubleshooting

### Common Issues

#### 401 Unauthorized
**Cause:** Invalid API key
**Solution:**
- Verify API key is correct
- Regenerate API key in BambooHR if needed
- Ensure API key has not been revoked

#### 403 Forbidden
**Cause:** API key doesn't have required permissions
**Solution:**
- Ensure API key has read access to employee directory
- Contact BambooHR admin to grant permissions

#### No Employees Synced
**Cause:** Incorrect subdomain or endpoint
**Solution:**
- Verify subdomain matches your BambooHR URL
- Check BambooHR has employees in the directory
- Test API endpoint manually

#### Duplicate Employees Created
**Cause:** Email address mismatch
**Solution:**
- Ensure employee emails match exactly
- Check for typos in email addresses
- Manually merge duplicate records if needed

---

## Rate Limits

BambooHR API rate limits:
- **1,000 requests per day** per API key
- No published per-minute limit

### Mitigation
- Sync runs maximum once per hour
- Recommended sync frequency: daily
- Integration uses efficient single-request directory fetch

---

## Security & Compliance

### Data Security
- ✅ API key encrypted at rest using Cloak
- ✅ HTTPS for all API communications
- ✅ Read-only access (no write operations)
- ✅ Tenant-isolated data storage

### Compliance Considerations
- **GDPR:** Employee data synced with consent
- **Data Retention:** Follows Assetronics policies
- **Access Control:** Limited to authorized API key

### Best Practices
1. Use dedicated API key for integration
2. Rotate API key periodically (every 90 days)
3. Monitor sync logs for anomalies
4. Audit employee data access regularly

---

## Monitoring

### Key Metrics to Track
- Sync success rate
- Number of employees synced
- Onboarding workflows created
- Sync duration
- Error count

### Logging
```bash
# View BambooHR sync logs
tail -f logs/assetronics.log | grep "BambooHR"
```

### Alert Conditions
- Sync failures for 3+ consecutive attempts
- Zero employees synced (unexpected)
- High error count (>5% of total)
- Authentication failures

---

## Integration Benefits

### For IT Teams
- **Automated Onboarding:** No manual employee entry
- **Accurate Records:** Single source of truth from HR
- **Timely Offboarding:** Equipment collected promptly
- **Reduced Admin:** Less time on data entry

### For HR Teams
- **Streamlined Process:** BambooHR remains system of record
- **IT Coordination:** Automatic equipment provisioning
- **Compliance:** Audit trail of employee-asset relationships

### For Finance
- **Cost Tracking:** Assets linked to departments/employees
- **Budget Planning:** Headcount-based asset forecasting
- **Audit Support:** Complete employee-asset history

---

## Roadmap & Future Enhancements

### Planned Features
- [ ] Webhook support for real-time sync
- [ ] Custom field mapping configuration
- [ ] Bulk import for historical data
- [ ] Two-way sync (update BambooHR from Assetronics)
- [ ] Advanced filtering by department/location

### Enhancement Requests
Submit feature requests via GitHub or support portal.

---

## Support Resources

### Documentation
- [BambooHR API Docs](https://documentation.bamboohr.com/docs)
- [Assetronics Integration Guide](../integration_setup_guide.md)

### Support Contacts
- **BambooHR Support:** https://help.bamboohr.com
- **Assetronics Support:** support@assetronics.com

### Related Integrations
- [Workday Integration](workday_integration_card.md)
- [Okta Integration](okta_integration_card.md)
- [Google Workspace Integration](../google_workspace_integration_summary.md)

---

**Last Updated:** November 2025
**Adapter Version:** 1.0
**Minimum Assetronics Version:** 1.0.0