defmodule Assetronics.Integrations.Adapters.QuickBooks do
  @moduledoc """
  QuickBooks Online integration adapter for syncing purchase orders and expense data.

  QuickBooks API Documentation: https://developer.intuit.com/app/developer/qbo/docs/api/accounting/all-entities/purchase

  Authentication: OAuth 2.0
  Base URL: https://quickbooks.api.intuit.com
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Assets
  alias Assetronics.Integrations
  alias Assetronics.Integrations.Integration

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    client = build_client(integration)
    realm_id = get_realm_id(integration)

    # Test with CompanyInfo query
    case Tesla.get(client, "/v3/company/#{realm_id}/companyinfo/#{realm_id}") do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, %{status: "connected", message: "Successfully connected to QuickBooks"}}

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
    Logger.info("Starting QuickBooks sync for tenant: #{tenant}")

    # Refresh token if needed
    integration = maybe_refresh_token(tenant, integration)
    client = build_client(integration)
    realm_id = get_realm_id(integration)

    with {:ok, purchases} <- fetch_purchases(client, realm_id),
         {:ok, sync_results} <- sync_assets(tenant, purchases) do
      Logger.info("QuickBooks sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("QuickBooks sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp build_client(%Integration{} = integration) do
    base_url = integration.base_url || "https://quickbooks.api.intuit.com"

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"accept", "application/json"},
        {"authorization", "Bearer #{integration.access_token}"},
        {"content-type", "application/json"}
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]

    Tesla.client(middleware)
  end

  defp get_realm_id(%Integration{} = integration) do
    case integration.auth_config do
      %{"realm_id" => realm_id} -> realm_id
      _ -> "123456789"  # Default realm ID
    end
  end

  defp maybe_refresh_token(_tenant, %Integration{token_expires_at: nil} = integration), do: integration
  defp maybe_refresh_token(tenant, %Integration{token_expires_at: expires_at} = integration) do
    # Check if token expires within next hour
    expires_soon = DateTime.diff(expires_at, DateTime.utc_now(), :second) < 3600

    if expires_soon do
      case refresh_oauth_token(integration) do
        {:ok, access_token, refresh_token, expires_in} ->
          # Update integration with new tokens
          {:ok, updated_integration} = Integrations.update_tokens(
            tenant,
            integration,
            access_token,
            refresh_token,
            expires_in
          )
          updated_integration

        {:error, _reason} ->
          Logger.error("Failed to refresh QuickBooks token")
          integration
      end
    else
      integration
    end
  end

  defp refresh_oauth_token(%Integration{} = integration) do
    # QuickBooks OAuth token refresh
    client_id = integration.auth_config["client_id"]
    client_secret = integration.auth_config["client_secret"]
    refresh_token = integration.refresh_token

    body = %{
      grant_type: "refresh_token",
      refresh_token: refresh_token
    }

    auth = Base.encode64("#{client_id}:#{client_secret}")

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://oauth.platform.intuit.com"},
      {Tesla.Middleware.Headers, [
        {"authorization", "Basic #{auth}"},
        {"content-type", "application/x-www-form-urlencoded"}
      ]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.JSON
    ]

    client = Tesla.client(middleware)

    case Tesla.post(client, "/oauth2/v1/tokens/bearer", body) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        access_token = body["access_token"]
        refresh_token = body["refresh_token"]
        expires_in = body["expires_in"]
        {:ok, access_token, refresh_token, expires_in}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_purchases(client, realm_id) do
    # Query purchases from last 90 days
    ninety_days_ago = Date.add(Date.utc_today(), -90) |> Date.to_iso8601()

    query = "SELECT * FROM Purchase WHERE TxnDate >= '#{ninety_days_ago}' MAXRESULTS 1000"

    case Tesla.get(client, "/v3/company/#{realm_id}/query", query: [query: query]) do
      {:ok, %Tesla.Env{status: 200, body: %{"QueryResponse" => %{"Purchase" => purchases}}}} ->
        {:ok, purchases}

      {:ok, %Tesla.Env{status: 200, body: %{"QueryResponse" => %{}}}} ->
        {:ok, []}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp sync_assets(tenant, purchases) do
    results = %{
      total: length(purchases),
      created: 0,
      updated: 0,
      skipped: 0,
      errors: 0
    }

    purchases
    |> Enum.reduce(results, fn purchase, acc ->
      # Only sync purchases that look like IT/hardware purchases
      if is_hardware_purchase?(purchase) do
        case sync_purchase(tenant, purchase) do
          {:ok, :created} -> Map.update!(acc, :created, &(&1 + 1))
          {:ok, :updated} -> Map.update!(acc, :updated, &(&1 + 1))
          {:error, _} -> Map.update!(acc, :errors, &(&1 + 1))
        end
      else
        Map.update!(acc, :skipped, &(&1 + 1))
      end
    end)
    |> then(&{:ok, &1})
  end

  defp is_hardware_purchase?(purchase) do
    # Check if purchase contains IT/hardware-related items
    lines = purchase["Line"] || []

    Enum.any?(lines, fn line ->
      description = String.downcase(line["Description"] || "")
      item_name = String.downcase(get_in(line, ["ItemBasedExpenseLineDetail", "ItemRef", "name"]) || "")

      hardware_keywords = ["laptop", "computer", "monitor", "phone", "tablet", "keyboard", "mouse", "equipment"]

      Enum.any?(hardware_keywords, fn keyword ->
        String.contains?(description, keyword) || String.contains?(item_name, keyword)
      end)
    end)
  end

  defp sync_purchase(tenant, purchase) do
    lines = purchase["Line"] || []

    # Get first hardware item line
    hardware_line = Enum.find(lines, fn line ->
      description = String.downcase(line["Description"] || "")
      String.contains?(description, ["laptop", "computer", "monitor", "phone"])
    end)

    attrs = %{
      name: extract_item_name(hardware_line),
      category: determine_category(hardware_line),
      status: "in_stock",
      purchase_date: parse_date(purchase["TxnDate"]),
      purchase_cost: parse_decimal(purchase["TotalAmt"]),
      vendor: get_in(purchase, ["EntityRef", "name"]),
      po_number: purchase["DocNumber"],
      notes: purchase["PrivateNote"],
      custom_fields: %{
        quickbooks_id: purchase["Id"],
        quickbooks_txn: purchase["DocNumber"]
      }
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    # Check if asset already exists
    case find_asset_by_quickbooks_id(tenant, purchase["Id"]) do
      nil ->
        case Assets.create_asset(tenant, attrs) do
          {:ok, _asset} -> {:ok, :created}
          {:error, reason} ->
            Logger.error("Failed to create asset from QuickBooks: #{inspect(reason)}")
            {:error, reason}
        end

      asset ->
        case Assets.update_asset(tenant, asset, attrs) do
          {:ok, _asset} -> {:ok, :updated}
          {:error, reason} ->
            Logger.error("Failed to update asset from QuickBooks: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp extract_item_name(nil), do: "Hardware Purchase"
  defp extract_item_name(line) do
    line["Description"] ||
      get_in(line, ["ItemBasedExpenseLineDetail", "ItemRef", "name"]) ||
      "Hardware Purchase"
  end

  defp determine_category(nil), do: "other"
  defp determine_category(line) do
    description = String.downcase(line["Description"] || "")

    cond do
      String.contains?(description, "laptop") -> "laptop"
      String.contains?(description, "desktop") || String.contains?(description, "computer") -> "desktop"
      String.contains?(description, "monitor") || String.contains?(description, "display") -> "monitor"
      String.contains?(description, "phone") -> "phone"
      String.contains?(description, "tablet") || String.contains?(description, "ipad") -> "tablet"
      true -> "other"
    end
  end

  defp find_asset_by_quickbooks_id(_tenant, _quickbooks_id) do
    # Would need custom query in Assets context
    nil
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
