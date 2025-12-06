defmodule Assetronics.Integrations.Adapters.BambooHR do
  @moduledoc """
  BambooHR integration adapter for syncing employee data.

  BambooHR API Documentation: https://documentation.bamboohr.com/docs

  Authentication: API Key (Basic Auth with x-api-key header)
  Base URL: https://api.bamboohr.com/api/gateway.php/{subdomain}/v1/
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Employees
  alias Assetronics.Integrations.Integration
  alias Assetronics.Workflows
  alias Assetronics.Files
  alias Assetronics.Organizations
  alias Assetronics.Departments
  alias Assetronics.Locations

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    client = build_client(integration)

    # Try the meta/users endpoint which should be accessible with basic OAuth
    Logger.info("Testing BambooHR connection with /meta/users endpoint")

    case Tesla.get(client, "/meta/users") do
      {:ok, %Tesla.Env{status: 200}} ->
        Logger.info("Successfully connected to BambooHR via OAuth")
        {:ok, %{status: "connected", message: "Successfully connected to BambooHR"}}

      {:ok, %Tesla.Env{status: 401, body: body}} ->
        Logger.error("BambooHR connection unauthorized: #{inspect(body)}")
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403, body: body}} ->
        Logger.error("BambooHR connection forbidden: #{inspect(body)}")
        {:error, :forbidden}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("BambooHR connection failed with status #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("BambooHR connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting BambooHR sync for tenant: #{tenant}")

    client = build_client(integration)

    with {:ok, employees_data} <- fetch_employees(client),
         {:ok, sync_results} <- sync_employees(tenant, employees_data, integration) do
      Logger.info("BambooHR sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("BambooHR sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp build_client(%Integration{} = integration) do
    # BambooHR API uses company-specific domain
    # Format: https://{companyDomain}.bamboohr.com/api/v1/
    subdomain = get_subdomain(integration)
    base_url = "https://#{subdomain}.bamboohr.com/api/v1"

    Logger.info("Building BambooHR client - Integration ID: #{integration.id}")
    Logger.info("Auth type: #{integration.auth_type}")

    # Determine authentication method
    # Priority: API Key > OAuth Access Token
    # BambooHR OAuth may be for identity only, while API keys provide full API access
    auth_header = cond do
      # Prefer API key if available (more reliable for API access)
      integration.api_key && integration.api_key != "" ->
        Logger.info("Using API key authentication for BambooHR integration #{integration.id}")
        Logger.debug("API key (first 10 chars): #{String.slice(integration.api_key, 0, 10)}...")
        # BambooHR API key format: API_KEY:x (key as username, 'x' as password)
        {"authorization", "Basic #{Base.encode64("#{integration.api_key}:x")}"}

      # Fall back to OAuth access token
      integration.access_token && integration.access_token != "" ->
        Logger.info("Using OAuth access token for BambooHR integration #{integration.id}")
        Logger.debug("Access token (first 10 chars): #{String.slice(integration.access_token, 0, 10)}...")
        Logger.warning("Note: BambooHR OAuth may not grant API data access. Consider using API key instead.")
        {"authorization", "Bearer #{integration.access_token}"}

      # No valid credentials
      true ->
        Logger.error("No valid credentials found for BambooHR integration #{integration.id}")
        Logger.error("Please provide either an API key (recommended) or complete OAuth flow")
        {"authorization", "Invalid"}
    end

    Logger.info("BambooHR API base URL: #{base_url}")

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"accept", "application/json"},
        auth_header
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]

    Tesla.client(middleware)
  end

  defp get_subdomain(%Integration{} = integration) do
    # Extract subdomain from base_url (e.g., https://trial1bcb4c20.bamboohr.com/)
    # or from auth_config
    cond do
      integration.auth_config && integration.auth_config["subdomain"] ->
        integration.auth_config["subdomain"]

      integration.base_url ->
        # Extract subdomain from URL like https://trial1bcb4c20.bamboohr.com/
        integration.base_url
        |> String.replace("https://", "")
        |> String.replace("http://", "")
        |> String.split(".")
        |> List.first()

      true ->
        Logger.error("No subdomain found for BambooHR integration #{integration.id}")
        "unknown"
    end
  end

  defp fetch_employees(client) do
    # 1. Fetch detailed data using Custom Report API
    # This provides critical fields like hireDate, status, email, PII
    report_endpoint = "/reports/custom?format=json"
    
    report_fields = [
      "id", "employeeNumber", "firstName", "lastName", 
      "workEmail", "email", "jobTitle", "department", "division", "location", 
      "supervisorEmail", "hireDate", "terminationDate", "employmentStatus", 
      "mobilePhone", "workPhone", "dateOfBirth", "ssn", "gender", 
      "maritalStatus", "address1", "address2", "city", "state", "zipcode", "country"
    ]

    report_body = %{"title" => "Assetronics Sync", "fields" => report_fields}

    Logger.info("Fetching BambooHR employees details (Custom Report)...")
    
    with {:ok, report_data} <- post_request(client, report_endpoint, report_body),
         # 2. Fetch basic data (including photos) using Directory API
         # Photos are often only available here or require specific permissions in reports
         {:ok, directory_data} <- get_request(client, "/employees/directory") do
      
      Logger.info("Fetched #{length(report_data)} detailed records and #{length(directory_data)} directory records")
      
      # 3. Merge data
      # Create a map of directory data keyed by ID for O(1) lookup
      dir_map = Map.new(directory_data, fn emp -> {to_string(emp["id"]), emp} end)
      
      merged_data = Enum.map(report_data, fn emp ->
        id = to_string(emp["id"])
        dir_emp = Map.get(dir_map, id, %{})

        # Merge, preferring report data but filling gaps (like photoUrl) from directory
        merged = Map.merge(dir_emp, emp)

        # Preserve photoUrl from directory if report doesn't have a valid value
        photo_url = case merged["photoUrl"] do
          url when url in [nil, "", "null"] -> dir_emp["photoUrl"]
          url -> url
        end

        Map.put(merged, "photoUrl", photo_url)
      end)
      
      {:ok, merged_data}
    else
      error -> error
    end
  end

  defp post_request(client, endpoint, body) do
    case Tesla.post(client, endpoint, body) do
      {:ok, %Tesla.Env{status: 200, body: %{"employees" => employees}}} -> {:ok, employees}
      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) -> {:ok, body}
      {:ok, %Tesla.Env{status: status, body: body}} -> 
        Logger.error("BambooHR POST #{endpoint} failed: #{status}")
        {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_request(client, endpoint) do
    case Tesla.get(client, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: %{"employees" => employees}}} -> {:ok, employees}
      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) -> {:ok, body}
      {:ok, %Tesla.Env{status: status, body: body}} -> 
        Logger.error("BambooHR GET #{endpoint} failed: #{status}")
        {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp sync_employees(tenant, employees_data, integration) do
    # Debug: Log the first employee to check field names
    if List.first(employees_data) do
      Logger.info("Sample BambooHR employee data: #{inspect(List.first(employees_data))}")
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
    hris_id = to_string(employee_data["id"])

    # Check if employee should be terminated
    # Parse date first to handle "0000-00-00" as nil
    termination_date = parse_date(employee_data["terminationDate"])
    status = employee_data["employmentStatus"] || employee_data["status"]
    is_terminated = status in ["Terminated", "Inactive"] || !is_nil(termination_date)

    Logger.debug("Syncing employee #{hris_id} (#{attrs[:email]}). Status: #{status}. Terminated: #{is_terminated}")

    case Employees.sync_employee_from_hris(tenant, attrs) do
      {:ok, employee} ->
        # Download and store employee photo if available
        download_and_store_photo(tenant, employee, employee_data, integration)

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
        Logger.error("Failed to sync employee #{hris_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp download_and_store_photo(tenant, employee, employee_data, integration) do
    photo_url = get_value(employee_data, "photoUrl")

    # Skip if no photo URL
    # Skip if photo is already a local path (starts with /api/ or /uploads/)
    cond do
      is_nil(photo_url) ->
        :skip

      String.contains?(photo_url, "/api/") || String.contains?(photo_url, "/uploads/") ->
        Logger.debug("Photo already stored locally for #{employee.email}")
        :skip

      true ->
        # BambooHR photoUrl can be relative or absolute
        photo_url = if String.starts_with?(photo_url, "http") do
          photo_url
        else
          # Make relative URL absolute
          subdomain = get_subdomain(integration)
          "https://#{subdomain}.bamboohr.com#{photo_url}"
        end

        Logger.info("Downloading employee photo for #{employee.email} from #{photo_url}")

        # Use a simple HTTP client without API auth for CloudFront-signed image URLs
        # CloudFront URLs are already signed and don't need API authentication
        image_client = Tesla.client([
          {Tesla.Middleware.Timeout, timeout: 30_000}
        ])

        case Tesla.get(image_client, photo_url) do
          {:ok, %Tesla.Env{status: 200, body: image_data, headers: headers}} ->
            # Get content type from headers
            content_type = Enum.find_value(headers, "image/jpeg", fn
              {"content-type", val} -> val
              _ -> nil
            end)

            # Determine file extension from content type
            ext = case content_type do
              "image/png" -> "png"
              "image/jpeg" -> "jpg"
              "image/jpg" -> "jpg"
              "image/gif" -> "gif"
              _ -> "jpg"
            end

            # Save to temporary file
            temp_path = Path.join(System.tmp_dir!(), "bamboo_photo_#{employee.id}_#{:rand.uniform(100000)}.#{ext}")
            File.write!(temp_path, image_data)

            # Upload to our file storage
            upload_attrs = %{
              category: "avatar",
              original_filename: "#{employee.first_name}_#{employee.last_name}.#{ext}",
              content_type: content_type,
              uploaded_by_id: nil, # System upload
              attachable_type: "Employee",
              attachable_id: employee.id
            }

            case Files.upload_file(tenant, temp_path, upload_attrs) do
              {:ok, file} ->
                # Get the file URL
                {:ok, url} = Files.get_file_url(file)

                # Update employee with local photo URL
                custom_fields = employee.custom_fields || %{}
                updated_custom_fields = Map.put(custom_fields, "photo_url", url)

                Employees.update_employee(tenant, employee, %{custom_fields: updated_custom_fields})

                # Clean up temp file
                File.rm(temp_path)
                Logger.info("Successfully stored employee photo for #{employee.email}")
                :ok

              {:error, reason} ->
                Logger.error("Failed to upload photo for #{employee.email}: #{inspect(reason)}")
                File.rm(temp_path)
                :error
            end

          {:ok, %Tesla.Env{status: status}} ->
            Logger.warning("Failed to download photo for #{employee.email}: HTTP #{status}")
            :error

          {:error, reason} ->
            Logger.error("Failed to download photo for #{employee.email}: #{inspect(reason)}")
            :error
        end
    end
  end

  defp map_employee_attrs(tenant, employee_data) do
    address = %{
      street1: get_value(employee_data, "address1"),
      street2: get_value(employee_data, "address2"),
      city: get_value(employee_data, "city"),
      state: get_value(employee_data, "state"),
      zip: get_value(employee_data, "zipcode"),
      country: get_value(employee_data, "country")
    } |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()

    custom_fields = %{
      "gender" => get_value(employee_data, "gender"),
      "marital_status" => get_value(employee_data, "maritalStatus"),
      "employee_number" => get_value(employee_data, "employeeNumber"),
      "photo_url" => get_value(employee_data, "photoUrl")
    } |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()

    # Resolve hierarchical references from BambooHR text fields
    organization_id = resolve_organization(tenant, get_value(employee_data, "division"))
    department_id = resolve_department(tenant, get_value(employee_data, "department"))
    office_location_id = resolve_location(tenant, get_value(employee_data, "location"))

    %{
      hris_id: to_string(employee_data["id"]),
      # Custom report guarantees requested fields, usually maps workEmail correctly
      email: get_value(employee_data, "workEmail") || get_value(employee_data, "email"),
      first_name: get_value(employee_data, "firstName"),
      last_name: get_value(employee_data, "lastName"),
      phone: get_value(employee_data, "workPhone") || get_value(employee_data, "mobilePhone"),
      job_title: get_value(employee_data, "jobTitle"),
      department: get_value(employee_data, "department"), # Legacy field - keep for compatibility
      division: get_value(employee_data, "division"),
      work_location: get_value(employee_data, "location"),

      # Hierarchical foreign keys
      organization_id: organization_id,
      department_id: department_id,
      office_location_id: office_location_id,

      manager_email: get_value(employee_data, "supervisorEmail"),
      hire_date: parse_date(employee_data["hireDate"]),
      employment_status: map_employment_status(employee_data),

      # Sensitive PII
      date_of_birth: get_value(employee_data, "dateOfBirth"), # Encrypted string
      ssn: get_value(employee_data, "ssn"), # Encrypted string
      home_address: if(map_size(address) > 0, do: address, else: nil), # Encrypted map

      # Metadata
      custom_fields: custom_fields,

      sync_enabled: true,
      sync_source: "bamboohr"
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  # Resolver functions for hierarchical references
  # These find or create organizations, departments, and locations based on BambooHR text fields

  # Resolves an organization by division name.
  # Creates a new organization if it doesn't exist.
  defp resolve_organization(_tenant, nil), do: nil
  defp resolve_organization(_tenant, ""), do: nil
  defp resolve_organization(tenant, division_name) do
    case Organizations.get_organization_by_name(tenant, division_name) do
      {:ok, organization} ->
        Logger.debug("Found existing organization: #{division_name} (ID: #{organization.id})")
        organization.id

      {:error, :not_found} ->
        Logger.info("Creating new organization from BambooHR: #{division_name}")
        case Organizations.create_organization(tenant, %{
          name: division_name,
          type: "division",
          description: "Auto-created from BambooHR sync"
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

  # Resolves a department by department name.
  # Creates a new department if it doesn't exist.
  defp resolve_department(_tenant, nil), do: nil
  defp resolve_department(_tenant, ""), do: nil
  defp resolve_department(tenant, department_name) do
    case Departments.get_department_by_name(tenant, department_name) do
      {:ok, department} ->
        Logger.debug("Found existing department: #{department_name} (ID: #{department.id})")
        department.id

      {:error, :not_found} ->
        Logger.info("Creating new department from BambooHR: #{department_name}")
        case Departments.create_department(tenant, %{
          name: department_name,
          type: "department",
          description: "Auto-created from BambooHR sync"
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

  # Resolves a location by location name.
  # Creates a new location if it doesn't exist.
  defp resolve_location(_tenant, nil), do: nil
  defp resolve_location(_tenant, ""), do: nil
  defp resolve_location(tenant, location_name) do
    case Locations.get_location_by_name(tenant, location_name) do
      {:ok, location} ->
        Logger.debug("Found existing location: #{location_name} (ID: #{location.id})")
        location.id

      {:error, :not_found} ->
        Logger.info("Creating new location from BambooHR: #{location_name}")
        case Locations.create_location(tenant, %{
          name: location_name,
          location_type: "office",
          description: "Auto-created from BambooHR sync"
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
      val -> String.trim(val)
    end
  end

  defp map_employment_status(employee_data) do
    status = employee_data["employmentStatus"] || employee_data["status"]

    case String.downcase(status || "") do
      s when s in ["active", "full-time", "part-time"] -> "active"
      s when s in ["terminated", "inactive"] -> "terminated"
      s when s in ["on_leave", "leave"] -> "on_leave"
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
    Employees.terminate_employee(tenant, employee, date, "Synced from BambooHR", nil)
  end

  defp maybe_create_workflow(tenant, employee, employee_data, integration) do
    # Create onboarding workflow for new hires
    hire_date = parse_date(employee_data["hireDate"])
    today = Date.utc_today()

    if hire_date do
      diff = Date.diff(today, hire_date)
      
      Logger.debug("Checking workflow for #{employee.email}: Hire Date #{hire_date}, Today #{today}, Diff #{diff} days")

      # Only create workflow if hired in last 30 days (or future)
      # Logic: if diff <= 30 means hire_date is within last 30 days OR in the future (diff is negative)
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
