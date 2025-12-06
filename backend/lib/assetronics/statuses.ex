defmodule Assetronics.Statuses do
  @moduledoc """
  The Statuses context.

  Handles asset status management:
  - CRUD operations for statuses
  - Status listing and retrieval
  - Tenant-specific status workflow definitions
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Statuses.Status

  @doc """
  Returns the list of statuses for a tenant.

  ## Examples

      iex> list_statuses("acme")
      [%Status{}, ...]

  """
  def list_statuses(tenant) do
    query = from(s in Status, order_by: [asc: s.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single status.

  Raises `Ecto.NoResultsError` if the Status does not exist.

  ## Examples

      iex> get_status!("acme", "123")
      %Status{}

  """
  def get_status!(tenant, id) do
    Repo.get!(Status, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a status by value.

  Returns `nil` if no status with that value exists.

  ## Examples

      iex> get_status_by_value("acme", "available")
      %Status{}

  """
  def get_status_by_value(tenant, value) do
    query = from(s in Status, where: s.value == ^value)
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates a status.

  ## Examples

      iex> create_status("acme", %{name: "Available", value: "available", color: "green"})
      {:ok, %Status{}}

  """
  def create_status(tenant, attrs \\ %{}) do
    %Status{}
    |> Status.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "status_created")
  end

  @doc """
  Updates a status.

  ## Examples

      iex> update_status("acme", status, %{name: "New Name"})
      {:ok, %Status{}}

  """
  def update_status(tenant, %Status{} = status, attrs) do
    status
    |> Status.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "status_updated")
  end

  @doc """
  Deletes a status.

  ## Examples

      iex> delete_status("acme", status)
      {:ok, %Status{}}

  """
  def delete_status(tenant, %Status{} = status) do
    Repo.delete(status, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking status changes.

  ## Examples

      iex> change_status(status)
      %Ecto.Changeset{data: %Status{}}

  """
  def change_status(%Status{} = status, attrs \\ %{}) do
    Status.changeset(status, attrs)
  end

  # Private functions

  defp broadcast_result({:ok, status} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "statuses:#{tenant}",
      {event, status}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result
end
