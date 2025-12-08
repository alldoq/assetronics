# Testing Okta Integration Locally

This guide covers how to test the Okta integration on your local development environment, including webhook/event hook testing using tunneling tools.

## Prerequisites

1. **Okta Developer Account**
   - Sign up for free at https://developer.okta.com/signup/
   - You'll get a free developer org (e.g., `dev-12345.okta.com`)

2. **Local Development Environment**
   - Backend server running on `localhost:4000` (Phoenix)
   - Frontend running on `localhost:5173` (Vue.js)

3. **Tunneling Tool** (for webhooks)
   - Choose one: ngrok, Cloudflare Tunnel, or localtunnel
   - Needed to expose your local server to the internet

---

## Part 1: Setting Up Okta Developer Account

### Step 1: Create Okta Developer Org

1. Go to https://developer.okta.com/signup/
2. Create a free developer account
3. Note your Okta domain (e.g., `dev-12345.okta.com`)

### Step 2: Generate API Token

1. Log in to your Okta Admin Console
2. Navigate to **Security → API → Tokens**
3. Click **"Create Token"**
4. Name it "Assetronics Local Testing"
5. Copy the token immediately (it's only shown once)
6. Save it securely

### Step 3: Add Test Users

1. Navigate to **Directory → People**
2. Click **"Add Person"**
3. Add a few test users with different statuses:
   ```
   User 1: John Doe (Active)
   - Email: john.doe@example.com
   - First: John
   - Last: Doe
   - Status: Active

   User 2: Jane Smith (Active)
   - Email: jane.smith@example.com
   - First: Jane
   - Last: Smith
   - Status: Active
   ```

---

## Part 2: Testing API Sync (Without Webhooks)

### Step 1: Start Local Backend

```bash
cd backend
mix phx.server
```

Your server should be running on `http://localhost:4000`

### Step 2: Create Integration via API or UI

**Option A: Via Frontend UI**

1. Start frontend: `cd frontend && npm run dev`
2. Navigate to `http://localhost:5173/settings/integrations`
3. Find Okta card and click "Configure"
4. Enter:
   - **Base URL**: `https://dev-12345.okta.com` (your Okta domain)
   - **API Token**: Your API token from Step 2 above
5. Click "Test Connection"
6. Click "Save"

**Option B: Via API (curl)**

```bash
# Login and get auth token first
curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-admin@example.com",
    "password": "your-password",
    "tenant": "your-tenant-id"
  }'

# Create Okta integration
curl -X POST http://localhost:4000/api/v1/integrations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "X-Tenant-ID: your-tenant-id" \
  -d '{
    "integration": {
      "name": "Okta Dev",
      "provider": "okta",
      "integration_type": "identity",
      "api_key": "YOUR_OKTA_API_TOKEN",
      "base_url": "https://dev-12345.okta.com",
      "sync_enabled": true
    }
  }'
```

### Step 3: Test Connection

```bash
curl -X POST http://localhost:4000/api/v1/integrations/INTEGRATION_ID/test \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "X-Tenant-ID: your-tenant-id"
```

Expected response:
```json
{
  "success": true,
  "message": "Connection successful"
}
```

### Step 4: Run Manual Sync

```bash
curl -X POST http://localhost:4000/api/v1/integrations/INTEGRATION_ID/sync \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "X-Tenant-ID: your-tenant-id"
```

Expected response:
```json
{
  "users_synced": 2,
  "employees_created": 2,
  "employees_updated": 0,
  "workflows_created": 2
}
```

### Step 5: Verify in Database

```bash
# Open IEx console
iex -S mix

# Check employees were created
Assetronics.Employees.list_employees("your-tenant-id")
```

You should see John Doe and Jane Smith as employees.

---

## Part 3: Testing Webhooks with Tunneling

### Option A: Using ngrok (Recommended)

#### 1. Install ngrok

```bash
# macOS
brew install ngrok

# Or download from https://ngrok.com/download
```

#### 2. Start ngrok Tunnel

```bash
# Make sure your Phoenix server is running on port 4000
ngrok http 4000
```

You'll see output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:4000
```

Copy the `https://abc123.ngrok.io` URL.

#### 3. Configure Okta Event Hook

1. In Okta Admin Console, go to **Workflow → Event Hooks**
2. Click **"Create Event Hook"**
3. Configure:
   - **Name**: Assetronics Local Webhook
   - **URL**: `https://abc123.ngrok.io/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID`

4. **Subscribe to Events** (IMPORTANT - you need to search for these):
   - In the "Subscribe to events" section, you'll see a dropdown with event types
   - **Don't use the dropdown** - it shows a limited set by default
   - Instead, use the **search/filter box** at the top of the event list
   - Search for and select each of these events:
     - **user.lifecycle.create** - "Create user"
     - **user.lifecycle.activate** - "Activate user"
     - **user.lifecycle.deactivate** - "Deactivate user"
     - **user.lifecycle.suspend** - "Suspend user"
     - **user.lifecycle.unsuspend** - "Unsuspend user"

   **How to find events:**
   - Type "user.lifecycle" in the search box
   - All user lifecycle events will appear
   - Click the checkbox next to each event you want to subscribe to
   - You can also filter by typing "lifecycle" or "user"

5. Click **Save & Continue**

#### 4. Verify Event Hook

When you save the event hook, Okta will **immediately** send a one-time verification challenge:
- Okta sends a **GET request** to your webhook URL
- The request includes the `X-Okta-Verification-Challenge` header
- Your endpoint automatically responds with `{"verification": "challenge-value"}`

**Check your terminal logs:**
```
[info] Received Okta verification challenge
```

**In Okta:**
- You should see **"Verified"** status next to your event hook
- If verification fails, check:
  - ngrok tunnel is running
  - Backend server is running on port 4000
  - URL format is correct: `https://abc123.ngrok.io/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID`

**Note:** The verification uses a GET request, but actual event webhooks use POST.

#### 5. Test Webhook by Creating a User

1. In Okta Admin Console, go to **Directory → People**
2. Click **"Add Person"**
3. Create a new user:
   ```
   First Name: Test
   Last Name: Webhook
   Email: test.webhook@example.com
   ```
4. Click **Save**

#### 6. Monitor Webhook Processing

Watch your Phoenix logs:
```
[info] Received Okta event hook for tenant: your-tenant-id
[info] Handling user created event for ID: 00u123abc
[info] Okta event hook processed successfully: %{action: :created, user_id: "00u123abc"}
```

#### 7. Verify in Database

```bash
iex -S mix

# Check the new employee was created
Assetronics.Employees.list_employees("your-tenant-id")
|> Enum.find(&(&1.email == "test.webhook@example.com"))
```

### Option B: Using Cloudflare Tunnel

#### 1. Install cloudflared

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Or download from https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/
```

#### 2. Start Tunnel

```bash
cloudflared tunnel --url http://localhost:4000
```

You'll see output like:
```
Your quick Tunnel has been created! Visit it at:
https://abc-def-ghi.trycloudflare.com
```

#### 3. Configure Okta Event Hook

Use the Cloudflare URL: `https://abc-def-ghi.trycloudflare.com/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID`

Follow steps 3-7 from Option A above.

### Option C: Using localtunnel

#### 1. Install localtunnel

```bash
npm install -g localtunnel
```

#### 2. Start Tunnel

```bash
lt --port 4000 --subdomain assetronics-dev
```

You'll get: `https://assetronics-dev.loca.lt`

#### 3. Configure Okta Event Hook

Use: `https://assetronics-dev.loca.lt/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID`

---

## Part 4: Testing Webhook Signature Verification (Optional)

For production-grade testing, you can add webhook signature verification.

### 1. Generate Shared Secret

In Okta Event Hook settings, copy the **"Shared Secret"** value.

### 2. Update Integration Config

```bash
curl -X PATCH http://localhost:4000/api/v1/integrations/INTEGRATION_ID \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "X-Tenant-ID: your-tenant-id" \
  -H "Content-Type: application/json" \
  -d '{
    "integration": {
      "auth_config": {
        "event_hook_secret": "YOUR_SHARED_SECRET"
      }
    }
  }'
```

### 3. Test with Invalid Signature

Create a test webhook with invalid signature:

```bash
curl -X POST https://abc123.ngrok.io/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID \
  -H "Content-Type: application/json" \
  -H "X-Okta-Event-Hook-Signature: invalid_signature" \
  -d '{
    "data": {
      "events": [
        {
          "eventType": "user.lifecycle.create",
          "target": [{"id": "00u123"}]
        }
      ]
    }
  }'
```

Expected response: `401 Unauthorized`

---

## Part 5: Common Testing Scenarios

### Scenario 1: New User Created

**Action**: Create new user in Okta
**Expected**:
- Webhook received
- New employee created in Assetronics
- Onboarding workflow created (if configured)

### Scenario 2: User Activated

**Action**: Activate suspended user in Okta
**Expected**:
- Webhook received
- Employee status updated to "active"
- Employee record synced

### Scenario 3: User Deactivated

**Action**: Deactivate user in Okta
**Expected**:
- Webhook received
- Employee status updated to "terminated" or "inactive"
- Offboarding workflow triggered (if configured)

### Scenario 4: Batch User Updates

**Action**: Import multiple users via CSV in Okta
**Expected**:
- Multiple webhooks received
- All users processed
- Batch sync statistics logged

---

## Part 6: Debugging Tips

### View Webhook Logs

```bash
# In Phoenix console
tail -f log/dev.log | grep Okta
```

### Check Okta Event Hook Delivery

1. In Okta Admin Console, go to **Workflow → Event Hooks**
2. Click on your event hook
3. View **"Recent Deliveries"** tab
4. See request/response details for each webhook

### Enable Verbose Logging

In `config/dev.exs`:
```elixir
config :logger, level: :debug
```

### Test Webhook Locally Without Okta

```bash
# Send manual webhook to your local server
curl -X POST http://localhost:4000/api/v1/webhooks/okta?tenant=YOUR_TENANT_ID \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "events": [
        {
          "uuid": "test-event-123",
          "eventType": "user.lifecycle.create",
          "target": [
            {
              "id": "00u123abc",
              "type": "User",
              "alternateId": "test@example.com"
            }
          ]
        }
      ]
    }
  }'
```

This will trigger the webhook handler without waiting for Okta to send real events.

---

## Part 7: Cleanup After Testing

### Stop Tunnel

- **ngrok**: Press `Ctrl+C`
- **Cloudflare**: Press `Ctrl+C`
- **localtunnel**: Press `Ctrl+C`

### Delete Test Event Hook in Okta

1. Go to **Workflow → Event Hooks**
2. Click on your test event hook
3. Click **"Delete"**

### Keep Test Users for Future Testing

You can keep the test users in Okta for ongoing development.

---

## Troubleshooting

### Issue: Cannot Find User Lifecycle Events in Okta

**Symptoms**:
- Event dropdown shows only IAM policy, admin assignment events
- Can't find `user.lifecycle.create`, `user.lifecycle.activate`, etc.

**Solution**:
1. Look for a **search box or filter field** above the event list
2. Type `user.lifecycle` in the search box
3. All user lifecycle events will appear
4. If still not visible, try:
   - Type just `lifecycle`
   - Type just `user`
   - Check if you're on the "Subscribe to events" step (not "Preview")
5. Verify your Okta org has user management enabled

**Alternative**: Subscribe to ALL events initially for testing, then narrow down later

### Issue: Webhook Not Received

**Possible Causes**:
- Tunnel not running
- Wrong URL in Okta
- Firewall blocking
- Tenant ID missing or incorrect

**Solution**: Check ngrok/tunnel logs, verify URL format

### Issue: 401 Unauthorized

**Possible Causes**:
- Invalid signature verification
- Webhook secret mismatch

**Solution**: Remove `event_hook_secret` from integration config for testing

### Issue: 404 Integration Not Found

**Possible Causes**:
- Wrong tenant ID
- Integration not created
- Integration disabled

**Solution**: Verify integration exists for the tenant

### Issue: Users Not Syncing

**Possible Causes**:
- Okta API token expired
- Wrong base URL
- Network connectivity

**Solution**: Test connection endpoint first, check logs

---

## Summary Checklist

- [ ] Created Okta developer account
- [ ] Generated API token
- [ ] Added test users in Okta
- [ ] Started local Phoenix server
- [ ] Created Okta integration via UI/API
- [ ] Tested connection successfully
- [ ] Ran manual sync successfully
- [ ] Verified employees created
- [ ] Started tunnel (ngrok/cloudflare)
- [ ] Configured Okta event hook with tunnel URL
- [ ] Verified event hook in Okta
- [ ] Created test user and verified webhook received
- [ ] Checked logs for webhook processing
- [ ] Verified employee created via webhook

---

## Webhook Endpoints

The Okta integration uses **two endpoints**:

1. **GET /api/v1/webhooks/okta** - For one-time verification
   - Okta calls this when you first create the event hook
   - Returns the verification challenge
   - Action: `okta_verify/2`

2. **POST /api/v1/webhooks/okta** - For actual event webhooks
   - Okta calls this when events occur (user created, activated, etc.)
   - Processes user lifecycle events
   - Action: `okta/2`

Both use the same URL; Okta chooses GET or POST based on the operation.

## Related Files

- `/backend/lib/assetronics/integrations/adapters/okta.ex` - Main Okta adapter
- `/backend/lib/assetronics/integrations/adapters/okta/webhook.ex` - Webhook handler
- `/backend/lib/assetronics/integrations/adapters/okta/client.ex` - HTTP client
- `/backend/lib/assetronics/integrations/adapters/okta/api.ex` - API calls
- `/backend/lib/assetronics/integrations/adapters/okta/employee_sync.ex` - Employee sync logic
- `/backend/lib/assetronics_web/controllers/webhook_controller.ex` - Webhook endpoint (both GET and POST)
- `/backend/lib/assetronics_web/router.ex` - Routes configuration

---

## Additional Resources

- Okta Developer Docs: https://developer.okta.com/docs/reference/api/users/
- Okta Event Hooks: https://developer.okta.com/docs/concepts/event-hooks/
- ngrok Documentation: https://ngrok.com/docs
- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
