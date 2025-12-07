# Procurement Integrations - Precoro & Procurify

## Overview

This document describes the implementation of Precoro and Procurify procurement integrations for automatic asset tracking from purchase orders.

## Precoro Integration

### About Precoro

Precoro is a cloud-based procurement management platform that helps organizations manage purchase requests, orders, and vendor relationships.

### Authentication

**Type:** API Key (Header-based)

**Configuration:**
- API Key is obtained from Precoro: Configuration → Integrations → API Key
- The key is only shown once during generation and must be stored securely
- Header name: `X-AUTH-TOKEN`

**Environment Support:**
- Default: `https://api.precoro.com` (Global)
- US Region: `https://api.precoro.us`

### API Rate Limits

Precoro enforces strict rate limiting:
- **Standard:** 60 requests/minute, 1,500/hour, 3,000/day
- **Duplicate requests:** 1/minute, 30/hour
- **Power BI connector:** 300/minute, 1,500/hour, 3,000/day

Exceeding limits returns HTTP 429; subsequent requests fail until the window resets.

### Features

**Purchase Order Sync:**
- Automatically fetches approved purchase orders from the last 30 days
- Creates assets for hardware items identified by keywords
- Supports both serialized and non-serialized items
- **Real-time webhook support** for instant purchase order updates

**Data Mapping:**
- Purchase Order → Asset fields:
  - PO Number → `po_number`
  - Vendor Name → `vendor`
  - Item Name → `name`, `description`
  - SKU/Code → `model`
  - Price → `purchase_cost`
  - Approval Date → `purchase_date`
  - Serial Numbers → `serial_number` (if provided)

**Status Mapping:**
- Items with serial numbers → `in_transit`
- Items without serial numbers → `on_order`

**Hardware Detection:**
Keywords: laptop, desktop, monitor, computer, server, tablet, phone, macbook, thinkpad, dell, hp, lenovo

### API Endpoints Used

**List Purchase Orders:**
```
GET /purchaseorders
```

**Query Parameters:**
- `createDate[left_date]` - Start date (DD.MM.YYYY format)
- `createDate[right_date]` - End date (DD.MM.YYYY format)
- `status[]` - Status filter (2 = Approved)
- `per_page` - Items per page (default: 100, max: 100)
- `page` - Page number

**Response Structure:**
```json
[
  {
    "id": 123,
    "number": "PO-2024-001",
    "vendor": {
      "name": "Tech Supplier Inc"
    },
    "createDate": "15.01.2024",
    "approvalDate": "16.01.2024",
    "items": [
      {
        "name": "MacBook Pro 16\"",
        "description": "MacBook Pro with M3 chip",
        "sku": "MBP-M3-16",
        "quantity": 2,
        "price": 2499.00,
        "serialNumbers": ["C02ABC123XYZ", "C02DEF456ABC"]
      }
    ]
  }
]
```

### Implementation

**File:** `lib/assetronics/integrations/adapters/precoro.ex`

**Key Functions:**
- `test_connection/1` - Validates API key by fetching one PO
- `sync/2` - Fetches recent POs and creates assets
- `fetch_purchase_orders/2` - GET request with pagination support
- `process_purchase_order/2` - Extracts items and creates assets
- `is_hardware_item?/1` - Filters hardware from other items

**Asset Creation Logic:**
1. Fetch approved POs from last 30 days
2. Extract line items from each PO
3. Filter hardware items by keywords
4. For items with serial numbers: create one asset per serial (status: `in_transit`)
5. For items without serials: create based on quantity (status: `on_order`)
6. Use serial number for deduplication if available

### Configuration Example

```elixir
%{
  provider: "precoro",
  integration_type: "procurement",
  auth_type: "api_key",
  api_key: "your-precoro-api-key",
  base_url: "https://api.precoro.com",  # or https://api.precoro.us
  environment: "global",  # or "us"
  sync_enabled: true,
  sync_frequency: "daily"
}
```

