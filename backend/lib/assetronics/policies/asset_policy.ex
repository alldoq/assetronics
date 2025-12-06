defmodule Assetronics.Policies.AssetPolicy do
  @moduledoc """
  Authorization policy for Asset resources.

  Defines permissions for asset management operations.
  """

  @behaviour Bodyguard.Policy

  alias Assetronics.Accounts.User
  alias Assetronics.Assets.Asset
  alias Assetronics.Policy

  @doc """
  Authorizes asset actions based on role and ownership.

  ## Actions
  - :list_assets - List all assets (all authenticated users)
  - :show_asset - View asset details (all authenticated users)
  - :create_asset - Create new asset (admin, manager)
  - :update_asset - Update asset (admin, manager)
  - :delete_asset - Delete asset (admin only)
  - :assign_asset - Assign asset to employee (admin, manager)
  - :unassign_asset - Unassign asset from employee (admin, manager)
  - :bulk_import - Bulk import assets (admin, manager)
  - :export - Export assets (admin, manager)
  """

  # List assets - all authenticated users can list assets
  def authorize(:list_assets, %User{} = user, _params) do
    Policy.active?(user)
  end

  # Show asset - all authenticated users can view asset details
  def authorize(:show_asset, %User{} = user, %Asset{}) do
    Policy.active?(user)
  end

  # Create asset - managers and admins
  def authorize(:create_asset, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Update asset - managers and admins
  def authorize(:update_asset, %User{} = user, %Asset{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Delete asset - admins only
  def authorize(:delete_asset, %User{} = user, %Asset{}) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Assign asset - managers and admins
  def authorize(:assign_asset, %User{} = user, %Asset{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Unassign asset - managers and admins
  def authorize(:unassign_asset, %User{} = user, %Asset{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Bulk import - managers and admins
  def authorize(:bulk_import, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Export - managers and admins
  def authorize(:export, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Default deny
  def authorize(_action, _user, _params), do: false
end
