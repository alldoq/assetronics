defmodule Assetronics.Seeds do
  @moduledoc """
  Handles seeding of default data for new tenants.

  This module provides functions to populate new tenant databases
  with sensible defaults for categories, statuses, and other master data.
  """

  alias Assetronics.Categories
  alias Assetronics.Statuses

  @doc """
  Seeds all default data for a new tenant.

  This should be called after tenant creation and schema migration.
  """
  def seed_tenant(tenant) do
    seed_categories(tenant)
    seed_statuses(tenant)

    {:ok, "Tenant #{tenant} seeded successfully"}
  end

  @doc """
  Seeds default asset categories.
  """
  def seed_categories(tenant) do
    categories = [
      %{
        name: "Computers",
        description: "Desktop computers, laptops, and workstations"
      },
      %{
        name: "Monitors",
        description: "Display monitors and screens"
      },
      %{
        name: "Mobile Devices",
        description: "Phones, tablets, and mobile devices"
      },
      %{
        name: "Peripherals",
        description: "Keyboards, mice, and other computer peripherals"
      },
      %{
        name: "Networking",
        description: "Routers, switches, and networking equipment"
      },
      %{
        name: "Printers & Scanners",
        description: "Printing and scanning equipment"
      },
      %{
        name: "Audio/Video",
        description: "Cameras, microphones, and AV equipment"
      },
      %{
        name: "Furniture",
        description: "Desks, chairs, and office furniture"
      },
      %{
        name: "Software Licenses",
        description: "Software licenses and subscriptions"
      },
      %{
        name: "Other",
        description: "Miscellaneous assets"
      }
    ]

    Enum.each(categories, fn category_data ->
      case Categories.create_category(tenant, category_data) do
        {:ok, category} ->
          IO.puts("Created category: #{category.name}")

        {:error, changeset} ->
          IO.puts("Failed to create category #{category_data.name}: #{inspect(changeset)}")
      end
    end)

    {:ok, "Categories seeded"}
  end

  @doc """
  Seeds default asset statuses.
  """
  def seed_statuses(tenant) do
    statuses = [
      %{
        name: "Available",
        value: "available",
        description: "Asset is available and not currently assigned",
        color: "green"
      },
      %{
        name: "Assigned",
        value: "assigned",
        description: "Asset is currently assigned to an employee",
        color: "blue"
      },
      %{
        name: "In Maintenance",
        value: "maintenance",
        description: "Asset is undergoing maintenance or repair",
        color: "amber"
      },
      %{
        name: "In Transit",
        value: "in_transit",
        description: "Asset is being shipped or transferred",
        color: "primary"
      },
      %{
        name: "Retired",
        value: "retired",
        description: "Asset is retired and no longer in use",
        color: "gray"
      },
      %{
        name: "Lost",
        value: "lost",
        description: "Asset is lost or missing",
        color: "red"
      },
      %{
        name: "Damaged",
        value: "damaged",
        description: "Asset is damaged and requires attention",
        color: "red"
      }
    ]

    Enum.each(statuses, fn status_data ->
      case Statuses.create_status(tenant, status_data) do
        {:ok, status} ->
          IO.puts("Created status: #{status.name}")

        {:error, changeset} ->
          IO.puts("Failed to create status #{status_data.name}: #{inspect(changeset)}")
      end
    end)

    {:ok, "Statuses seeded"}
  end

  @doc """
  Reseeds categories (useful for updating existing tenants).

  Only creates categories that don't already exist.
  """
  def reseed_categories(tenant) do
    existing_categories =
      Categories.list_categories(tenant)
      |> Enum.map(& &1.name)
      |> MapSet.new()

    default_categories = [
      %{name: "Computers", description: "Desktop computers, laptops, and workstations"},
      %{name: "Monitors", description: "Display monitors and screens"},
      %{name: "Mobile Devices", description: "Phones, tablets, and mobile devices"},
      %{name: "Peripherals", description: "Keyboards, mice, and other computer peripherals"},
      %{name: "Networking", description: "Routers, switches, and networking equipment"},
      %{name: "Printers & Scanners", description: "Printing and scanning equipment"},
      %{name: "Audio/Video", description: "Cameras, microphones, and AV equipment"},
      %{name: "Furniture", description: "Desks, chairs, and office furniture"},
      %{name: "Software Licenses", description: "Software licenses and subscriptions"},
      %{name: "Other", description: "Miscellaneous assets"}
    ]

    Enum.each(default_categories, fn category_data ->
      unless MapSet.member?(existing_categories, category_data.name) do
        case Categories.create_category(tenant, category_data) do
          {:ok, category} ->
            IO.puts("Created missing category: #{category.name}")

          {:error, changeset} ->
            IO.puts("Failed to create category #{category_data.name}: #{inspect(changeset)}")
        end
      end
    end)

    {:ok, "Categories reseeded"}
  end

  @doc """
  Reseeds statuses (useful for updating existing tenants).

  Only creates statuses that don't already exist.
  """
  def reseed_statuses(tenant) do
    existing_statuses =
      Statuses.list_statuses(tenant)
      |> Enum.map(& &1.value)
      |> MapSet.new()

    default_statuses = [
      %{name: "Available", value: "available", description: "Asset is available and not currently assigned", color: "green"},
      %{name: "Assigned", value: "assigned", description: "Asset is currently assigned to an employee", color: "blue"},
      %{name: "In Maintenance", value: "maintenance", description: "Asset is undergoing maintenance or repair", color: "amber"},
      %{name: "In Transit", value: "in_transit", description: "Asset is being shipped or transferred", color: "primary"},
      %{name: "Retired", value: "retired", description: "Asset is retired and no longer in use", color: "gray"},
      %{name: "Lost", value: "lost", description: "Asset is lost or missing", color: "red"},
      %{name: "Damaged", value: "damaged", description: "Asset is damaged and requires attention", color: "red"}
    ]

    Enum.each(default_statuses, fn status_data ->
      unless MapSet.member?(existing_statuses, status_data.value) do
        case Statuses.create_status(tenant, status_data) do
          {:ok, status} ->
            IO.puts("Created missing status: #{status.name}")

          {:error, changeset} ->
            IO.puts("Failed to create status #{status_data.name}: #{inspect(changeset)}")
        end
      end
    end)

    {:ok, "Statuses reseeded"}
  end
end
