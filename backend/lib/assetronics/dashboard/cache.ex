defmodule Assetronics.Dashboard.Cache do
  @moduledoc """
  Simple ETS-based cache for dashboard metrics.

  Caches dashboard data for 5 minutes to reduce database load.
  """

  use GenServer
  require Logger

  @table_name :dashboard_cache
  @default_ttl :timer.minutes(5)

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Gets a cached value or computes it if not cached/expired.

  ## Examples

      Cache.get_or_compute("acme:admin_dashboard", fn ->
        Dashboard.get_admin_dashboard("acme", user_id)
      end)
  """
  def get_or_compute(key, compute_fun, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    case get(key) do
      {:ok, value} ->
        Logger.debug("[Dashboard.Cache] Cache hit for key: #{key}")
        value

      :miss ->
        Logger.debug("[Dashboard.Cache] Cache miss for key: #{key}, computing...")
        value = compute_fun.()
        put(key, value, ttl)
        value
    end
  end

  @doc """
  Gets a value from cache.

  Returns `{:ok, value}` if found and not expired, `:miss` otherwise.
  """
  def get(key) do
    try do
      case :ets.lookup(@table_name, key) do
        [{^key, value, expires_at}] ->
          if System.monotonic_time(:millisecond) < expires_at do
            {:ok, value}
          else
            # Expired, delete it
            :ets.delete(@table_name, key)
            :miss
          end

        [] ->
          :miss
      end
    rescue
      ArgumentError ->
        Logger.warning("[Dashboard.Cache] ETS table does not exist, cache miss for key: #{key}")
        :miss
    end
  end

  @doc """
  Puts a value in cache with TTL.
  """
  def put(key, value, ttl \\ @default_ttl) do
    try do
      expires_at = System.monotonic_time(:millisecond) + ttl
      :ets.insert(@table_name, {key, value, expires_at})
      :ok
    rescue
      ArgumentError ->
        Logger.warning("[Dashboard.Cache] ETS table does not exist, cannot cache key: #{key}")
        :ok
    end
  end

  @doc """
  Invalidates a specific cache key.
  """
  def invalidate(key) do
    try do
      :ets.delete(@table_name, key)
      :ok
    rescue
      ArgumentError ->
        Logger.warning("[Dashboard.Cache] ETS table does not exist, cannot invalidate key: #{key}")
        :ok
    end
  end

  @doc """
  Invalidates all cache keys matching a pattern.

  ## Examples

      # Invalidate all cache for a specific tenant
      Cache.invalidate_pattern("acme:")
  """
  def invalidate_pattern(pattern) do
    GenServer.cast(__MODULE__, {:invalidate_pattern, pattern})
  end

  @doc """
  Clears the entire cache.
  """
  def clear do
    try do
      :ets.delete_all_objects(@table_name)
      :ok
    rescue
      ArgumentError ->
        Logger.warning("[Dashboard.Cache] ETS table does not exist, cannot clear cache")
        :ok
    end
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("[Dashboard.Cache] Starting dashboard cache")

    # Create ETS table
    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    # Schedule periodic cleanup of expired entries
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:invalidate_pattern, pattern}, state) do
    # Find and delete all keys matching pattern
    match_pattern = {:"$1", :_, :_}
    guard = [{:==, {:hd, {:string, :tokens, [:"$1", ":"]}}, pattern}]

    keys = :ets.select(@table_name, [{match_pattern, guard, [:"$1"]}])

    Enum.each(keys, fn key ->
      :ets.delete(@table_name, key)
    end)

    Logger.debug("[Dashboard.Cache] Invalidated #{length(keys)} keys matching pattern: #{pattern}")

    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  # Private Functions

  defp schedule_cleanup do
    # Clean up every 5 minutes
    Process.send_after(self(), :cleanup, :timer.minutes(5))
  end

  defp cleanup_expired do
    now = System.monotonic_time(:millisecond)

    # Match all expired entries
    match_pattern = {:"$1", :_, :"$2"}
    guard = [{:<, :"$2", now}]

    deleted = :ets.select_delete(@table_name, [{match_pattern, guard, [true]}])

    if deleted > 0 do
      Logger.debug("[Dashboard.Cache] Cleaned up #{deleted} expired cache entries")
    end

    deleted
  end
end
