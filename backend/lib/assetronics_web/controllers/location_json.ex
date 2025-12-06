defmodule AssetronicsWeb.LocationJSON do
  alias Assetronics.Locations.Location

  @doc """
  Renders a list of locations.
  """
  def index(%{locations: locations}) do
    %{data: for(location <- locations, do: data(location))}
  end

  @doc """
  Renders a single location.
  """
  def show(%{location: location}) do
    %{data: data(location)}
  end

  @doc """
  Renders location with assets.
  """
  def assets(%{location: location}) do
    %{
      data: %{
        id: location.id,
        name: location.name,
        location_type: location.location_type,
        city: location.city,
        state_province: location.state_province,
        country: location.country,
        assets: render_assets(location.assets || [])
      }
    }
  end

  @doc """
  Renders location with employees.
  """
  def employees(%{location: location}) do
    %{
      data: %{
        id: location.id,
        name: location.name,
        location_type: location.location_type,
        city: location.city,
        state_province: location.state_province,
        country: location.country,
        employees: render_employees(location.employees || [])
      }
    }
  end

  defp data(%Location{} = location) do
    %{
      id: location.id,
      name: location.name,
      location_type: location.location_type,
      is_active: location.is_active,
      address_line1: location.address_line1,
      address_line2: location.address_line2,
      city: location.city,
      state_province: location.state_province,
      postal_code: location.postal_code,
      country: location.country,
      contact_name: location.contact_name,
      contact_email: location.contact_email,
      contact_phone: location.contact_phone,
      notes: location.notes,
      custom_fields: location.custom_fields,
      parent_id: location.parent_id,
      parent: parent_data(location.parent),
      children: children_data(location.children),
      inserted_at: location.inserted_at,
      updated_at: location.updated_at
    }
  end

  defp parent_data(%Ecto.Association.NotLoaded{}), do: nil
  defp parent_data(nil), do: nil

  defp parent_data(%Location{} = parent) do
    %{
      id: parent.id,
      name: parent.name,
      location_type: parent.location_type
    }
  end

  defp children_data(%Ecto.Association.NotLoaded{}), do: nil
  defp children_data(nil), do: nil
  defp children_data([]), do: []

  defp children_data(children) when is_list(children) do
    for child <- children do
      %{
        id: child.id,
        name: child.name,
        location_type: child.location_type
      }
    end
  end

  defp render_assets(assets) do
    Enum.map(assets, fn asset ->
      %{
        id: asset.id,
        asset_tag: asset.asset_tag,
        name: asset.name,
        category: asset.category,
        make: asset.make,
        model: asset.model,
        status: asset.status,
        condition: asset.condition
      }
    end)
  end

  defp render_employees(employees) do
    Enum.map(employees, fn employee ->
      %{
        id: employee.id,
        email: employee.email,
        first_name: employee.first_name,
        last_name: employee.last_name,
        job_title: employee.job_title,
        department: employee.department,
        employment_status: employee.employment_status
      }
    end)
  end
end