### Webhook Setup (Real-time Sync)

**Benefits:**
- Instant asset creation when POs are created/approved
- Eliminates polling delays
- Reduces API calls and avoids rate limits
- More efficient than scheduled syncs

**Configuration Steps:**

1. **Get your webhook URL:**
   - Format: `https://your-domain.com/api/v1/webhooks/precoro?tenant=YOUR_TENANT_ID`
   - Replace `your-domain.com` with your Assetronics instance URL
   - Replace `YOUR_TENANT_ID` with your tenant identifier

2. **Configure in Precoro:**
   - Log in to Precoro
   - Navigate to **Configuration → Integrations → Webhooks**
   - Click **"New Webhook"**
   - Enter your webhook URL
   - Select events to track:
     - **Purchase Order Created** (Type 2, Action 0)
     - **Purchase Order Updated** (Type 2, Action 1)
   - Click **Save**

3. **Verify webhook:**
   - Create a test purchase order in Precoro
   - Check Assetronics logs for webhook processing confirmation
   - Verify assets are created automatically

**Webhook Payload Format:**

Precoro sends minimal webhook data:
```json
{
  "id": 123456,
  "type": 2,
  "action": 0,
  "idn": 5
}
```

Where:
- `id`: Purchase order ID
- `type`: Entity type (2 = Purchase Order)
- `action`: Event action (0 = Create, 1 = Update)
- `idn`: Additional identifier

Assetronics automatically fetches full purchase order details using the Precoro API after receiving the webhook.

**Important Notes:**
- The user creating webhooks must have **maximum access roles** for unrestricted data
- Webhooks are processed asynchronously to avoid blocking
- If webhook processing fails, scheduled sync will still catch missed items
- Webhooks and scheduled syncs can run simultaneously

**Supported Events:**
- Purchase Order Created → Creates new assets from PO items
- Purchase Order Updated → Updates existing assets or creates new ones

**Security:**
- Webhooks require valid tenant ID in URL
- Integration must exist and be active for the tenant
- Failed authentications are logged

---

## Procurify Integration

### About Procurify

Procurify is a spend management platform that provides purchase order management, approval workflows, and procurement analytics.

### Authentication

**Type:** OAuth 2.0 (Client Credentials)

**Configuration:**
- Client ID and Client Secret obtained from Procurify API settings
- Credentials are only shown once during creation
- OAuth token endpoint: `/api/v3/oauth/token`

**Base URL:** `https://app.procurify.com/api/v3`

### Features

**Order Items Sync:**
- Fetches order items from the last 30 days
- Creates assets for hardware items
- Supports multiple status states (Pending, In Use, Receiving, etc.)

**Data Mapping:**
- Order Item → Asset fields:
  - Order Number → `po_number`
  - Item Name → `name`, `description`
  - SKU → `model`
  - Vendor → `vendor`
  - Approved Price → `purchase_cost`
  - Approved Date → `purchase_date`
  - Department ID → `custom_fields.department_id`
  - Location ID → `custom_fields.location_id`

**Status Mapping:**
- Status 0 (Pending) → `on_order`
- Status 1 (In Use) → `assigned`
- Status 2 (Receive Pending) → `in_transit`
- Status 3 (Fully Received) → `in_stock`
- Status 5 (Partially Received) → `in_transit`

**Hardware Detection:**
Keywords: laptop, desktop, monitor, computer, server, tablet, phone, macbook, thinkpad, dell, hp, lenovo, ipad

### API Endpoints Used

**List Order Items:**
```
GET /api/v3/order-items/
```

**Query Parameters:**
- `page_size` - Items per page (default: 100)
- `page` - Page number
- `order_created_date_0` - Start date (ISO 8601)
- `order_created_date_1` - End date (ISO 8601)
- `status` - Comma-separated status codes (e.g., "1,2,3,5")
- `department` - Filter by department ID
- `location` - Filter by location ID

