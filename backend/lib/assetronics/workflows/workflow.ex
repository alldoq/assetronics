defmodule Assetronics.Workflows.Workflow do
  @moduledoc """
  Workflow schema for automated processes.

  Handles onboarding, offboarding, repairs, procurement, and transfers.
  Tracks steps, approvals, and completion status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @workflow_types ~w(onboarding offboarding repair procurement transfer maintenance audit)
  @status_values ~w(pending in_progress completed cancelled failed)
  @priority_values ~w(low normal high urgent)
  @trigger_sources ~w(manual hris_sync scheduled api webhook)

  schema "workflows" do
    field :workflow_type, :string
    field :status, :string, default: "pending"
    field :priority, :string, default: "normal"

    # Related entities
    belongs_to :asset, Assetronics.Assets.Asset
    belongs_to :employee, Assetronics.Employees.Employee
    belongs_to :integration, Assetronics.Integrations.Integration

    # Workflow details
    field :title, :string
    field :description, :string
    field :steps, {:array, :map}, default: []
    field :current_step, :integer, default: 0

    # Assignment and approval
    field :assigned_to, :string
    field :approver, :string
    field :approved_at, :naive_datetime
    field :approval_notes, :string

    # Dates
    field :due_date, :date
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :cancelled_at, :naive_datetime

    # Triggering
    field :triggered_by, :string

    # Metadata
    field :metadata, :map, default: %{}
    field :notes, :string

    # Associations
    has_many :transactions, Assetronics.Transactions.Transaction

    timestamps()
  end

  @doc false
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [
      :workflow_type,
      :status,
      :priority,
      :asset_id,
      :employee_id,
      :integration_id,
      :title,
      :description,
      :steps,
      :current_step,
      :assigned_to,
      :approver,
      :approved_at,
      :approval_notes,
      :due_date,
      :started_at,
      :completed_at,
      :cancelled_at,
      :triggered_by,
      :metadata,
      :notes
    ])
    |> validate_required([:workflow_type, :title, :status])
    |> validate_inclusion(:workflow_type, @workflow_types)
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:priority, @priority_values)
    |> validate_inclusion(:triggered_by, @trigger_sources, allow_nil: true)
    |> validate_number(:current_step, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:employee_id)
    |> foreign_key_constraint(:integration_id)
  end

  @doc """
  Changeset for starting a workflow.
  """
  def start_changeset(workflow, attrs \\ %{}) do
    workflow
    |> changeset(attrs)
    |> put_change(:status, "in_progress")
    |> put_change(:started_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  @doc """
  Changeset for completing a workflow.
  """
  def complete_changeset(workflow, attrs \\ %{}) do
    workflow
    |> changeset(attrs)
    |> put_change(:status, "completed")
    |> put_change(:completed_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> validate_workflow_can_complete()
  end

  @doc """
  Changeset for cancelling a workflow.
  """
  def cancel_changeset(workflow, reason) do
    workflow
    |> change()
    |> put_change(:status, "cancelled")
    |> put_change(:cancelled_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> put_change(:notes, reason)
  end

  defp validate_workflow_can_complete(changeset) do
    current_step = get_field(changeset, :current_step)
    steps = get_field(changeset, :steps) || []

    # current_step should equal or exceed the number of steps to complete
    if current_step < length(steps) do
      add_error(changeset, :current_step, "all steps must be completed before finishing workflow")
    else
      changeset
    end
  end
end
