defmodule Assetronics.Integrations.Adapters.Rippling do
  @moduledoc """
  Rippling integration adapter for syncing employee data.

  Rippling API Documentation: https://developer.rippling.com/documentation/rest-api

  Authentication: OAuth 2.0 (Bearer token) or API Key
  Base URL: https://api.rippling.com/platform/api/
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Employees
  alias Assetronics.Integrations.Integration
  alias Assetronics.Workflows
  alias Assetronics.Organizations
  alias Assetronics.Departments
  alias Assetronics.Locations

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    client = build_client(integration)

    # Test connection with employees endpoint
    Logger.info("Testing Rippling connection with /employees endpoint")

    case Tesla.get(client, "/employees") do
      {:ok, %Tesla.Env{status: 200}} ->
        Logger.info("Successfully connected to Rippling")
        {:ok, %{status: "connected", message: "Successfully connected to Rippling"}}

      {:ok, %Tesla.Env{status: 401, body: body}} ->
        Logger.error("Rippling connection unauthorized: #{inspect(body)}")
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403, body: body}} ->
        Logger.error("Rippling connection forbidden: #{inspect(body)}")
        {:error, :forbidden}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Rippling connection failed with status #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Rippling connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting Rippling sync for tenant: #{tenant}")

    client = build_client(integration)

    with {:ok, employees_data} <- fetch_employees(client),
         {:ok, sync_results} <- sync_employees(tenant, employees_data, integration) do
      Logger.info("Rippling sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("Rippling sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp build_client(%Integration{} = integration) do
    base_url = integration.base_url || "https://api.rippling.com/platform/api"

    Logger.info("Building Rippling client - Integration ID: #{integration.id}")
    Logger.info("Auth type: #{integration.auth_type}")

    # Determine authentication method
    # Rippling supports OAuth 2.0 (Bearer token) or API Key
    auth_header = cond do
      # OAuth 2.0 with access token
      integration.access_token && integration.access_token != "" ->
        Logger.info("Using OAuth access token for Rippling integration #{integration.id}")
        {"authorization", "Bearer #{integration.access_token}"}

      # API Key authentication
      integration.api_key && integration.api_key != "" ->
        Logger.info("Using API key authentication for Rippling integration #{integration.id}")
        {"authorization", "Bearer #{integration.api_key}"}

      # No valid credentials
      true ->
        Logger.error("No valid credentials found for Rippling integration #{integration.id}")
        Logger.error("Please provide either an OAuth access token or API key")
        {"authorization", "Invalid"}
    end

    Logger.info("Rippling API base URL: #{base_url}")

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"accept", "application/json"},
        {"content-type", "application/json"},
        auth_header
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 60_000}
    ]

    Tesla.client(middleware)
  end

  defp fetch_employees(client) do
    # Use the include_terminated endpoint to get all employees
    Logger.info("Fetching Rippling employees (including terminated)...")

    case Tesla.get(client, "/employees/include_terminated") do
      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) ->
        Logger.info("Fetched #{length(body)} employees from Rippling")
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: %{"data" => employees}}} when is_list(employees) ->
        Logger.info("Fetched #{length(employees)} employees from Rippling")
        {:ok, employees}

      {:ok, %Tesla.Env{status: 200, body: %{"employees" => employees}}} when is_list(employees) ->
        Logger.info("Fetched #{length(employees)} employees from Rippling")
        {:ok, employees}

      {:ok, %Tesla.Env{status: 200, body: body}} when is_map(body) ->
        # Single employee or unexpected format
        Logger.warning("Unexpected response format from Rippling: #{inspect(body)}")
        {:ok, [body]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Rippling fetch employees failed: #{status} - #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Failed to fetch employees from Rippling: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_employees(tenant, employees_data, integration) do
    # Debug: Log the first employee to check field names
    if List.first(employees_data) do
      Logger.info("Sample Rippling employee data: #{inspect(List.first(employees_data))}")
    end

    results = %{
      total: length(employees_data),
      created: 0,
      updated: 0,
      terminated: 0,
      errors: 0,
      workflows_created: 0
    }

    employees_data
    |> Enum.reduce(results, fn employee_data, acc ->
      case sync_employee(tenant, employee_data, integration) do
        {:ok, :created, workflow_created?} ->
          acc
          |> Map.update!(:created, &(&1 + 1))
          |> maybe_increment_workflows(workflow_created?)

        {:ok, :updated, workflow_created?} ->
          acc
          |> Map.update!(:updated, &(&1 + 1))
          |> maybe_increment_workflows(workflow_created?)

        {:ok, :terminated, _} ->
          Map.update!(acc, :terminated, &(&1 + 1))

        {:error, _reason} ->
          Map.update!(acc, :errors, &(&1 + 1))
      end
    end)
    |> then(&{:ok, &1})
  end

  defp sync_employee(tenant, employee_data, integration) do
    attrs = map_employee_attrs(tenant, employee_data)

    # Rippling typically uses "id" as the unique identifier
    hris_id = to_string(employee_data["id"] || employee_data["employee_id"])

    # Check employment status
    status = employee_data["employment_status"] || employee_data["status"]
    termination_date = parse_date(employee_data["termination_date"] || employee_data["terminationDate"])
    is_terminated = status in ["Terminated", "Inactive", "terminated", "inactive"] || !is_nil(termination_date)

    Logger.debug("Syncing employee #{hris_id} (#{attrs[:email]}). Status: #{status}. Terminated: #{is_terminated}")

    case Employees.sync_employee_from_hris(tenant, attrs) do
      {:ok, employee} ->
        workflow_created? = maybe_create_workflow(tenant, employee, employee_data, integration)

        # Handle termination if needed
        action = cond do
          is_terminated && employee.employment_status == "active" ->
            terminate_employee(tenant, employee, termination_date)
            :terminated

          true ->
            if employee.inserted_at == employee.updated_at, do: :created, else: :updated
        end

        {:ok, action, workflow_created?}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        Logger.error("Validation failed for employee #{hris_id}: #{inspect(errors)}")
        {:error, :validation_failed}

      {:error, reason} ->
        Logger.error("Failed to sync Rippling employee #{hris_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp map_employee_attrs(tenant, employee_data) do
    # Build address from available fields
    address = %{
      street1: get_value(employee_data, "address_line_1") || get_value(employee_data, "address1"),
      street2: get_value(employee_data, "address_line_2") || get_value(employee_data, "address2"),
      city: get_value(employee_data, "city"),
      state: get_value(employee_data, "state"),
      zip: get_value(employee_data, "zip_code") || get_value(employee_data, "zipcode"),
      country: get_value(employee_data, "country")
    } |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()

    # Custom fields for additional data
    custom_fields = %{
      "employee_number" => get_value(employee_data, "employee_number") || get_value(employee_data, "employeeNumber"),
      "gender" => get_value(employee_data, "gender"),
      "marital_status" => get_value(employee_data, "marital_status"),
      "work_type" => get_value(employee_data, "work_type"),
      "pay_schedule" => get_value(employee_data, "pay_schedule")
    } |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()

    # Resolve hierarchical references
    organization_id = resolve_organization(tenant, get_value(employee_data, "division") || get_value(employee_data, "company"))
    department_id = resolve_department(tenant, get_value(employee_data, "department"))
    office_location_id = resolve_location(tenant, get_value(employee_data, "work_location") || get_value(employee_data, "location"))

    %{
      hris_id: to_string(employee_data["id"] || employee_data["employee_id"]),
      email: get_value(employee_data, "work_email") || get_value(employee_data, "email") || get_value(employee_data, "personal_email"),
      first_name: get_value(employee_data, "first_name") || get_value(employee_data, "firstName"),
      last_name: get_value(employee_data, "last_name") || get_value(employee_data, "lastName"),
      phone: get_value(employee_data, "work_phone") || get_value(employee_data, "phone") || get_value(employee_data, "mobile_phone"),
      job_title: get_value(employee_data, "job_title") || get_value(employee_data, "title"),
      department: get_value(employee_data, "department"),
      division: get_value(employee_data, "division") || get_value(employee_data, "company"),
      work_location: get_value(employee_data, "work_location") || get_value(employee_data, "location"),

      # Hierarchical foreign keys
      organization_id: organization_id,
      department_id: department_id,
      office_location_id: office_location_id,

      manager_email: get_value(employee_data, "manager_email") || get_value(employee_data, "supervisor_email"),
      hire_date: parse_date(employee_data["hire_date"] || employee_data["start_date"] || employee_data["hireDate"]),
      employment_status: map_employment_status(employee_data),

      # Sensitive PII
      date_of_birth: get_value(employee_data, "date_of_birth") || get_value(employee_data, "dob"),
      ssn: get_value(employee_data, "ssn") || get_value(employee_data, "social_security_number"),
      home_address: if(map_size(address) > 0, do: address, else: nil),

      # Metadata
      custom_fields: custom_fields,

      sync_enabled: true,
      sync_source: "rippling"
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  # Resolver functions for hierarchical references

  defp resolve_organization(_tenant, nil), do: nil
  defp resolve_organization(_tenant, ""), do: nil
  defp resolve_organization(tenant, division_name) do
    case Organizations.get_organization_by_name(tenant, division_name) do
      {:ok, organization} ->
        Logger.debug("Found existing organization: #{division_name} (ID: #{organization.id})")
        organization.id

      {:error, :not_found} ->
        Logger.info("Creating new organization from Rippling: #{division_name}")
        case Organizations.create_organization(tenant, %{
          name: division_name,
          type: "division",
          description: "Auto-created from Rippling sync"
        }) do
          {:ok, organization} ->
            Logger.info("Created organization: #{division_name} (ID: #{organization.id})")
            organization.id

          {:error, reason} ->
            Logger.error("Failed to create organization '#{division_name}': #{inspect(reason)}")
            nil
        end
    end
  end

  defp resolve_department(_tenant, nil), do: nil
  defp resolve_department(_tenant, ""), do: nil
  defp resolve_department(tenant, department_name) do
    case Departments.get_department_by_name(tenant, department_name) do
      {:ok, department} ->
        Logger.debug("Found existing department: #{department_name} (ID: #{department.id})")
        department.id

      {:error, :not_found} ->
        Logger.info("Creating new department from Rippling: #{department_name}")
        case Departments.create_department(tenant, %{
          name: department_name,
          type: "department",
          description: "Auto-created from Rippling sync"
        }) do
          {:ok, department} ->
            Logger.info("Created department: #{department_name} (ID: #{department.id})")
            department.id

          {:error, reason} ->
            Logger.error("Failed to create department '#{department_name}': #{inspect(reason)}")
            nil
        end
    end
  end

  defp resolve_location(_tenant, nil), do: nil
  defp resolve_location(_tenant, ""), do: nil
  defp resolve_location(tenant, location_name) do
    case Locations.get_location_by_name(tenant, location_name) do
      {:ok, location} ->
        Logger.debug("Found existing location: #{location_name} (ID: #{location.id})")
        location.id

      {:error, :not_found} ->
        Logger.info("Creating new location from Rippling: #{location_name}")
        case Locations.create_location(tenant, %{
          name: location_name,
          location_type: "office",
          description: "Auto-created from Rippling sync"
        }) do
          {:ok, location} ->
            Logger.info("Created location: #{location_name} (ID: #{location.id})")
            location.id

          {:error, reason} ->
            Logger.error("Failed to create location '#{location_name}': #{inspect(reason)}")
            nil
        end
    end
  end

  defp get_value(data, key) do
    case data[key] do
      nil -> nil
      "" -> nil
      "null" -> nil
      val when is_binary(val) -> String.trim(val)
      val -> val
    end
  end

  defp map_employment_status(employee_data) do
    status = employee_data["employment_status"] || employee_data["status"]

    case String.downcase(to_string(status || "")) do
      s when s in ["active", "full-time", "part-time", "full time", "part time"] -> "active"
      s when s in ["terminated", "inactive"] -> "terminated"
      s when s in ["on_leave", "leave", "on leave"] -> "on_leave"
      _ -> "active"
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date("0000-00-00"), do: nil
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
  defp parse_date(_), do: nil

  defp terminate_employee(tenant, employee, termination_date) do
    date = termination_date || Date.utc_today()
    Employees.terminate_employee(tenant, employee, date, "Synced from Rippling", nil)
  end

  defp maybe_create_workflow(tenant, employee, employee_data, integration) do
    hire_date = parse_date(employee_data["hire_date"] || employee_data["start_date"] || employee_data["hireDate"])
    today = Date.utc_today()

    if hire_date do
      diff = Date.diff(today, hire_date)

      Logger.debug("Checking workflow for #{employee.email}: Hire Date #{hire_date}, Today #{today}, Diff #{diff} days")
      if diff <= 30 do
        Logger.info("Creating onboarding workflow for #{employee.email} (Hired: #{hire_date})")
        case Workflows.create_onboarding_workflow(tenant, employee, nil,
              triggered_by: "hris_sync",
              integration_id: integration.id) do
          {:ok, _workflow} -> true
          {:error, reason} ->
            Logger.error("Failed to create workflow: #{inspect(reason)}")
            false
        end
      else
        Logger.debug("Skipping workflow: Hire date #{hire_date} is too old (> 30 days ago)")
        false
      end
    else
      Logger.debug("Skipping workflow: No hire date found")
      false
    end
  end

  defp maybe_increment_workflows(acc, true), do: Map.update!(acc, :workflows_created, &(&1 + 1))
  defp maybe_increment_workflows(acc, false), do: acc
end
