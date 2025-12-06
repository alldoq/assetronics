# OAuth Integration Setup Guide

This guide explains how to set up OAuth integrations in Assetronics for Microsoft Intune and Dell Premier.

## Overview

Assetronics is a **multi-tenant SaaS platform**. Each tenant must provide their own OAuth application credentials for security and compliance. OAuth credentials are stored encrypted per-tenant in the database using AES-256-GCM encryption.

## Architecture

### Per-Tenant OAuth Credentials

- **Storage**: OAuth `client_id` and `client_secret` are stored in the `integrations.auth_config` encrypted field
- **Encryption**: All credentials are encrypted using Cloak with AES-256-GCM
- **Isolation**: Each tenant's OAuth tokens are completely isolated using PostgreSQL schema-based multi-tenancy (Triplex)
- **Security**: CSRF protection using Phoenix.Token with 10-minute expiration

### OAuth Flow

```
1. User enters OAuth credentials (client_id, client_secret) in Assetronics UI
   ↓
2. Credentials stored encrypted in integrations.auth_config
   ↓
3. User clicks "Connect" → Backend generates OAuth authorization URL
   ↓
4. User redirected to Microsoft/Dell login page
   ↓
5. User authorizes Assetronics app
   ↓
6. Provider redirects back with authorization code
   ↓
7. Backend exchanges code for access_token + refresh_token
   ↓
8. Tokens stored encrypted, integration activated
   ↓
9. User redirected back to Assetronics UI
```

---

## Microsoft Intune Setup

### Prerequisites

- Azure AD Administrator access
- Microsoft 365 or Azure subscription with Intune licensing
- Assetronics account with integration management permissions

### Step 1: Register Azure AD Application

1. Navigate to **[Azure Portal > App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)**

2. Click **"New registration"**

3. Configure the application:
   - **Name**: `Assetronics MDM Integration` (or your preferred name)
   - **Supported account types**:
     - For single organization: "Accounts in this organizational directory only"
     - For multi-organization: "Accounts in any organizational directory"
   - **Redirect URI**:
     - Platform: **Web**
     - URL: `https://your-domain.com/api/v1/oauth/callback`
     - For local dev: `http://localhost:4000/api/v1/oauth/callback`

4. Click **"Register"**

### Step 2: Configure API Permissions

1. In your app registration, navigate to **"API permissions"**

2. Click **"Add a permission"** → **"Microsoft Graph"** → **"Delegated permissions"**

3. Add the following permissions:
   - `DeviceManagementManagedDevices.Read.All` - Read managed device information
   - `User.Read.All` - Read all users' full profiles
   - `offline_access` - Maintain access to data (for refresh tokens)

4. Click **"Add permissions"**

5. Click **"Grant admin consent for [Your Organization]"** (requires Admin)
   - This is **required** to avoid user consent prompts

### Step 3: Create Client Secret

1. Navigate to **"Certificates & secrets"** → **"Client secrets"**

2. Click **"New client secret"**

3. Configure:
   - **Description**: `Assetronics Integration Secret`
   - **Expires**: Choose appropriate duration (24 months recommended)

4. Click **"Add"**

