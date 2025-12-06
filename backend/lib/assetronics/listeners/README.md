# PubSub event listeners

Event listeners enable event-driven automation by subscribing to PubSub events and reacting to system changes.

## Available listeners

### WorkflowAutomationListener

Automatically creates workflows based on system events:

- **Employee terminated** → Creates offboarding workflow
- **Asset status changed to "in_repair"** → Creates repair workflow
- **Asset status changed to "lost" or "stolen"** → Creates incident workflow

### AuditTrailListener

Creates audit trail records for non-asset events:

- **Employee events**: created, updated, terminated, synced
- **Workflow events**: created, started, completed, step advanced
- **Integration events**: sync completed, sync failed

## Usage

### Starting listeners for a tenant

```elixir
# Start all listeners for a tenant
Assetronics.Listeners.start_listeners_for_tenant("acme")

# Check if listeners are running
Assetronics.Listeners.listeners_running?("acme")
```

### Stopping listeners for a tenant

```elixir
Assetronics.Listeners.stop_listeners_for_tenant("acme")
```

### Listing all running listeners

```elixir
Assetronics.Listeners.list_listeners()
# => [{"acme", Assetronics.Listeners.WorkflowAutomationListener}, ...]
```

## Integration with tenant lifecycle

You should start listeners when:

1. A tenant is created
2. The application starts (for existing tenants)
3. A tenant's subscription is activated

Example in tenant creation:

```elixir
defmodule Assetronics.Accounts do
  def create_tenant(attrs) do
    case do_create_tenant(attrs) do
      {:ok, tenant} ->
        # Start event listeners for the new tenant
        Assetronics.Listeners.start_listeners_for_tenant(tenant.slug)
        {:ok, tenant}

      error ->
        error
    end
  end
end
```

## Architecture

### Event flow

```
Context (Assets, Employees, Workflows)
  ↓
broadcast_result() calls Phoenix.PubSub.broadcast()
  ↓
PubSub broadcasts event to topic "entity:tenant"
  ↓
Listeners subscribed to topic receive event
  ↓
Listener handles event (creates workflows, audit logs, etc.)
```

### Supervision tree

```
Application
  ├─ Registry (Assetronics.ListenerRegistry)
  │    └─ Stores listener PIDs by {module, tenant}
  │
  └─ DynamicSupervisor (Assetronics.ListenerSupervisor)
       └─ Starts/stops listeners dynamically
```

## Adding new listeners

1. Create a new GenServer in `lib/assetronics/listeners/`
2. Implement the required callbacks:
   - `start_link/1` - Start the listener for a tenant
   - `child_spec/1` - Define the child spec
   - `init/1` - Subscribe to PubSub topics
   - `handle_info/2` - Handle events
3. Add the listener to `Assetronics.Listeners.start_listeners_for_tenant/1`

Example:

```elixir
defmodule Assetronics.Listeners.MyListener do
  use GenServer
  require Logger

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

  @impl true
  def init(tenant) do
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "my_topic:#{tenant}")
    {:ok, %{tenant: tenant}}
  end

  @impl true
  def handle_info({"my_event", data}, state) do
    # Handle the event
    {:noreply, state}
  end

  defp via_tuple(tenant) do
    {:via, Registry, {Assetronics.ListenerRegistry, {__MODULE__, tenant}}}
  end
end
```

## Monitoring and debugging

### Checking listener status

```elixir
# See if listeners are running
Assetronics.Listeners.list_listeners()

# Check a specific tenant
Assetronics.Listeners.listeners_running?("acme")

# View listener process info
Registry.lookup(Assetronics.ListenerRegistry, {Assetronics.Listeners.WorkflowAutomationListener, "acme"})
```

### Logs

Listeners log their activities:

```
[WorkflowAutomationListener] Employee terminated: abc-123, creating offboarding workflow
[AuditTrailListener] Created audit record: employee_terminated
```

Set log level to `:debug` to see more details:

```elixir
# In config/dev.exs
config :logger, level: :debug
```

## Testing

Test event listeners by broadcasting events manually:

```elixir
# Start listeners for test tenant
Assetronics.Listeners.start_listeners_for_tenant("test")

# Broadcast an event
Phoenix.PubSub.broadcast(
  Assetronics.PubSub,
  "employees:test",
  {"employee_terminated", %{id: "123", first_name: "John", last_name: "Doe"}}
)

# Check logs to see listener response
```
