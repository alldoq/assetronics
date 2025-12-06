defmodule AssetronicsWeb.UserPreferencesController do
  use AssetronicsWeb, :controller

  alias Assetronics.Settings
  alias Assetronics.Policies.SettingsPolicy

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  GET /api/v1/preferences/notifications
  Returns all notification preferences for the current user.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]
    user_id = current_user.id

    with :ok <- Bodyguard.permit(SettingsPolicy, :view_notification_preferences, current_user),
         {:ok, preferences} <- Settings.get_user_notification_preferences(tenant, user_id) do
      render(conn, :index, preferences: preferences)
    end
  end

  @doc """
  GET /api/v1/preferences/notifications/:type
  Returns a specific notification preference for the current user.
  """
  def show(conn, %{"type" => notification_type}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]
    user_id = current_user.id

    with :ok <- Bodyguard.permit(SettingsPolicy, :view_notification_preferences, current_user),
         {:ok, preference} <- Settings.get_user_notification_preference(tenant, user_id, notification_type) do
      render(conn, :show, preference: preference)
    end
  end

  @doc """
  PATCH /api/v1/preferences/notifications/:type
  Updates a specific notification preference for the current user.
  """
  def update(conn, %{"type" => notification_type, "preference" => preference_params}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]
    user_id = current_user.id

    with :ok <- Bodyguard.permit(SettingsPolicy, :update_notification_preferences, current_user),
         {:ok, preference} <- Settings.upsert_notification_preference(tenant, user_id, notification_type, preference_params) do
      render(conn, :show, preference: preference)
    end
  end
end
