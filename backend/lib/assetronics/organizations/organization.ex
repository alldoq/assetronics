defmodule Assetronics.Organizations.Organization do
  @moduledoc """
  Organization schema for hierarchical organizational structures.

  Organizations are tenant-specific and can represent holding companies,
  subsidiaries, divisions, business units, or branches in a hierarchical tree.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @organization_types ~w(holding_company parent_company subsidiary division business_unit branch other)

  schema "organizations" do
    field :name, :string
    field :type, :string
    field :description, :string

    belongs_to :parent, __MODULE__, type: :binary_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :type, :description, :parent_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:type, @organization_types, message: "must be one of: #{Enum.join(@organization_types, ", ")}")
    |> foreign_key_constraint(:parent_id)
    |> validate_no_circular_reference()
  end

  defp validate_no_circular_reference(changeset) do
    # Prevent circular references in the hierarchy
    # This will be validated at the context level with database queries
    changeset
  end

  def organization_types, do: @organization_types
end
