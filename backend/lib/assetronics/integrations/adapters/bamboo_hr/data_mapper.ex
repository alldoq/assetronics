defmodule Assetronics.Integrations.Adapters.BambooHR.DataMapper do
  @moduledoc """
  Handles data transformation between BambooHR and Assetronics formats.

  Maps employee attributes, employment status, dates, and custom fields
  from BambooHR's format to Assetronics' internal format.
  """

  alias Assetronics.Integrations.Adapters.BambooHR.Resolvers

  require Logger

  @doc """
  Maps BambooHR employee data to Assetronics employee attributes.
  """
  def map_employee_attrs(tenant, employee_data) do
    address = build_address(employee_data)
    custom_fields = build_custom_fields(employee_data)

    # Resolve hierarchical references from BambooHR text fields
    organization_id = Resolvers.resolve_organization(tenant, get_value(employee_data, "division"))
    department_id = Resolvers.resolve_department(tenant, get_value(employee_data, "department"))
    office_location_id = Resolvers.resolve_location(tenant, get_value(employee_data, "location"))

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

  @doc """
  Determines if an employee should be considered terminated.
  """
  def is_terminated?(employee_data) do
    termination_date = parse_date(employee_data["terminationDate"])
    status = employee_data["employmentStatus"] || employee_data["status"]
    status in ["Terminated", "Inactive"] || !is_nil(termination_date)
  end

  @doc """
  Maps employment status from BambooHR format to Assetronics format.
  """
  def map_employment_status(employee_data) do
    status = employee_data["employmentStatus"] || employee_data["status"]

    case String.downcase(status || "") do
      s when s in ["active", "full-time", "part-time"] -> "active"
      s when s in ["terminated", "inactive"] -> "terminated"
      s when s in ["on_leave", "leave"] -> "on_leave"
      _ -> "active"
    end
  end

  @doc """
  Parses date string from BambooHR format.
  """
  def parse_date(nil), do: nil
  def parse_date("0000-00-00"), do: nil
  def parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
  def parse_date(_), do: nil

  @doc """
  Extracts and cleans a value from employee data.
  """
  def get_value(data, key) do
    case data[key] do
      nil -> nil
      "" -> nil
      "null" -> nil
      val -> String.trim(val)
    end
  end

  @doc """
  Determines file extension from content type.
  """
  def get_file_extension(content_type) do
    case content_type do
      "image/png" -> "png"
      "image/jpeg" -> "jpg"
      "image/jpg" -> "jpg"
      "image/gif" -> "gif"
      _ -> "jpg"
    end
  end

  # Private functions

  defp build_address(employee_data) do
    %{
      street1: get_value(employee_data, "address1"),
      street2: get_value(employee_data, "address2"),
      city: get_value(employee_data, "city"),
      state: get_value(employee_data, "state"),
      zip: get_value(employee_data, "zipcode"),
      country: get_value(employee_data, "country")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp build_custom_fields(employee_data) do
    %{
      "gender" => get_value(employee_data, "gender"),
      "marital_status" => get_value(employee_data, "maritalStatus"),
      "employee_number" => get_value(employee_data, "employeeNumber"),
      "photo_url" => get_value(employee_data, "photoUrl")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end