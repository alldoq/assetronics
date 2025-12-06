# Integration Selection System - Implementation Summary

**Date**: 2025-11-30
**Status**: Backend Complete ✅ | Frontend Pending ⬜

---

## Overview

Implemented a robust integration selection system to determine which integration to use when multiple integrations of the same type exist (e.g., both BambooHR and Workday for HRIS).

---

## Changes Made

### 1. Database Migration

**File**: `backend/priv/repo/tenant_migrations/20251130000000_add_is_primary_to_integrations.exs`

Added `is_primary` boolean column to integrations table with database constraints:
- Default value: `false`
- Unique partial index: Only one primary integration per type per tenant
- Regular index on `is_primary` for query performance

```sql
ALTER TABLE integrations ADD COLUMN is_primary BOOLEAN DEFAULT FALSE;

CREATE UNIQUE INDEX idx_integrations_primary_per_type
ON integrations(integration_type)
WHERE is_primary = true;
```

**Migration Status**: ✅ Applied to tenant schemas

---

### 2. Schema Updates

**File**: `backend/lib/assetronics/integrations/integration.ex`

- Added `is_primary` field to Integration schema (line 43)
- Updated changeset to cast `is_primary` field (line 96)
- Maintains backward compatibility with existing integrations

---

### 3. Integration Selection Logic

**File**: `backend/lib/assetronics/integrations.ex`

Implemented 5 new functions:

#### `get_integration_for_type/2` (Primary Function)
- Main function to retrieve the correct integration for a type
- Implements hybrid selection strategy:
  1. **Primary integration** (`is_primary = true`)
  2. **Single active** integration (if no primary)
  3. **Most recently updated** (if multiple active)
  4. **Error** if no active integrations

**Usage Example**:
```elixir
case Integrations.get_integration_for_type("acme", "hris") do
  {:ok, integration} ->
    # Use this integration for HRIS operations
  {:error, :no_active_integration} ->
    # Handle no integration configured
end
```

#### `get_primary_integration/2`
- Queries for primary integration of a specific type
- Filters by: `integration_type`, `is_primary = true`, `status = "active"`
- Returns `nil` if no primary set

#### `list_active_by_type/2`
- Lists all active integrations of a type
- Ordered by `updated_at DESC` (most recent first)
- Used as fallback when no primary exists

#### `set_as_primary/2`
- Sets an integration as primary
- Automatically unsets existing primary (transactional)
- Ensures data consistency across tenant schema

**Usage Example**:
```elixir
{:ok, updated} = Integrations.set_as_primary("acme", integration)
# updated.is_primary == true
# All other integrations of same type now have is_primary == false
```

#### `unset_primary/2`
- Removes primary flag from integration
- Simple update operation

#### `select_most_recent/1` (Private)
- Helper function to choose most recently updated integration
- Uses `Enum.max_by/3` with `DateTime` comparator

---

## Selection Logic Flow

```
User Request (e.g., "Create onboarding workflow")
        ↓
get_integration_for_type("acme", "hris")
        ↓
   Check for PRIMARY?
        ↓
   ┌─── YES ──→ Return primary integration
   │
   └─── NO ──→ Check active integrations
                    ↓
              ┌─── NONE ──→ {:error, :no_active_integration}
              │
              ├─── ONE ──→ Return that integration
              │
              └─── MULTIPLE ──→ Return most recently updated
```

---

## Use Cases

### Use Case 1: Single Integration (Most Common)
**Scenario**: Tenant has only BambooHR configured
**Behavior**: Automatically selected (no primary flag needed)

### Use Case 2: Multiple Integrations with Primary
**Scenario**: Tenant has BambooHR (primary) + Workday (backup)
**Behavior**: Always uses BambooHR for automatic workflows

### Use Case 3: Migration Between Systems
**Scenario**: Migrating from BambooHR to Workday
**Process**:
1. Keep BambooHR as primary during migration
2. Add Workday as secondary
3. Test Workday sync manually
4. Switch primary to Workday: `set_as_primary("acme", workday_integration)`
5. All future workflows now use Workday

### Use Case 4: Multi-Region Setup (Future)
**Scenario**: Workday for US/EMEA, BambooHR for APAC
**Behavior**: Primary integration used by default, metadata can route by region

---

## Testing

### Manual Testing

