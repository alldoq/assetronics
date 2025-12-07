defmodule Assetronics.Integrations.Adapters.Precoro.Webhook do
  @moduledoc """
  Handles webhook events from Precoro for automatic purchase order synchronization.

  Precoro sends webhooks for various entity events including:
  - Purchase Order created (type: 2, action: 0)
  - Purchase Order updated (type: 2, action: 1)
  - Invoice created/updated (type: 3, action: 0/1)
  - Supplier created/updated (type: 7, action: 0/1)

  Webhook payload format:
  {
    "id": 123456,      # Entity ID
    "type": 2,         # Entity type (2 = Purchase Order)
    "action": 0,       # Action (0 = Create, 1 = Update)
    "idn": 5           # Additional identifier
  }

  After receiving the webhook, we fetch full entity details via Precoro API.
  """

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapters.Precoro
  alias Assetronics.Assets

  require Logger

  # Entity types
  @type_warehouse_request 0
  @type_purchase_requisition 1
  @type_purchase_order 2
  @type_invoice 3
  @type_rfp 4
  @type_receipt 5
  @type_expense 6
  @type_supplier 7
  @type_stock_transfer 8
  @type_budget 9

  # Actions
  @action_create 0
  @action_update 1

  @doc """
  Processes an incoming webhook from Precoro.

  The webhook contains minimal information, so we fetch full details from the API.
  """
  def process_webhook(tenant, webhook_payload) do
    Logger.info("Processing Precoro webhook for tenant: #{tenant}")

    with {:ok, integration} <- get_precoro_integration(tenant),
         {:ok, result} <- process_webhook_event(tenant, integration, webhook_payload) do
      Logger.info("Precoro webhook processed successfully: #{inspect(result)}")
      {:ok, result}
    else
      {:error, reason} ->
        Logger.error("Failed to process Precoro webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Validates the webhook payload structure.
  """
  def validate_payload(%{"id" => _id, "type" => type, "action" => action})
      when is_integer(type) and is_integer(action) do
    :ok
  end

  def validate_payload(_payload) do
    {:error, "Invalid webhook payload format"}
  end

  @doc """
  Handles Purchase Order created event.
  """
  def handle_purchase_order_created(tenant, integration, po_id) do
    Logger.info("Handling purchase order created event for ID: #{po_id}")

    with {:ok, client} <- build_client(integration),
         {:ok, purchase_order} <- fetch_purchase_order(client, po_id),
         {:ok, assets} <- process_purchase_order(tenant, purchase_order) do
      {:ok, %{
        action: :purchase_order_created,
        po_id: po_id,
        assets_created: length(assets)
      }}
    end
  end

  @doc """
  Handles Purchase Order updated event.
  """
  def handle_purchase_order_updated(tenant, integration, po_id) do
    Logger.info("Handling purchase order updated event for ID: #{po_id}")

    with {:ok, client} <- build_client(integration),
         {:ok, purchase_order} <- fetch_purchase_order(client, po_id),
         {:ok, assets} <- process_purchase_order(tenant, purchase_order) do
      {:ok, %{
        action: :purchase_order_updated,
        po_id: po_id,
        assets_processed: length(assets)
      }}
    end
  end

  # Private functions

  defp get_precoro_integration(tenant) do
    case Integrations.get_integration_by_provider(tenant, "precoro") do
      nil -> {:error, :integration_not_found}
      integration -> {:ok, integration}
    end
  end

  defp process_webhook_event(tenant, integration, %{"type" => @type_purchase_order, "action" => @action_create, "id" => po_id}) do
    handle_purchase_order_created(tenant, integration, po_id)
  end

  defp process_webhook_event(tenant, integration, %{"type" => @type_purchase_order, "action" => @action_update, "id" => po_id}) do
    handle_purchase_order_updated(tenant, integration, po_id)
  end

  defp process_webhook_event(_tenant, _integration, %{"type" => type, "action" => action}) do
    Logger.info("Ignoring Precoro webhook event - type: #{type}, action: #{action}")
    {:ok, %{action: :ignored, type: type, webhook_action: action}}
  end

  defp process_webhook_event(_tenant, _integration, payload) do
    Logger.error("Unrecognized Precoro webhook payload format: #{inspect(payload)}")
    {:error, :invalid_payload_format}
  end

  defp build_client(integration) do
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

  defp get_base_url(integration) do
    cond do
      integration.base_url && integration.base_url != "" ->
        integration.base_url

      integration.environment == "us" ->
        "https://api.precoro.us"

      true ->
        "https://api.precoro.com"
    end
  end

  defp fetch_purchase_order(client, po_id) do
    # Fetch specific purchase order by ID
    case Tesla.get(client, "/purchaseorders/#{po_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :purchase_order_not_found}

      {:ok, %Tesla.Env{status: 429}} ->
        Logger.warning("Precoro API rate limit exceeded")
        {:error, :rate_limit_exceeded}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "Failed to fetch purchase order: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_purchase_order(tenant, po) do
    po_number = po["number"] || po["id"]
    vendor = get_in(po, ["vendor", "name"]) || "Unknown"
    po_date = parse_date(po["createDate"] || po["approvalDate"])

    # Process line items
    items = po["items"] || po["purchaseOrderItems"] || []

    # Filter hardware items and create assets
    results =
      items
      |> Enum.filter(&is_hardware_item?/1)
      |> Enum.flat_map(fn item ->
        create_assets_from_item(tenant, item, po_number, vendor, po_date)
      end)
      |> Enum.filter(fn result -> match?({:ok, _}, result) end)

    {:ok, results}
  end

  defp is_hardware_item?(item) do
    # Check if the item is likely hardware based on description or category
    description = String.downcase(item["name"] || item["description"] || "")

    hardware_keywords = ~w(laptop desktop monitor computer server tablet phone macbook thinkpad dell hp lenovo)

    Enum.any?(hardware_keywords, &String.contains?(description, &1))
  end

  defp create_assets_from_item(tenant, item, po_number, vendor, po_date) do
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
        "source" => "precoro_webhook"
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
