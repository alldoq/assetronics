defmodule Assetronics.Repo.Migrations.CreateIntegrations do
  use Ecto.Migration

  def change do
    create table(:integrations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      
      add :name, :string, null: false
      add :integration_type, :string, null: false  # hris, finance, itsm, mdm, procurement, communication
      add :provider, :string, null: false  # bamboohr, workday, netsuite, quickbooks, slack, jamf, etc.
      add :status, :string, default: "inactive"  # active, inactive, error, syncing
      
      # Authentication (all encrypted)
      add :auth_type, :string  # oauth2, api_key, basic, custom
      add :api_key_encrypted, :binary  # Encrypted
      add :api_secret_encrypted, :binary  # Encrypted
      add :access_token_encrypted, :binary  # Encrypted
      add :refresh_token_encrypted, :binary  # Encrypted
      add :token_expires_at, :naive_datetime
      add :auth_config_encrypted, :binary  # Encrypted JSON with custom auth config
      
      # Connection details
      add :base_url, :string
      add :api_version, :string
      add :environment, :string  # production, sandbox, development
      
      # Sync configuration
      add :sync_enabled, :boolean, default: false
      add :sync_frequency, :string  # realtime, hourly, daily, weekly, manual
      add :sync_direction, :string  # bidirectional, inbound_only, outbound_only
      add :sync_config, :map, default: %{}  # Field mappings, filters, etc.
      
      # Sync status
      add :last_sync_at, :naive_datetime
      add :last_sync_status, :string  # success, partial, failed
      add :last_sync_error, :text
      add :next_sync_at, :naive_datetime
      add :total_syncs, :integer, default: 0
      add :failed_syncs, :integer, default: 0
      
      # Webhook configuration
      add :webhook_url, :string
      add :webhook_secret_encrypted, :binary  # Encrypted
      add :webhook_events, {:array, :string}, default: []
      
      # Metadata
      add :notes, :text
      add :custom_fields, :map, default: %{}
      
      timestamps()
    end

    create index(:integrations, [:integration_type])
    create index(:integrations, [:provider])
    create index(:integrations, [:status])
    create index(:integrations, [:sync_enabled])
  end
end
