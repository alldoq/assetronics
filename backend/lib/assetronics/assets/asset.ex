defmodule Assetronics.Assets.Asset do

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @category_values ~w(laptop desktop monitor phone tablet peripheral server network_equipment other)
  @status_values ~w(on_order in_stock assigned in_transit in_repair retired lost stolen)
  @condition_values ~w(new excellent good fair poor damaged)
  @assignment_types ~w(permanent temporary loaner)
  @depreciation_methods ~w(straight_line declining_balance)

  schema "assets" do
    field :asset_tag, :string
    field :name, :string
    field :description, :string
    field :category, :string
    field :type, :string
    field :make, :string
    field :model, :string
    field :serial_number, EncryptedFields.EncryptedString, source: :serial_number_encrypted
    field :serial_number_hash, :binary
    field :purchase_date, :date
    field :purchase_cost, EncryptedFields.EncryptedDecimal, source: :purchase_cost_encrypted
    field :purchase_cost_hash, :binary
    field :vendor, :string
    field :po_number, EncryptedFields.EncryptedString, source: :po_number_encrypted
    field :invoice_number, EncryptedFields.EncryptedString, source: :invoice_number_encrypted
    field :warranty_start_date, :date
    field :warranty_end_date, :date
    field :warranty_provider, :string
    field :warranty_info, EncryptedFields.EncryptedString, source: :warranty_info_encrypted
    field :status, :string, default: "in_stock"
    field :condition, :string
    belongs_to :location, Assetronics.Locations.Location
    belongs_to :employee, Assetronics.Employees.Employee
    field :assigned_at, :naive_datetime
    field :assignment_type, :string
    field :expected_return_date, :date
    field :depreciation_method, :string
    field :useful_life_months, :integer
    field :salvage_value, EncryptedFields.EncryptedDecimal, source: :salvage_value_encrypted
    field :current_book_value, EncryptedFields.EncryptedDecimal, source: :current_book_value_encrypted
    field :cost_center, :string
    field :department, :string
    field :notes, :string
    field :tags, {:array, :string}, default: []
    field :custom_fields, :map, default: %{}
    field :retired_at, :naive_datetime
    field :retired_reason, :string
    field :last_audit_date, :date
    field :next_audit_date, :date
    field :hostname, :string
    field :os_info, :string
    field :last_checkin_at, :naive_datetime
    field :ip_address, :string
    field :mac_address, :string
    field :installed_software, {:array, :map}, default: []
    has_many :transactions, Assetronics.Transactions.Transaction
    has_many :workflows, Assetronics.Workflows.Workflow

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :asset_tag,
      :name,
      :description,
      :category,
      :type,
      :make,
      :model,
      :serial_number,
      :purchase_date,
      :purchase_cost,
      :vendor,
      :po_number,
      :invoice_number,
      :warranty_start_date,
      :warranty_end_date,
      :warranty_provider,
      :warranty_info,
      :status,
      :condition,
      :location_id,
      :employee_id,
      :assigned_at,
      :assignment_type,
      :expected_return_date,
      :depreciation_method,
      :useful_life_months,
      :salvage_value,
      :current_book_value,
      :cost_center,
      :department,
      :notes,
      :tags,
      :custom_fields,
      :retired_at,
      :retired_reason,
      :last_audit_date,
      :next_audit_date,
      :hostname,
      :os_info,
      :last_checkin_at,
      :ip_address,
      :mac_address,
      :installed_software
    ])
    |> validate_required([:asset_tag, :name, :category, :status])
    |> validate_inclusion(:category, @category_values)
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:condition, @condition_values, allow_nil: true)
    |> validate_inclusion(:assignment_type, @assignment_types, allow_nil: true)
    |> validate_inclusion(:depreciation_method, @depreciation_methods, allow_nil: true)
    |> unique_constraint(:asset_tag)
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:employee_id)
    |> generate_serial_number_hash()
    |> generate_purchase_cost_hash()
    |> validate_assignment()
  end

  defp generate_serial_number_hash(changeset) do
    case get_change(changeset, :serial_number) do
      nil ->
        changeset

      serial_number ->
        hash = :crypto.hash(:sha256, serial_number)
        put_change(changeset, :serial_number_hash, hash)
    end
  end

  defp generate_purchase_cost_hash(changeset) do
    case get_change(changeset, :purchase_cost) do
      nil ->
        changeset

      %Decimal{} = cost ->
        hash = :crypto.hash(:sha256, Decimal.to_string(cost))
        put_change(changeset, :purchase_cost_hash, hash)

      _ ->
        changeset
    end
  end

  defp validate_assignment(changeset) do
    status = get_field(changeset, :status)
    employee_id = get_field(changeset, :employee_id)

    cond do
      status == "assigned" and is_nil(employee_id) ->
        add_error(changeset, :employee_id, "must be set when status is assigned")

      status != "assigned" and not is_nil(employee_id) ->
        add_error(changeset, :status, "must be assigned when employee_id is set")

      true ->
        changeset
    end
  end
end