```elixir
# In IEx console
alias Assetronics.{Repo, Integrations}
alias Assetronics.Integrations.Integration

# Create test integrations
{:ok, bamboo} = Integrations.create_integration("acme", %{
  name: "BambooHR",
  integration_type: "hris",
  provider: "bamboohr",
  status: "active",
  auth_type: "api_key",
  api_key: "test-key"
})

{:ok, workday} = Integrations.create_integration("acme", %{
  name: "Workday",
  integration_type: "hris",
  provider: "workday",
  status: "active",
  auth_type: "oauth2",
  access_token: "test-token"
})

# Test selection (should return most recent)
{:ok, selected} = Integrations.get_integration_for_type("acme", "hris")
IO.inspect(selected.provider)  # "workday" (most recent)

# Set BambooHR as primary
{:ok, _} = Integrations.set_as_primary("acme", bamboo)

# Test selection again (should now return primary)
{:ok, selected} = Integrations.get_integration_for_type("acme", "hris")
IO.inspect(selected.provider)  # "bamboohr" (primary)
IO.inspect(selected.is_primary)  # true

# Verify Workday no longer primary
workday = Repo.get(Integration, workday.id, prefix: Triplex.to_prefix("acme"))
IO.inspect(workday.is_primary)  # false
```

---

## API Integration Points

The selection system is used by:

1. **Workflow Triggers** (`lib/assetronics/workflows.ex`):
   ```elixir
   def create_new_employee_workflow(tenant, employee, opts) do
     with {:ok, hris} <- Integrations.get_integration_for_type(tenant, "hris") do
       # Create workflow using primary HRIS integration
     end
   end
   ```

2. **Webhook Handlers** (`lib/assetronics_web/controllers/webhook_controller.ex`):
   ```elixir
   def hris_webhook(conn, params) do
     tenant = conn.assigns.tenant
     {:ok, integration} = Integrations.get_integration_for_type(tenant, "hris")
     # Process webhook data using primary integration
   end
   ```

3. **Sync Workers** (`lib/assetronics/workers/sync_integration_worker.ex`):
   ```elixir
   def perform(%{tenant: tenant, integration_type: type}) do
     {:ok, integration} = Integrations.get_integration_for_type(tenant, type)
     # Sync data from primary integration
   end
   ```

---

## Future Enhancements (Frontend)

### Pending Implementation:

1. **UI Indicators**:
   - Show "PRIMARY" badge on integration cards
   - Visual distinction for primary vs secondary integrations

2. **Management Actions**:
   - "Set as Primary" button with confirmation dialog
   - "Remove Primary" option
   - Warning when switching primary integration

3. **API Endpoints** (to be added to router):
   ```elixir
   scope "/api/v1/integrations", AssetronicsWeb do
     post "/:id/set-primary", IntegrationController, :set_primary
     post "/:id/unset-primary", IntegrationController, :unset_primary
   end
   ```

4. **Automatic Primary Assignment**:
   - When first integration of a type is created, auto-set as primary
   - Modify `create_integration/2` to check if others exist

---

## Documentation

- **Detailed Guide**: `docs/INTEGRATION_SELECTION.md`
- **Implementation Status**: Updated with completion details
- **Architecture Diagrams**: Included in integration selection doc

---

## Verification Checklist

- [x] Migration created and applied
- [x] Schema updated with `is_primary` field
- [x] Changeset updated to cast `is_primary`
- [x] `get_integration_for_type/2` implemented
- [x] `get_primary_integration/2` implemented
- [x] `list_active_by_type/2` implemented
- [x] `set_as_primary/2` implemented (with transaction)
- [x] `unset_primary/2` implemented
- [x] Database constraints in place (unique index)
- [x] Documentation updated
- [ ] Frontend UI components (pending)
- [ ] API endpoints for primary management (pending)
- [ ] Automatic primary assignment (pending)
- [ ] Unit tests (recommended)

---

## Database Schema

```elixir
# integrations table (per tenant schema)
field :is_primary, :boolean, default: false

# Index ensures only one primary per type
CREATE UNIQUE INDEX idx_integrations_primary_per_type
ON integrations(integration_type)
WHERE is_primary = true;
```

---

## Impact

### Solves Critical Problem:
**Before**: System had no way to choose between multiple integrations of same type
**After**: Clear, deterministic selection logic with user control

### Benefits:
1. **User Control**: Tenants can explicitly set which integration to use
2. **Automatic Fallback**: Works even if no primary is set
3. **Data Consistency**: Transaction ensures only one primary at a time
4. **Migration Support**: Allows gradual transition between systems
5. **Multi-Integration**: Supports backup integrations and multi-region setups

### No Breaking Changes:
- Existing integrations continue to work
- Default value `is_primary = false` maintains current behavior
- Selection falls back to most recent if no primary

---

**Implementation**: Backend Complete ✅
**Next Step**: Frontend UI for primary management
**Documentation**: `docs/INTEGRATION_SELECTION.md`
