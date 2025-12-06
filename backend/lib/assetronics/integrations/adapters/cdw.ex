defmodule Assetronics.Integrations.Adapters.Cdw do
  @moduledoc """
  Integration adapter for CDW Orders.
  Uses the CDW B2B / eProcurement API to fetch order history.
  """
  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @default_base_url "https://api.cdw.com/v1" 

  @impl true
  def test_connection(%Integration{} = integration) do
    # Simple ping to orders endpoint with limit 1
    case fetch_orders(integration, 1) do
      {:ok, _} -> {:ok, %{success: true, message: "Connected to CDW"}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    # Fetch recent orders (last 30 days is standard for periodic sync)
    # CDW API usually supports date filters
    
    case fetch_orders(integration, 50) do
      {:ok, orders} ->
        results = Enum.flat_map(orders, fn order ->
          process_order(tenant, order)
        end)
        
        synced = Enum.count(results, fn {status, _} -> status == :ok end)
        failed = Enum.count(results, fn {status, _} -> status == :error end)
        
        {:ok, %{orders_processed: length(orders), assets_created: synced, failed: failed}}
        
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Internal Logic ---

  defp fetch_orders(integration, limit) do
    base_url = if integration.base_url, do: integration.base_url, else: @default_base_url
    
    # Auth is usually Basic or Header-based API Key
    headers = build_headers(integration)
    
    # Simulated Endpoint: /orders?limit=X
    # Adjust based on specific CDW documentation provided to user
    url = "#{base_url}/orders?limit=#{limit}&sort=orderDate:desc"

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        # Expecting body["orders"] or list
        orders = Map.get(body, "orders", body) 
        # Handle case where it might be empty or direct list
        if is_list(orders), do: {:ok, orders}, else: {:ok, []}
        
      {:ok, %{status: 401}} -> {:error, "CDW Auth Failed (401)"}
      {:ok, %{status: 403}} -> {:error, "CDW Access Denied (403)"}
      {:ok, %{status: status}} -> {:error, "CDW API Error: #{status}"}
      {:error, reason} -> {:error, "Network Error: #{inspect(reason)}"}
    end
  end

  defp process_order(tenant, order) do
    order_number = order["order_number"] || order["orderNumber"]
    po_number = order["customer_po"] || order["customerPONumber"]
    order_date = parse_date(order["order_date"] || order["orderDate"])
    
    lines = order["lines"] || order["lineItems"] || []
    
    Enum.map(lines, fn line ->
      if is_hardware?(line) do
        qty = line["quantity"] || 1
        
        # If we have serials (shipped items), create assets for each
        serials = line["serial_numbers"] || line["serials"] || []
        
        if length(serials) > 0 do
           Enum.map(serials, fn serial ->
             create_asset(tenant, order_number, po_number, order_date, line, serial)
           end)
        else
           # If no serials (pending/on_order), create placeholders based on Qty
           Enum.map(1..qty, fn _ ->
             create_asset(tenant, order_number, po_number, order_date, line, nil)
           end)
        end
      else
        [{:ignore, "Not hardware"}]
      end
    end)
    |> List.flatten()
  end

  defp create_asset(tenant, order_num, po_num, date, line, serial) do
    desc = line["description"] || line["productName"]
    mfg = line["manufacturer"] || "Unknown"
    part_no = line["manufacturer_part_number"] || line["partNumber"]
    price = parse_price(line["unit_price"] || line["price"])
    
    # Asset Tag strategy: Use Serial if available, else generate placeholder
    {tag, serial_val, status} = if serial do
      {"CDW-#{serial}", serial, "in_transit"} # Or "in_stock" if received logic exists
    else
      {"CDW-ORD-#{order_num}-#{part_no}-#{Nanoid.generate(6)}", nil, "on_order"}
    end

    attrs = %{
      asset_tag: tag,
      serial_number: serial_val,
      name: desc,
      description: desc,
      make: mfg,
      model: part_no, # Often part number is best proxy for model in CDW
      category: categorize(desc),
      status: status,
      purchase_date: date,
      purchase_cost: price,
      vendor: "CDW",
      po_number: po_num,
      custom_fields: %{
        "cdw_order_number" => order_num,
        "cdw_part_number" => part_no
      }
    }

    # If serial is nil, we use create_asset (duplicates allowed for on_order)
    # If serial exists, we use sync_from_mdm to upsert
    if serial_val do
      Assets.sync_from_mdm(tenant, attrs)
    else
      Assets.create_asset(tenant, attrs)
    end
  end

  defp build_headers(integration) do
    # Assuming Basic Auth for MVP
    # "username" -> Customer ID/Code, "password" -> API Key/Secret
    user = integration.auth_config["username"]
    pass = integration.auth_config["password"]
    
    encoded = Base.encode64("#{user}:#{pass}")
    
    [
      Authorization: "Basic #{encoded}",
      Accept: "application/json"
    ]
  end

  defp is_hardware?(line) do
    # Naive keyword filter
    desc = String.downcase(line["description"] || line["productName"] || "")
    keywords = ~w(laptop desktop monitor server tablet macbook thinkpad latitude surface)
    Enum.any?(keywords, &String.contains?(desc, &1))
  end
  
  defp categorize(desc) do
    desc = String.downcase(desc || "")
    cond do
      String.contains?(desc, "monitor") -> "monitor"
      String.contains?(desc, "server") -> "server"
      String.contains?(desc, "tablet") -> "tablet"
      String.contains?(desc, "ipad") -> "tablet"
      true -> "laptop" # Default guess
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end
  
  defp parse_price(p) when is_number(p), do: Decimal.from_float(p / 1.0)
  defp parse_price(p) when is_binary(p) do
    case Decimal.parse(p) do
      {d, _} -> d
      _ -> nil
    end
  end
  defp parse_price(_), do: nil
end