**Response Structure:**
```json
{
  "metadata": {
    "pagination": {
      "count": 50,
      "page_size": 100,
      "num_pages": 1,
      "current_page": 1
    }
  },
  "data": [
    {
      "id": 12345,
      "name": "Dell Latitude 7430",
      "sku": "LAT-7430-I7",
      "num": "REQ-2024-001",
      "quantity": "3",
      "price": "1299.00",
      "status": 2,
      "approved_datetime": "2024-01-15T14:30:00Z",
      "approved_price": "1299.00",
      "approved_quantity": "3",
      "orderNum": 567,
      "purchase_order": 890,
      "vendor": "Dell Technologies",
      "department": 10,
      "location": 5,
      "lineComment": "For engineering team",
      "created_at": "2024-01-10T10:00:00Z",
      "last_modified": "2024-01-15T14:30:00Z"
    }
  ]
}
```

### Implementation

**File:** `lib/assetronics/integrations/adapters/procurify.ex`

**Key Functions:**
- `test_connection/1` - Validates OAuth credentials
- `sync/2` - Fetches recent order items and creates assets
- `get_access_token/3` - OAuth Client Credentials flow
- `fetch_order_items/2` - GET request with pagination
- `process_order_item/2` - Creates assets from order items
- `map_status/1` - Maps Procurify status codes to asset statuses

**Asset Creation Logic:**
1. Authenticate via OAuth 2.0
2. Fetch approved order items from last 30 days
3. Filter hardware items by keywords in name/SKU
4. Create individual assets based on approved quantity
5. Generate unique asset tags: `PROCURIFY-{orderNum}-{sku}-{index}`
6. Preserve department and location in custom fields

### Configuration Example

```elixir
%{
  provider: "procurify",
  integration_type: "procurement",
  auth_type: "oauth2",
  auth_config: %{
    "client_id" => "your-client-id",
    "client_secret" => "your-client-secret"
  },
  base_url: "https://app.procurify.com/api/v3",
  sync_enabled: true,
  sync_frequency: "daily"
}
```

---

## Comparison: Precoro vs Procurify

| Feature | Precoro | Procurify |
|---------|---------|-----------|
| **Authentication** | API Key (Header) | OAuth 2.0 |
| **Data Model** | Purchase Orders → Items | Order Items (direct) |
| **Serial Numbers** | Supported | Not typically available |
| **Webhooks** | ✅ Real-time PO events | ❌ Not available |
| **Rate Limits** | 60/min, 1,500/hr | Not explicitly documented |
| **Status Granularity** | 2 states (approved/not) | 9 states (lifecycle) |
| **Department/Location** | In PO metadata | In each order item |
| **Date Format** | DD.MM.YYYY | ISO 8601 |
| **Best For** | Organizations with serial tracking & real-time needs | Organizations needing detailed status |

---

## Frontend Integration

### Integration Cards

Both integrations appear in the Procurement section of the Integrations page:

**Precoro Card:**
```vue
<IntegrationCard
  name="Precoro"
  description="Sync purchase orders and automate procurement workflows."
  provider="precoro"
  type="procurement"
  icon="truck"
  :status="getIntegrationStatus('precoro')"
  :last-sync="getIntegration('precoro')?.last_sync_at"
  @configure="openConfig('precoro')"
/>
```

**Procurify Card:**
```vue
<IntegrationCard
  name="Procurify"
  description="Import purchase orders and track procurement data."
  provider="procurify"
  type="procurement"
  icon="truck"
  :status="getIntegrationStatus('procurify')"
  :last-sync="getIntegration('procurify')?.last_sync_at"
  @configure="openConfig('procurify')"
/>
```

### Configuration Modal

**Precoro:**
- **Auth Type:** API Key
- **Fields:** API Key, Base URL (optional)
- **Environment:** Dropdown for Global/US regions

