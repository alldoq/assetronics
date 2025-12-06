defmodule AssetronicsWeb.LocationController do
  use AssetronicsWeb, :controller

  alias Assetronics.Locations
  alias Assetronics.Locations.Location

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all locations for the tenant.
  Includes parent relationship in the response.

  Query parameters:
  - location_type: Filter by type (office, warehouse, datacenter, retail, remote)
  - status: Filter by status (active, inactive)
  - country: Filter by country
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params) ++ [preload: [:parent]]
    locations = Locations.list_locations(tenant, opts)
    render(conn, :index, locations: locations)
  end

  @doc """
  Create a new location.
  """
  def create(conn, %{"location" => location_params}) do
    tenant = conn.assigns[:tenant]

    with {:ok, %Location{} = location} <- Locations.create_location(tenant, location_params) do
      # Reload with associations
      location = Locations.get_location!(tenant, location.id, preload: [:parent])

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/locations/#{location.id}")
      |> render(:show, location: location)
    end
  end

  @doc """
  Get a single location by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location!(tenant, id, preload: [:parent, :children])
    render(conn, :show, location: location)
  end

  @doc """
  Update a location.
  """
  def update(conn, %{"id" => id, "location" => location_params}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location!(tenant, id)

    with {:ok, %Location{} = location} <- Locations.update_location(tenant, location, location_params) do
      # Reload with associations
      location = Locations.get_location!(tenant, location.id, preload: [:parent])

      render(conn, :show, location: location)
    end
  end

  @doc """
  Delete a location.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location!(tenant, id)

    with {:ok, %Location{}} <- Locations.delete_location(tenant, location) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Activate a location.
  """
  def activate(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location!(tenant, id)

    with {:ok, %Location{} = location} <- Locations.activate_location(tenant, location) do
      render(conn, :show, location: location)
    end
  end

  @doc """
  Deactivate a location.
  """
  def deactivate(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location!(tenant, id)

    with {:ok, %Location{} = location} <- Locations.deactivate_location(tenant, location) do
      render(conn, :show, location: location)
    end
  end

  @doc """
  Get location with all assets.
  """
  def assets(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location_with_assets(tenant, id)
    render(conn, :assets, location: location)
  end

  @doc """
  Get location with all employees.
  """
  def employees(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    location = Locations.get_location_with_employees(tenant, id)
    render(conn, :employees, location: location)
  end

  # Private helpers

  defp build_filters(params) do
    []
    |> add_filter(:location_type, params["location_type"])
    |> add_filter(:status, params["status"])
    |> add_filter(:country, params["country"])
  end

  defp add_filter(filters, _key, nil), do: filters
  defp add_filter(filters, key, value), do: [{key, value} | filters]
end
