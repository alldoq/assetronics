defmodule Assetronics.Listeners do
  @moduledoc """
  Manages PubSub event listeners for tenants.

  This module provides functions to start and stop event listeners for specific tenants.
  Listeners enable event-driven automation by subscribing to PubSub events and reacting
  to system events.

  Listeners are automatically started for all active tenants when the application boots
  via the Listeners.Initializer module.

  Available listeners:
  - WorkflowAutomationListener: Auto-creates workflows based on events
  - AuditTrailListener: Creates audit records for non-asset events
  - WorkflowCompletionListener: Handles workflow completion feedback loops

  ## Usage

      # Start all listeners for a tenant (usually not needed - done automatically)
      Listeners.start_listeners_for_tenant("acme")

      # Stop all listeners for a tenant
      Listeners.stop_listeners_for_tenant("acme")

      # List running listeners
      Listeners.list_listeners()

      # Check if listeners are running for a tenant
      Listeners.listeners_running?("acme")
  """

  require Logger

  alias Assetronics.Listeners.WorkflowAutomationListener
  alias Assetronics.Listeners.AuditTrailListener
  alias Assetronics.Listeners.WorkflowCompletionListener

  @doc """
  Starts all event listeners for a specific tenant.

  Returns {:ok, pids} where pids is a list of started listener PIDs.
  """
  def start_listeners_for_tenant(tenant) do
    Logger.info("[Listeners] Starting event listeners for tenant: #{tenant}")

    results = [
      start_listener(WorkflowAutomationListener, tenant),
      start_listener(AuditTrailListener, tenant),
      start_listener(WorkflowCompletionListener, tenant)
    ]

    case Enum.filter(results, fn {status, _} -> status == :error end) do
      [] ->
        pids = Enum.map(results, fn {:ok, pid} -> pid end)
        Logger.info("[Listeners] Started #{length(pids)} listeners for tenant: #{tenant}")
        {:ok, pids}

      errors ->
        Logger.error("[Listeners] Failed to start some listeners for tenant #{tenant}: #{inspect(errors)}")
        {:error, errors}
    end
  end

  @doc """
  Stops all event listeners for a specific tenant.
  """
  def stop_listeners_for_tenant(tenant) do
    Logger.info("[Listeners] Stopping event listeners for tenant: #{tenant}")

    results = [
      stop_listener(WorkflowAutomationListener, tenant),
      stop_listener(AuditTrailListener, tenant),
      stop_listener(WorkflowCompletionListener, tenant)
    ]

    case Enum.filter(results, fn status -> status == :error end) do
      [] ->
        Logger.info("[Listeners] Stopped all listeners for tenant: #{tenant}")
        :ok

      _ ->
        Logger.warning("[Listeners] Some listeners may not have stopped cleanly for tenant: #{tenant}")
        :ok
    end
  end

  @doc """
  Lists all running event listeners.

  Returns a list of {tenant, listener_module} tuples.
  """
  def list_listeners do
    Registry.select(Assetronics.ListenerRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.map(fn {module, tenant} -> {tenant, module} end)
  end

  @doc """
  Checks if listeners are running for a specific tenant.
  """
  def listeners_running?(tenant) do
    case Registry.lookup(Assetronics.ListenerRegistry, {WorkflowAutomationListener, tenant}) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  ## Private Functions

  defp start_listener(listener_module, tenant) do
    child_spec = listener_module.child_spec(tenant)

    case DynamicSupervisor.start_child(Assetronics.ListenerSupervisor, child_spec) do
      {:ok, pid} ->
        Logger.debug("[Listeners] Started #{listener_module} for tenant: #{tenant}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("[Listeners] #{listener_module} already running for tenant: #{tenant}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("[Listeners] Failed to start #{listener_module} for tenant #{tenant}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp stop_listener(listener_module, tenant) do
    case Registry.lookup(Assetronics.ListenerRegistry, {listener_module, tenant}) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(Assetronics.ListenerSupervisor, pid)
        Logger.debug("[Listeners] Stopped #{listener_module} for tenant: #{tenant}")
        :ok

      [] ->
        Logger.debug("[Listeners] #{listener_module} not running for tenant: #{tenant}")
        :ok
    end
  end
end
