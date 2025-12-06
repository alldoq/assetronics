defmodule AssetronicsWeb.TenantController do
  use AssetronicsWeb, :controller

  alias Assetronics.Accounts
  alias Assetronics.Accounts.Tenant

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Get current tenant information.

  Returns information about the tenant making the request.
  """
  def show(conn, _params) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)
    render(conn, :show, tenant: tenant)
  end

  @doc """
  Update current tenant.

  Allows updating tenant settings, branding, and configuration.
  Admin-only endpoint.
  """
  def update(conn, %{"tenant" => tenant_params}) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)

    with {:ok, %Tenant{} = tenant} <- Accounts.update_tenant(tenant, tenant_params) do
      render(conn, :show, tenant: tenant)
    end
  end

  @doc """
  Get tenant usage statistics.

  Returns current usage metrics for the tenant:
  - Asset count
  - Employee count
  - Integration count
  - Workflow count
  - Storage usage
  """
  def usage(conn, _params) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)
    usage_stats = Accounts.get_tenant_usage(tenant_slug)

    json(conn, %{
      data: %{
        tenant_id: tenant.id,
        tenant_name: tenant.name,
        plan: tenant.plan,
        usage: usage_stats,
        plan_limits: get_plan_limits(tenant.plan)
      }
    })
  end

  @doc """
  Get tenant features.

  Returns list of enabled features for the tenant based on their plan.
  """
  def features(conn, _params) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)

    json(conn, %{
      data: %{
        tenant_id: tenant.id,
        plan: tenant.plan,
        features: tenant.features || [],
        available_features: get_available_features(tenant.plan)
      }
    })
  end

  @doc """
  Add a feature to the tenant.

  Admin-only endpoint to enable additional features.
  """
  def add_feature(conn, %{"feature" => feature}) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)

    with {:ok, %Tenant{} = tenant} <- Accounts.add_feature(tenant, feature) do
      json(conn, %{
        status: "ok",
        message: "Feature added successfully",
        features: tenant.features
      })
    end
  end

  @doc """
  Remove a feature from the tenant.

  Admin-only endpoint to disable features.
  """
  def remove_feature(conn, %{"feature" => feature}) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)

    with {:ok, %Tenant{} = tenant} <- Accounts.remove_feature(tenant, feature) do
      json(conn, %{
        status: "ok",
        message: "Feature removed successfully",
        features: tenant.features
      })
    end
  end

  @doc """
  Update tenant subscription.

  Upgrade or downgrade tenant plan.
  Admin-only endpoint.
  """
  def update_subscription(conn, %{"plan" => plan} = params) do
    tenant_slug = conn.assigns[:tenant]
    tenant = Accounts.get_tenant_by_slug!(tenant_slug)
    billing_cycle = params["billing_cycle"] || "monthly"

    with {:ok, %Tenant{} = tenant} <- Accounts.update_subscription(tenant, plan, billing_cycle) do
      render(conn, :show, tenant: tenant)
    end
  end

  # Private helpers

  defp get_plan_limits(plan) do
    case plan do
      "starter" ->
        %{
          assets: 100,
          employees: 25,
          integrations: 2,
          workflows: 50,
          storage_gb: 5
        }

      "professional" ->
        %{
          assets: 500,
          employees: 100,
          integrations: 10,
          workflows: 500,
          storage_gb: 50
        }

      "enterprise" ->
        %{
          assets: :unlimited,
          employees: :unlimited,
          integrations: :unlimited,
          workflows: :unlimited,
          storage_gb: :unlimited
        }

      _ ->
        %{}
    end
  end

  defp get_available_features(plan) do
    base_features = [
      "asset_management",
      "employee_management",
      "basic_workflows",
      "basic_reporting"
    ]

    professional_features = [
      "advanced_workflows",
      "custom_fields",
      "api_access",
      "integrations",
      "advanced_reporting",
      "audit_logs"
    ]

    enterprise_features = [
      "sso",
      "advanced_rbac",
      "custom_integrations",
      "dedicated_support",
      "sla",
      "data_export",
      "webhooks",
      "graphql_api"
    ]

    case plan do
      "starter" -> base_features
      "professional" -> base_features ++ professional_features
      "enterprise" -> base_features ++ professional_features ++ enterprise_features
      _ -> []
    end
  end
end
