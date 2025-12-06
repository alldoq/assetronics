defmodule AssetronicsWeb.SettingsController do
  use AssetronicsWeb, :controller

  alias Assetronics.Settings
  alias Assetronics.Policies.SettingsPolicy

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  GET /api/v1/settings
  Returns all tenant settings.
  Requires admin role.
  """
  def show(conn, _params) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    with :ok <- Bodyguard.permit(SettingsPolicy, :view_tenant_settings, current_user),
         {:ok, settings} <- Settings.get_tenant_settings(tenant) do
      render(conn, :show, settings: settings)
    end
  end

  @doc """
  PATCH /api/v1/settings
  Updates tenant settings.
  Requires admin role.
  """
  def update(conn, %{"settings" => settings_params}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    with :ok <- Bodyguard.permit(SettingsPolicy, :update_tenant_settings, current_user),
         {:ok, settings} <- Settings.update_tenant_settings(tenant, settings_params) do
      render(conn, :show, settings: settings)
    end
  end
end
