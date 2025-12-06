defmodule Assetronics.Statuses.Status do
  @moduledoc """
  Status schema for asset status management.

  Statuses are tenant-specific and allow each organization
  to define their own asset status workflow.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @color_options ~w(primary blue green amber red gray)

  schema "statuses" do
    field :name, :string
    field :value, :string
    field :description, :string
    field :color, :string, default: "primary"

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:name, :value, :description, :color])
    |> validate_required([:name, :value, :color])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:value, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:color, @color_options)
    |> unique_constraint(:value)
  end

  def color_options, do: @color_options
end
