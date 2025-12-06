defmodule Assetronics.Integrations.Adapters.NetSuite do
  @moduledoc """
  NetSuite integration adapter for syncing financial and asset data.

  NetSuite API Documentation: https://system.netsuite.com/help/helpcenter/en_US/APIs/REST_API_Browser/record/v1/2021.2/index.html

  Authentication: OAuth 1.0 or Token-Based Authentication (TBA)
  Base URL: Account-specific (e.g., https://{accountId}.suitetalk.api.netsuite.com)
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Assets
  alias Assetronics.Integrations.Integration

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    client = build_client(integration)

    # Test with a simple query to get account info
    case Tesla.get(client, "/services/rest/record/v1/metadata-catalog") do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, %{status: "connected", message: "Successfully connected to NetSuite"}}

      {:ok, %Tesla.Env{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403}} ->
        {:error, :forbidden}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting NetSuite sync for tenant: #{tenant}")

    client = build_client(integration)

    with {:ok, purchase_orders} <- fetch_purchase_orders(client),
         {:ok, assets_data} <- fetch_fixed_assets(client),
         {:ok, sync_results} <- sync_assets(tenant, purchase_orders, assets_data) do
      Logger.info("NetSuite sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("NetSuite sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp build_client(%Integration{} = integration) do
    account_id = get_account_id(integration)
    base_url = integration.base_url || "https://#{account_id}.suitetalk.api.netsuite.com"

    # NetSuite uses OAuth 1.0 or Token-Based Authentication
    auth_headers = build_auth_headers(integration)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, auth_headers},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 60_000}
    ]

    Tesla.client(middleware)
  end

  defp get_account_id(%Integration{} = integration) do
    case integration.auth_config do
      %{"account_id" => account_id} -> account_id
      _ -> "TSTDRV1234567"  # Default test account
    end
  end

  defp build_auth_headers(%Integration{auth_type: "api_key"} = integration) do
    # Token-Based Authentication
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{integration.api_key}"}
    ]
  end

  defp build_auth_headers(%Integration{auth_type: "oauth1"} = integration) do
    # OAuth 1.0 - would need to sign each request
    # For simplicity, assuming pre-signed token
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "OAuth #{integration.access_token}"}
    ]
  end

  defp build_auth_headers(_integration) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ]
  end

  defp fetch_purchase_orders(client) do
    # Query recent purchase orders for IT assets
    query = """
    SELECT
      id, tranId, entity, tranDate, status, memo,
      item, quantity, rate, amount
    FROM
      PurchaseOrder
    WHERE
      mainLine = 'F'
      AND item.type IN ('InvtPart', 'NonInvtPart')
      AND tranDate >= ADD_MONTHS(SYSDATE, -3)
    ORDER BY
      tranDate DESC
    """

    case Tesla.post(client, "/services/rest/query/v1/suiteql", %{q: query}) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => items}}} ->
        {:ok, items}

      {:ok, %Tesla.Env{status: 200, body: %{"hasMore" => false}}} ->
        {:ok, []}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_fixed_assets(client) do
    # Get fixed assets (computers, equipment, etc.)
    case Tesla.get(client, "/services/rest/record/v1/fixedAsset", query: [limit: 1000]) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => items}}} ->
        {:ok, items}

      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, []}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp sync_assets(tenant, purchase_orders, assets_data) do
    results = %{
      total_pos: length(purchase_orders),
      total_assets: length(assets_data),
      assets_created: 0,
      assets_updated: 0,
      errors: 0
    }

    # Sync purchase orders first
    results = Enum.reduce(purchase_orders, results, fn po, acc ->
      case sync_purchase_order(tenant, po) do
        {:ok, :created} -> Map.update!(acc, :assets_created, &(&1 + 1))
        {:ok, :updated} -> Map.update!(acc, :assets_updated, &(&1 + 1))
        {:error, _} -> Map.update!(acc, :errors, &(&1 + 1))
      end
    end)

    # Then sync fixed assets
    results = Enum.reduce(assets_data, results, fn asset_data, acc ->
      case sync_fixed_asset(tenant, asset_data) do
        {:ok, :created} -> Map.update!(acc, :assets_created, &(&1 + 1))
        {:ok, :updated} -> Map.update!(acc, :assets_updated, &(&1 + 1))
        {:error, _} -> Map.update!(acc, :errors, &(&1 + 1))
      end
    end)

    {:ok, results}
  end

  defp sync_purchase_order(tenant, po_data) do
    # Map PO to asset attributes
    attrs = %{
      name: po_data["item"] || "Asset from PO #{po_data["tranId"]}",
      category: "other",
      status: "in_stock",
      purchase_date: parse_date(po_data["tranDate"]),
      purchase_cost: parse_decimal(po_data["amount"] || po_data["rate"]),
      vendor: po_data["entity"],
      po_number: po_data["tranId"],
      notes: po_data["memo"],
      custom_fields: %{
        netsuite_id: po_data["id"],
        netsuite_po: po_data["tranId"]
      }
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    # Check if asset already exists by NetSuite ID
    case find_asset_by_netsuite_id(tenant, po_data["id"]) do
      nil ->
        case Assets.create_asset(tenant, attrs) do
          {:ok, _asset} -> {:ok, :created}
          {:error, reason} ->
            Logger.error("Failed to create asset from PO: #{inspect(reason)}")
            {:error, reason}
        end

      asset ->
        case Assets.update_asset(tenant, asset, attrs) do
          {:ok, _asset} -> {:ok, :updated}
          {:error, reason} ->
            Logger.error("Failed to update asset from PO: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp sync_fixed_asset(tenant, asset_data) do
    attrs = %{
      name: asset_data["assetName"] || asset_data["displayName"],
      asset_tag: asset_data["assetId"],
      category: map_asset_category(asset_data["class"]),
      status: map_asset_status(asset_data["assetStatus"]),
      purchase_date: parse_date(asset_data["purchaseDate"]),
      purchase_cost: parse_decimal(asset_data["cost"] || asset_data["originalCost"]),
      serial_number: asset_data["serialNumber"],
      notes: asset_data["description"],
      custom_fields: %{
        netsuite_id: asset_data["id"],
        depreciation_method: asset_data["depreciationMethod"],
        book_value: asset_data["bookValue"]
      }
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    case find_asset_by_netsuite_id(tenant, asset_data["id"]) do
      nil ->
        case Assets.create_asset(tenant, attrs) do
          {:ok, _asset} -> {:ok, :created}
          {:error, reason} ->
            Logger.error("Failed to create fixed asset: #{inspect(reason)}")
            {:error, reason}
        end

      asset ->
        case Assets.update_asset(tenant, asset, attrs) do
          {:ok, _asset} -> {:ok, :updated}
          {:error, reason} ->
            Logger.error("Failed to update fixed asset: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp find_asset_by_netsuite_id(_tenant, _netsuite_id) do
    # This would query for assets with matching NetSuite ID in custom_fields
    # For now, returns nil (would need custom query in Assets context)
    nil
  end

  defp map_asset_category(nil), do: "other"
  defp map_asset_category(class) do
    class_lower = String.downcase(class)

    cond do
      String.contains?(class_lower, "computer") -> "laptop"
      String.contains?(class_lower, "laptop") -> "laptop"
      String.contains?(class_lower, "desktop") -> "desktop"
      String.contains?(class_lower, "monitor") -> "monitor"
      String.contains?(class_lower, "phone") -> "phone"
      String.contains?(class_lower, "tablet") -> "tablet"
      true -> "other"
    end
  end

  defp map_asset_status(nil), do: "in_stock"
  defp map_asset_status(status) do
    case String.downcase(status) do
      s when s in ["active", "in service"] -> "in_stock"
      s when s in ["disposed", "sold"] -> "retired"
      s when s in ["lost", "stolen"] -> "lost"
      _ -> "in_stock"
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
  defp parse_date(_), do: nil

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_number(value), do: Decimal.new(to_string(value))
  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> decimal
      :error -> nil
    end
  end
  defp parse_decimal(_), do: nil
end
