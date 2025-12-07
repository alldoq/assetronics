defmodule Assetronics.Integrations.Adapters.Okta.DataMapper do
  @moduledoc """
  Handles data transformation between Okta and Assetronics formats.

  Maps user attributes, status, dates, and custom fields
  from Okta's format to Assetronics' internal format.
  """

  alias Assetronics.Integrations.Adapters.Okta.Resolvers

  require Logger

  @doc """
  Maps Okta user data to Assetronics employee attributes.

  Okta user structure:
  {
    "id": "00u...",
    "status": "ACTIVE",
    "profile": {
      "firstName": "John",
      "lastName": "Doe",
      "email": "john.doe@example.com",
      "login": "john.doe@example.com",
      "mobilePhone": "+1-555-123-4567",
      "employeeNumber": "12345",
      "department": "Engineering",
      "division": "Technology",
      "title": "Software Engineer",
      "manager": "Jane Smith",
      "managerId": "00u...",
      ...
    },
    "created": "2024-01-15T10:30:00.000Z",
    "activated": "2024-01-15T11:00:00.000Z"
  }
  """
  def map_employee_attrs(tenant, user_data) do
    profile = user_data["profile"] || %{}

    address = build_address(profile)
    custom_fields = build_custom_fields(user_data, profile)

    # Resolve hierarchical references from Okta profile fields
    organization_id = Resolvers.resolve_organization(tenant, get_value(profile, "division"))
    department_id = Resolvers.resolve_department(tenant, get_value(profile, "department"))
    office_location_id = Resolvers.resolve_location(tenant, get_value(profile, "office") || get_value(profile, "location"))

    %{
      hris_id: to_string(user_data["id"]),
      email: get_value(profile, "email") || get_value(profile, "login"),
      first_name: get_value(profile, "firstName"),
      last_name: get_value(profile, "lastName"),
      phone: get_value(profile, "mobilePhone") || get_value(profile, "primaryPhone"),
      job_title: get_value(profile, "title"),
      department: get_value(profile, "department"),
      division: get_value(profile, "division"),
      work_location: get_value(profile, "office") || get_value(profile, "location"),

      # Hierarchical foreign keys
      organization_id: organization_id,
      department_id: department_id,
      office_location_id: office_location_id,

      # Manager info - Okta can have manager email or managerId
      manager_email: get_value(profile, "manager"),
      hire_date: parse_date(get_value(profile, "hireDate") || user_data["activated"]),
      employment_status: map_employment_status(user_data),

      # Sensitive PII
      date_of_birth: get_value(profile, "dateOfBirth"),
      ssn: get_value(profile, "ssn"),
      home_address: if(map_size(address) > 0, do: address, else: nil),

      # Metadata
      custom_fields: custom_fields,

      sync_enabled: true,
      sync_source: "okta"
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc """
  Determines if a user should be considered terminated/deactivated.

  Okta user statuses:
  - ACTIVE: User is active
  - DEPROVISIONED: User has been deactivated (terminated)
  - SUSPENDED: User is temporarily suspended
  - LOCKED_OUT: User is locked out
  """
  def is_terminated?(user_data) do
    status = user_data["status"]
    status in ["DEPROVISIONED", "DELETED"]
  end

  @doc """
  Maps employment status from Okta format to Assetronics format.
  """
  def map_employment_status(user_data) do
    status = user_data["status"]

    case status do
      "ACTIVE" -> "active"
      "PROVISIONED" -> "active"
      "STAGED" -> "active"
      "RECOVERY" -> "active"
      "SUSPENDED" -> "on_leave"
      "LOCKED_OUT" -> "on_leave"
      "DEPROVISIONED" -> "terminated"
      "PASSWORD_EXPIRED" -> "active"
      _ -> "active"
    end
  end

  @doc """
  Parses date string from Okta format (ISO 8601).
  """
  def parse_date(nil), do: nil
  def parse_date("0000-00-00"), do: nil
  def parse_date(date_string) when is_binary(date_string) do
    # Okta uses ISO 8601 format with timezone
    # Example: "2024-01-15T10:30:00.000Z"
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> DateTime.to_date(datetime)
      {:error, _} ->
        # Try parsing as just date
        case Date.from_iso8601(date_string) do
          {:ok, date} -> date
          {:error, _} -> nil
        end
    end
  end
  def parse_date(_), do: nil

  @doc """
  Extracts and cleans a value from user data.
  """
  def get_value(data, key) do
    case data[key] do
      nil -> nil
      "" -> nil
      "null" -> nil
      val when is_binary(val) -> String.trim(val)
      val -> to_string(val)
    end
  end

  # Private functions

  defp build_address(profile) do
    %{
      street1: get_value(profile, "streetAddress") || get_value(profile, "address1"),
      street2: get_value(profile, "address2"),
      city: get_value(profile, "city"),
      state: get_value(profile, "state"),
      zip: get_value(profile, "zipCode") || get_value(profile, "postalCode"),
      country: get_value(profile, "countryCode") || get_value(profile, "country")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp build_custom_fields(user_data, profile) do
    %{
      "employee_number" => get_value(profile, "employeeNumber"),
      "cost_center" => get_value(profile, "costCenter"),
      "organization" => get_value(profile, "organization"),
      "okta_user_type" => get_value(profile, "userType"),
      "okta_status" => user_data["status"],
      "okta_id" => user_data["id"],
      "last_login" => user_data["lastLogin"],
      "manager_id" => get_value(profile, "managerId")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end