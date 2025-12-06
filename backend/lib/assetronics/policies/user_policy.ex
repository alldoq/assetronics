defmodule Assetronics.Policies.UserPolicy do
  @moduledoc """
  Authorization policy for User resources.

  Defines permissions for user management operations.
  """

  @behaviour Bodyguard.Policy

  alias Assetronics.Accounts.User
  alias Assetronics.Policy

  @doc """
  Authorizes user actions based on role and ownership.

  ## Actions
  - :list_users - List all users (admin, manager)
  - :show_user - View user profile (own profile, or admin/manager)
  - :create_user - Create new user (admin only)
  - :update_user - Update user profile (own profile, or admin)
  - :delete_user - Delete user (admin only)
  - :update_role - Update user role (admin only)
  - :update_status - Update user status (admin only)
  - :unlock_user - Unlock user account (admin only)
  """

  # List users - admins and managers can list users
  def authorize(:list_users, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Show user - users can view their own profile, admins and managers can view any profile
  def authorize(:show_user, %User{} = current_user, %User{} = target_user) do
    Policy.active?(current_user) &&
      (Policy.own_profile?(current_user, target_user) || Policy.manager_or_higher?(current_user))
  end

  # Create user - admins only
  def authorize(:create_user, %User{} = user, _params) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Update user - users can update their own profile, admins can update any profile
  def authorize(:update_user, %User{} = current_user, %User{} = target_user) do
    Policy.active?(current_user) &&
      (Policy.own_profile?(current_user, target_user) || Policy.admin?(current_user))
  end

  # Delete user - admins only
  def authorize(:delete_user, %User{} = user, _target_user) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Update role - admins only
  def authorize(:update_role, %User{} = user, _target_user) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Update status - admins only
  def authorize(:update_status, %User{} = user, _target_user) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Unlock user - admins only
  def authorize(:unlock_user, %User{} = user, _target_user) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Default deny
  def authorize(_action, _user, _params), do: false
end
