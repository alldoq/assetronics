defmodule Assetronics.Software do
  @moduledoc """
  The Software context.
  
  Handles management of software licenses and subscriptions.
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Software.License
  alias Triplex

  alias Assetronics.Software.Assignment

  @doc "Returns the list of software licenses for a tenant."
  def list_licenses(tenant) do
    Repo.all(License, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Gets a single license."
  def get_license!(tenant, id) do
    Repo.get!(License, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Creates a license."
  def create_license(tenant, attrs \\ %{}) do
    %License{}
    |> License.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc "Updates a license."
  def update_license(tenant, %License{} = license, attrs) do
    license
    |> License.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc "Deletes a license."
  def delete_license(tenant, %License{} = license) do
    Repo.delete(license, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Returns an `%Ecto.Changeset{}` for tracking license changes."
  def change_license(%License{} = license, attrs \\ %{}) do
    License.changeset(license, attrs)
  end

  @doc "Assigns software to an employee."
  def assign_software(tenant, employee_id, license_id, attrs \\ %{}) do
    %Assignment{}
    |> Assignment.changeset(Map.merge(attrs, %{employee_id: employee_id, software_license_id: license_id}))
    |> Repo.insert(prefix: Triplex.to_prefix(tenant), on_conflict: :nothing)
  end

  @doc "Lists assignments for a license."
  def list_assignments(tenant, license_id) do
    query = from a in Assignment,
      where: a.software_license_id == ^license_id,
      preload: [:employee]
    
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end
end
