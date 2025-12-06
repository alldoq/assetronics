# Google Workspace Integration - Testing Guide

## Overview
This guide provides instructions for testing the Google Workspace integration, including mock data examples for development and validation steps for production deployment.

## Testing Environments

### 1. Development Testing (Mock Data)
Use mock Google API responses to test the integration logic without real credentials.

### 2. Staging Testing (Test Account)
Use a test Google Workspace account to validate the full integration flow.

### 3. Production Testing (Real Account)
Test with actual customer Google Workspace account in controlled manner.

---

## Development Testing with Mock Data

### Sample ChromeOS Device Response

```json
{
  "chromeosdevices": [
    {
      "deviceId": "chrome-device-123",
      "serialNumber": "5CD1234ABC",
      "model": "HP Chromebook 14",
      "status": "ACTIVE",
      "osVersion": "110.0.5481.100",
      "platformVersion": "14543.59.0",
      "firmwareVersion": "Google_Nami.10775.403.0",
      "lastSync": "2025-11-29T10:30:00.000Z",
      "firstEnrollmentTime": "2024-01-15T09:00:00.000Z",
      "annotatedAssetId": "CB-001",
      "annotatedUser": "john.doe@example.com",
      "annotatedLocation": "Office - 3rd Floor",
      "notes": "Assigned to Marketing team",
      "macAddress": "00:1A:2B:3C:4D:5E",
      "ethernetMacAddress": "00:1A:2B:3C:4D:5F",
      "systemRamTotal": 8589934592,
      "autoUpdateExpiration": "2028-06-30T00:00:00.000Z",
      "recentUsers": [
        {
          "email": "john.doe@example.com",
          "type": "USER_TYPE_MANAGED"
        }
      ],
      "diskVolumeReports": [
        {
          "volumeInfo": {
            "volumeId": "vol-001",
            "storageTotalBytes": 68719476736,
            "storageFreeBytes": 34359738368
          }
        }
      ],
      "cpuStatusReports": [
        {
          "cpuTemperatureInfo": [
            {"label": "Core 0", "temperature": 45},
            {"label": "Core 1", "temperature": 47}
          ]
        }
      ]
    }
  ],
  "nextPageToken": null
}
```

### Sample Mobile Device Response (iOS)

```json
{
  "mobiledevices": [
    {
      "resourceId": "mobile-res-456",
      "deviceId": "ABCDEF123456",
      "serialNumber": "DNPW1234ABCD",
      "status": "ACTIVE",
      "model": "iPhone 15 Pro",
      "manufacturer": "Apple",
      "brand": "Apple",
      "os": "iOS",
      "type": "IOS",
      "osVersion": "17.1.1",
      "lastSync": "2025-11-29T09:15:00.000Z",
      "firstSync": "2024-03-10T08:00:00.000Z",
      "email": ["jane.smith@example.com"],
      "imei": "123456789012345",
      "wifiMacAddress": "A1:B2:C3:D4:E5:F6",
      "networkOperator": "Verizon",
      "hardware": "iPhone15,2",
      "buildNumber": "21B74",
      "securityPatchLevel": "2024-11-01",
      "encryptionStatus": "ENCRYPTED",
      "deviceCompromisedStatus": "NO_COMPROMISE"
    }
  ]
}
```

### Sample Mobile Device Response (Android)

```json
{
  "mobiledevices": [
    {
      "resourceId": "mobile-res-789",
      "deviceId": "android-xyz-789",
      "serialNumber": "RF8N1234567",
      "status": "ACTIVE",
      "model": "Pixel 8 Pro",
      "manufacturer": "Google",
      "brand": "Google",
      "os": "Android",
      "type": "ANDROID",
      "osVersion": "14",
      "lastSync": "2025-11-29T08:45:00.000Z",
      "firstSync": "2024-05-20T10:00:00.000Z",
      "email": ["bob.johnson@example.com"],
      "imei": "987654321098765",
      "meid": "A10000123456789",
      "wifiMacAddress": "B2:C3:D4:E5:F6:A7",
      "networkOperator": "T-Mobile",
      "hardware": "felix",
      "kernelVersion": "5.15.0",
      "basebandVersion": "g5300s-55.1",
      "buildNumber": "UPB2.231016.011",
      "securityPatchLevel": "2024-11-05",
      "encryptionStatus": "ENCRYPTED",
      "deviceCompromisedStatus": "NO_COMPROMISE"
    }
  ]
}
```

### Sample License Response

```json
{
  "items": [
    {
      "userId": "john.doe@example.com",
      "productId": "101005",
      "skuId": "1010050001",
      "skuName": "Google Workspace Business Standard"
    },
    {
      "userId": "jane.smith@example.com",
      "productId": "101009",
      "skuId": "1010090001",
      "skuName": "Google Workspace Business Plus"
    }
  ],
  "nextPageToken": null
}
```

---

## Unit Testing

### Test File Structure

Create test file: `backend/test/assetronics/integrations/adapters/google_workspace_test.exs`

