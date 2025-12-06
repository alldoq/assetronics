defmodule Assetronics.Repo.TenantMigrations.CreateSettingsTables do
  use Ecto.Migration

  def change do
    # User Notification Preferences (per user)
    create table(:user_notification_preferences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      # Notification type (asset_assigned, asset_returned, workflow_assigned, etc.)
      add :notification_type, :string, null: false

      # Channels enabled for this notification type
      add :email_enabled, :boolean, default: true
      add :in_app_enabled, :boolean, default: true
      add :sms_enabled, :boolean, default: false
      add :push_enabled, :boolean, default: false

      # Frequency
      add :frequency, :string, default: "immediate" # immediate, daily_digest, weekly_digest, off

      # Quiet hours
      add :respect_quiet_hours, :boolean, default: true

      timestamps()
    end

    create index(:user_notification_preferences, [:user_id])
    create unique_index(:user_notification_preferences, [:user_id, :notification_type])

    # Tenant System Settings (tenant-wide configuration)
    create table(:tenant_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # SMS/Twilio Configuration (tenant-wide, encrypted)
      add :twilio_enabled, :boolean, default: false
      add :twilio_account_sid_encrypted, :binary
      add :twilio_auth_token_encrypted, :binary
      add :twilio_from_number, :string

      # Email Configuration
      add :email_from_address, :string
      add :email_from_name, :string
      add :email_reply_to, :string
      add :email_bcc_admin, :boolean, default: false

      # Quiet Hours (default for all users)
      add :default_quiet_hours_enabled, :boolean, default: false
      add :default_quiet_hours_start, :time
      add :default_quiet_hours_end, :time
      add :default_timezone, :string, default: "UTC"

      # Workflow Settings
      add :workflow_auto_create_onboarding, :boolean, default: true
      add :workflow_auto_create_offboarding, :boolean, default: true
      add :workflow_default_priority, :string, default: "normal"
      add :workflow_default_due_days, :integer, default: 7
      add :workflow_auto_escalate_days, :integer, default: 3
      add :workflow_notify_manager_overdue, :boolean, default: true

      # Integration Settings
      add :integration_sync_frequency_minutes, :integer, default: 60
      add :integration_max_retries, :integer, default: 3
      add :integration_retry_backoff_minutes, :integer, default: 5
      add :integration_conflict_resolution, :string, default: "last_write_wins"
      add :integration_notify_on_failure, :boolean, default: true

      # Asset Management Settings
      add :asset_depreciation_method, :string, default: "straight_line"
      add :asset_depreciation_months, :integer, default: 36
      add :asset_warranty_alert_days, :integer, default: 30
      add :asset_audit_frequency_months, :integer, default: 12
      add :asset_tag_prefix, :string
      add :asset_auto_generate_tags, :boolean, default: true
      add :asset_require_serial, :boolean, default: false
      add :asset_enforce_serial_unique, :boolean, default: true

      # Employee Management Settings
      add :employee_auto_terminate_on_hris_delete, :boolean, default: false
      add :employee_termination_asset_return_days, :integer, default: 7
      add :employee_require_return_confirmation, :boolean, default: true
      add :employee_sync_frequency_minutes, :integer, default: 60

      # Security & Access Settings
      add :security_require_2fa, :boolean, default: false
      add :security_session_timeout_minutes, :integer, default: 480
      add :security_failed_login_lockout_count, :integer, default: 5
      add :security_lockout_duration_minutes, :integer, default: 30
      add :security_password_expiration_days, :integer
      add :security_require_strong_passwords, :boolean, default: true
      add :security_api_key_expiration_days, :integer, default: 365

      # Audit & Compliance Settings
      add :audit_enable_detailed_logging, :boolean, default: true
      add :audit_log_retention_days, :integer, default: 365
      add :audit_require_change_approval, :boolean, default: false
      add :audit_approval_threshold_amount, :decimal, precision: 12, scale: 2
      add :audit_compliance_framework, :string, default: "none"

      # Reporting Settings
      add :reporting_auto_generate, :boolean, default: false
      add :reporting_frequency, :string, default: "monthly"
      add :reporting_default_format, :string, default: "pdf"
      add :reporting_include_sensitive_data, :boolean, default: false

      timestamps()
    end

    # One settings record per tenant
    create unique_index(:tenant_settings, [:id])
  end
end
