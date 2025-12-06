defmodule AssetronicsWeb.TransactionController do
  use AssetronicsWeb, :controller

  alias Assetronics.Transactions

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all transactions for the tenant.
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params)
    transactions = Transactions.list_transactions(tenant, opts)
    render(conn, :index, transactions: transactions)
  end

  @doc """
  List transactions for a specific asset.
  """
  def asset_transactions(conn, %{"asset_id" => asset_id} = params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params)
    transactions = Transactions.list_asset_transactions(tenant, asset_id, opts)
    render(conn, :index, transactions: transactions)
  end

  @doc """
  List transactions for a specific employee.
  """
  def employee_transactions(conn, %{"employee_id" => employee_id} = params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params)
    transactions = Transactions.list_employee_transactions(tenant, employee_id, opts)
    render(conn, :index, transactions: transactions)
  end

  @doc """
  Get a single transaction by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    transaction = Transactions.get_transaction!(tenant, id)
    render(conn, :show, transaction: transaction)
  end

  defp build_filters(params) do
    []
    |> add_filter(:transaction_type, params["transaction_type"])
    |> add_filter(:limit, params["limit"])
  end

  defp add_filter(filters, _key, nil), do: filters
  defp add_filter(filters, key, value), do: [{key, value} | filters]
end
