# Google Workspace Integration Setup Guide

## Overview
This guide walks through setting up the Google Workspace integration for Assetronics, enabling automatic sync of ChromeOS devices, mobile devices, and license management.

## Prerequisites
1. Google Workspace admin account access
2. Google Cloud Console access
3. Ability to enable Domain-Wide Delegation

## Step 1: Create Service Account in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **Service Account**
5. Fill in service account details:
   - Name: `Assetronics Integration`
   - ID: `assetronics-integration`
   - Description: `Service account for Assetronics asset management`
6. Click **Create and Continue**
7. Grant the following roles (optional, for Cloud Console access):
   - `Service Account Token Creator`
8. Click **Done**

## Step 2: Download Service Account Key

1. Click on the service account you just created
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Select **JSON** format
5. Click **Create** and save the JSON file securely

## Step 3: Enable Required APIs

In Google Cloud Console, enable these APIs:

1. Go to **APIs & Services** → **Library**
2. Search and enable each API:
   - Admin SDK API
   - Google Workspace Admin SDK
   - Enterprise License Manager API

## Step 4: Configure Domain-Wide Delegation

1. Copy the service account's **Client ID** (found in service account details)
2. Go to [Google Admin Console](https://admin.google.com/)
3. Navigate to **Security** → **API Controls** → **Domain-wide delegation**
4. Click **Add new**
5. Enter:
   - Client ID: `[Your service account client ID]`
   - OAuth Scopes (add all of these):
     ```
     https://www.googleapis.com/auth/admin.directory.device.chromeos
     https://www.googleapis.com/auth/admin.directory.device.mobile
     https://www.googleapis.com/auth/admin.directory.user.readonly
     https://www.googleapis.com/auth/apps.licensing
     ```
6. Click **Authorize**

## Step 5: Configure in Assetronics

### Via API
```bash
curl -X POST http://your-domain/api/integrations \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "integration": {
      "name": "Google Workspace",
      "adapter": "google_workspace",
      "enabled": true,
      "auth_config": {
        "service_account_json": "[PASTE_SERVICE_ACCOUNT_JSON_HERE]",
        "customer_id": "my_customer"
      },
      "sync_frequency": "daily",
      "sync_time": "02:00"
    }
  }'
```

### Via Environment Variables (Alternative)
If you prefer not to store the service account in the database:

```env
GOOGLE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
GOOGLE_CUSTOMER_ID=my_customer
```

## Step 6: Test Connection

```bash
curl -X POST http://your-domain/api/integrations/{id}/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected response:
```json
{
  "success": true,
  "message": "Connection successful"
}
```

## Step 7: Run Initial Sync

```bash
curl -X POST http://your-domain/api/integrations/{id}/sync \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected response:
```json
{
  "chromeos_synced": 45,
  "mobile_synced": 123,
  "licenses_synced": 200
}
```

## Sync Details

### ChromeOS Devices
The integration syncs the following ChromeOS device information:
- Device ID and serial number
- Model and manufacturer
- OS version and firmware
- Hardware specs (CPU, RAM, storage)
- Last sync time
- Assigned user (via annotation or recent users)
- Location annotation
- Auto-update expiration date
- Network information (MAC addresses)

### Mobile Devices
The integration syncs the following mobile device information:
- Device ID and IMEI/MEID
- Model, brand, and manufacturer
- OS type and version
- Security patch level
- Encryption status
- Compromised status
- Network operator
- WiFi MAC address
- Last sync time

### License Management
The integration syncs Google Workspace licenses:
- Business Starter (101001)
- Business Standard (101005)
- Business Plus (101009)
- Enterprise Standard (1010020)
- Enterprise Plus (1010060)
- Legacy Google Apps licenses

Licenses are mapped to employees by email address and stored in custom fields.

## Scheduling Automatic Syncs

The integration supports automatic scheduling via Oban background jobs:

```elixir
# In config/config.exs
config :assetronics, Oban,
  queues: [integrations: 10],
  plugins: [
    {Oban.Plugins.Cron,
      crontab: [
        {"0 2 * * *", Assetronics.Integrations.SyncWorker, args: %{adapter: "google_workspace"}}
      ]}
  ]
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized Error**
   - Verify service account JSON is correct
   - Check domain-wide delegation is configured
   - Ensure all required scopes are authorized

2. **403 Forbidden Error**
   - Admin SDK API not enabled
   - Service account doesn't have domain-wide delegation
   - Incorrect customer ID

3. **No Devices Found**
   - Verify devices exist in Google Admin Console
   - Check if devices are in correct organizational unit
   - Ensure devices have synced recently with Google

4. **License Sync Fails**
   - Enterprise License Manager API not enabled
   - Organization doesn't have the specified license SKUs
   - Scope `https://www.googleapis.com/auth/apps.licensing` not authorized

### Debug Logging

Enable debug logging in development:

```elixir
# config/dev.exs
config :logger, level: :debug
```

View integration logs:
```bash
tail -f logs/assetronics.log | grep "Google Workspace"
```

## API Rate Limits

Google Workspace APIs have the following limits:
- 2,400 queries per minute per user
- 50 queries per second per user

The integration implements:
- Automatic pagination with 500 items per page
- Parallel processing for different resource types
- Exponential backoff on rate limit errors

## Security Best Practices

1. **Store Service Account Securely**
   - Encrypt at rest in database
   - Use environment variables in production
   - Rotate keys periodically

2. **Limit Scope Access**
   - Only grant required scopes
   - Use read-only scopes where possible
   - Review delegated access regularly

3. **Monitor Integration Activity**
   - Set up alerts for sync failures
   - Monitor API usage in Google Cloud Console
   - Review audit logs regularly

## Support

For issues or questions:
1. Check integration logs in Assetronics
2. Review Google Workspace audit logs
3. Verify API quotas in Google Cloud Console
4. Contact support with integration ID and error details