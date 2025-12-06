defmodule Assetronics.Transactions do
  @moduledoc """
  The Transactions context for audit trail and asset history.
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Transactions.Transaction
  alias Triplex

  @doc """
  Returns the list of transactions for a tenant.

  ## Examples

      iex> list_transactions("acme")
      [%Transaction{}, ...]

  """
  def list_transactions(tenant, opts \\ []) do
    query = from t in Transaction,
      order_by: [desc: t.performed_at],
      preload: [:asset, :employee, :from_employee, :to_employee, :from_location, :to_location]

    query
    |> apply_filters(opts)
    |> Repo.all(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns the list of transactions for a specific asset.

  ## Examples

      iex> list_asset_transactions("acme", asset_id)
      [%Transaction{}, ...]

  """
  def list_asset_transactions(tenant, asset_id, opts \\ []) do
    query = from t in Transaction,
      where: t.asset_id == ^asset_id,
      order_by: [desc: t.performed_at],
      preload: [:asset, :employee, :from_employee, :to_employee, :from_location, :to_location]

    query
    |> apply_filters(opts)
    |> Repo.all(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns the list of transactions for a specific employee.

  ## Examples

      iex> list_employee_transactions("acme", employee_id)
      [%Transaction{}, ...]

  """
  def list_employee_transactions(tenant, employee_id, opts \\ []) do
    query = from t in Transaction,
      where: t.employee_id == ^employee_id or t.from_employee_id == ^employee_id or t.to_employee_id == ^employee_id,
      order_by: [desc: t.performed_at],
      preload: [:asset, :employee, :from_employee, :to_employee, :from_location, :to_location]

    query
    |> apply_filters(opts)
    |> Repo.all(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!("acme", 123)
      %Transaction{}

      iex> get_transaction!("acme", 456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(tenant, id) do
    Transaction
    |> preload([:asset, :employee, :from_employee, :to_employee, :from_location, :to_location])
    |> Repo.get!(id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction("acme", %{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction("acme", %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(tenant, attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Create a transaction for asset assignment.
  """
  def create_assignment_transaction(tenant, asset, employee, performed_by, metadata \\ %{}) do
    Transaction.assignment_changeset(asset, employee, performed_by, metadata)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Create a transaction for asset return.
  """
  def create_return_transaction(tenant, asset, employee, performed_by, metadata \\ %{}) do
    Transaction.return_changeset(asset, employee, performed_by, metadata)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Create a transaction for asset transfer.
  """
  def create_transfer_transaction(tenant, asset, from_employee, to_employee, performed_by, metadata \\ %{}) do
    Transaction.transfer_changeset(asset, from_employee, to_employee, performed_by, metadata)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Create a transaction for status change.
  """
  def create_status_change_transaction(tenant, asset, new_status, performed_by, metadata \\ %{}) do
    Transaction.status_change_changeset(asset, new_status, performed_by, metadata)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:transaction_type, type} | rest]) do
    query
    |> where([t], t.transaction_type == ^type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:limit, limit} | rest]) do
    query
    |> limit(^limit)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_  | rest]), do: apply_filters(query, rest)
end
