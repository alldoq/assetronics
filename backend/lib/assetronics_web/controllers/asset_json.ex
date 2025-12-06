defmodule AssetronicsWeb.AssetJSON do
  @moduledoc """
  JSON rendering for Asset resources.
  """

  alias Assetronics.Assets.Asset

  @doc """
  Renders a list of assets with pagination metadata.
  """
  def index(%{result: result}) do
    %{
      data: for(asset <- result.assets, do: data(asset)),
      meta: %{
        total: result.total,
        page: result.page,
        per_page: result.per_page,
        total_pages: result.total_pages
      }
    }
  end

  # Legacy support without pagination
  def index(%{assets: assets}) do
    %{data: for(asset <- assets, do: data(asset))}
  end

  @doc """
  Renders a single asset.
  """
  def show(%{asset: asset}) do
    %{data: data(asset)}
  end

  @doc """
  Renders asset history (transactions).
  """
  def history(%{transactions: transactions}) do
    %{data: for(transaction <- transactions, do: transaction_data(transaction))}
  end

  defp data(%Asset{} = asset) do
    %{
      id: asset.id,
      asset_tag: asset.asset_tag,
      name: asset.name,
      description: asset.description,
      category: asset.category,
      type: asset.type,
      make: asset.make,
      model: asset.model,
      serial_number: asset.serial_number,
      purchase_date: asset.purchase_date,
      purchase_cost: asset.purchase_cost,
      vendor: asset.vendor,
      warranty_start_date: asset.warranty_start_date,
      warranty_end_date: asset.warranty_end_date,
      warranty_provider: asset.warranty_provider,
      status: asset.status,
      condition: asset.condition,
      assigned_at: asset.assigned_at,
      assignment_type: asset.assignment_type,
      expected_return_date: asset.expected_return_date,
      depreciation_method: asset.depreciation_method,
      useful_life_months: asset.useful_life_months,
      cost_center: asset.cost_center,
      department: asset.department,
      notes: asset.notes,
      tags: asset.tags,
      custom_fields: asset.custom_fields,
      retired_at: asset.retired_at,
      retired_reason: asset.retired_reason,
      last_audit_date: asset.last_audit_date,
      next_audit_date: asset.next_audit_date,
      inserted_at: asset.inserted_at,
      updated_at: asset.updated_at
    }
    |> maybe_add_employee(asset)
    |> maybe_add_location(asset)
  end

  defp transaction_data(transaction) do
    %{
      id: transaction.id,
      transaction_type: transaction.transaction_type,
      description: transaction.description,
      notes: transaction.notes,
      from_status: transaction.from_status,
      to_status: transaction.to_status,
      performed_by: transaction.performed_by,
      performed_at: transaction.performed_at,
      metadata: transaction.metadata,
      inserted_at: transaction.inserted_at
    }
  end

  defp maybe_add_employee(data, %Asset{employee: %Ecto.Association.NotLoaded{}}), do: data

  defp maybe_add_employee(data, %Asset{employee: nil}), do: data

  defp maybe_add_employee(data, %Asset{employee: employee}) do
    Map.put(data, :employee, %{
      id: employee.id,
      email: employee.email,
      first_name: employee.first_name,
      last_name: employee.last_name,
      job_title: employee.job_title,
      department: employee.department
    })
  end

  defp maybe_add_location(data, %Asset{location: %Ecto.Association.NotLoaded{}}), do: data

  defp maybe_add_location(data, %Asset{location: nil}), do: data

  defp maybe_add_location(data, %Asset{location: location}) do
    Map.put(data, :location, %{
      id: location.id,
      name: location.name,
      location_type: location.location_type,
      city: location.city,
      state_province: location.state_province,
      country: location.country
    })
  end
end
