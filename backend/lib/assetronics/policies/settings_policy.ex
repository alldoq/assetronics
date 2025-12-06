defmodule Assetronics.Policies.SettingsPolicy do
  @moduledoc """
  Authorization policy for Settings resources.

  Defines permissions for system settings and notification preferences.
  """

  @behaviour Bodyguard.Policy

  alias Assetronics.Accounts.User
  alias Assetronics.Policy

  @doc """
  Authorizes settings actions based on role and ownership.

  ## Actions
  - :view_tenant_settings - View tenant settings (admin only)
  - :update_tenant_settings - Update tenant settings (admin only)
  - :view_notification_preferences - View own notification preferences (all authenticated users)
  - :update_notification_preferences - Update own notification preferences (all authenticated users)
  """

  # View tenant settings - admins only
  def authorize(:view_tenant_settings, %User{} = user, _params) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Update tenant settings - admins only
  def authorize(:update_tenant_settings, %User{} = user, _params) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # View notification preferences - all active users can view their own preferences
  def authorize(:view_notification_preferences, %User{} = user, _params) do
    Policy.active?(user)
  end

  # Update notification preferences - all active users can update their own preferences
  def authorize(:update_notification_preferences, %User{} = user, _params) do
    Policy.active?(user)
  end

  # Default deny
  def authorize(_action, _user, _params), do: false
end
