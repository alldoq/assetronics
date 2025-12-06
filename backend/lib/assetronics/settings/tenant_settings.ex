defmodule Assetronics.Settings.TenantSettings do
  @moduledoc """
  Tenant-wide system settings including workflow defaults,
  integration settings, security policies, etc.

  One record per tenant.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tenant_settings" do
    # Email Configuration
    field :email_from_address, :string
    field :email_from_name, :string
    field :email_reply_to, :string
    field :email_bcc_admin, :boolean, default: false

    # Quiet Hours (default for all users)
    field :default_quiet_hours_enabled, :boolean, default: false
    field :default_quiet_hours_start, :time
    field :default_quiet_hours_end, :time
    field :default_timezone, :string, default: "UTC"

    # Workflow Settings
    field :workflow_auto_create_onboarding, :boolean, default: true
    field :workflow_auto_create_offboarding, :boolean, default: true
    field :workflow_default_priority, :string, default: "normal"
    field :workflow_default_due_days, :integer, default: 7
    field :workflow_auto_escalate_days, :integer, default: 3
    field :workflow_notify_manager_overdue, :boolean, default: true

    # Integration Settings
    field :integration_sync_frequency_minutes, :integer, default: 60
    field :integration_max_retries, :integer, default: 3
    field :integration_retry_backoff_minutes, :integer, default: 5
    field :integration_conflict_resolution, :string, default: "last_write_wins"
    field :integration_notify_on_failure, :boolean, default: true

    # Asset Management Settings
    field :asset_depreciation_method, :string, default: "straight_line"
    field :asset_depreciation_months, :integer, default: 36
    field :asset_warranty_alert_days, :integer, default: 30
    field :asset_audit_frequency_months, :integer, default: 12
    field :asset_tag_prefix, :string
    field :asset_auto_generate_tags, :boolean, default: true
    field :asset_require_serial, :boolean, default: false
    field :asset_enforce_serial_unique, :boolean, default: true

    # Employee Management Settings
    field :employee_auto_terminate_on_hris_delete, :boolean, default: false
    field :employee_termination_asset_return_days, :integer, default: 7
    field :employee_require_return_confirmation, :boolean, default: true
    field :employee_sync_frequency_minutes, :integer, default: 60

    # Security & Access Settings
    field :security_require_2fa, :boolean, default: false
    field :security_session_timeout_minutes, :integer, default: 480
    field :security_failed_login_lockout_count, :integer, default: 5
    field :security_lockout_duration_minutes, :integer, default: 30
    field :security_password_expiration_days, :integer
    field :security_require_strong_passwords, :boolean, default: true
    field :security_api_key_expiration_days, :integer, default: 365

    # Audit & Compliance Settings
    field :audit_enable_detailed_logging, :boolean, default: true
    field :audit_log_retention_days, :integer, default: 365
    field :audit_require_change_approval, :boolean, default: false
    field :audit_approval_threshold_amount, :decimal
    field :audit_compliance_framework, :string, default: "none"

    # Reporting Settings
    field :reporting_auto_generate, :boolean, default: false
    field :reporting_frequency, :string, default: "monthly"
    field :reporting_default_format, :string, default: "pdf"
    field :reporting_include_sensitive_data, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      # Email
      :email_from_address,
      :email_from_name,
      :email_reply_to,
      :email_bcc_admin,
      # Quiet Hours
      :default_quiet_hours_enabled,
      :default_quiet_hours_start,
      :default_quiet_hours_end,
      :default_timezone,
      # Workflow
      :workflow_auto_create_onboarding,
      :workflow_auto_create_offboarding,
      :workflow_default_priority,
      :workflow_default_due_days,
      :workflow_auto_escalate_days,
      :workflow_notify_manager_overdue,
      # Integration
      :integration_sync_frequency_minutes,
      :integration_max_retries,
      :integration_retry_backoff_minutes,
      :integration_conflict_resolution,
      :integration_notify_on_failure,
      # Asset
      :asset_depreciation_method,
      :asset_depreciation_months,
      :asset_warranty_alert_days,
      :asset_audit_frequency_months,
      :asset_tag_prefix,
      :asset_auto_generate_tags,
      :asset_require_serial,
      :asset_enforce_serial_unique,
      # Employee
      :employee_auto_terminate_on_hris_delete,
      :employee_termination_asset_return_days,
      :employee_require_return_confirmation,
      :employee_sync_frequency_minutes,
      # Security
      :security_require_2fa,
      :security_session_timeout_minutes,
      :security_failed_login_lockout_count,
      :security_lockout_duration_minutes,
      :security_password_expiration_days,
      :security_require_strong_passwords,
      :security_api_key_expiration_days,
      # Audit
      :audit_enable_detailed_logging,
      :audit_log_retention_days,
      :audit_require_change_approval,
      :audit_approval_threshold_amount,
      :audit_compliance_framework,
      # Reporting
      :reporting_auto_generate,
      :reporting_frequency,
      :reporting_default_format,
      :reporting_include_sensitive_data
    ])
    |> validate_required([])
    |> validate_inclusion(:workflow_default_priority, ~w(low normal high urgent))
    |> validate_inclusion(:asset_depreciation_method, ~w(straight_line declining_balance))
    |> validate_inclusion(:integration_conflict_resolution, ~w(last_write_wins manual_review source_wins))
    |> validate_inclusion(:audit_compliance_framework, ~w(none HIPAA GDPR SOC2 ISO27001))
    |> validate_inclusion(:reporting_frequency, ~w(daily weekly monthly quarterly))
    |> validate_inclusion(:reporting_default_format, ~w(pdf csv excel))
    |> validate_number(:workflow_default_due_days, greater_than: 0)
    |> validate_number(:integration_sync_frequency_minutes, greater_than: 0)
    |> validate_number(:security_session_timeout_minutes, greater_than: 0)
  end
end
