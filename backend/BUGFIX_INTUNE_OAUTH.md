# Bugfix: Microsoft Intune Integration Save Failure

**Date**: 2025-11-30
**Status**: Fixed ✅

---

## Problem

Microsoft Intune integration was failing to save with error:
```
Error: Failed to save
at saveIntegration (IntegrationConfigModal.vue:227:29)
```

---

## Root Cause

**Auth Type Mismatch and Validation Timing Issue**:

1. **Frontend was sending wrong auth_type**:
   - Sent: `auth_type: 'bearer'`
   - Should be: `auth_type: 'oauth2'` (Intune uses Microsoft OAuth 2.0)

2. **Backend validation was too strict**:
   - For `auth_type: 'oauth2'` → Required `access_token` to be present
   - But OAuth integrations are created with `status: 'inactive'`
   - `access_token` is obtained AFTER creation during OAuth flow
   - Validation was rejecting creation because no token existed yet

---

## Files Changed

### 1. Frontend: `IntegrationConfigModal.vue`

**File**: `frontend/src/components/settings/IntegrationConfigModal.vue`

**Line 291**: Changed auth_type for Intune from 'bearer' to 'oauth2'

```diff
const getAuthType = (p: string) => {
-  if (p === 'intune') return 'bearer' // Simplified for MVP
+  if (p === 'intune') return 'oauth2' // Microsoft OAuth 2.0
   if (p === 'okta') return 'api_key' // SSWS
   if (p === 'jamf') return 'basic' // Username/Pass -> Token
   if (p === 'dell') return 'oauth2' // Client Credentials
   return 'api_key'
}
```

**Reason**: Intune uses Microsoft OAuth 2.0, same as Dell. Should use 'oauth2' not 'bearer'.

---

### 2. Backend: `Integration.ex` Schema

**File**: `backend/lib/assetronics/integrations/integration.ex`

#### Change 1: Conditional Credential Validation (Lines 174-202)

Updated `validate_credentials/1` to allow OAuth integrations without access_token at creation:

```elixir
defp validate_credentials(changeset) do
  auth_type = get_field(changeset, :auth_type)
  status = get_field(changeset, :status)

  case auth_type do
    "api_key" ->
      validate_required(changeset, [:api_key])
    "oauth2" ->
      # OAuth integrations don't have access_token at creation (status: inactive)
      # Tokens are added after OAuth flow completes
      if status == "active" do
        validate_required(changeset, [:access_token])
      else
        changeset
      end
    "basic" ->
      validate_required(changeset, [:api_key, :api_secret])
    "bearer" ->
      # Bearer tokens also obtained via OAuth flow for some providers
      if status == "active" do
        validate_required(changeset, [:access_token])
      else
        changeset
      end

    _ ->
      changeset
  end
end
```

**Reason**: OAuth flow is two-step:
1. Create integration with `status: 'inactive'` (no token yet)
2. Complete OAuth flow → obtain token → update to `status: 'active'`

Validation now only requires `access_token` when status is 'active'.

#### Change 2: OAuth Config Validation (Lines 204-222)

Added new `validate_oauth_config/1` function:

```elixir
defp validate_oauth_config(changeset) do
  auth_type = get_field(changeset, :auth_type)

  if auth_type == "oauth2" do
    auth_config = get_field(changeset, :auth_config)

    case auth_config do
      %{"client_id" => client_id, "client_secret" => client_secret}
      when is_binary(client_id) and is_binary(client_secret) and
           byte_size(client_id) > 0 and byte_size(client_secret) > 0 ->
        changeset

      _ ->
        add_error(changeset, :auth_config, "must contain client_id and client_secret for OAuth2")
    end
  else
    changeset
  end
end
```

**Reason**: Ensures OAuth2 integrations have required `client_id` and `client_secret` in encrypted `auth_config` field.

#### Change 3: Changeset Pipeline (Line 132)

Added validation to changeset pipeline:

```diff
def changeset(integration, attrs) do
  integration
  |> cast(attrs, [...])
  |> validate_required([...])
  |> validate_inclusion([...])
  |> validate_credentials()
+  |> validate_oauth_config()
end
```

---

## How OAuth Integration Flow Works Now

### Step 1: Create Integration (Frontend)
```javascript
const payload = {
  integration: {
    name: 'Microsoft Intune',
    provider: 'intune',
    integration_type: 'mdm',
    auth_type: 'oauth2',  // ✅ Correct now
    auth_config: {
      client_id: 'your-azure-app-id',
      client_secret: 'your-client-secret'
    },
    status: 'inactive'  // No access_token yet
  }
}

POST /api/v1/integrations
```

