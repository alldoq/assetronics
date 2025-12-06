defmodule AssetronicsWeb.SettingsJSON do
  alias Assetronics.Settings.TenantSettings

  def show(%{settings: settings}) do
    %{data: data(settings)}
  end

  defp data(%TenantSettings{} = settings) do
    %{
      id: settings.id,
      # Email
      email: %{
        from_address: settings.email_from_address,
        from_name: settings.email_from_name,
        reply_to: settings.email_reply_to,
        bcc_admin: settings.email_bcc_admin
      },
      # Quiet Hours
      quiet_hours: %{
        enabled: settings.default_quiet_hours_enabled,
        start: settings.default_quiet_hours_start,
        end: settings.default_quiet_hours_end,
        timezone: settings.default_timezone
      },
      # Workflow
      workflow: %{
        auto_create_onboarding: settings.workflow_auto_create_onboarding,
        auto_create_offboarding: settings.workflow_auto_create_offboarding,
        default_priority: settings.workflow_default_priority,
        default_due_days: settings.workflow_default_due_days,
        auto_escalate_days: settings.workflow_auto_escalate_days,
        notify_manager_overdue: settings.workflow_notify_manager_overdue
      },
      # Integration
      integration: %{
        sync_frequency_minutes: settings.integration_sync_frequency_minutes,
        max_retries: settings.integration_max_retries,
        retry_backoff_minutes: settings.integration_retry_backoff_minutes,
        conflict_resolution: settings.integration_conflict_resolution,
        notify_on_failure: settings.integration_notify_on_failure
      },
      # Asset
      asset: %{
        depreciation_method: settings.asset_depreciation_method,
        depreciation_months: settings.asset_depreciation_months,
        warranty_alert_days: settings.asset_warranty_alert_days,
        audit_frequency_months: settings.asset_audit_frequency_months,
        tag_prefix: settings.asset_tag_prefix,
        auto_generate_tags: settings.asset_auto_generate_tags,
        require_serial: settings.asset_require_serial,
        enforce_serial_unique: settings.asset_enforce_serial_unique
      },
      # Employee
      employee: %{
        auto_terminate_on_hris_delete: settings.employee_auto_terminate_on_hris_delete,
        termination_asset_return_days: settings.employee_termination_asset_return_days,
        require_return_confirmation: settings.employee_require_return_confirmation,
        sync_frequency_minutes: settings.employee_sync_frequency_minutes
      },
      # Security
      security: %{
        require_2fa: settings.security_require_2fa,
        session_timeout_minutes: settings.security_session_timeout_minutes,
        failed_login_lockout_count: settings.security_failed_login_lockout_count,
        lockout_duration_minutes: settings.security_lockout_duration_minutes,
        password_expiration_days: settings.security_password_expiration_days,
        require_strong_passwords: settings.security_require_strong_passwords,
        api_key_expiration_days: settings.security_api_key_expiration_days
      },
      # Audit
      audit: %{
        enable_detailed_logging: settings.audit_enable_detailed_logging,
        log_retention_days: settings.audit_log_retention_days,
        require_change_approval: settings.audit_require_change_approval,
        approval_threshold_amount: settings.audit_approval_threshold_amount,
        compliance_framework: settings.audit_compliance_framework
      },
      # Reporting
      reporting: %{
        auto_generate: settings.reporting_auto_generate,
        frequency: settings.reporting_frequency,
        default_format: settings.reporting_default_format,
        include_sensitive_data: settings.reporting_include_sensitive_data
      },
      inserted_at: settings.inserted_at,
      updated_at: settings.updated_at
    }
  end
end