5. **IMPORTANT**: Copy the secret **Value** immediately (it's only shown once)

### Step 4: Retrieve Application (Client) ID

1. Navigate to **"Overview"** tab

2. Copy the **"Application (client) ID"** (UUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### Step 5: Configure in Assetronics

1. Log into Assetronics

2. Navigate to **Settings → Integrations**

3. Click **"Connect"** on the **Microsoft Intune** card

4. Enter the credentials:
   - **OAuth Client ID**: Paste the Application (client) ID from Step 4
   - **OAuth Client Secret**: Paste the client secret value from Step 3

5. Click **"Save & Connect"**

6. You'll be redirected to Microsoft login:
   - Sign in with an admin account
   - Grant the requested permissions
   - You'll be redirected back to Assetronics

7. Verify the integration is **Active** in your integrations list

### Troubleshooting Microsoft Intune

| Error | Cause | Solution |
|-------|-------|----------|
| `AADSTS50011: The reply URL specified in the request does not match...` | Incorrect redirect URI | Ensure redirect URI in Azure AD matches exactly: `https://your-domain.com/api/v1/oauth/callback` |
| `AADSTS65001: The user or administrator has not consented` | Admin consent not granted | Click "Grant admin consent" in API permissions |
| `Insufficient privileges to complete the operation` | Missing Graph API permissions | Add `DeviceManagementManagedDevices.Read.All` permission |
| `invalid_client` | Wrong client_secret | Generate new client secret and update in Assetronics |

---

## Dell Premier Setup

### Prerequisites

- Dell Premier account with API access
- Dell account representative contact
- Assetronics account with integration management permissions

### Step 1: Contact Dell for OAuth Credentials

Dell Premier OAuth credentials must be requested from Dell directly:

1. **Contact**: Reach out to your Dell account representative

2. **Request**: OAuth 2.0 API credentials for Dell Premier

3. **Information to Provide**:
   - Company name and Dell customer ID
   - Use case: "MDM/ITAM integration for automated device procurement"
   - Redirect URI: `https://your-domain.com/api/v1/oauth/callback`
   - Required scopes: `purchasing` (for order management)

4. **Wait for Approval**: Dell will review and provision credentials (typically 3-5 business days)

### Step 2: Receive Credentials

Dell will provide:
- **Client ID**: Unique identifier for your application
- **Client Secret**: Confidential secret key
- **API Environment**: Production or Sandbox URL
- **Documentation**: Dell-specific API documentation

### Step 3: Configure in Assetronics

1. Log into Assetronics

2. Navigate to **Settings → Integrations**

3. Click **"Connect"** on the **Dell Premier** card

4. Enter the credentials:
   - **OAuth Client ID**: Paste the Client ID from Dell
   - **OAuth Client Secret**: Paste the Client Secret from Dell

5. Click **"Save & Connect"**

6. You'll be redirected to Dell's OAuth login:
   - Sign in with your Dell Premier account
   - Authorize Assetronics access
   - You'll be redirected back to Assetronics

7. Verify the integration is **Active**

### Troubleshooting Dell Premier

| Error | Cause | Solution |
|-------|-------|----------|
| `invalid_client` | Incorrect client_id or client_secret | Verify credentials with Dell, regenerate if needed |
| `unauthorized_client` | Redirect URI mismatch | Ensure Dell has configured the correct redirect URI |
| `access_denied` | User denied access | Re-initiate OAuth flow and authorize access |
| `invalid_grant` | Authorization code expired | OAuth codes expire in 10 minutes, restart flow |

---

## Security Best Practices

### Credential Management

1. **Never share OAuth credentials** between environments (dev/staging/prod)
2. **Rotate client secrets** every 6-12 months
3. **Use separate OAuth apps** for testing vs. production
4. **Audit integration access** regularly in Azure AD / Dell portal

### Access Control

1. **Principle of Least Privilege**: Only request necessary permissions
2. **Admin Consent**: Always grant admin consent for enterprise apps
3. **Monitor Usage**: Review OAuth app sign-in logs for anomalies

### Incident Response

If credentials are compromised:
1. **Immediately revoke** the client secret in Azure AD / Dell portal
2. **Generate new secret** and update in Assetronics
3. **Review audit logs** for unauthorized access
4. **Notify security team** per your incident response policy

---

## Technical Details

### Stored Data (Encrypted)

In `integrations` table, `auth_config` field stores:
```json
{
  "client_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "client_secret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

Additionally stored (also encrypted):
- `access_token`: Current OAuth access token
- `refresh_token`: Long-lived refresh token
- `token_expires_at`: Access token expiration timestamp

### Token Refresh

- **Automatic**: Tokens are automatically refreshed when expired
- **Trigger**: Before each API call to Intune/Dell, token expiration is checked
- **Mechanism**: Refresh token is used to obtain new access token
- **Storage**: New tokens replace old tokens in database

### Database Schema

```sql
-- integrations table (simplified)
CREATE TABLE integrations (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  provider VARCHAR(50) NOT NULL,          -- 'intune' or 'dell'
  auth_type VARCHAR(20) DEFAULT 'oauth2',
  auth_config_encrypted BYTEA,            -- Encrypted: {client_id, client_secret}
  access_token_encrypted BYTEA,           -- Encrypted access token
  refresh_token_encrypted BYTEA,          -- Encrypted refresh token
  token_expires_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'inactive',  -- Changes to 'active' after OAuth
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints

**Initiate OAuth Flow**:
```
GET /api/v1/integrations/auth/connect?provider={intune|dell}&integration_id={uuid}
→ Returns: { "url": "https://login.microsoftonline.com/..." }
```

**OAuth Callback** (handled automatically):
```
GET /api/v1/oauth/callback?code={authorization_code}&state={signed_token}
→ Exchanges code for tokens, stores encrypted, redirects to frontend
```

**Token Refresh** (automatic, internal):
```elixir
AssetronicsWeb.OAuthController.refresh_token(tenant, integration)
→ Returns: {:ok, updated_integration} | {:error, reason}
```

---

## Frequently Asked Questions

### Do I need separate OAuth apps for dev/staging/prod?

**Yes, strongly recommended.** Use different redirect URIs for each environment:
- Dev: `http://localhost:4000/api/v1/oauth/callback`
- Staging: `https://staging.your-domain.com/api/v1/oauth/callback`
- Prod: `https://your-domain.com/api/v1/oauth/callback`

### Can I use the same Microsoft app for multiple tenants?

**No.** Each Assetronics tenant should use their own Azure AD application for proper security isolation and compliance.

### How long do tokens last?

- **Microsoft Access Tokens**: 1 hour (automatically refreshed)
- **Microsoft Refresh Tokens**: 90 days of inactivity (rolling expiration)
- **Dell Access Tokens**: Varies (typically 1 hour, check Dell docs)
- **Dell Refresh Tokens**: Varies (check Dell docs)

### What happens if my refresh token expires?

Users will need to re-authorize the integration by clicking "Connect" again in the Assetronics UI. This will restart the OAuth flow.

### Can I revoke access?

**Yes**, from two places:
1. **Azure AD / Dell Portal**: Revoke the OAuth app's access
2. **Assetronics**: Delete or disable the integration

### Is my data secure?

**Yes**:
- All credentials encrypted at rest (AES-256-GCM)
- All credentials encrypted in transit (TLS 1.3)
- Multi-tenant database isolation (separate PostgreSQL schemas)
- CSRF protection on OAuth state
- No credentials logged or exposed in errors

---

## Support

For additional help:
- **Microsoft Intune**: [Microsoft Graph API Documentation](https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview)
- **Dell Premier**: Contact your Dell account representative
- **Assetronics**: Contact support@assetronics.com

---

## Changelog

- **2025-01-XX**: Initial OAuth implementation for Intune and Dell Premier
- Per-tenant credential storage with Cloak encryption
- Phoenix.Token-based CSRF protection
- Automatic token refresh mechanism