### Step 2: Backend Validation
```elixir
# Validation passes because:
# 1. auth_type = 'oauth2' ✅
# 2. status = 'inactive' → access_token NOT required ✅
# 3. auth_config has client_id and client_secret ✅

{:ok, integration} = Integrations.create_integration(tenant, payload)
# integration.id = "uuid-123"
# integration.status = "inactive"
```

### Step 3: Initiate OAuth Flow (Frontend)
```javascript
// Generate signed state token
const state = await generateStateToken(integration.id)

// Redirect to Microsoft OAuth
window.location.href = `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?
  client_id=${client_id}&
  response_type=code&
  redirect_uri=http://localhost:4000/api/v1/oauth/callback&
  scope=DeviceManagementManagedDevices.Read.All User.Read.All offline_access&
  state=${state}`
```

### Step 4: OAuth Callback (Backend)
```elixir
# User approves in Microsoft → redirected to callback
GET /api/v1/oauth/callback?code=auth_code&state=signed_token

# Exchange code for token
{:ok, token_data} = exchange_code("intune", code, integration)

# Update integration with tokens
{:ok, updated} = Integrations.update_tokens(
  tenant,
  integration,
  token_data.access_token,
  token_data.refresh_token,
  token_data.expires_in
)

# Activate integration
Integrations.update_integration(tenant, updated, %{status: "active"})

# Redirect to frontend
redirect(external: "http://localhost:5173/integrations?success=true&provider=intune")
```

### Step 5: Integration Active ✅
```elixir
integration.status = "active"
integration.access_token = "encrypted_token"
integration.refresh_token = "encrypted_refresh"
# Now passes "active" validation with access_token present
```

---

## Testing

### Manual Test Steps

1. **Open Integrations Settings**:
   ```
   http://localhost:5173/settings/integrations
   ```

2. **Click "Configure" on Microsoft Intune**

3. **Enter OAuth Credentials**:
   - OAuth Client ID: `your-azure-app-id`
   - OAuth Client Secret: `your-client-secret`
   - Enable automatic sync: ✓

4. **Click "Save & Connect"**

5. **Expected Behavior**:
   - ✅ Integration created with `status: 'inactive'`
   - ✅ No validation errors
   - ✅ Redirects to Microsoft OAuth consent screen
   - ✅ After approval, redirected back to app
   - ✅ Integration status changes to `active`
   - ✅ Tokens stored encrypted in database

### Before Fix ❌

```
POST /api/v1/integrations
{
  "integration": {
    "auth_type": "bearer",  // Wrong!
    "status": "inactive",
    "access_token": null
  }
}

Response: 422 Unprocessable Entity
{
  "errors": {
    "access_token": ["can't be blank"]  // Validation failed
  }
}

Frontend: "Error: Failed to save"
```

### After Fix ✅

```
POST /api/v1/integrations
{
  "integration": {
    "auth_type": "oauth2",  // Correct!
    "status": "inactive",
    "auth_config": {
      "client_id": "...",
      "client_secret": "..."
    }
  }
}

Response: 201 Created
{
  "data": {
    "id": "uuid-123",
    "name": "Microsoft Intune",
    "status": "inactive",
    ...
  }
}

Frontend: Redirects to OAuth flow
```

---

## Related Files

**OAuth Controller**: `backend/lib/assetronics_web/controllers/oauth_controller.ex`
- `callback/2` - Handles OAuth callback (line 10)
- `exchange_code/3` - Exchanges authorization code for token (line 118)

**OAuth Callback Route**: `GET /api/v1/oauth/callback`

**Microsoft OAuth Endpoints**:
- Authorize: `https://login.microsoftonline.com/common/oauth2/v2.0/authorize`
- Token: `https://login.microsoftonline.com/common/oauth2/v2.0/token`

---

## Impact

### Before Fix
- ❌ Microsoft Intune integration completely broken
- ❌ Could not create integration at all
- ❌ Users stuck at configuration modal

### After Fix
- ✅ Microsoft Intune OAuth flow works end-to-end
- ✅ Integration created successfully
- ✅ Validation correctly handles OAuth lifecycle
- ✅ Consistent with Dell OAuth implementation

---

## Future Improvements

1. **Better Error Messages**:
   - Show specific validation errors in frontend alert
   - Parse backend error response and display field-specific messages

2. **OAuth State Management**:
   - Store integration creation state in frontend during OAuth redirect
   - Show loading spinner while OAuth completes

3. **Testing**:
   - Add unit tests for `validate_credentials/1` with different statuses
   - Add integration test for full OAuth flow
   - Mock Microsoft OAuth endpoints for testing

---

**Fixed By**: Integration selection and OAuth validation improvements
**Verified**: Manual testing with Microsoft Intune configuration
**Status**: ✅ Ready for deployment
