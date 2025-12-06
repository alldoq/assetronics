defmodule Assetronics.Employees.Employee do
  @moduledoc """
  Employee schema representing company employees.

  Synced from HRIS systems (BambooHR, Rippling, Gusto, etc.).
  All PII is encrypted: names, phone, addresses, SSN, date of birth.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @employment_status_values ~w(active on_leave terminated)
  @work_location_types ~w(office remote hybrid)

  schema "employees" do
    # Basic information (encrypted for privacy)
    field :employee_id, :string
    field :hris_id, :string
    field :first_name, EncryptedFields.EncryptedString, source: :first_name_encrypted
    field :last_name, EncryptedFields.EncryptedString, source: :last_name_encrypted
    field :email, :string
    field :phone, EncryptedFields.EncryptedString, source: :phone_encrypted

    # Employment details
    field :job_title, :string
    field :department, :string  # Legacy field - kept for HRIS sync compatibility
    belongs_to :organization, Assetronics.Organizations.Organization
    belongs_to :department_rel, Assetronics.Departments.Department, foreign_key: :department_id
    belongs_to :manager, Assetronics.Employees.Employee
    field :hire_date, :date
    field :termination_date, :date
    field :employment_status, :string, default: "active"

    # Location
    belongs_to :office_location, Assetronics.Locations.Location
    field :work_location_type, :string
    field :home_address, EncryptedFields.EncryptedMap, source: :home_address_encrypted

    # Personal information (encrypted)
    field :date_of_birth, EncryptedFields.EncryptedString, source: :date_of_birth_encrypted
    field :ssn, EncryptedFields.EncryptedString, source: :ssn_encrypted
    field :national_id, EncryptedFields.EncryptedString, source: :national_id_encrypted

    # Integration sync
    field :last_synced_at, :naive_datetime
    field :sync_source, :string
    field :external_data, :map, default: %{}
    field :last_login_at, :naive_datetime

    # Metadata
    field :notes, :string
    field :custom_fields, :map, default: %{}

    # Associations
    has_many :assets, Assetronics.Assets.Asset
    has_many :workflows, Assetronics.Workflows.Workflow
    has_many :transactions, Assetronics.Transactions.Transaction

    timestamps()
  end

  @doc false
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [
      :employee_id,
      :hris_id,
      :first_name,
      :last_name,
      :email,
      :phone,
      :job_title,
      :department,
      :organization_id,
      :department_id,
      :manager_id,
      :hire_date,
      :termination_date,
      :employment_status,
      :office_location_id,
      :work_location_type,
      :home_address,
      :date_of_birth,
      :ssn,
      :national_id,
      :last_synced_at,
      :sync_source,
      :external_data,
      :notes,
      :custom_fields
    ])
    |> validate_required([:email, :employment_status])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:employment_status, @employment_status_values)
    |> validate_inclusion(:work_location_type, @work_location_types, allow_nil: true)
    |> unique_constraint(:email)
    |> unique_constraint(:employee_id)
    |> foreign_key_constraint(:manager_id)
    |> foreign_key_constraint(:office_location_id)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:department_id)
  end

  @doc """
  Changeset for syncing from HRIS.
  Less strict validations since external data may be incomplete.
  """
  def sync_changeset(employee, attrs) do
    employee
    |> cast(attrs, [
      :employee_id,
      :hris_id,
      :first_name,
      :last_name,
      :email,
      :phone,
      :job_title,
      :department,
      :organization_id,
      :department_id,
      :manager_id,
      :hire_date,
      :termination_date,
      :employment_status,
      :office_location_id,
      :work_location_type,
      :home_address,
      :date_of_birth,
      :ssn,
      :national_id,
      :last_synced_at,
      :sync_source,
      :external_data,
      :notes,
      :custom_fields,
      :last_login_at
    ])
    |> validate_required([:email, :hris_id, :sync_source])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:hris_id)
    |> foreign_key_constraint(:manager_id)
    |> foreign_key_constraint(:office_location_id)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:department_id)
    |> put_change(:last_synced_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end
end
