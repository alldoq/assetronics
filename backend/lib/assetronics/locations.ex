defmodule Assetronics.Locations do
  @moduledoc """
  The Locations context.

  Handles physical location management:
  - CRUD operations for locations
  - Hierarchical location structures (regions, countries, offices, etc.)
  - Office, warehouse, employee home locations
  - Address information (encrypted for privacy)
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Locations.Location

  @doc """
  Returns the list of locations for a tenant.

  Optionally preloads parent and children relationships using opts.

  ## Examples

      iex> list_locations("acme")
      [%Location{}, ...]

      iex> list_locations("acme", preload: [:parent, :children])
      [%Location{parent: %Location{}, children: [...]}, ...]

  """
  def list_locations(tenant, opts \\ []) do
    query = from(l in Location, order_by: [asc: l.name])

    query
    |> apply_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!("acme", "123")
      %Location{}

      iex> get_location!("acme", "123", preload: [:parent, :children])
      %Location{parent: %Location{}, children: [...]}

  """
  def get_location!(tenant, id, opts \\ []) do
    query = from(l in Location, where: l.id == ^id)

    query =
      if Keyword.get(opts, :preload) do
        from(l in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.one!(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a location by name.

  ## Examples

      iex> get_location_by_name("acme", "SF Office")
      {:ok, %Location{}}

  """
  def get_location_by_name(tenant, name) do
    case Repo.one(from(l in Location, where: l.name == ^name), prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      location -> {:ok, location}
    end
  end

  @doc """
  Creates a location.

  ## Examples

      iex> create_location("acme", %{name: "SF Office", location_type: "office"})
      {:ok, %Location{}}

  """
  def create_location(tenant, attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "location_created")
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location("acme", location, %{name: "New Name"})
      {:ok, %Location{}}

  """
  def update_location(tenant, %Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "location_updated")
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location("acme", location)
      {:ok, %Location{}}

  """
  def delete_location(tenant, %Location{} = location) do
    Repo.delete(location, prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "location_deleted")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  @doc """
  Lists active locations.

  ## Examples

      iex> list_active_locations("acme")
      [%Location{}, ...]

  """
  def list_active_locations(tenant) do
    query = from(l in Location, where: l.is_active == true, order_by: [asc: l.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists locations by type.

  ## Examples

      iex> list_locations_by_type("acme", "office")
      [%Location{}, ...]

  """
  def list_locations_by_type(tenant, location_type) do
    query = from(l in Location, where: l.location_type == ^location_type, order_by: [asc: l.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Deactivates a location.

  ## Examples

      iex> deactivate_location("acme", location)
      {:ok, %Location{}}

  """
  def deactivate_location(tenant, %Location{} = location) do
    location
    |> Location.changeset(%{is_active: false})
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Activates a location.

  ## Examples

      iex> activate_location("acme", location)
      {:ok, %Location{}}

  """
  def activate_location(tenant, %Location{} = location) do
    location
    |> Location.changeset(%{is_active: true})
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets location with associated assets.

  ## Examples

      iex> get_location_with_assets("acme", location_id)
      %Location{assets: [...]}

  """
  def get_location_with_assets(tenant, location_id) do
    query =
      from l in Location,
        where: l.id == ^location_id,
        preload: [:assets, :employees]

    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets location with associated employees.

  ## Examples

      iex> get_location_with_employees("acme", location_id)
      %Location{employees: [...]}

  """
  def get_location_with_employees(tenant, location_id) do
    query =
      from l in Location,
        where: l.id == ^location_id,
        preload: [:employees]

    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets all root locations (locations without a parent).

  ## Examples

      iex> list_root_locations("acme")
      [%Location{}, ...]

  """
  def list_root_locations(tenant) do
    query = from(l in Location, where: is_nil(l.parent_id), order_by: [asc: l.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets all children of a location.

  ## Examples

      iex> list_children("acme", parent_id)
      [%Location{}, ...]

  """
  def list_children(tenant, parent_id) do
    query = from(l in Location, where: l.parent_id == ^parent_id, order_by: [asc: l.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  # Private functions

  defp validate_no_circular_reference(changeset, tenant) do
    # Check if setting a parent would create a circular reference
    case Ecto.Changeset.fetch_change(changeset, :parent_id) do
      {:ok, nil} ->
        changeset

      {:ok, parent_id} ->
        loc_id = Ecto.Changeset.get_field(changeset, :id)

        if loc_id && would_create_circular_reference?(tenant, loc_id, parent_id) do
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

  defp would_create_circular_reference?(tenant, loc_id, parent_id) do
    # Check if parent_id is a descendant of loc_id
    # If so, setting parent_id as parent would create a cycle
    is_descendant?(tenant, parent_id, loc_id)
  end

  defp is_descendant?(tenant, potential_descendant_id, ancestor_id) do
    query =
      from(l in Location,
        where: l.id == ^potential_descendant_id,
        select: l.parent_id
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

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:location_type, location_type}, query ->
        from(l in query, where: l.location_type == ^location_type)

      {:is_active, is_active}, query ->
        from(l in query, where: l.is_active == ^is_active)

      {:preload, preloads}, query ->
        from(l in query, preload: ^preloads)

      _, query ->
        query
    end)
  end

  defp broadcast_result({:ok, location} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "locations:#{tenant}",
      {event, location}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result
end
