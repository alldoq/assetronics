defmodule AssetronicsWeb.WebhookController do
  use AssetronicsWeb, :controller

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapters.BambooHR
  require Logger

  @doc """
  Receiver for BambooHR webhooks.

  Expected payload format (configured in BambooHR):
  {
    "employees": [
      {
        "id": "123",
        "firstName": "John",
        "lastName": "Doe",
        ...
      }
    ]
  }
  """
  def bamboohr(conn, %{"employees" => employees} = params) do
    # 1. Identify Tenant
    # Webhooks are public, so we need to identify the tenant.
    # We can use a query param `?tenant=acme` in the webhook URL configured in BambooHR.
    tenant = conn.query_params["tenant"]

    if is_nil(tenant) do
      Logger.error("BambooHR webhook received without tenant identifier")
      send_resp(conn, 400, "Missing tenant identifier")
    else
      # 2. Verify Security
      # Ideally verify signature, but for MVP we can check if an active BambooHR integration exists for this tenant
      case Integrations.get_integration_by_provider(tenant, "bamboohr") do
        nil ->
          Logger.error("BambooHR webhook received for tenant #{tenant} but no integration found")
          send_resp(conn, 404, "Integration not found")

        integration ->
          Logger.info("Received BambooHR webhook for tenant #{tenant} with #{length(employees)} updates")
          
          # 3. Process Updates
          # We reuse the existing adapter logic but need to wrap the payload to match what the adapter expects
          # The adapter expects a list of maps
          
          # We invoke the adapter's sync logic directly for these specific employees
          # This avoids a full sync
          
          # Note: BambooHR webhooks might send partial data depending on configuration.
          # Ideally, we should fetch the full profile to be safe, or ensure the webhook payload is complete.
          # For robustness, we will take the IDs and fetch full details via the report API.
          
          # Extract IDs
          employee_ids = Enum.map(employees, & &1["id"])
          
          # Trigger a targeted sync job or immediate sync
          # For immediate feedback, we'll do it inline (or spawn a task)
          
          Task.start(fn ->
            # We can't easily fetch *just* specific IDs with the custom report API efficiently 
            # (it usually fetches all or filters by changed since).
            # So we will trigger a full sync for now, OR we can try to rely on the payload if we trust it.
            # Given we just improved the report fetching logic, triggering a sync is safer 
            # but might be heavy if high volume.
            
            # Alternative: Just sync.
            Assetronics.Integrations.Adapter.dispatch_sync(tenant, integration)
          end)

          send_resp(conn, 200, "Webhook received")
      end
    end
  end

  def bamboohr(conn, _params) do
    Logger.warning("BambooHR webhook received with invalid payload")
    send_resp(conn, 400, "Invalid payload")
  end
end
