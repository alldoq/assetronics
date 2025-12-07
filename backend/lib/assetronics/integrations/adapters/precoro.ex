defmodule Assetronics.Integrations.Adapters.Precoro do
  @moduledoc """
  Integration adapter for Precoro procurement platform.

  Supports:
  - Purchase Order sync -> Assets (status: on_order)
  - Vendor and invoice data retrieval
  - Real-time procurement tracking

  Authentication:
  - API Key (X-AUTH-TOKEN header)
  - Rate limits: 60 requests/minute, 1,500/hour, 3,000/day

  API Documentation: https://help.precoro.com/using-api-in-precoro
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @default_base_url "https://api.precoro.com"
  @us_base_url "https://api.precoro.us"

  @impl true
  def test_connection(%Integration{} = integration) do
    # Test by fetching a single purchase order (limited query)
    with {:ok, client} <- build_client(integration),
         {:ok, _response} <- fetch_purchase_orders(client, %{per_page: 1}) do
      {:ok, %{success: true, message: "Connection successful"}}
    else
      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    with {:ok, client} <- build_client(integration),
         {:ok, purchase_orders} <- fetch_recent_purchase_orders(client) do
      # Process each purchase order and create assets
      results =
        Enum.flat_map(purchase_orders, fn po ->
          process_purchase_order(tenant, po)
        end)

      success_count = Enum.count(results, fn {status, _} -> status == :ok end)
      failed_count = Enum.count(results, fn {status, _} -> status == :error end)

      {:ok,
       %{
         purchase_orders_synced: length(purchase_orders),
         assets_created: success_count,
         assets_failed: failed_count
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns webhook configuration details for Precoro integration.

  This provides the webhook URL and instructions for setting up real-time sync.
  """
  def webhook_config(tenant_id, base_url \\ nil) do
    webhook_url = build_webhook_url(tenant_id, base_url)

    %{
      webhook_url: webhook_url,
      instructions: """
      To enable real-time purchase order sync:

      1. Log in to Precoro and navigate to Settings → Webhooks
      2. Click "New Webhook"
      3. Enter the webhook URL: #{webhook_url}
      4. Select the following events to track:
         - Purchase Order Created (Type 2, Action 0)
         - Purchase Order Updated (Type 2, Action 1)
      5. Save the webhook configuration

      Note: The user creating the webhook must have maximum access roles for unrestricted data access.
      """,
      events_to_track: [
        %{name: "Purchase Order Created", type: 2, action: 0},
        %{name: "Purchase Order Updated", type: 2, action: 1}
      ]
    }
  end

  defp build_webhook_url(tenant_id, base_url) do
    base = base_url || System.get_env("APP_URL") || "https://app.assetronics.com"
    "#{base}/api/v1/webhooks/precoro?tenant=#{tenant_id}"
  end

  # Private Helpers

  defp build_client(%Integration{} = integration) do
    base_url = get_base_url(integration)
    api_key = integration.api_key

    if !api_key || api_key == "" do
      {:error, "API key is required"}
    else
      middleware = [
        {Tesla.Middleware.BaseUrl, base_url},
        {Tesla.Middleware.Headers,
         [
           {"X-AUTH-TOKEN", api_key},
           {"Accept", "application/json"},
           {"Content-Type", "application/json"}
         ]},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Timeout, timeout: 30_000}
      ]

      {:ok, Tesla.client(middleware)}
    end
  end

  defp get_base_url(%Integration{} = integration) do
    cond do
      integration.base_url && integration.base_url != "" ->
        integration.base_url

      integration.environment == "us" ->
        @us_base_url

      true ->
        @default_base_url
    end
  end

  defp fetch_purchase_orders(client, params \\ %{}) do
    query_params =
      params
      |> Map.put_new(:per_page, 50)
      |> Map.put_new(:page, 1)
      |> URI.encode_query()

    case Tesla.get(client, "/purchaseorders?#{query_params}") do
      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: %{"data" => data}}} when is_list(data) ->
        {:ok, data}

      {:ok, %Tesla.Env{status: 429}} ->
        Logger.warning("Precoro API rate limit exceeded")
        {:error, :rate_limit_exceeded}

      {:ok, %Tesla.Env{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "Failed to fetch purchase orders: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_recent_purchase_orders(client) do
    # Fetch purchase orders from the last 30 days
    thirty_days_ago = Date.utc_today() |> Date.add(-30)
    date_str = Calendar.strftime(thirty_days_ago, "%d.%m.%Y")

    params = %{
      "createDate[left_date]" => date_str,
      "createDate[right_date]" => Calendar.strftime(Date.utc_today(), "%d.%m.%Y"),
      status: [2],
      # Status 2 = Approved
      per_page: 100
    }

    fetch_purchase_orders(client, params)
  end

  defp process_purchase_order(tenant, po) do
    po_number = po["number"] || po["id"]
    vendor = po["vendor"]["name"] || "Unknown"
    po_date = parse_date(po["createDate"] || po["approvalDate"])

    # Process line items
    items = po["items"] || po["purchaseOrderItems"] || []

    Enum.map(items, fn item ->
      if is_hardware_item?(item) do
        create_asset_from_item(tenant, item, po_number, vendor, po_date)
      else
        {:ignore, "Not hardware"}
      end
    end)
  end

  defp is_hardware_item?(item) do
    # Check if the item is likely hardware based on description or category
    description = String.downcase(item["name"] || item["description"] || "")

    hardware_keywords = ~w(laptop desktop monitor computer server tablet phone macbook thinkpad dell hp lenovo)

    Enum.any?(hardware_keywords, &String.contains?(description, &1))
  end

  defp create_asset_from_item(tenant, item, po_number, vendor, po_date) do
    # Extract item details
    name = item["name"] || item["description"]
    sku = item["sku"] || item["code"]
    quantity = item["quantity"] || 1
    unit_price = parse_price(item["price"] || item["unitPrice"])

    # Create assets based on quantity
    # If we have serial numbers, create one per serial, otherwise create based on quantity
    serials = item["serialNumbers"] || []

    if length(serials) > 0 do
      # Create one asset per serial number
      Enum.map(serials, fn serial ->
        create_single_asset(tenant, name, serial, sku, po_number, vendor, po_date, unit_price)
      end)
    else
      # Create placeholder assets based on quantity
      Enum.map(1..quantity, fn _ ->
        create_single_asset(tenant, name, nil, sku, po_number, vendor, po_date, unit_price)
      end)
    end
  end

  defp create_single_asset(tenant, name, serial, sku, po_number, vendor, po_date, unit_price) do
    {asset_tag, serial_val, status} =
      if serial do
        {"PRECORO-#{serial}", serial, "in_transit"}
      else
        {"PRECORO-#{po_number}-#{Nanoid.generate(6)}", nil, "on_order"}
      end

    attrs = %{
      asset_tag: asset_tag,
      serial_number: serial_val,
      name: name,
      description: name,
      model: sku,
      category: categorize_item(name),
      status: status,
      purchase_date: po_date,
      purchase_cost: unit_price,
      vendor: vendor,
      po_number: po_number,
      custom_fields: %{
        "precoro_sku" => sku,
        "source" => "precoro"
      }
    }

    # If we have a serial number, use upsert logic, otherwise create
    if serial_val do
      Assets.sync_from_mdm(tenant, attrs)
    else
      Assets.create_asset(tenant, attrs)
    end
  end

  defp categorize_item(name) do
    name_lower = String.downcase(name || "")

    cond do
      String.contains?(name_lower, "laptop") -> "laptop"
      String.contains?(name_lower, "desktop") -> "desktop"
      String.contains?(name_lower, "monitor") -> "monitor"
      String.contains?(name_lower, "server") -> "server"
      String.contains?(name_lower, "tablet") -> "tablet"
      String.contains?(name_lower, "phone") -> "phone"
      true -> "other"
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_str) when is_binary(date_str) do
    # Precoro uses DD.MM.YYYY format
    case String.split(date_str, ".") do
      [day, month, year] ->
        case Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day)) do
          {:ok, date} -> date
          _ -> nil
        end

      _ ->
        # Try ISO 8601 format as fallback
        case Date.from_iso8601(date_str) do
          {:ok, date} -> date
          _ -> nil
        end
    end
  end

  defp parse_date(_), do: nil

  defp parse_price(price) when is_number(price), do: Decimal.from_float(price / 1.0)

  defp parse_price(price) when is_binary(price) do
    case Decimal.parse(price) do
      {decimal, _} -> decimal
      :error -> nil
    end
  end

  defp parse_price(_), do: nil
end
