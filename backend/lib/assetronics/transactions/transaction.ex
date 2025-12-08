defmodule Assetronics.Transactions.Transaction do
  @moduledoc """
  Transaction schema for audit trail.

  Records all asset movements and state changes:
  - Assignments, returns, transfers
  - Repairs, purchases, retirements
  - Status changes, location changes
  - Audit events

  Provides complete history for compliance and reporting.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @transaction_types ~w(
    assignment return transfer
    repair_start repair_complete
    purchase retire lost stolen
    audit status_change location_change
    maintenance other
    employee_created employee_updated employee_terminated employee_synced
    workflow_created workflow_started workflow_completed workflow_step_advanced
    integration_sync_completed integration_sync_failed
  )

  schema "transactions" do
    field :transaction_type, :string

    # Related entities
    belongs_to :asset, Assetronics.Assets.Asset
    belongs_to :employee, Assetronics.Employees.Employee

    # Transaction details
    field :from_status, :string
    field :to_status, :string
    belongs_to :from_location, Assetronics.Locations.Location
    belongs_to :to_location, Assetronics.Locations.Location
    belongs_to :from_employee, Assetronics.Employees.Employee
    belongs_to :to_employee, Assetronics.Employees.Employee

    # Metadata
    field :description, :string
    field :notes, :string
    field :performed_by, :string
    field :performed_at, :naive_datetime

    # Financial data (encrypted)
    field :transaction_amount, EncryptedFields.EncryptedDecimal, source: :transaction_amount_encrypted
    field :transaction_amount_hash, :binary, virtual: true

    # Audit trail
    field :metadata, :map, default: %{}
    field :ip_address, :string
    field :user_agent, :string

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :transaction_type,
      :asset_id,
      :employee_id,
      :from_status,
      :to_status,
      :from_location_id,
      :to_location_id,
      :from_employee_id,
      :to_employee_id,
      :description,
      :notes,
      :performed_by,
      :performed_at,
      :transaction_amount,
      :metadata,
      :ip_address,
      :user_agent
    ])
    |> validate_required([:transaction_type, :performed_at])
    |> validate_inclusion(:transaction_type, @transaction_types)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:employee_id)
    |> foreign_key_constraint(:from_location_id)
    |> foreign_key_constraint(:to_location_id)
    |> foreign_key_constraint(:from_employee_id)
    |> foreign_key_constraint(:to_employee_id)
    |> put_default_performed_at()
    |> generate_transaction_amount_hash()
  end

  @doc """
  Create a transaction for audit trail events (non-asset related).

  Used for employee, workflow, and integration events.
  """
  def audit_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :transaction_type,
      :asset_id,
      :employee_id,
      :description,
      :performed_by,
      :performed_at,
      :metadata
    ])
    |> validate_required([:transaction_type, :performed_at])
    |> validate_inclusion(:transaction_type, @transaction_types)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:employee_id)
    |> put_default_performed_at()
  end

  @doc """
  Create a transaction for asset assignment.
  """
  def assignment_changeset(asset, employee, performed_by, metadata \\ %{}) do
    %__MODULE__{}
    |> changeset(%{
      transaction_type: "assignment",
      asset_id: asset.id,
      to_employee_id: employee.id,
      from_status: asset.status,
      to_status: "assigned",
      performed_by: performed_by,
      performed_at: NaiveDateTime.utc_now(),
      description: "Asset assigned to #{employee.email}",
      metadata: metadata
    })
    |> validate_required([:asset_id])
  end

  @doc """
  Create a transaction for asset return.
  """
  def return_changeset(asset, employee, performed_by, metadata \\ %{}) do
    %__MODULE__{}
    |> changeset(%{
      transaction_type: "return",
      asset_id: asset.id,
      from_employee_id: employee.id,
      from_status: "assigned",
      to_status: "in_stock",
      performed_by: performed_by,
      performed_at: NaiveDateTime.utc_now(),
      description: "Asset returned by #{employee.email}",
      metadata: metadata
    })
    |> validate_required([:asset_id])
  end

  @doc """
  Create a transaction for asset transfer.
  """
  def transfer_changeset(asset, from_employee, to_employee, performed_by, metadata \\ %{}) do
    %__MODULE__{}
    |> changeset(%{
      transaction_type: "transfer",
      asset_id: asset.id,
      from_employee_id: from_employee.id,
      to_employee_id: to_employee.id,
      performed_by: performed_by,
      performed_at: NaiveDateTime.utc_now(),
      description: "Asset transferred from #{from_employee.email} to #{to_employee.email}",
      metadata: metadata
    })
    |> validate_required([:asset_id])
  end

  @doc """
  Create a transaction for status change.
  """
  def status_change_changeset(asset, new_status, performed_by, metadata \\ %{}) do
    %__MODULE__{}
    |> changeset(%{
      transaction_type: "status_change",
      asset_id: asset.id,
      from_status: asset.status,
      to_status: new_status,
      performed_by: performed_by,
      performed_at: NaiveDateTime.utc_now(),
      description: "Status changed from #{asset.status} to #{new_status}",
      metadata: metadata
    })
    |> validate_required([:asset_id])
  end

  defp put_default_performed_at(changeset) do
    case get_field(changeset, :performed_at) do
      nil -> put_change(changeset, :performed_at, NaiveDateTime.utc_now())
      _ -> changeset
    end
  end

  defp generate_transaction_amount_hash(changeset) do
    case get_change(changeset, :transaction_amount) do
      nil ->
        changeset

      %Decimal{} = amount ->
        hash = :crypto.hash(:sha256, Decimal.to_string(amount))
        put_change(changeset, :transaction_amount_hash, hash)

      _ ->
        changeset
    end
  end
end