```elixir
defmodule Assetronics.Integrations.Adapters.GoogleWorkspaceTest do
  use Assetronics.DataCase

  alias Assetronics.Integrations.Adapters.GoogleWorkspace
  alias Assetronics.Integrations.Integration

  setup do
    tenant = insert(:tenant)

    integration = insert(:integration, %{
      tenant_id: tenant.id,
      adapter: "google_workspace",
      provider: "google",
      enabled: true,
      access_token: "mock_token_for_testing"
    })

    {:ok, tenant: tenant, integration: integration}
  end

  describe "test_connection/1" do
    test "returns success with valid credentials", %{integration: integration} do
      # Mock the HTTP request
      # Assert connection test passes
    end

    test "returns error with invalid credentials" do
      # Test authentication failure
    end
  end

  describe "sync/2" do
    test "syncs ChromeOS devices successfully", %{tenant: tenant, integration: integration} do
      # Mock Google API response with sample ChromeOS data
      # Call sync
      # Verify assets created in database
      # Check asset attributes match expected values
    end

    test "syncs mobile devices successfully", %{tenant: tenant, integration: integration} do
      # Mock Google API response with sample mobile data
      # Call sync
      # Verify assets created
    end

    test "syncs licenses successfully", %{tenant: tenant, integration: integration} do
      # Mock license API response
      # Call sync
      # Verify employee records updated with license info
    end

    test "handles pagination correctly", %{tenant: tenant, integration: integration} do
      # Mock paginated response
      # Verify all pages processed
    end

    test "handles API errors gracefully", %{tenant: tenant, integration: integration} do
      # Mock error response
      # Verify error handling
    end
  end

  describe "device processing" do
    test "maps ChromeOS device to employee by email", %{tenant: tenant} do
      employee = insert(:employee, %{
        tenant_id: tenant.id,
        email: "john.doe@example.com"
      })

      device = %{
        "deviceId" => "chrome-123",
        "serialNumber" => "ABC123",
        "annotatedUser" => "john.doe@example.com",
        "model" => "HP Chromebook",
        "status" => "ACTIVE"
      }

      # Process device
      # Verify asset assigned to employee
    end

    test "categorizes mobile devices correctly", %{tenant: tenant} do
      # Test iPhone -> phone
      # Test iPad -> tablet
      # Test Android phone -> phone
    end
  end
end
```

---

## Integration Testing

### Prerequisites
1. Google Workspace test account (domain with admin access)
2. Service account created with proper scopes
3. Test devices enrolled in Google Workspace
4. Assetronics development environment running

### Step 1: Setup Test Integration

```bash
# Create test integration
curl -X POST http://localhost:4000/api/v1/integrations \
  -H "Authorization: Bearer YOUR_DEV_TOKEN" \
  -H "Content-Type: application/json" \
  -d @test_integration.json
```

`test_integration.json`:
```json
{
  "integration": {
    "name": "Google Workspace Test",
    "adapter": "google_workspace",
    "provider": "google",
    "integration_type": "mdm",
    "enabled": true,
    "auth_config": {
      "service_account_json": "PASTE_SERVICE_ACCOUNT_JSON_HERE",
      "customer_id": "my_customer"
    },
    "sync_frequency": "manual"
  }
}
```

### Step 2: Test Connection

```bash
# Test authentication
curl -X POST http://localhost:4000/api/v1/integrations/{integration_id}/test \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

**Expected Result:**
```json
{
  "status": "ok",
  "message": "Connection successful",
  "integration_id": "uuid-here",
  "provider": "google"
}
```

**Failure Scenarios to Test:**
1. Invalid service account JSON → Should return 401 error
2. Missing scopes → Should return 403 error
3. Disabled API → Should return specific error message

### Step 3: Trigger Manual Sync

```bash
# Start sync job
curl -X POST http://localhost:4000/api/v1/integrations/{integration_id}/sync \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

**Monitor Logs:**
```bash
tail -f backend/logs/assetronics.log | grep "Google Workspace"
```

**Expected Log Output:**
```
[info] Starting sync for integration [id] (google_workspace)
[info] Google Workspace: Synced 10 ChromeOS devices
[info] Google Workspace: Synced 5 mobile devices
[info] Sync completed successfully: %{chromeos_synced: 10, mobile_synced: 5, licenses_synced: 15}
```

### Step 4: Verify Results

#### Check Sync History
```bash
curl -X GET http://localhost:4000/api/v1/integrations/{integration_id}/history \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

#### Check Created Assets
```bash
# List all assets
curl -X GET "http://localhost:4000/api/v1/assets?limit=50" \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

**Verification Checklist:**
- [ ] ChromeOS devices created with correct serial numbers
- [ ] Mobile devices created with correct models
- [ ] Asset tags follow pattern (GW-CB-* or GW-M-*)
- [ ] Devices mapped to employees by email (if employee exists)
- [ ] Custom fields populated (google_device_id, etc.)
- [ ] Status set correctly (assigned/in_stock)
- [ ] Last checkin timestamp populated
- [ ] Hardware specs populated (RAM, storage)

