defmodule AssetronicsWeb.SoftwareJSON do
  alias Assetronics.Software.License
  alias Assetronics.Software.Assignment

  @doc """
  Renders a list of software licenses.
  """
  def index(%{licenses: licenses}) do
    %{data: for(license <- licenses, do: data(license))}
  end

  @doc """
  Renders a single software license.
  """
  def show(%{license: license}) do
    %{data: data(license)}
  end

  @doc """
  Renders a software assignment.
  """
  def assignment(%{assignment: assignment}) do
    %{data: assignment_data(assignment)}
  end

  @doc """
  Renders a list of assignments.
  """
  def assignments(%{assignments: assignments}) do
    %{data: for(assignment <- assignments, do: assignment_data(assignment))}
  end

  @doc """
  Renders license statistics.
  """
  def stats(%{stats: stats}) do
    %{data: stats}
  end

  defp data(%License{} = license) do
    base_data = %{
      id: license.id,
      name: license.name,
      vendor: license.vendor,
      description: license.description,
      total_seats: license.total_seats,
      annual_cost: license.annual_cost,
      cost_per_seat: license.cost_per_seat,
      purchase_date: license.purchase_date,
      expiration_date: license.expiration_date,
      status: license.status,
      license_key: license.license_key,
      sso_app_id: license.sso_app_id,
      integration_id: license.integration_id,
      created_at: license.inserted_at,
      updated_at: license.updated_at
    }

    # Add assigned_count if it exists (set by controller)
    # Using Map.get to avoid typing warnings since this field is dynamically added
    case Map.get(license, :assigned_count) do
      nil -> base_data
      count -> Map.put(base_data, :assigned_count, count)
    end
  end

  defp assignment_data(%Assignment{} = assignment) do
    %{
      id: assignment.id,
      employee_id: assignment.employee_id,
      software_license_id: assignment.software_license_id,
      assigned_at: assignment.assigned_at,
      last_used_at: assignment.last_used_at,
      status: assignment.status,
      created_at: assignment.inserted_at,
      updated_at: assignment.updated_at
    }
    |> maybe_add_employee(assignment)
    |> maybe_add_license(assignment)
  end

  defp maybe_add_employee(data, %Assignment{employee: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_employee(data, %Assignment{employee: nil}), do: data
  defp maybe_add_employee(data, %Assignment{employee: employee}) do
    Map.put(data, :employee, %{
      id: employee.id,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email
    })
  end
  defp maybe_add_employee(data, _), do: data

  defp maybe_add_license(data, %Assignment{software_license: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_license(data, %Assignment{software_license: nil}), do: data
  defp maybe_add_license(data, %Assignment{software_license: license}) do
    Map.put(data, :software_license, %{
      id: license.id,
      name: license.name,
      vendor: license.vendor
    })
  end
  defp maybe_add_license(data, _), do: data
end
