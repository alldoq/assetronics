defmodule Assetronics.Policy do
  @moduledoc """
  Base authorization policy module.

  Provides helper functions for common authorization patterns.
  All policy modules should use Bodyguard.Policy and define authorize/3 callbacks.

  ## Role Hierarchy

  - super_admin: Full system access across all tenants
  - admin: Full access within their tenant
  - manager: Can manage employees, assets, and workflows
  - employee: Can view assigned assets and complete workflows
  - viewer: Read-only access to resources
  """

  @doc """
  Checks if a user has a specific role.
  """
  def has_role?(user, role) when is_binary(role) do
    user.role == role
  end

  def has_role?(user, roles) when is_list(roles) do
    user.role in roles
  end

  @doc """
  Checks if a user is an admin (super_admin or admin).
  """
  def admin?(user) do
    user.role in ["super_admin", "admin"]
  end

  @doc """
  Checks if a user is a manager or higher.
  """
  def manager_or_higher?(user) do
    user.role in ["super_admin", "admin", "manager"]
  end

  @doc """
  Checks if a user is active and not locked.
  """
  def active?(user) do
    user.status == "active" && is_nil(user.locked_at)
  end

  @doc """
  Checks if a user owns a resource.
  """
  def owns_resource?(user, %{user_id: user_id}) do
    user.id == user_id
  end

  def owns_resource?(_user, _resource), do: false

  @doc """
  Checks if a user is accessing their own profile.
  """
  def own_profile?(user, target_user) do
    user.id == target_user.id
  end
end
