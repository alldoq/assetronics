defmodule Assetronics.Software.Assignment do
  @moduledoc """
  Join table linking Employees to Software Licenses.
  Tracks assignment status and last usage.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "software_assignments" do
    belongs_to :employee, Assetronics.Employees.Employee
    belongs_to :software_license, Assetronics.Software.License
    
    field :assigned_at, :date
    field :last_used_at, :naive_datetime
    field :status, :string, default: "active"

    timestamps()
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:employee_id, :software_license_id, :assigned_at, :last_used_at, :status])
    |> validate_required([:employee_id, :software_license_id])
    |> unique_constraint([:employee_id, :software_license_id])
  end
end
