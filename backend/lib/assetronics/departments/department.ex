defmodule Assetronics.Departments.Department do
  @moduledoc """
  Department schema for organizing assets and employees.

  Departments are tenant-specific and can represent divisions, departments,
  teams, units, or groups in a hierarchical tree structure.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @department_types ~w(division department team unit group other)

  schema "departments" do
    field :name, :string
    field :type, :string
    field :description, :string
    field :code, :string

    belongs_to :parent, __MODULE__, type: :binary_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps()
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :type, :description, :code, :parent_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_length(:code, max: 50)
    |> validate_inclusion(:type, @department_types, message: "must be one of: #{Enum.join(@department_types, ", ")}")
    |> unique_constraint(:name)
    |> unique_constraint(:code)
    |> foreign_key_constraint(:parent_id)
    |> validate_no_circular_reference()
  end

  defp validate_no_circular_reference(changeset) do
    # Prevent circular references in the hierarchy
    # This will be validated at the context level with database queries
    changeset
  end

  def department_types, do: @department_types
end
