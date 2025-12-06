defmodule Assetronics.Locations.Location do
  @moduledoc """
  Location schema representing physical locations.

  Locations can be hierarchical, representing regions, countries, states,
  cities, offices, buildings, floors, warehouses, datacenters, or stores.
  Address information is encrypted for privacy.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @location_types ~w(region country state city office building floor warehouse datacenter store employee_home remote other)

  schema "locations" do
    field :name, :string
    field :location_type, :string

    # Address information (encrypted)
    field :address_line1, EncryptedFields.EncryptedString, source: :address_line1_encrypted
    field :address_line2, EncryptedFields.EncryptedString, source: :address_line2_encrypted
    field :city, :string
    field :state_province, :string
    field :postal_code, EncryptedFields.EncryptedString, source: :postal_code_encrypted
    field :country, :string

    # Contact information
    field :contact_name, :string
    field :contact_email, :string
    field :contact_phone, EncryptedFields.EncryptedString, source: :contact_phone_encrypted

    # Metadata
    field :notes, :string
    field :is_active, :boolean, default: true
    field :custom_fields, :map, default: %{}

    # Hierarchical relationships
    belongs_to :parent, __MODULE__, type: :binary_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    # Associations
    has_many :assets, Assetronics.Assets.Asset
    has_many :employees, Assetronics.Employees.Employee, foreign_key: :office_location_id

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :name,
      :location_type,
      :address_line1,
      :address_line2,
      :city,
      :state_province,
      :postal_code,
      :country,
      :contact_name,
      :contact_email,
      :contact_phone,
      :notes,
      :is_active,
      :custom_fields,
      :parent_id
    ])
    |> validate_required([:name, :location_type])
    |> validate_inclusion(:location_type, @location_types)
    |> validate_format(:contact_email, ~r/@/, message: "must be a valid email", allow_nil: true)
    |> foreign_key_constraint(:parent_id)
    |> validate_no_circular_reference()
  end

  defp validate_no_circular_reference(changeset) do
    # Prevent circular references in the hierarchy
    # This will be validated at the context level with database queries
    changeset
  end

  def location_types, do: @location_types
end
