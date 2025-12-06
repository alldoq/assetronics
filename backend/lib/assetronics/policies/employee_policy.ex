defmodule Assetronics.Policies.EmployeePolicy do
  @moduledoc """
  Authorization policy for Employee resources.

  Defines permissions for employee management operations.
  """

  @behaviour Bodyguard.Policy

  alias Assetronics.Accounts.User
  alias Assetronics.Employees.Employee
  alias Assetronics.Policy

  @doc """
  Authorizes employee actions based on role.

  ## Actions
  - :list_employees - List all employees (all authenticated users)
  - :show_employee - View employee details (all authenticated users)
  - :create_employee - Create new employee (admin, manager)
  - :update_employee - Update employee (admin, manager)
  - :delete_employee - Delete employee (admin only)
  - :bulk_import - Bulk import employees (admin, manager)
  - :export - Export employees (admin, manager)
  """

  # List employees - all authenticated users can list employees
  def authorize(:list_employees, %User{} = user, _params) do
    Policy.active?(user)
  end

  # Show employee - all authenticated users can view employee details
  def authorize(:show_employee, %User{} = user, %Employee{}) do
    Policy.active?(user)
  end

  # Create employee - managers and admins
  def authorize(:create_employee, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Update employee - managers and admins
  def authorize(:update_employee, %User{} = user, %Employee{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Delete employee - admins only
  def authorize(:delete_employee, %User{} = user, %Employee{}) do
    Policy.admin?(user) && Policy.active?(user)
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
