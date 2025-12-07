defmodule Assetronics.Integrations.Adapters.Okta.Resolvers do
  @moduledoc """
  Resolves hierarchical references for Okta data.

  Handles finding or creating organizations, departments, and locations
  based on text field values from Okta user profiles.
  """

  alias Assetronics.Organizations
  alias Assetronics.Departments
  alias Assetronics.Locations

  require Logger

  @doc """
  Resolves an organization by division name.

  Creates a new organization if it doesn't exist using normalized name.
  """
  def resolve_organization(_tenant, nil), do: nil
  def resolve_organization(_tenant, ""), do: nil
  def resolve_organization(tenant, division_name) do
    case Organizations.get_or_create_organization(tenant, division_name) do
      {:ok, organization} ->
        Logger.debug("Resolved organization: #{organization.name} (ID: #{organization.id})")
        organization.id

      {:error, reason} ->
        Logger.error("Failed to resolve organization '#{division_name}': #{inspect(reason)}")
        nil
    end
  end

  @doc """
  Resolves a department by department name.

  Creates a new department if it doesn't exist using normalized name.
  """
  def resolve_department(_tenant, nil), do: nil
  def resolve_department(_tenant, ""), do: nil
  def resolve_department(tenant, department_name) do
    case Departments.get_or_create_department(tenant, department_name) do
      {:ok, department} ->
        Logger.debug("Resolved department: #{department.name} (ID: #{department.id})")
        department.id

      {:error, reason} ->
        Logger.error("Failed to resolve department '#{department_name}': #{inspect(reason)}")
        nil
    end
  end

  @doc """
  Resolves a location by location name.

  Creates a new location if it doesn't exist.
  """
  def resolve_location(_tenant, nil), do: nil
  def resolve_location(_tenant, ""), do: nil
  def resolve_location(tenant, location_name) do
    case Locations.get_location_by_name(tenant, location_name) do
      {:ok, location} ->
        Logger.debug("Found existing location: #{location_name} (ID: #{location.id})")
        location.id

      {:error, :not_found} ->
        Logger.info("Creating new location from Okta: #{location_name}")
        case Locations.create_location(tenant, %{
          name: location_name,
          location_type: "office",
          description: "Auto-created from Okta sync"
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
end