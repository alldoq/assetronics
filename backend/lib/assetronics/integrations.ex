defmodule Assetronics.Integrations do
  @moduledoc """
  The Integrations context.

  Handles external system integrations:
  - CRUD operations for integrations
  - Connection management
  - Sync operations
  - OAuth token management
  - All credentials encrypted with Cloak
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Integrations.Integration
  alias Assetronics.Integrations.Adapter

  @doc """
  Returns the list of integrations for a tenant.

  ## Examples

      iex> list_integrations("acme")
      [%Integration{}, ...]

  """
  def list_integrations(tenant, opts \\ []) do
    query = from(i in Integration, order_by: [asc: i.name])

    query
    |> apply_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single integration.

  Raises `Ecto.NoResultsError` if the Integration does not exist.

  ## Examples

      iex> get_integration!("acme", "123")
      %Integration{}

  """
  def get_integration!(tenant, id) do
    Repo.get!(Integration, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets an integration by provider.

  ## Examples

      iex> get_integration_by_provider("acme", "bamboohr")
      {:ok, %Integration{}}

  """
  def get_integration_by_provider(tenant, provider) do
    case Repo.one(from(i in Integration, where: i.provider == ^provider), prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      integration -> {:ok, integration}
    end
  end

  @doc """
  Gets an integration by provider name for a tenant.
  Returns the first active match.
  """
  def get_integration_by_provider(tenant, provider) do
    query = from(i in Integration, 
      where: i.provider == ^provider and i.status == "active",
      limit: 1
    )
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates an integration.

  ## Examples

      iex> create_integration("acme", %{name: "BambooHR", provider: "bamboohr", ...})
      {:ok, %Integration{}}

  """
  def create_integration(tenant, attrs \\ %{}) do
    changeset = Integration.changeset(%Integration{}, attrs)

    # Log validation errors for debugging
    if !changeset.valid? do
      require Logger
      Logger.error("Integration validation failed: #{inspect(changeset.errors)}")
    end

    changeset
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "integration_created")
  end

  @doc """
  Updates an integration.

  ## Examples

      iex> update_integration("acme", integration, %{sync_enabled: true})
      {:ok, %Integration{}}

  """
  def update_integration(tenant, %Integration{} = integration, attrs) do
    integration
    |> Integration.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "integration_updated")
  end

  @doc """
  Deletes an integration.

  ## Examples

      iex> delete_integration("acme", integration)
      {:ok, %Integration{}}

  """
  def delete_integration(tenant, %Integration{} = integration) do
    Repo.delete(integration, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking integration changes.

  ## Examples

      iex> change_integration(integration)
      %Ecto.Changeset{data: %Integration{}}

  """
  def change_integration(%Integration{} = integration, attrs \\ %{}) do
    Integration.changeset(integration, attrs)
  end

  @doc """
  Updates OAuth tokens for an integration.

  ## Examples

      iex> update_tokens("acme", integration, "new_access_token", "new_refresh_token", 3600)
      {:ok, %Integration{}}

  """
  def update_tokens(tenant, %Integration{} = integration, access_token, refresh_token, expires_in) do
    integration
    |> Integration.update_tokens_changeset(access_token, refresh_token, expires_in)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Records a successful sync.

  ## Examples

      iex> record_sync_success("acme", integration)
      {:ok, %Integration{}}

  """
  def record_sync_success(tenant, %Integration{} = integration, result \\ %{}) do
    integration
    |> Integration.sync_completed_changeset("success", result)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "integration_sync_completed")
  end

  @doc """
  Records a failed sync.

  ## Examples

      iex> record_sync_failure("acme", integration, "Connection timeout")
      {:ok, %Integration{}}

  """
  def record_sync_failure(tenant, %Integration{} = integration, error_message) do
    integration
    |> Integration.sync_completed_changeset("failed", error_message)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "integration_sync_failed")
  end

  @doc """
  Lists active integrations (enabled and not in error state).

  ## Examples

      iex> list_active_integrations("acme")
      [%Integration{}, ...]

  """
  def list_active_integrations(tenant) do
    query =
      from i in Integration,
        where: i.status == "active",
        where: i.sync_enabled == true,
        order_by: [asc: i.name]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists integrations by type.

  ## Examples

      iex> list_integrations_by_type("acme", "hris")
      [%Integration{}, ...]

  """
  def list_integrations_by_type(tenant, integration_type) do
    query =
      from i in Integration,
        where: i.integration_type == ^integration_type,
        order_by: [asc: i.name]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists integrations that need syncing.

  Returns integrations where sync is enabled and next_sync_at is in the past.

  ## Examples

      iex> list_integrations_needing_sync("acme")
      [%Integration{}, ...]

  """
  def list_integrations_needing_sync(tenant) do
    now = DateTime.utc_now()

    query =
      from i in Integration,
        where: i.sync_enabled == true,
        where: i.status == "active",
        where: not is_nil(i.next_sync_at),
        where: i.next_sync_at <= ^now,
        order_by: [asc: i.next_sync_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists integrations with errors.

  ## Examples

      iex> list_integrations_with_errors("acme")
      [%Integration{}, ...]

  """
  def list_integrations_with_errors(tenant) do
    query =
      from i in Integration,
        where: i.status == "error" or i.last_sync_status == "failed",
        order_by: [desc: i.last_sync_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Enables sync for an integration.

  ## Examples

      iex> enable_sync("acme", integration)
      {:ok, %Integration{}}

  """
  def enable_sync(tenant, %Integration{} = integration) do
    next_sync = DateTime.utc_now()

    integration
    |> Integration.changeset(%{
      sync_enabled: true,
      status: "active",
      next_sync_at: next_sync
    })
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Disables sync for an integration.

  ## Examples

      iex> disable_sync("acme", integration)
      {:ok, %Integration{}}

  """
  def disable_sync(tenant, %Integration{} = integration) do
    integration
    |> Integration.changeset(%{
      sync_enabled: false,
      next_sync_at: nil
    })
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Triggers a manual sync for an integration.

  Enqueues an Oban job to perform the sync.

  ## Examples

      iex> trigger_sync("acme", integration)
      {:ok, %Oban.Job{}}

  """
  def trigger_sync(tenant, %Integration{} = integration) do
    # Update status to syncing
    {:ok, _updated_integration} =
      integration
      |> Integration.changeset(%{status: "syncing"})
      |> Repo.update(prefix: Triplex.to_prefix(tenant))

    # Enqueue Oban job
    %{
      tenant: tenant,
      integration_id: integration.id,
      integration_type: integration.integration_type,
      provider: integration.provider
    }
    |> Assetronics.Workers.SyncIntegrationWorker.new(queue: :integrations)
    |> Oban.insert()
  end

  @doc """
  Tests connection to an integration.

  Returns {:ok, :connected} or {:error, reason}.

  ## Examples

      iex> test_connection("acme", integration)
      {:ok, :connected}

  """
  def test_connection(_tenant, %Integration{} = integration) do
    # Use the adapter to test the connection
    Adapter.dispatch_test(integration)
  end

  @doc """
  Gets sync history for an integration.

  TODO: This currently returns the integration's most recent sync state.
  For proper sync history, implement a separate sync_logs table to track
  each sync execution with full details.

  ## Examples

      iex> get_sync_history("acme", integration_id, 50)
      [%Integration{}, ...]

  """
  def get_sync_history(tenant, integration_id, limit \\ 50) when is_integer(limit) and limit > 0 do
    # TODO: Query from a dedicated sync_logs table when implemented
    # For now, return the integration itself so controller doesn't break
    case Repo.get(Integration, integration_id, prefix: Triplex.to_prefix(tenant)) do
      nil -> []
      integration -> [integration]
    end
  end

  @doc """
  Gets the active integration to use for a specific integration type.

  Priority order:
  1. Primary integration (if is_primary = true)
  2. Single active integration
  3. Most recently updated active integration

  ## Examples

      iex> get_integration_for_type("acme", "hris")
      {:ok, %Integration{provider: "bamboohr"}}

      iex> get_integration_for_type("acme", "mdm")
      {:error, :no_active_integration}

  """
  def get_integration_for_type(tenant, integration_type) do
    # Try to get primary integration first
    case get_primary_integration(tenant, integration_type) do
      %Integration{} = integration ->
        {:ok, integration}

      nil ->
        # Fall back to any active integration
        case list_active_by_type(tenant, integration_type) do
          [] -> {:error, :no_active_integration}
          [single] -> {:ok, single}
          multiple -> {:ok, select_most_recent(multiple)}
        end
    end
  end

  @doc """
  Gets the primary integration for a specific type.

  Returns nil if no primary integration is set.

  ## Examples

      iex> get_primary_integration("acme", "hris")
      %Integration{is_primary: true, provider: "bamboohr"}

  """
  def get_primary_integration(tenant, integration_type) do
    query =
      from i in Integration,
        where: i.integration_type == ^integration_type,
        where: i.is_primary == true,
        where: i.status == "active"

    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists all active integrations for a specific type.

  ## Examples

      iex> list_active_by_type("acme", "hris")
      [%Integration{}, ...]

  """
  def list_active_by_type(tenant, integration_type) do
    query =
      from i in Integration,
        where: i.integration_type == ^integration_type,
        where: i.status == "active",
        order_by: [desc: i.updated_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Sets an integration as the primary for its type.

  Automatically unsets any existing primary integration of the same type.

  ## Examples

      iex> set_as_primary("acme", integration)
      {:ok, %Integration{is_primary: true}}

  """
  def set_as_primary(tenant, %Integration{} = integration) do
    prefix = Triplex.to_prefix(tenant)

    Repo.transaction(fn ->
      # Unset any existing primary for this integration type
      query =
        from i in Integration,
          where: i.integration_type == ^integration.integration_type,
          where: i.is_primary == true,
          where: i.id != ^integration.id

      Repo.update_all(query, [set: [is_primary: false]], prefix: prefix)

      # Set this integration as primary
      integration
      |> Integration.changeset(%{is_primary: true})
      |> Repo.update(prefix: prefix)
      |> case do
        {:ok, updated} -> updated
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Unsets an integration as primary.

  ## Examples

      iex> unset_primary("acme", integration)
      {:ok, %Integration{is_primary: false}}

  """
  def unset_primary(tenant, %Integration{} = integration) do
    integration
    |> Integration.changeset(%{is_primary: false})
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  # Private functions

  defp select_most_recent(integrations) do
    Enum.max_by(integrations, & &1.updated_at, DateTime)
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:integration_type, integration_type}, query ->
        from(i in query, where: i.integration_type == ^integration_type)

      {:provider, provider}, query ->
        from(i in query, where: i.provider == ^provider)

      {:status, status}, query ->
        from(i in query, where: i.status == ^status)

      {:sync_enabled, sync_enabled}, query ->
        from(i in query, where: i.sync_enabled == ^sync_enabled)

      _, query ->
        query
    end)
  end

  defp broadcast_result({:ok, integration} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "integrations:#{tenant}",
      {event, integration}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result

  # Placeholder connection test functions
end
