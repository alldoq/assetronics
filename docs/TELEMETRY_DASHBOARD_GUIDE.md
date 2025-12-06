# Telemetry Dashboard Guide

This guide explains how to access and use the Phoenix LiveDashboard to monitor your Assetronics application metrics.

## Accessing the Dashboard

### Development Environment

The LiveDashboard is available in development at:
```
http://localhost:4000/dev/dashboard
```

### What You'll See

The dashboard provides several tabs:

1. **Home** - System overview with memory and process counts
2. **Metrics** - Live telemetry metrics with charts
3. **Request Logger** - HTTP request logging
4. **Applications** - Running applications and dependencies
5. **Processes** - Erlang/Elixir process information
6. **Ports** - System ports and connections
7. **Sockets** - Active socket connections
8. **ETS** - ETS table information
9. **OS Data** - Operating system metrics

## Available Metrics

### Asset Operations

**Asset Assignment**
- `assetronics.assets.assign.duration` - Time taken to assign assets
- `assetronics.assets.assign.success` - Count of successful assignments
- `assetronics.assets.assign.failure` - Count of failed assignments

**Asset Returns**
- `assetronics.assets.return.duration` - Time taken to return assets
- `assetronics.assets.return.success` - Count of successful returns
- `assetronics.assets.return.failure` - Count of failed returns

**Asset Transfers**
- `assetronics.assets.transfer.duration` - Time taken to transfer assets
- `assetronics.assets.transfer.success` - Count of successful transfers
- `assetronics.assets.transfer.failure` - Count of failed transfers

### Workflow Operations

**Workflow Creation**
- `assetronics.workflows.create.duration` - Time taken to create workflows
- `assetronics.workflows.create.success` - Count of successful creations by type
- `assetronics.workflows.create.failure` - Count of failed creations by type

**Workflow Completion**
- `assetronics.workflows.complete.duration` - Time taken to complete workflows
- `assetronics.workflows.complete.success` - Count of successful completions by type
- `assetronics.workflows.complete.failure` - Count of failed completions by type

### Employee Sync

- `assetronics.employees.sync.duration` - Time taken to sync employees
- `assetronics.employees.sync.success` - Count of successful syncs by source
- `assetronics.employees.sync.failure` - Count of failed syncs by source

### Integration Sync

- `assetronics.integrations.sync.duration` - Time taken for integration syncs
- `assetronics.integrations.sync.success` - Count of successful syncs by provider
- `assetronics.integrations.sync.failure` - Count of failed syncs by provider
- `assetronics.integrations.sync.records` - Number of records synced by provider

### Notifications

- `assetronics.notifications.send.duration` - Time taken to send notifications
- `assetronics.notifications.send.success` - Count of successful sends by channel
- `assetronics.notifications.send.failure` - Count of failed sends by channel
- `assetronics.notifications.send.skipped` - Count of skipped notifications by channel

## Metric Tags

Most metrics include tags for filtering:

- **tenant** - The tenant slug (e.g., "acme")
- **workflow_type** - Type of workflow (e.g., "onboarding", "offboarding", "repair")
- **provider** - Integration provider (e.g., "bamboo_hr", "rippling", "jamf")
- **source** - Data source for employee sync
- **channel** - Notification channel ("email", "in_app", "sms", "push")

## Console Metrics

In development, metrics are also logged to the console. You'll see output like:

```
[Telemetry.Metrics.ConsoleReporter] Got new metric measurement: assetronics.assets.assign.success
[Telemetry.Metrics.ConsoleReporter] %{count: 1} %{tenant: "acme"}
```

## Understanding the Metrics

### Duration Metrics

Duration metrics show how long operations take in milliseconds. Look for:
- **Trends** - Are operations getting slower over time?
- **Spikes** - Are there sudden slowdowns?
- **Outliers** - Are some operations much slower than others?

### Counter Metrics

Counter metrics show how many times something happened. Look for:
- **Success vs Failure Rates** - High failure rates indicate problems
- **Volume Patterns** - Unusual spikes in activity
- **Tenant Distribution** - Are certain tenants driving all the load?

### Example Insights

**"Integration syncs are taking 5x longer than usual"**
- Check `assetronics.integrations.sync.duration` metric
- Filter by provider to see which integration is slow
- Look at `records` count to see if volume increased

**"Asset assignments are failing for tenant X"**
- Check `assetronics.assets.assign.failure` counter
- Filter by tenant to isolate the problem
- Check application logs for error details

**"Notification delivery rate dropped"**
- Compare `success` vs `failure` counters for notifications
- Filter by channel to see if it's email, in-app, or SMS
- Check external service status (email provider, etc.)

## Production Deployment

### Security Warning

The dashboard is currently only available in development. For production:

1. **Add authentication** - Protect the dashboard behind admin-only auth
2. **Use SSL** - Always access over HTTPS
3. **Restrict access** - Limit to admin users only

### Example Production Setup

```elixir
# In router.ex
scope "/admin" do
  pipe_through [:fetch_session, :protect_from_forgery, :require_admin]

  live_dashboard "/dashboard",
    metrics: AssetronicsWeb.Telemetry,
    ecto_repos: [Assetronics.Repo]
end
```

## Integration with Monitoring Tools

While the LiveDashboard is great for development, for production you should integrate with professional monitoring:

### DataDog

```elixir
# Add to mix.exs
{:telemetry_metrics_datadog, "~> 0.1"}

# Add to telemetry.ex children
{TelemetryMetricsDatadog.Reporter,
  api_key: System.get_env("DATADOG_API_KEY"),
  metrics: metrics()}
```

### Prometheus

```elixir
# Add to mix.exs
{:telemetry_metrics_prometheus, "~> 1.0"}

# Add to telemetry.ex children
{TelemetryMetricsPrometheus,
  metrics: metrics(),
  port: 9568}
```

### New Relic

```elixir
# Add to mix.exs
{:new_relic_agent, "~> 1.0"}

# Configure in config/config.exs
config :new_relic_agent,
  license_key: System.get_env("NEW_RELIC_LICENSE_KEY"),
  app_name: "Assetronics"
```

## Troubleshooting

### "Dashboard shows no metrics"

Metrics are only recorded when operations occur. Try:
1. Perform some asset operations (assign, return, transfer)
2. Create workflows
3. Trigger an integration sync
4. Send some notifications

The metrics will appear after these events.

### "Metrics page is blank"

Check that:
1. The application is running
2. Telemetry is properly configured
3. You're accessing `/dev/dashboard` not `/dashboard`
4. The ConsoleReporter is running (check supervision tree)

### "Console shows no telemetry output"

The ConsoleReporter only logs when metrics have new data. Generate some activity and you should see logs like:

```
[Telemetry.Metrics.ConsoleReporter] Got new metric measurement
```

## Next Steps

1. **Monitor in Real-Time** - Keep the dashboard open while using the application
2. **Identify Bottlenecks** - Look for slow operations
3. **Track Failures** - Monitor error rates
4. **Plan Capacity** - Use trends to predict growth
5. **Set Up Alerts** - Connect to monitoring tools for proactive notifications

## Additional Resources

- [Phoenix LiveDashboard Documentation](https://hexdocs.pm/phoenix_live_dashboard)
- [Telemetry Documentation](https://hexdocs.pm/telemetry)
- [Telemetry Metrics](https://hexdocs.pm/telemetry_metrics)
