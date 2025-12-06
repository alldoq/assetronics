defmodule Assetronics.Organizations do
  @moduledoc """
  The Organizations context.

  Handles organization management:
  - CRUD operations for organizations
  - Hierarchical organization structures
  - Parent-child relationships
  - Tenant-specific organization management
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Organizations.Organization

  @doc """
  Returns the list of organizations for a tenant.

  Optionally preloads parent and children relationships.

  ## Examples

      iex> list_organizations("acme")
      [%Organization{}, ...]

      iex> list_organizations("acme", preload: [:parent, :children])
      [%Organization{parent: %Organization{}, children: [...]}, ...]

  """
  def list_organizations(tenant, opts \\ []) do
    query = from(o in Organization, order_by: [asc: o.name])

    query =
      if Keyword.get(opts, :preload) do
        from(o in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization!("acme", "123")
      %Organization{}

  """
  def get_organization!(tenant, id, opts \\ []) do
    query = from(o in Organization, where: o.id == ^id)

    query =
      if Keyword.get(opts, :preload) do
        from(o in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.one!(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets an organization by name.

  Returns `{:ok, organization}` if found, `{:error, :not_found}` otherwise.

  ## Examples

      iex> get_organization_by_name("acme", "Acme Corp")
      {:ok, %Organization{}}

      iex> get_organization_by_name("acme", "Non Existent")
      {:error, :not_found}

  """
  def get_organization_by_name(tenant, name) do
    query = from(o in Organization, where: o.name == ^name)
    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      organization -> {:ok, organization}
    end
  end

  @doc """
  Creates an organization.

  ## Examples

      iex> create_organization("acme", %{name: "Acme Corp", type: "parent_company"})
      {:ok, %Organization{}}

  """
  def create_organization(tenant, attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "organization_created")
  end

  @doc """
  Updates an organization.

  ## Examples

      iex> update_organization("acme", organization, %{name: "New Name"})
      {:ok, %Organization{}}

  """
  def update_organization(tenant, %Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "organization_updated")
  end

  @doc """
  Deletes an organization.

  ## Examples

      iex> delete_organization("acme", organization)
      {:ok, %Organization{}}

  """
  def delete_organization(tenant, %Organization{} = organization) do
    Repo.delete(organization, prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "organization_deleted")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  @doc """
  Gets all root organizations (organizations without a parent).

  ## Examples

      iex> list_root_organizations("acme")
      [%Organization{}, ...]

  """
  def list_root_organizations(tenant) do
    query = from(o in Organization, where: is_nil(o.parent_id), order_by: [asc: o.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets all children of an organization.

  ## Examples

      iex> list_children("acme", parent_id)
      [%Organization{}, ...]

  """
  def list_children(tenant, parent_id) do
    query = from(o in Organization, where: o.parent_id == ^parent_id, order_by: [asc: o.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  # Private functions

  defp validate_no_circular_reference(changeset, tenant) do
    # Check if setting a parent would create a circular reference
    case Ecto.Changeset.fetch_change(changeset, :parent_id) do
      {:ok, nil} ->
        changeset

      {:ok, parent_id} ->
        org_id = Ecto.Changeset.get_field(changeset, :id)

        if org_id && would_create_circular_reference?(tenant, org_id, parent_id) do
          Ecto.Changeset.add_error(
            changeset,
            :parent_id,
            "would create a circular reference"
          )
        else
          changeset
        end

      :error ->
        changeset
    end
  end

  defp would_create_circular_reference?(tenant, org_id, parent_id) do
    # Check if parent_id is a descendant of org_id
    # If so, setting parent_id as parent would create a cycle
    is_descendant?(tenant, parent_id, org_id)
  end

  defp is_descendant?(tenant, potential_descendant_id, ancestor_id) do
    query =
      from(o in Organization,
        where: o.id == ^potential_descendant_id,
        select: o.parent_id
      )

    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil ->
        false

      ^ancestor_id ->
        true

      parent_id ->
        is_descendant?(tenant, parent_id, ancestor_id)
    end
  end

  defp broadcast_result({:ok, organization} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "organizations:#{tenant}",
      {event, organization}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result
end
