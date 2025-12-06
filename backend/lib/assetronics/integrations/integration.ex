defmodule Assetronics.Integrations.Integration do
  @moduledoc """
  Integration schema for external system connections.

  All authentication credentials are encrypted:
  - API keys, secrets, tokens
  - OAuth access/refresh tokens
  - Webhook secrets

  Supports HRIS, Finance/ERP, ITSM, MDM, Procurement, and Communication integrations.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.EncryptedFields

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @integration_types ~w(hris finance itsm mdm procurement communication shipping email other)
  @providers ~w(
    bamboohr rippling gusto adp
    netsuite quickbooks xero sage_intacct
    servicenow jira freshservice
    jamf intune google_workspace
    dell coupa ariba
    slack teams
    gmail microsoft_graph
    fedex ups dhl
    other
  )
  @status_values ~w(active inactive error syncing)
  @auth_types ~w(oauth2 api_key basic bearer custom)
  @sync_frequencies ~w(realtime hourly daily weekly manual)
  @sync_directions ~w(bidirectional inbound_only outbound_only)
  @sync_statuses ~w(success partial failed)

  schema "integrations" do
    field :name, :string
    field :integration_type, :string
    field :provider, :string
    field :status, :string, default: "inactive"
    field :is_primary, :boolean, default: false

    # Authentication (all encrypted)
    field :auth_type, :string
    field :api_key, EncryptedFields.EncryptedString, source: :api_key_encrypted
    field :api_secret, EncryptedFields.EncryptedString, source: :api_secret_encrypted
    field :access_token, EncryptedFields.EncryptedString, source: :access_token_encrypted
    field :refresh_token, EncryptedFields.EncryptedString, source: :refresh_token_encrypted
    field :token_expires_at, :naive_datetime
    field :auth_config, EncryptedFields.EncryptedMap, source: :auth_config_encrypted

    # Connection details
    field :base_url, :string
    field :api_version, :string
    field :environment, :string

    # Sync configuration
    field :sync_enabled, :boolean, default: false
    field :sync_frequency, :string
    field :sync_direction, :string
    field :sync_config, :map, default: %{}

    # Sync status
    field :last_sync_at, :naive_datetime
    field :last_sync_status, :string
    field :last_sync_error, :string
    field :next_sync_at, :naive_datetime
    field :total_syncs, :integer, default: 0
    field :failed_syncs, :integer, default: 0

    # Webhook configuration
    field :webhook_url, :string
    field :webhook_secret, EncryptedFields.EncryptedString, source: :webhook_secret_encrypted
    field :webhook_events, {:array, :string}, default: []

    # Metadata
    field :notes, :string
    field :custom_fields, :map, default: %{}

    # Associations
    has_many :workflows, Assetronics.Workflows.Workflow

    timestamps()
  end

  @doc false
  def changeset(integration, attrs) do
    integration
    |> cast(attrs, [
      :name,
      :integration_type,
      :provider,
      :status,
      :is_primary,
      :auth_type,
      :api_key,
      :api_secret,
      :access_token,
      :refresh_token,
      :token_expires_at,
      :auth_config,
      :base_url,
      :api_version,
      :environment,
      :sync_enabled,
      :sync_frequency,
      :sync_direction,
      :sync_config,
      :last_sync_at,
      :last_sync_status,
      :last_sync_error,
      :next_sync_at,
      :total_syncs,
      :failed_syncs,
      :webhook_url,
      :webhook_secret,
      :webhook_events,
      :notes,
      :custom_fields
    ])
    |> validate_required([:name, :integration_type, :provider, :auth_type])
    |> validate_inclusion(:integration_type, @integration_types)
    |> validate_inclusion(:provider, @providers)
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:auth_type, @auth_types)
    |> validate_inclusion(:sync_frequency, @sync_frequencies, allow_nil: true)
    |> validate_inclusion(:sync_direction, @sync_directions, allow_nil: true)
    |> validate_inclusion(:last_sync_status, @sync_statuses, allow_nil: true)
    |> validate_credentials()
    |> validate_oauth_config()
  end

  @doc """
  Changeset for updating sync status after a sync operation.
  """
  def sync_completed_changeset(integration, status, metadata_or_error \\ nil) do
    {error, metadata} = case metadata_or_error do
      nil -> {nil, nil}
      error when is_binary(error) -> {error, nil}
      metadata when is_map(metadata) -> {nil, metadata}
      _ -> {nil, nil}
    end

    # Determine the integration status based on sync result
    integration_status = case status do
      "success" -> "active"
      "failed" -> "error"
      "partial" -> "active"  # Still active even if partial sync
      _ -> "active"  # Default to active
    end

    changeset = integration
    |> change()
    |> put_change(:status, integration_status)  # Update integration status
    |> put_change(:last_sync_at, DateTime.utc_now())
    |> put_change(:last_sync_status, status)
    |> put_change(:last_sync_error, error)
    |> increment_sync_counters(status)
    |> calculate_next_sync()

    # Store metadata in custom_fields if present
    if status == "success" && metadata do
      existing_custom_fields = integration.custom_fields || %{}
      updated_custom_fields = Map.put(existing_custom_fields, "sync_metadata", metadata)
      put_change(changeset, :custom_fields, updated_custom_fields)
    else
      changeset
    end
  end

  @doc """
  Changeset for updating OAuth tokens.
  """
  def update_tokens_changeset(integration, access_token, refresh_token, expires_in) do
    # Convert DateTime to NaiveDateTime for database storage
    # Truncate to seconds (no microseconds) as required by :naive_datetime
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(expires_in, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()

    integration
    |> change()
    |> put_change(:access_token, access_token)
    |> put_change(:refresh_token, refresh_token)
    |> put_change(:token_expires_at, expires_at)
  end

  defp validate_credentials(changeset) do
    auth_type = get_field(changeset, :auth_type)
    status = get_field(changeset, :status)

    case auth_type do
      "api_key" ->
        validate_required(changeset, [:api_key])
      "oauth2" ->
        # OAuth integrations don't have access_token at creation (status: inactive)
        # Tokens are added after OAuth flow completes
        if status == "active" do
          validate_required(changeset, [:access_token])
        else
          changeset
        end
      "basic" ->
        validate_required(changeset, [:api_key, :api_secret])
      "bearer" ->
        # Bearer tokens also obtained via OAuth flow for some providers
        if status == "active" do
          validate_required(changeset, [:access_token])
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_oauth_config(changeset) do
    auth_type = get_field(changeset, :auth_type)
    provider = get_field(changeset, :provider)

    if auth_type == "oauth2" do
      auth_config = get_field(changeset, :auth_config)

      case auth_config do
        %{"client_id" => client_id, "client_secret" => client_secret}
        when is_binary(client_id) and is_binary(client_secret) and
             byte_size(client_id) > 0 and byte_size(client_secret) > 0 ->
          # For Jamf, also validate endpoint is present
          if provider == "jamf" do
            validate_jamf_endpoint(changeset, auth_config)
          else
            changeset
          end

        _ ->
          add_error(changeset, :auth_config, "must contain client_id and client_secret for OAuth2")
      end
    else
      changeset
    end
  end

  defp validate_jamf_endpoint(changeset, auth_config) do
    case auth_config do
      %{"endpoint" => endpoint} when is_binary(endpoint) and byte_size(endpoint) > 0 ->
        changeset
      _ ->
        add_error(changeset, :auth_config, "must contain endpoint URL for Jamf OAuth2")
    end
  end

  defp increment_sync_counters(changeset, status) do
    total_syncs = get_field(changeset, :total_syncs) || 0
    failed_syncs = get_field(changeset, :failed_syncs) || 0

    changeset
    |> put_change(:total_syncs, total_syncs + 1)
    |> maybe_increment_failed(status, failed_syncs)
  end

  defp maybe_increment_failed(changeset, "failed", failed_syncs) do
    put_change(changeset, :failed_syncs, failed_syncs + 1)
  end
  defp maybe_increment_failed(changeset, _, _), do: changeset

  defp calculate_next_sync(changeset) do
    sync_frequency = get_field(changeset, :sync_frequency)
    sync_enabled = get_field(changeset, :sync_enabled)

    if sync_enabled do
      next_sync = calculate_next_sync_time(sync_frequency)
      put_change(changeset, :next_sync_at, next_sync)
    else
      changeset
    end
  end

  defp calculate_next_sync_time("hourly"), do: DateTime.add(DateTime.utc_now(), 3600, :second)
  defp calculate_next_sync_time("daily"), do: DateTime.add(DateTime.utc_now(), 86400, :second)
  defp calculate_next_sync_time("weekly"), do: DateTime.add(DateTime.utc_now(), 604800, :second)
  defp calculate_next_sync_time(_), do: nil
end
