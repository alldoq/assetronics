defmodule AssetronicsWeb.TenantJSON do
  alias Assetronics.Accounts.Tenant

  @doc """
  Renders a single tenant.
  """
  def show(%{tenant: tenant}) do
    %{data: data(tenant)}
  end

  defp data(%Tenant{} = tenant) do
    %{
      id: tenant.id,
      name: tenant.name,
      slug: tenant.slug,
      status: tenant.status,
      plan: tenant.plan,
      trial_ends_at: tenant.trial_ends_at,
      subscription_starts_at: tenant.subscription_starts_at,
      subscription_ends_at: tenant.subscription_ends_at,
      company_name: tenant.company_name,
      employee_count_range: tenant.employee_count_range,
      industry: tenant.industry,
      website: tenant.website,
      primary_contact_name: tenant.primary_contact_name,
      primary_contact_email: tenant.primary_contact_email,
      primary_contact_phone: tenant.primary_contact_phone,
      billing_email: tenant.billing_email,
      billing_address: tenant.billing_address,
      features: tenant.features || [],
      settings: tenant.settings || %{},
      inserted_at: tenant.inserted_at,
      updated_at: tenant.updated_at
    }
    |> add_trial_status(tenant)
    |> add_subscription_health(tenant)
  end

  # Add trial status
  defp add_trial_status(data, %Tenant{trial_ends_at: nil}), do: Map.put(data, :is_trial, false)
  defp add_trial_status(data, %Tenant{trial_ends_at: trial_ends_at}) do
    now = DateTime.utc_now()
    is_trial = DateTime.compare(trial_ends_at, now) == :gt
    days_remaining = if is_trial do
      DateTime.diff(trial_ends_at, now, :day)
    else
      0
    end

    data
    |> Map.put(:is_trial, is_trial)
    |> Map.put(:trial_days_remaining, days_remaining)
  end

  # Add subscription health status
  defp add_subscription_health(data, %Tenant{} = tenant) do
    health = case tenant.status do
      "active" -> "healthy"
      "trial" -> "trial"
      "cancelled" -> "cancelled"
      "suspended" -> "suspended"
      _ -> "unknown"
    end

    Map.put(data, :subscription_health, health)
  end
end
