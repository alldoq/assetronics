defmodule Assetronics.Software.License do
  @moduledoc """
  Schema for Software Licenses and Subscriptions.
  
  Tracks vendor, cost, seats, and expiration.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @status_values ~w(active expired cancelled future)

  schema "software_licenses" do
    field :name, :string
    field :vendor, :string
    field :description, :string
    
    field :total_seats, :integer, default: 0
    field :annual_cost, EncryptedFields.EncryptedDecimal, source: :annual_cost_encrypted
    field :cost_per_seat, EncryptedFields.EncryptedDecimal, source: :cost_per_seat_encrypted
    
    field :purchase_date, :date
    field :expiration_date, :date
    
    field :status, :string, default: "active"
    field :license_key, EncryptedFields.EncryptedString, source: :license_key_encrypted
    
    field :sso_app_id, :string
    belongs_to :integration, Assetronics.Integrations.Integration

    timestamps()
  end

  @doc false
  def changeset(license, attrs) do
    license
    |> cast(attrs, [
      :name,
      :vendor,
      :description,
      :total_seats,
      :annual_cost,
      :cost_per_seat,
      :purchase_date,
      :expiration_date,
      :status,
      :license_key,
      :sso_app_id,
      :integration_id
    ])
    |> validate_required([:name, :vendor, :status])
    |> validate_inclusion(:status, @status_values)
    |> unique_constraint([:name, :vendor])
  end
end
