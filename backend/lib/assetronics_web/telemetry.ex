defmodule AssetronicsWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Console reporter disabled by default - uncomment to enable verbose telemetry logging
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
      # Note: You can view metrics in the Phoenix LiveDashboard at /dev/dashboard instead
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("assetronics.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("assetronics.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("assetronics.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("assetronics.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("assetronics.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Asset Metrics
      summary("assetronics.assets.assign.duration",
        unit: {:native, :millisecond},
        tags: [:tenant]
      ),
      counter("assetronics.assets.assign.success", tags: [:tenant]),
      counter("assetronics.assets.assign.failure", tags: [:tenant]),
      summary("assetronics.assets.return.duration",
        unit: {:native, :millisecond},
        tags: [:tenant]
      ),
      counter("assetronics.assets.return.success", tags: [:tenant]),
      counter("assetronics.assets.return.failure", tags: [:tenant]),
      summary("assetronics.assets.transfer.duration",
        unit: {:native, :millisecond},
        tags: [:tenant]
      ),
      counter("assetronics.assets.transfer.success", tags: [:tenant]),
      counter("assetronics.assets.transfer.failure", tags: [:tenant]),

      # Workflow Metrics
      summary("assetronics.workflows.create.duration",
        unit: {:native, :millisecond},
        tags: [:tenant, :workflow_type]
      ),
      counter("assetronics.workflows.create.success", tags: [:tenant, :workflow_type]),
      counter("assetronics.workflows.create.failure", tags: [:tenant, :workflow_type]),
      summary("assetronics.workflows.complete.duration",
        unit: {:native, :millisecond},
        tags: [:tenant, :workflow_type]
      ),
      counter("assetronics.workflows.complete.success", tags: [:tenant, :workflow_type]),
      counter("assetronics.workflows.complete.failure", tags: [:tenant, :workflow_type]),

      # Employee Metrics
      summary("assetronics.employees.sync.duration",
        unit: {:native, :millisecond},
        tags: [:tenant, :source]
      ),
      counter("assetronics.employees.sync.success", tags: [:tenant, :source]),
      counter("assetronics.employees.sync.failure", tags: [:tenant, :source]),

      # Integration Metrics
      summary("assetronics.integrations.sync.duration",
        unit: {:native, :millisecond},
        tags: [:tenant, :provider]
      ),
      counter("assetronics.integrations.sync.success", tags: [:tenant, :provider]),
      counter("assetronics.integrations.sync.failure", tags: [:tenant, :provider]),
      summary("assetronics.integrations.sync.records",
        tags: [:tenant, :provider],
        description: "Number of records synced"
      ),

      # Notification Metrics
      summary("assetronics.notifications.send.duration",
        unit: {:native, :millisecond},
        tags: [:tenant, :channel]
      ),
      counter("assetronics.notifications.send.success", tags: [:tenant, :channel]),
      counter("assetronics.notifications.send.failure", tags: [:tenant, :channel]),
      counter("assetronics.notifications.send.skipped", tags: [:tenant, :channel])
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {AssetronicsWeb, :count_users, []}
      {__MODULE__, :dispatch_periodic_stats, []}
    ]
  end

  @doc """
  Dispatches periodic telemetry stats about the system.
  Called every 10 seconds by the telemetry poller.
  """
  def dispatch_periodic_stats do
    # This would need to be enhanced to gather stats across all tenants
    # For now, it's a placeholder for future periodic metrics
    :ok
  end
end
