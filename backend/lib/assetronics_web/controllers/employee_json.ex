defmodule AssetronicsWeb.EmployeeJSON do
  alias Assetronics.Employees.Employee

  @doc """
  Renders a list of employees.
  """
  def index(%{employees: employees}) do
    %{data: for(employee <- employees, do: data(employee))}
  end

  @doc """
  Renders a single employee.
  """
  def show(%{employee: employee}) do
    %{data: data(employee)}
  end

  @doc """
  Renders employee with assets.
  """
  def assets(%{employee: employee}) do
    %{
      data: %{
        id: employee.id,
        email: employee.email,
        first_name: employee.first_name,
        last_name: employee.last_name,
        assets: render_assets(employee.assets || [])
      }
    }
  end

  defp data(%Employee{} = employee) do
    %{
      id: employee.id,
      employee_id: employee.employee_id,
      hris_id: employee.hris_id,
      email: employee.email,
      first_name: employee.first_name,
      last_name: employee.last_name,
      phone: employee.phone,
      job_title: employee.job_title,
      department: employee.department,  # Legacy field
      organization_id: employee.organization_id,
      department_id: employee.department_id,
      employment_status: employee.employment_status,
      hire_date: employee.hire_date,
      termination_date: employee.termination_date,
      termination_reason: get_in(employee.custom_fields, ["termination_reason"]),
      photo_url: get_in(employee.custom_fields, ["photo_url"]),
      custom_fields: employee.custom_fields || %{},
      manager_id: employee.manager_id,
      work_location_type: employee.work_location_type,
      is_remote: employee.work_location_type == "remote",
      sync_source: employee.sync_source,
      last_synced_at: employee.last_synced_at,
      inserted_at: employee.inserted_at,
      updated_at: employee.updated_at
    }
    |> maybe_add_home_address(employee)
    |> maybe_add_organization(employee)
    |> maybe_add_department(employee)
    |> maybe_add_location(employee)
    |> maybe_add_assets(employee)
  end

  defp maybe_add_home_address(data, %Employee{home_address: nil}), do: data
  defp maybe_add_home_address(data, %Employee{home_address: address}) when is_map(address) do
    Map.put(data, :home_address, address)
  end
  defp maybe_add_home_address(data, _), do: data

  defp maybe_add_organization(data, %Employee{organization: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_organization(data, %Employee{organization: nil}), do: data
  defp maybe_add_organization(data, %Employee{organization: organization}) do
    Map.put(data, :organization, %{
      id: organization.id,
      name: organization.name,
      type: organization.type,
      parent_id: organization.parent_id
    })
  end
  defp maybe_add_organization(data, _), do: data

  defp maybe_add_department(data, %Employee{department_rel: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_department(data, %Employee{department_rel: nil}), do: data
  defp maybe_add_department(data, %Employee{department_rel: department}) do
    Map.put(data, :department_info, %{
      id: department.id,
      name: department.name,
      type: department.type,
      parent_id: department.parent_id
    })
  end
  defp maybe_add_department(data, _), do: data

  defp maybe_add_location(data, %Employee{office_location: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_location(data, %Employee{office_location: nil}), do: data
  defp maybe_add_location(data, %Employee{office_location: location}) do
    Map.put(data, :office_location, %{
      id: location.id,
      name: location.name,
      location_type: location.location_type,
      parent_id: location.parent_id,
      city: location.city,
      state_province: location.state_province,
      country: location.country
    })
  end
  defp maybe_add_location(data, _), do: data

  defp maybe_add_assets(data, %Employee{assets: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_assets(data, %Employee{assets: nil}), do: data
  defp maybe_add_assets(data, %Employee{assets: assets}) when is_list(assets) do
    data
    |> Map.put(:assets, render_assets(assets))
    |> Map.put(:assets_count, length(assets))
  end
  defp maybe_add_assets(data, _), do: data

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
        condition: asset.condition,
        assigned_at: asset.assigned_at
      }
    end)
  end
end
