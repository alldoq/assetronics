defmodule Assetronics.Integrations.Adapters.Procurify do
  @moduledoc """
  Integration adapter for Procurify procurement platform.

  Supports:
  - Order Items sync -> Assets (status: on_order)
  - Purchase Order tracking
  - Vendor and item catalog data

  Authentication:
  - OAuth 2.0 (Client Credentials)
  - Requires Client ID and Client Secret

  API Documentation: https://developer.procurify.com/
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @default_base_url "https://app.procurify.com/api/v3"

  # Status codes from Procurify API
  @status_pending 0
  @status_in_use 1
  @status_receive_pending 2
  @status_fully_received 3
  @status_partially_received 5

  @impl true
  def test_connection(%Integration{} = integration) do
    with {:ok, client} <- build_client(integration),
         {:ok, _response} <- fetch_order_items(client, %{page_size: 1}) do
      {:ok, %{success: true, message: "Connection successful"}}
    else
      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    with {:ok, client} <- build_client(integration),
         {:ok, order_items} <- fetch_recent_order_items(client) do
      # Process each order item and create assets
      results =
        Enum.map(order_items, fn item ->
          process_order_item(tenant, item)
        end)

      success_count = Enum.count(results, fn {status, _} -> status == :ok end)
      failed_count = Enum.count(results, fn {status, _} -> status == :error end)

      {:ok,
       %{
         order_items_synced: length(order_items),
         assets_created: success_count,
         assets_failed: failed_count
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private Helpers

  defp build_client(%Integration{} = integration) do
    base_url = get_base_url(integration)

    # Check for OAuth credentials in auth_config
    auth_config = integration.auth_config || %{}
    client_id = auth_config["client_id"]
    client_secret = auth_config["client_secret"]

    cond do
      !client_id || !client_secret ->
        {:error, "OAuth credentials (client_id and client_secret) are required"}

      true ->
        # Get access token via OAuth
        case get_access_token(base_url, client_id, client_secret) do
          {:ok, token} ->
            middleware = [
              {Tesla.Middleware.BaseUrl, base_url},
              {Tesla.Middleware.Headers,
               [
                 {"Authorization", "Bearer #{token}"},
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]},
              Tesla.Middleware.JSON,
              {Tesla.Middleware.Timeout, timeout: 30_000}
            ]

            {:ok, Tesla.client(middleware)}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp get_base_url(%Integration{} = integration) do
    if integration.base_url && integration.base_url != "" do
      integration.base_url
    else
      @default_base_url
    end
  end

  defp get_access_token(base_url, client_id, client_secret) do
    # OAuth 2.0 Client Credentials flow
    token_url = "#{base_url}/oauth/token"

    body = %{
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    }

    case Tesla.post(token_url, body) do
      {:ok, %Tesla.Env{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "Failed to obtain access token: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_order_items(client, params \\ %{}) do
    query_params =
      params
      |> Map.put_new(:page_size, 100)
      |> Map.put_new(:page, 1)
      |> URI.encode_query()

    case Tesla.get(client, "/order-items/?#{query_params}") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => data}}} when is_list(data) ->
        {:ok, data}

      {:ok, %Tesla.Env{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403}} ->
        {:error, :forbidden}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "Failed to fetch order items: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_recent_order_items(client) do
    # Fetch order items from the last 30 days
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.to_iso8601()

    params = %{
      order_created_date_0: thirty_days_ago,
      page_size: 100,
      # Filter for approved items (status 1 = In Use, 2 = Receive Pending)
      status: "1,2,3,5"
    }

    fetch_order_items(client, params)
  end

  defp process_order_item(tenant, item) do
    if is_hardware_item?(item) do
      create_asset_from_item(tenant, item)
    else
      {:ignore, "Not hardware"}
    end
  end

  defp is_hardware_item?(item) do
    # Check if the item is likely hardware based on name or SKU
    name = String.downcase(item["name"] || "")
    sku = String.downcase(item["sku"] || "")

    hardware_keywords = ~w(laptop desktop monitor computer server tablet phone macbook thinkpad dell hp lenovo ipad)

    Enum.any?(hardware_keywords, fn keyword ->
      String.contains?(name, keyword) || String.contains?(sku, keyword)
    end)
  end

  defp create_asset_from_item(tenant, item) do
    # Extract item details
    name = item["name"]
    sku = item["sku"]
    quantity = parse_quantity(item["quantity"])
    approved_quantity = parse_quantity(item["approved_quantity"])
    po_num = item["num"] || item["orderNum"]
    vendor = item["vendor"]

    # Determine purchase date from available dates
    purchase_date =
      item["approved_datetime"] ||
        item["purchased_date"] || item["created_at"] || DateTime.utc_now() |> DateTime.to_iso8601()

    parsed_date = parse_datetime(purchase_date)

    # Determine unit price
    unit_price = parse_price(item["approved_price"] || item["price"])

    # Determine status based on Procurify status codes
    status = map_status(item["status"])

    # Create assets based on quantity (use approved_quantity if available)
    qty = approved_quantity || quantity || 1

    # Create individual assets for each unit
    Enum.map(1..qty, fn index ->
      asset_tag = "PROCURIFY-#{po_num}-#{sku}-#{index}"

      attrs = %{
        asset_tag: asset_tag,
        serial_number: nil,
        # Procurify doesn't typically provide serial numbers at order time
        name: name,
        description: item["lineComment"] || name,
        model: sku,
        category: categorize_item(name),
        status: status,
        purchase_date: parsed_date,
        purchase_cost: unit_price,
        vendor: vendor,
        po_number: to_string(po_num),
        custom_fields: %{
          "procurify_item_id" => item["id"],
          "procurify_sku" => sku,
          "source" => "procurify",
          "department_id" => item["department"],
          "location_id" => item["location"]
        }
      }

      Assets.create_asset(tenant, attrs)
    end)
    |> List.first()

    # Return only the first result for simplicity in counting
  end

  defp map_status(status_code) do
    case status_code do
      @status_pending -> "on_order"
      @status_in_use -> "assigned"
      @status_receive_pending -> "in_transit"
      @status_fully_received -> "in_stock"
      @status_partially_received -> "in_transit"
      _ -> "on_order"
    end
  end

  defp categorize_item(name) do
    name_lower = String.downcase(name || "")

    cond do
      String.contains?(name_lower, "laptop") -> "laptop"
      String.contains?(name_lower, "desktop") -> "desktop"
      String.contains?(name_lower, "monitor") -> "monitor"
      String.contains?(name_lower, "server") -> "server"
      String.contains?(name_lower, "tablet") || String.contains?(name_lower, "ipad") -> "tablet"
      String.contains?(name_lower, "phone") -> "phone"
      true -> "other"
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_str) when is_binary(datetime_str) do
    case DateTime.from_iso8601(datetime_str) do
      {:ok, datetime, _} -> DateTime.to_date(datetime)
      _ -> Date.utc_today()
    end
  end

  defp parse_datetime(_), do: Date.utc_today()

  defp parse_quantity(nil), do: 1

  defp parse_quantity(qty) when is_binary(qty) do
    case Integer.parse(qty) do
      {num, _} -> max(num, 1)
      :error -> 1
    end
  end

  defp parse_quantity(qty) when is_integer(qty), do: max(qty, 1)
  defp parse_quantity(_), do: 1

  defp parse_price(price) when is_number(price), do: Decimal.from_float(price / 1.0)

  defp parse_price(price) when is_binary(price) do
    case Decimal.parse(price) do
      {decimal, _} -> decimal
      :error -> nil
    end
  end

  defp parse_price(_), do: nil
end
