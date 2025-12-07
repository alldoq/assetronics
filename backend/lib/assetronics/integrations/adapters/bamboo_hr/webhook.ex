defmodule Assetronics.Integrations.Adapters.BambooHR.Webhook do
  @moduledoc """
  Handles webhook events from BambooHR for automatic data synchronization.

  BambooHR sends webhooks for various employee lifecycle events including:
  - Employee created
  - Employee updated
  - Employee terminated
  - Employee rehired
  """

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapters.BambooHR.{Client, Api, EmployeeSync}

  require Logger

  @doc """
  Processes an incoming webhook from BambooHR.

  Supports both single employee updates and batch updates.
  """
  def process_webhook(tenant, webhook_payload) do
    Logger.info("Processing BambooHR webhook for tenant: #{tenant}")

    with {:ok, integration} <- get_bamboo_integration(tenant),
         {:ok, result} <- process_webhook_type(tenant, integration, webhook_payload) do
      Logger.info("BambooHR webhook processed successfully: #{inspect(result)}")
      {:ok, result}
    else
      {:error, reason} ->
        Logger.error("Failed to process BambooHR webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Verifies webhook signature from BambooHR.

  BambooHR uses HMAC-SHA256 for webhook signatures.
  """
  def verify_signature(payload, signature, secret) do
    expected_signature =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    if Plug.Crypto.secure_compare(expected_signature, signature) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end

  @doc """
  Handles employee created event.
  """
  def handle_employee_created(tenant, integration, employee_id) do
    Logger.info("Handling employee created event for ID: #{employee_id}")

    with {:ok, employee_data} <- fetch_single_employee(integration, employee_id),
         {:ok, _result} <- EmployeeSync.sync_employee(tenant, employee_data, integration) do
      {:ok, %{action: :created, employee_id: employee_id}}
    end
  end

  @doc """
  Handles employee updated event.
  """
  def handle_employee_updated(tenant, integration, employee_id) do
    Logger.info("Handling employee updated event for ID: #{employee_id}")

    with {:ok, employee_data} <- fetch_single_employee(integration, employee_id),
         {:ok, _result} <- EmployeeSync.sync_employee(tenant, employee_data, integration) do
      {:ok, %{action: :updated, employee_id: employee_id}}
    end
  end

  @doc """
  Handles employee terminated event.
  """
  def handle_employee_terminated(tenant, integration, employee_id, termination_date \\ nil) do
    Logger.info("Handling employee terminated event for ID: #{employee_id}")

    # Create a minimal employee data structure for termination
    employee_data = %{
      "id" => employee_id,
      "employmentStatus" => "Terminated",
      "terminationDate" => termination_date || Date.to_iso8601(Date.utc_today())
    }

    with {:ok, _result} <- EmployeeSync.sync_employee(tenant, employee_data, integration) do
      {:ok, %{action: :terminated, employee_id: employee_id}}
    end
  end

  @doc """
  Handles batch employee updates.
  """
  def handle_batch_update(tenant, integration, employee_ids) do
    Logger.info("Handling batch update for #{length(employee_ids)} employees")

    results = Enum.map(employee_ids, fn employee_id ->
      case fetch_and_sync_employee(tenant, integration, employee_id) do
        {:ok, result} -> {:ok, Map.put(result, :employee_id, employee_id)}
        {:error, reason} -> {:error, %{employee_id: employee_id, error: reason}}
      end
    end)

    successful = Enum.filter(results, &match?({:ok, _}, &1))
    failed = Enum.filter(results, &match?({:error, _}, &1))

    {:ok, %{
      total: length(employee_ids),
      successful: length(successful),
      failed: length(failed),
      results: results
    }}
  end

  # Private functions

  defp get_bamboo_integration(tenant) do
    case Integrations.get_integration_by_provider(tenant, "bamboohr") do
      {:ok, integration} -> {:ok, integration}
      {:error, :not_found} -> {:error, :integration_not_found}
      error -> error
    end
  end

  defp process_webhook_type(tenant, integration, %{"event" => event} = payload) do
    case event do
      "employee.created" ->
        handle_employee_created(tenant, integration, payload["employee_id"])

      "employee.updated" ->
        handle_employee_updated(tenant, integration, payload["employee_id"])

      "employee.terminated" ->
        handle_employee_terminated(
          tenant,
          integration,
          payload["employee_id"],
          payload["termination_date"]
        )

      "employees.batch_update" ->
        handle_batch_update(tenant, integration, payload["employee_ids"])

      _ ->
        Logger.warning("Unknown BambooHR webhook event: #{event}")
        {:ok, %{action: :ignored, event: event}}
    end
  end

  defp process_webhook_type(tenant, integration, %{"employees" => employee_ids}) when is_list(employee_ids) do
    # Handle batch webhook format
    handle_batch_update(tenant, integration, employee_ids)
  end

  defp process_webhook_type(_tenant, _integration, payload) do
    Logger.error("Unrecognized BambooHR webhook payload format: #{inspect(payload)}")
    {:error, :invalid_payload_format}
  end

  defp fetch_single_employee(integration, employee_id) do
    client = Client.build_client(integration)

    case Api.fetch_employees(client) do
      {:ok, employees} ->
        case Enum.find(employees, &(to_string(&1["id"]) == to_string(employee_id))) do
          nil -> {:error, :employee_not_found}
          employee -> {:ok, employee}
        end

      error ->
        error
    end
  end

  defp fetch_and_sync_employee(tenant, integration, employee_id) do
    with {:ok, employee_data} <- fetch_single_employee(integration, employee_id),
         {:ok, action, _} <- EmployeeSync.sync_employee(tenant, employee_data, integration) do
      {:ok, %{action: action}}
    end
  end
end