**Procurify:**
- **Auth Type:** OAuth 2.0
- **Fields:** Client ID, Client Secret, Base URL (optional)
- **OAuth Flow:** Automatic token retrieval on save

---

## Testing

### Manual Testing Steps

**Precoro:**
1. Obtain API key from Precoro dashboard
2. Create integration via UI with API key
3. Test connection (should fetch 1 PO)
4. Run manual sync
5. Verify assets created with status `on_order` or `in_transit`
6. Check custom fields include `precoro_sku` and `source`

**Procurify:**
1. Obtain Client ID and Secret from Procurify
2. Create integration via UI with OAuth credentials
3. Test connection (should authenticate and fetch 1 item)
4. Run manual sync
5. Verify assets created with appropriate status mapping
6. Check custom fields include department and location IDs

### Expected Logs

**Precoro:**
```
[info] Precoro sync started for tenant: acme
[info] Fetched 15 purchase orders from Precoro
[info] Processing PO: PO-2024-001
[info] Created asset: PRECORO-C02ABC123XYZ (in_transit)
[info] Precoro sync completed: 15 POs, 23 assets created
```

**Procurify:**
```
[info] Procurify sync started for tenant: acme
[info] Authenticated with Procurify OAuth
[info] Fetched 42 order items from Procurify
[info] Processing order item: Dell Latitude 7430
[info] Created asset: PROCURIFY-567-LAT-7430-I7-1 (in_transit)
[info] Procurify sync completed: 42 items, 38 assets created
```

---

## Troubleshooting

### Precoro Issues

**429 Rate Limit Exceeded:**
- Reduce sync frequency
- Implement exponential backoff
- Contact Precoro to increase limits

**401 Unauthorized:**
- Verify API key is correct
- Regenerate key if needed (old key becomes invalid)
- Check key is not expired

**No Items Returned:**
- Adjust date range (default is 30 days)
- Verify POs are in "Approved" status (status = 2)
- Check base URL matches your region (global vs US)

### Procurify Issues

**OAuth Authentication Failed:**
- Verify Client ID and Secret are correct
- Regenerate credentials if needed
- Check base URL is correct

**Empty Response:**
- Verify date range includes recent orders
- Check status filter includes desired states
- Confirm API access permissions

**Access Suspended:**
- Contact Procurify support immediately
- Reduce request volume
- Implement caching

---

## Future Enhancements

### Precoro
1. ✅ ~~Webhook support for real-time updates~~ (Implemented)
2. Invoice matching and reconciliation
3. Custom field mapping configuration
4. Vendor catalog sync
5. Receipt confirmation workflow
6. Webhook signature verification for enhanced security

### Procurify
6. Purchase requisition tracking
7. Budget and spending analytics
8. Approval workflow integration
9. Catalog item synchronization
10. Advanced filtering by account/department

---

## Related Files

### Backend
- `/backend/lib/assetronics/integrations/adapters/precoro.ex` - Precoro adapter
- `/backend/lib/assetronics/integrations/adapters/precoro/webhook.ex` - Precoro webhook handler
- `/backend/lib/assetronics/integrations/adapters/procurify.ex` - Procurify adapter
- `/backend/lib/assetronics/integrations/adapter.ex` - Adapter registry
- `/backend/lib/assetronics/integrations/integration.ex` - Schema and validations
- `/backend/lib/assetronics_web/controllers/webhook_controller.ex` - Webhook endpoint controller
- `/backend/lib/assetronics_web/router.ex` - API routes including webhooks

### Frontend
- `/frontend/src/views/settings/IntegrationsView.vue` - Integration cards
- `/frontend/src/components/settings/IntegrationConfigModal.vue` - Configuration UI

---

## API Documentation References

- **Precoro:** https://help.precoro.com/using-api-in-precoro
- **Procurify:** https://developer.procurify.com/
