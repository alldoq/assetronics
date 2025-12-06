defmodule Assetronics.Integrations.Adapters.Dell do
  @moduledoc """
  Integration adapter for Dell Premier APIs.

  Supports:
  - Order History Sync -> Assets (status: on_order)
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    # Dell uses OAuth2 (Client Credentials)
    case get_access_token(integration) do
      {:ok, _token} ->
        {:ok, %{success: true, message: "Connection successful"}}
      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    with {:ok, token} <- get_access_token(integration),
         {:ok, orders} <- fetch_recent_orders(integration, token) do
      
      # Process each order line item
      results = 
        Enum.flat_map(orders, fn order -> 
          process_order(tenant, order)
        end)

      success_count = Enum.count(results, fn {status, _} -> status == :ok end)
      failed_count = Enum.count(results, fn {status, _} -> status == :error end)

      {:ok, %{
        orders_synced: length(orders),
        assets_created: success_count,
        assets_failed: failed_count
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private Helpers

  defp get_access_token(integration) do
    # Dell API Token Endpoint
    url = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
    
    # Needs Client ID and Secret
    client_id = integration.api_key
    client_secret = integration.api_secret

    body = URI.encode_query(%{
      "grant_type" => "client_credentials",
      "client_id" => client_id,
      "client_secret" => client_secret
    })

    case Req.post(url, body: body, headers: [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}
      {:ok, %{status: status}} ->
        {:error, "Failed to authenticate with Dell: #{status}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_recent_orders(integration, token) do
    # Purchase Order API / Order Status API
    # Usually filtered by date range. Fetching last 30 days for MVP.
    start_date = Date.utc_today() |> Date.add(-30) |> Date.to_iso8601()
    end_date = Date.utc_today() |> Date.to_iso8601()
    
    # Dell Order Status API endpoint (example)
    url = "#{integration.base_url}/PROD/v2/order-status?start_date=#{start_date}&end_date=#{end_date}"

    case Req.get(url, headers: [Authorization: "Bearer #{token}", Accept: "application/json"]) do
      {:ok, %{status: 200, body: orders}} ->
        # Dell returns a list of orders. We need to normalize.
        {:ok, orders}
      {:ok, %{status: status}} ->
        {:error, "Failed to fetch orders: #{status}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_order(tenant, order) do
    # Order structure varies by region, but generally contains:
    # orderNumber, purchaseOrderNumber, orderDate, orderDetail (lines)
    
    po_number = order["purchaseOrderNumber"]
    order_number = order["orderNumber"]
    purchase_date = parse_date(order["orderDate"])
    
    # Iterate over line items
    Enum.map(order["lineItems"] || [], fn line ->
      # We only care about hardware (Laptops, Desktops, Monitors)
      # Skip software, warranties if possible, or filter by SKU/Description
      if is_hardware?(line) do
        # Dell might provide Service Tags (Serials) in the response if shipped
        # If not shipped, we might not have serials yet.
        # If we have Service Tags, we create one asset per tag.
        # If not, we might create a "placeholder" asset or skip until shipped?
        # Strategy: Create placeholder "On Order" asset if quantity > 0
        
        service_tags = line["serviceTags"] || []
        quantity = line["quantity"] || 0
        
        if length(service_tags) > 0 do
          # Create asset for each service tag
          Enum.map(service_tags, fn tag -> 
            create_or_update_asset(tenant, line, tag, po_number, purchase_date)
          end)
        else
          # Pending items (no serial yet). 
          # Complex to track individual items without serials.
          # For MVP, maybe we only track SHIPPED items which have Service Tags.
          [{:ignore, "No service tags yet"}]
        end
      else
        [{:ignore, "Not hardware"}]
      end
    end) 
    |> List.flatten()
  end

  defp create_or_update_asset(tenant, line, service_tag, po_number, purchase_date) do
    attrs = %{
      asset_tag: "DELL-#{service_tag}", # Temporary until tagged
      serial_number: service_tag,
      name: line["productDescription"], # e.g. "XPS 15 9500"
      description: line["productDescription"],
      model: line["modelDescription"], # Dell often puts model here
      make: "Dell",
      category: categorize(line["productDescription"]),
      status: "on_order", # Or "in_transit" if shipped
      po_number: po_number,
      purchase_date: purchase_date,
      vendor: "Dell",
      purchase_cost: parse_cost(line["unitPrice"]), # Encrypted by schema
      custom_fields: %{
        "sku" => line["sku"],
        "order_status" => line["status"]
      }
    }

    # Upsert using MDM logic (Serial is key)
    Assets.sync_from_mdm(tenant, attrs)
  end

  defp is_hardware?(line) do
    desc = String.downcase(line["productDescription"] || "")
    cond do
      String.contains?(desc, "latitude") -> true
      String.contains?(desc, "precision") -> true
      String.contains?(desc, "xps") -> true
      String.contains?(desc, "optiplex") -> true
      String.contains?(desc, "monitor") -> true
      String.contains?(desc, "dock") -> true
      true -> false
    end
  end

  defp categorize(desc) do
    desc = String.downcase(desc || "")
    cond do
      String.contains?(desc, "monitor") -> "monitor"
      String.contains?(desc, "dock") -> "peripheral"
      String.contains?(desc, "server") -> "server"
      true -> "laptop" # Default for Dell Premier usually
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_cost(cost) when is_number(cost), do: Decimal.from_float(cost / 1.0)
  defp parse_cost(_), do: nil
end