#### Check Employee License Data
```bash
# Get employee details
curl -X GET "http://localhost:4000/api/v1/employees/{employee_id}" \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

**Verify:**
- [ ] custom_fields.google_licenses array populated
- [ ] License SKU IDs correct
- [ ] License names human-readable

### Step 5: Test Deduplication

1. Run sync twice
2. Verify no duplicate assets created
3. Check that existing assets are updated, not recreated

**SQL Query to Check:**
```sql
SELECT
  serial_number,
  COUNT(*) as count
FROM assets
WHERE tenant_id = 'your-tenant-id'
GROUP BY serial_number
HAVING COUNT(*) > 1;
```

Should return 0 rows.

### Step 6: Test Error Handling

#### Simulate Rate Limit
1. Run multiple syncs in quick succession
2. Verify graceful handling of 429 errors
3. Check retry logic

#### Simulate Network Failure
1. Disable network temporarily during sync
2. Verify error logged
3. Check sync marked as failed

#### Simulate Invalid Token
1. Invalidate service account credentials
2. Run sync
3. Verify appropriate error message

---

## Performance Testing

### Benchmark Sync Times

Create script: `backend/scripts/benchmark_google_sync.exs`

```elixir
# Benchmark different dataset sizes
tenant = "test-tenant"
integration = get_integration()

datasets = [
  {10, "Small (10 devices)"},
  {100, "Medium (100 devices)"},
  {500, "Large (500 devices)"},
  {2000, "Enterprise (2000 devices)"}
]

Enum.each(datasets, fn {count, label} ->
  IO.puts("\nTesting #{label}...")

  {time, result} = :timer.tc(fn ->
    GoogleWorkspace.sync(tenant, integration)
  end)

  IO.puts("Time: #{time / 1_000_000} seconds")
  IO.puts("Result: #{inspect(result)}")
end)
```

**Expected Performance:**
- 10 devices: < 5 seconds
- 100 devices: < 15 seconds
- 500 devices: < 45 seconds
- 2000 devices: < 3 minutes

### Memory Usage Monitoring

```bash
# Monitor Elixir VM memory during sync
:observer.start()
```

Watch for:
- Memory spikes during pagination
- Proper garbage collection
- No memory leaks

---

## Production Readiness Checklist

### Pre-Deployment
- [ ] All unit tests passing
- [ ] Integration tests passing with test account
- [ ] Performance benchmarks meet targets
- [ ] Error handling tested for common failure scenarios
- [ ] Logging configured and working
- [ ] Service account credentials securely stored

### Deployment
- [ ] Dependencies installed (Goth, Joken)
- [ ] Database migrations applied
- [ ] Oban workers configured
- [ ] Scheduled sync cron job enabled
- [ ] Monitoring alerts configured

### Post-Deployment
- [ ] Test connection with production service account
- [ ] Run initial sync manually
- [ ] Verify assets created correctly
- [ ] Monitor error rates for 24 hours
- [ ] Confirm scheduled syncs running

### Rollback Plan
If issues occur:
1. Disable integration via API: `POST /integrations/{id}/disable`
2. Stop Oban workers: Update config to disable cron
3. Investigate logs for root cause
4. Fix issue and re-deploy

---

## Troubleshooting Common Issues

### Issue: "Invalid service account JSON"
**Cause:** Malformed JSON or wrong file
**Fix:** Validate JSON syntax, ensure correct service account key downloaded

### Issue: "403 Forbidden" on API calls
**Cause:** Missing domain-wide delegation or wrong scopes
**Fix:**
1. Check domain-wide delegation in Google Admin
2. Verify all required scopes authorized
3. Wait 10 minutes for changes to propagate

### Issue: Devices not mapping to employees
**Cause:** Email mismatch between Google and employee records
**Fix:**
1. Check employee email format matches Google exactly
2. Verify `annotatedUser` field populated in Google Admin
3. Check employee exists in database before sync

### Issue: Sync timing out
**Cause:** Too many devices, network latency
**Fix:**
1. Increase timeout in config
2. Check pagination working correctly
3. Verify network connectivity to Google APIs

### Issue: Duplicate assets created
**Cause:** Deduplication logic not working
**Fix:**
1. Check serial numbers match exactly
2. Verify google_device_id stored in custom_fields
3. Review Assets.sync_from_mdm implementation

---

## Next Steps

After testing is complete:
1. Document any issues found and resolutions
2. Update integration based on feedback
3. Create customer-facing setup documentation
4. Train support team on troubleshooting
5. Monitor production usage and iterate

## Support Resources

- **API Documentation:** `docs/google_workspace_api_research.md`
- **Setup Guide:** `docs/google_workspace_setup_guide.md`
- **Implementation Summary:** `docs/google_workspace_integration_summary.md`
- **Google Workspace Admin SDK:** https://developers.google.com/admin-sdk
- **Goth Library:** https://hexdocs.pm/goth