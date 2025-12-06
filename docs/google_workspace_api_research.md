# Google Workspace Admin SDK API Research

## Overview
The Google Workspace Admin SDK provides APIs to manage devices, users, and licenses in Google Workspace domains.

## Authentication
Google Workspace APIs require OAuth 2.0 authentication using Service Accounts for server-to-server applications.

### Service Account Setup Requirements:
1. Create a service account in Google Cloud Console
2. Enable Admin SDK API
3. Download JSON key file
4. Enable Domain-Wide Delegation in Google Workspace Admin Console
5. Grant necessary scopes to the service account

### Required Scopes:
- `https://www.googleapis.com/auth/admin.directory.device.chromeos` - ChromeOS devices
- `https://www.googleapis.com/auth/admin.directory.device.mobile` - Mobile devices
- `https://www.googleapis.com/auth/admin.directory.user.readonly` - User information
- `https://www.googleapis.com/auth/apps.licensing` - License management

## Device Management APIs

### 1. ChromeOS Devices
**Endpoint:** `GET https://admin.googleapis.com/admin/directory/v1/customer/{customerId}/devices/chromeos`

**Response Fields:**
- `deviceId` - Unique device identifier
- `serialNumber` - Hardware serial number
- `status` - Device status (ACTIVE, DISABLED, DEPROVISIONED)
- `lastSync` - Last time device synced
- `annotatedAssetId` - Admin-assigned asset ID
- `annotatedUser` - Admin-assigned user
- `annotatedLocation` - Physical location
- `notes` - Admin notes
- `model` - Device model
- `osVersion` - Chrome OS version
- `platformVersion` - Platform version
- `firmwareVersion` - Firmware version
- `macAddress` - MAC address
- `meid` - Mobile equipment identifier
- `ethernetMacAddress` - Ethernet MAC address
- `recentUsers` - List of recent users with email
- `activeTimeRanges` - Device usage time ranges
- `cpuStatusReports` - CPU temperature and usage
- `systemRamTotal` - Total RAM in bytes
- `diskVolumeReports` - Storage information

### 2. Mobile Devices
**Endpoint:** `GET https://admin.googleapis.com/admin/directory/v1/customer/{customerId}/devices/mobile`

**Response Fields:**
- `resourceId` - Device ID
- `deviceId` - Unique identifier
- `serialNumber` - Serial number (if available)
- `status` - Device status
- `model` - Device model
- `os` - Operating system
- `type` - Device type (Android, iOS)
- `userAgent` - User agent string
- `manufacturer` - Device manufacturer
- `releaseVersion` - OS version
- `brand` - Device brand
- `hardware` - Hardware info
- `lastSync` - Last sync time
- `firstSync` - First sync time
- `imei` - IMEI number
- `meid` - MEID number
- `wifiMacAddress` - WiFi MAC address
- `networkOperator` - Carrier
- `defaultLanguage` - Default language
- `managedAccountIsOnOwnerProfile` - Management status
- `email` - Associated user email

## License Management APIs

### 1. License Assignment API
**Endpoint:** `GET https://www.googleapis.com/apps/licensing/v1/product/{productId}/users`

**Supported Product IDs:**
- `Google-Apps` - Google Workspace licenses
- `Google-Drive-storage` - Google Drive storage
- `Google-Vault` - Google Vault
- `101001` - Google Workspace Business Starter
- `101005` - Google Workspace Business Standard
- `101009` - Google Workspace Business Plus
- `1010020` - Google Workspace Enterprise Standard
- `1010060` - Google Workspace Enterprise Plus

**Response Fields:**
- `userId` - User's email
- `productId` - Product SKU ID
- `skuId` - Specific SKU
- `skuName` - Human-readable SKU name

### 2. Get License Assignment
**Endpoint:** `GET https://www.googleapis.com/apps/licensing/v1/product/{productId}/sku/{skuId}/user/{userId}`

### 3. List All Licenses for User
**Endpoint:** `GET https://www.googleapis.com/apps/licensing/v1/product/{productId}/users?customerId={customerId}`

## User Directory API (for Employee Mapping)

**Endpoint:** `GET https://admin.googleapis.com/admin/directory/v1/users`

**Key Fields:**
- `primaryEmail` - User's primary email
- `name.fullName` - Full name
- `suspended` - Account status
- `lastLoginTime` - Last login
- `creationTime` - Account creation
- `orgUnitPath` - Organizational unit
- `isAdmin` - Admin status
- `isDelegatedAdmin` - Delegated admin
- `agreedToTerms` - Terms acceptance
- `customerId` - Customer ID
- `emails` - All email aliases
- `relations` - Manager relationships
- `organizations` - Department/title info

## Implementation Recommendations

### 1. Authentication Flow
```elixir
# Use Goth library for Service Account JWT generation
{:ok, %{token: access_token}} = Goth.fetch(MyApp.Goth)
```

### 2. Pagination Handling
All list endpoints support pagination:
- `maxResults` - Max items per page (default 100, max 500)
- `pageToken` - Token for next page
- Response includes `nextPageToken` for continuation

### 3. Rate Limiting
- 2,400 queries per minute per user
- 50 queries per second per user
- Implement exponential backoff for 403/429 errors

### 4. Error Handling
Common errors:
- `401` - Invalid authentication
- `403` - Insufficient permissions
- `404` - Resource not found
- `429` - Rate limit exceeded
- `500` - Server error

### 5. Data Sync Strategy
1. Initial full sync on integration setup
2. Incremental syncs using `lastSync` timestamps
3. Store Google IDs for deduplication
4. Map users by email to Employee records
5. Handle device status changes (active/disabled/deprovisioned)

## Next Steps
1. Set up Goth library for JWT authentication
2. Implement paginated fetching for all endpoints
3. Add proper error handling and retries
4. Create sync scheduling mechanism
5. Build comprehensive test suite with mock data