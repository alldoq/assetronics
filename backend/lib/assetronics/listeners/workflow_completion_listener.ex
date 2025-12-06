defmodule Assetronics.Listeners.WorkflowCompletionListener do
  @moduledoc """
  Handles workflow completion events to create feedback loops between workflows and other entities.

  When workflows complete, this listener:
  - Updates related asset statuses
  - Triggers follow-up workflows
  - Ensures data consistency across the system

  ## Workflow Feedback Loops

  ### Repair Workflow
  - Updates asset status from "in_repair" back to "in_stock"
  - Records last maintenance date

  ### Offboarding Workflow
  - Ensures assets are unassigned
  - Updates asset status to "in_stock"

  ### Procurement Workflow
  - Updates asset status from "on_order" to "in_stock"
  - Records received date

  ### Maintenance Workflow
  - Records last maintenance date on asset
  - Schedules next maintenance if applicable
  """

  use GenServer
  require Logger

  alias Assetronics.Assets
  alias Assetronics.Workflows.Workflow

  ## Client API

  def start_link(tenant) do
    GenServer.start_link(__MODULE__, tenant, name: via_tuple(tenant))
  end

  def child_spec(tenant) do
    %{
      id: {__MODULE__, tenant},
      start: {__MODULE__, :start_link, [tenant]},
      restart: :permanent,
      type: :worker
    }
  end

  ## Server Callbacks

  @impl true
  def init(tenant) do
    Logger.info("[WorkflowCompletionListener] Starting for tenant: #{tenant}")

    # Subscribe to workflow events
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "workflows:#{tenant}")

    {:ok, %{tenant: tenant}}
  end

  @impl true
  def handle_info({event, workflow}, state) when event in ["workflow_completed"] do
    Logger.debug("[WorkflowCompletionListener] Received #{event} for workflow: #{workflow.id}")
    handle_workflow_completion(state.tenant, workflow)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Private Functions

  defp handle_workflow_completion(tenant, %Workflow{} = workflow) do
    case workflow.workflow_type do
      "repair" ->
        handle_repair_completion(tenant, workflow)

      "offboarding" ->
        handle_offboarding_completion(tenant, workflow)

      "procurement" ->
        handle_procurement_completion(tenant, workflow)

      "maintenance" ->
        handle_maintenance_completion(tenant, workflow)

      "onboarding" ->
        handle_onboarding_completion(tenant, workflow)

      _ ->
        Logger.debug("[WorkflowCompletionListener] No feedback loop for workflow type: #{workflow.workflow_type}")
        :ok
    end
  end

  defp handle_repair_completion(tenant, workflow) do
    if workflow.asset_id do
      Logger.info("[WorkflowCompletionListener] Handling repair workflow completion for asset: #{workflow.asset_id}")

      try do
        asset = Assets.get_asset!(tenant, workflow.asset_id)

        # Update asset status from in_repair to in_stock
        if asset.status == "in_repair" do
          metadata = %{
            "last_repair_date" => Date.utc_today() |> Date.to_iso8601(),
            "last_repair_workflow_id" => workflow.id
          }

          case Assets.update_asset(tenant, asset, %{
            status: "in_stock",
            metadata: Map.merge(asset.metadata || %{}, metadata)
          }) do
            {:ok, updated_asset} ->
              Logger.info("[WorkflowCompletionListener] Updated asset #{asset.id} status to in_stock after repair completion")
              {:ok, updated_asset}

            {:error, changeset} ->
              Logger.error("[WorkflowCompletionListener] Failed to update asset after repair: #{inspect(changeset.errors)}")
              :error
          end
        else
          Logger.debug("[WorkflowCompletionListener] Asset #{asset.id} not in repair status, no update needed")
          :ok
        end
      rescue
        Ecto.NoResultsError ->
          Logger.warning("[WorkflowCompletionListener] Asset #{workflow.asset_id} not found for repair workflow")
          :error
      end
    else
      Logger.debug("[WorkflowCompletionListener] Repair workflow has no associated asset")
      :ok
    end
  end

  defp handle_offboarding_completion(tenant, workflow) do
    if workflow.asset_id do
      Logger.info("[WorkflowCompletionListener] Handling offboarding workflow completion for asset: #{workflow.asset_id}")

      try do
        asset = Assets.get_asset!(tenant, workflow.asset_id)

        # Ensure asset is unassigned and available
        if asset.employee_id do
          # Asset is still assigned, should be returned as part of offboarding
          employee = asset.employee_id
          case Assets.return_asset(tenant, asset, employee, workflow.triggered_by || "system") do
            {:ok, returned_asset} ->
              Logger.info("[WorkflowCompletionListener] Returned asset #{asset.id} after offboarding completion")
              {:ok, returned_asset}

            {:error, reason} ->
              Logger.error("[WorkflowCompletionListener] Failed to return asset after offboarding: #{inspect(reason)}")
              :error
          end
        else
          # Asset already unassigned, just ensure it's in correct status
          if asset.status == "assigned" do
            case Assets.update_asset(tenant, asset, %{status: "in_stock"}) do
              {:ok, updated_asset} ->
                Logger.info("[WorkflowCompletionListener] Updated asset #{asset.id} status to in_stock after offboarding")
                {:ok, updated_asset}

              {:error, changeset} ->
                Logger.error("[WorkflowCompletionListener] Failed to update asset status: #{inspect(changeset.errors)}")
                :error
            end
          else
            Logger.debug("[WorkflowCompletionListener] Asset #{asset.id} already in correct status")
            :ok
          end
        end
      rescue
        Ecto.NoResultsError ->
          Logger.warning("[WorkflowCompletionListener] Asset #{workflow.asset_id} not found for offboarding workflow")
          :error
      end
    else
      Logger.debug("[WorkflowCompletionListener] Offboarding workflow has no associated asset")
      :ok
    end
  end

  defp handle_procurement_completion(tenant, workflow) do
    if workflow.asset_id do
      Logger.info("[WorkflowCompletionListener] Handling procurement workflow completion for asset: #{workflow.asset_id}")

      try do
        asset = Assets.get_asset!(tenant, workflow.asset_id)

        # Update asset status from on_order to in_stock
        if asset.status == "on_order" do
          metadata = %{
            "received_date" => Date.utc_today() |> Date.to_iso8601(),
            "procurement_workflow_id" => workflow.id
          }

          case Assets.update_asset(tenant, asset, %{
            status: "in_stock",
            metadata: Map.merge(asset.metadata || %{}, metadata)
          }) do
            {:ok, updated_asset} ->
              Logger.info("[WorkflowCompletionListener] Updated asset #{asset.id} status to in_stock after procurement")
              {:ok, updated_asset}

            {:error, changeset} ->
              Logger.error("[WorkflowCompletionListener] Failed to update asset after procurement: #{inspect(changeset.errors)}")
              :error
          end
        else
          Logger.debug("[WorkflowCompletionListener] Asset #{asset.id} not in on_order status, no update needed")
          :ok
        end
      rescue
        Ecto.NoResultsError ->
          Logger.warning("[WorkflowCompletionListener] Asset #{workflow.asset_id} not found for procurement workflow")
          :error
      end
    else
      Logger.debug("[WorkflowCompletionListener] Procurement workflow has no associated asset")
      :ok
    end
  end

  defp handle_maintenance_completion(tenant, workflow) do
    if workflow.asset_id do
      Logger.info("[WorkflowCompletionListener] Handling maintenance workflow completion for asset: #{workflow.asset_id}")

      try do
        asset = Assets.get_asset!(tenant, workflow.asset_id)

        # Record last maintenance date
        metadata = %{
          "last_maintenance_date" => Date.utc_today() |> Date.to_iso8601(),
          "last_maintenance_workflow_id" => workflow.id
        }

        case Assets.update_asset(tenant, asset, %{
          metadata: Map.merge(asset.metadata || %{}, metadata)
        }) do
          {:ok, updated_asset} ->
            Logger.info("[WorkflowCompletionListener] Updated asset #{asset.id} with maintenance completion date")
            {:ok, updated_asset}

          {:error, changeset} ->
            Logger.error("[WorkflowCompletionListener] Failed to update asset after maintenance: #{inspect(changeset.errors)}")
            :error
        end
      rescue
        Ecto.NoResultsError ->
          Logger.warning("[WorkflowCompletionListener] Asset #{workflow.asset_id} not found for maintenance workflow")
          :error
      end
    else
      Logger.debug("[WorkflowCompletionListener] Maintenance workflow has no associated asset")
      :ok
    end
  end

  defp handle_onboarding_completion(_tenant, workflow) do
    # Onboarding completion could trigger follow-up workflows
    # For example: Schedule 30-day check-in, 90-day review, etc.
    Logger.info("[WorkflowCompletionListener] Onboarding workflow completed for employee: #{workflow.employee_id}")

    # This is a placeholder for future follow-up workflow logic
    # Could create check-in workflows at 30/60/90 day intervals
    :ok
  end

  defp via_tuple(tenant) do
    {:via, Registry, {Assetronics.ListenerRegistry, {__MODULE__, tenant}}}
  end
end
