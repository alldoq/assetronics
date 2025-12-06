defmodule AssetronicsWeb.EmployeeController do
  use AssetronicsWeb, :controller

  alias Assetronics.Employees
  alias Assetronics.Employees.Employee
  alias Assetronics.Files

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all employees for the tenant.
  Includes organization, department, and location hierarchical data.
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params) ++ [preload: [:organization, :department_rel, :office_location, :assets]]
    employees = Employees.list_employees(tenant, opts)
    render(conn, :index, employees: employees)
  end

  @doc """
  Create a new employee.
  """
  def create(conn, %{"employee" => employee_params}) do
    tenant = conn.assigns[:tenant]

    # Handle photo upload if present
    employee_params = handle_photo_upload(tenant, employee_params, conn.assigns[:current_user])

    with {:ok, %Employee{} = employee} <- Employees.create_employee(tenant, employee_params) do
      # Reload with associations
      employee = Employees.get_employee!(tenant, employee.id, preload: [:organization, :department_rel, :office_location])

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/employees/#{employee.id}")
      |> render(:show, employee: employee)
    end
  end

  @doc """
  Get a single employee by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee!(tenant, id, preload: [:organization, :department_rel, :office_location])
    render(conn, :show, employee: employee)
  end

  @doc """
  Update an employee.
  """
  def update(conn, %{"id" => id, "employee" => employee_params}) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee!(tenant, id)

    # Handle photo upload if present
    employee_params = handle_photo_upload(tenant, employee_params, conn.assigns[:current_user])

    with {:ok, %Employee{} = employee} <- Employees.update_employee(tenant, employee, employee_params) do
      # Reload with associations
      employee = Employees.get_employee!(tenant, employee.id, preload: [:organization, :department_rel, :office_location])

      render(conn, :show, employee: employee)
    end
  end

  @doc """
  Delete an employee.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee!(tenant, id)

    with {:ok, %Employee{}} <- Employees.delete_employee(tenant, employee) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Terminate an employee.

  Request body:
  {
    "termination_date": "2024-01-15",
    "reason": "Resignation",
    "notes": "Two weeks notice provided"
  }
  """
  def terminate(conn, %{"id" => id} = params) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee!(tenant, id)
    termination_date = parse_date(params["termination_date"])
    reason = params["reason"]
    notes = params["notes"]

    with {:ok, %Employee{} = employee} <- Employees.terminate_employee(tenant, employee, termination_date, reason, notes) do
      render(conn, :show, employee: employee)
    end
  end

  @doc """
  Reactivate a terminated employee.
  """
  def reactivate(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee!(tenant, id)

    with {:ok, %Employee{} = employee} <- Employees.reactivate_employee(tenant, employee) do
      render(conn, :show, employee: employee)
    end
  end

  @doc """
  Get all assets assigned to an employee.
  """
  def assets(conn, %{"employee_id" => id}) do
    tenant = conn.assigns[:tenant]
    employee = Employees.get_employee_with_assets(tenant, id)
    render(conn, :assets, employee: employee)
  end

  # Private helpers

  defp handle_photo_upload(tenant, %{"photo" => upload} = params, current_user) do
    # Upload the file
    case Files.upload_file(tenant, upload, %{
      category: "avatar",
      uploaded_by_id: current_user.id,
      attachable_type: "Employee"
      # attachable_id will be linked later or ignored for now if we just want URL
    }) do
      {:ok, file} ->
        {:ok, url} = Files.get_file_url(file)
        
        # Update custom_fields.photo_url
        custom_fields = Map.get(params, "custom_fields", %{})
        updated_custom_fields = Map.put(custom_fields, "photo_url", url)
        
        params
        |> Map.put("custom_fields", updated_custom_fields)
        |> Map.delete("photo") # Remove the upload struct so changeset doesn't choke

      _ ->
        # If upload fails, just return params as is (or log error)
        params
    end
  end

  defp handle_photo_upload(_tenant, params, _user), do: params

  defp build_filters(params) do
    []
    |> add_filter(:status, params["status"])
    |> add_filter(:department, params["department"])
    |> add_filter(:job_title, params["job_title"])
  end

  defp add_filter(filters, _key, nil), do: filters
  defp add_filter(filters, key, value), do: [{key, value} | filters]

  defp parse_date(nil), do: Date.utc_today()
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> Date.utc_today()
    end
  end
  defp parse_date(date), do: date
end
