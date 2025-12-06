defmodule Assetronics.Assets do
  @moduledoc """
  The Assets context.

  Handles all business logic for hardware asset management:
  - CRUD operations for assets
  - Assignment and return workflows
  - Status transitions
  - Audit trail via transactions
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Assets.Asset
  alias Assetronics.Transactions.Transaction
  alias Assetronics.Accounts
  alias Assetronics.Notifications
  alias Assetronics.Workflows

  require Logger

  @doc """
  Returns the list of assets for a tenant with pagination support.

  ## Options

  - `:page` - Page number (default: 1)
  - `:per_page` - Items per page (default: 50, max: 100)
  - `:q` - Search query (searches name, asset_tag, model, make using ILIKE)
  - `:status` - Filter by status
  - `:category` - Filter by category
  - `:employee_id` - Filter by assigned employee
  - `:location_id` - Filter by location
  - `:preload` - List of associations to preload

  ## Examples

      iex> list_assets("acme")
      %{assets: [%Asset{}, ...], total: 100, page: 1, per_page: 50, total_pages: 2}

      iex> list_assets("acme", page: 2, per_page: 25, q: "macbook")
      %{assets: [%Asset{}, ...], total: 10, page: 1, per_page: 25, total_pages: 1}

  ## Note

  Serial numbers are encrypted and cannot be searched with partial matching.
  Use the exact serial number in the search_assets function for serial number lookups.

  """
  def list_assets(tenant, opts \\ []) do
    page = Keyword.get(opts, :page, 1) |> max(1)
    per_page = Keyword.get(opts, :per_page, 50) |> min(100) |> max(1)
    offset = (page - 1) * per_page

    base_query = from(a in Asset, order_by: [desc: a.inserted_at])
    filtered_query = apply_filters(base_query, opts)

    # Get total count for pagination metadata
    total = Repo.aggregate(filtered_query, :count, :id, prefix: Triplex.to_prefix(tenant))

    # Get paginated results
    assets =
      filtered_query
      |> limit(^per_page)
      |> offset(^offset)
      |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))

    %{
      assets: assets,
      total: total,
      page: page,
      per_page: per_page,
      total_pages: ceil(total / per_page)
    }
  end

  @doc """
  Gets a single asset by ID.

  Raises `Ecto.NoResultsError` if the Asset does not exist.

  ## Examples

      iex> get_asset!("acme", "123")
      %Asset{}

      iex> get_asset!("acme", "456")
      ** (Ecto.NoResultsError)

  """
  def get_asset!(tenant, id) do
    Repo.get!(Asset, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single asset by asset tag.

  ## Examples

      iex> get_asset_by_tag("acme", "MBP-001")
      {:ok, %Asset{}}

      iex> get_asset_by_tag("acme", "invalid")
      {:error, :not_found}

  """
  def get_asset_by_tag(tenant, asset_tag) do
    case Repo.one(from(a in Asset, where: a.asset_tag == ^asset_tag), prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      asset -> {:ok, asset}
    end
  end

  @doc """
  Creates an asset.

  ## Examples

      iex> create_asset("acme", %{name: "MacBook Pro", category: "laptop"})
      {:ok, %Asset{}}

      iex> create_asset("acme", %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset(tenant, attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Updates an asset.

  ## Examples

      iex> update_asset("acme", asset, %{name: "New Name"})
      {:ok, %Asset{}}

      iex> update_asset("acme", asset, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset(tenant, %Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Deletes an asset.

  ## Examples

      iex> delete_asset("acme", asset)
      {:ok, %Asset{}}

      iex> delete_asset("acme", asset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset(tenant, %Asset{} = asset) do
    Repo.delete(asset, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.

  ## Examples

      iex> change_asset(asset)
      %Ecto.Changeset{data: %Asset{}}

  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  @doc """
  Assigns an asset to an employee.

  Creates a transaction record for audit trail.

  ## Examples

      iex> assign_asset("acme", asset, employee, "user@example.com")
      {:ok, %Asset{}}

  """
  def assign_asset(tenant, %Asset{} = asset, employee, performed_by, opts \\ []) do
    start_time = System.monotonic_time()
    assignment_type = Keyword.get(opts, :assignment_type, "permanent")
    expected_return_date = Keyword.get(opts, :expected_return_date)
    metadata = Keyword.get(opts, :metadata, %{})

    result = Repo.transaction(fn ->
      # Update asset
      {:ok, updated_asset} =
        asset
        |> Asset.changeset(%{
          status: "assigned",
          employee_id: employee.id,
          assigned_at: DateTime.utc_now(),
          assignment_type: assignment_type,
          expected_return_date: expected_return_date
        })
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

      # Create transaction record
      Transaction.assignment_changeset(asset, employee, performed_by, metadata)
      |> Repo.insert!(prefix: Triplex.to_prefix(tenant))

      # Broadcast event via PubSub
      broadcast_asset_event(tenant, "asset_assigned", updated_asset)

      # Send notification to employee
      case Accounts.get_user_by_email(tenant, employee.email) do
        %Accounts.User{} = user ->
          Notifications.notify(
            tenant,
            user.id,
            "asset_assigned",
            %{
              title: "Asset assigned to you",
              body: "#{asset.name || asset.asset_tag} has been assigned to you",
              asset_id: asset.id,
              asset_name: asset.name
            }
          )
          Logger.info("Sent asset assignment notification to user #{user.id} for asset #{asset.id}")

        nil ->
          Logger.warning("Could not send assignment notification: user not found for email #{employee.email}")
      end

      # Create onboarding workflow if employee is newly hired (within 30 days)
      if employee.hire_date && Date.diff(Date.utc_today(), employee.hire_date) <= 30 do
        case Workflows.create_onboarding_workflow(tenant, employee, updated_asset) do
          {:ok, workflow} ->
            Logger.info("Created onboarding workflow #{workflow.id} for employee #{employee.id}")

          {:error, reason} ->
            Logger.error("Failed to create onboarding workflow: #{inspect(reason)}")
        end
      end

      updated_asset
    end)

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _asset} ->
        :telemetry.execute(
          [:assetronics, :assets, :assign, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :assets, :assign, :success],
          %{count: 1},
          %{tenant: tenant}
        )

      {:error, _reason} ->
        :telemetry.execute(
          [:assetronics, :assets, :assign, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :assets, :assign, :failure],
          %{count: 1},
          %{tenant: tenant}
        )
    end

    result
  end

  @doc """
  Returns an asset from an employee.

  Creates a transaction record for audit trail.

  ## Examples

      iex> return_asset("acme", asset, employee, "user@example.com")
      {:ok, %Asset{}}

  """
  def return_asset(tenant, %Asset{} = asset, employee, performed_by, opts \\ []) do
    start_time = System.monotonic_time()
    metadata = Keyword.get(opts, :metadata, %{})
    new_status = Keyword.get(opts, :status, "in_stock")

    result = Repo.transaction(fn ->
      # Update asset
      {:ok, updated_asset} =
        asset
        |> Asset.changeset(%{
          status: new_status,
          employee_id: nil,
          assigned_at: nil,
          assignment_type: nil,
          expected_return_date: nil
        })
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

      # Create transaction record
      Transaction.return_changeset(asset, employee, performed_by, metadata)
      |> Repo.insert!(prefix: Triplex.to_prefix(tenant))

      # Broadcast event
      broadcast_asset_event(tenant, "asset_returned", updated_asset)

      # Send notification to employee confirming return
      case Accounts.get_user_by_email(tenant, employee.email) do
        %Accounts.User{} = user ->
          Notifications.notify(
            tenant,
            user.id,
            "asset_returned",
            %{
              title: "Asset return confirmed",
              body: "#{asset.name || asset.asset_tag} has been returned successfully",
              asset_id: asset.id,
              asset_name: asset.name
            }
          )
          Logger.info("Sent asset return notification to user #{user.id} for asset #{asset.id}")

        nil ->
          Logger.warning("Could not send return notification: user not found for email #{employee.email}")
      end

      # Create equipment return workflow if needed
      case Workflows.create_equipment_return_workflow(tenant, employee, updated_asset) do
        {:ok, workflow} ->
          Logger.info("Created equipment return workflow #{workflow.id} for asset #{asset.id}")

        {:error, reason} ->
          Logger.error("Failed to create equipment return workflow: #{inspect(reason)}")
      end

      updated_asset
    end)

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _asset} ->
        :telemetry.execute(
          [:assetronics, :assets, :return, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :assets, :return, :success],
          %{count: 1},
          %{tenant: tenant}
        )

      {:error, _reason} ->
        :telemetry.execute(
          [:assetronics, :assets, :return, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :assets, :return, :failure],
          %{count: 1},
          %{tenant: tenant}
        )
    end

    result
  end

  @doc """
  Transfers an asset from one employee to another.

  ## Examples

      iex> transfer_asset("acme", asset, from_employee, to_employee, "user@example.com")
      {:ok, %Asset{}}

  """
  def transfer_asset(tenant, %Asset{} = asset, from_employee, to_employee, performed_by, opts \\ []) do
    start_time = System.monotonic_time()
    metadata = Keyword.get(opts, :metadata, %{})

    result = Repo.transaction(fn ->
      # Update asset
      {:ok, updated_asset} =
        asset
        |> Asset.changeset(%{
          employee_id: to_employee.id,
          assigned_at: DateTime.utc_now()
        })
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

      # Create transaction record
      Transaction.transfer_changeset(asset, from_employee, to_employee, performed_by, metadata)
      |> Repo.insert!(prefix: Triplex.to_prefix(tenant))

      # Broadcast event
      broadcast_asset_event(tenant, "asset_transferred", updated_asset)

      # Notify the employee who is receiving the asset
      case Accounts.get_user_by_email(tenant, to_employee.email) do
        %Accounts.User{} = user ->
          Notifications.notify(
            tenant,
            user.id,
            "asset_assigned",
            %{
              title: "Asset transferred to you",
              body: "#{asset.name || asset.asset_tag} has been transferred to you",
              asset_id: asset.id,
              asset_name: asset.name
            }
          )
          Logger.info("Sent asset transfer notification to new owner #{user.id} for asset #{asset.id}")

        nil ->
          Logger.warning("Could not send transfer notification to new owner: user not found for email #{to_employee.email}")
      end

      # Notify the employee who is giving up the asset
      case Accounts.get_user_by_email(tenant, from_employee.email) do
        %Accounts.User{} = user ->
          Notifications.notify(
            tenant,
            user.id,
            "asset_returned",
            %{
              title: "Asset transferred",
              body: "#{asset.name || asset.asset_tag} has been transferred to #{to_employee.first_name} #{to_employee.last_name}",
              asset_id: asset.id,
              asset_name: asset.name
            }
          )
          Logger.info("Sent asset transfer notification to previous owner #{user.id} for asset #{asset.id}")

        nil ->
          Logger.warning("Could not send transfer notification to previous owner: user not found for email #{from_employee.email}")
      end

      updated_asset
    end)

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _asset} ->
        :telemetry.execute(
          [:assetronics, :assets, :transfer, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :assets, :transfer, :success],
          %{count: 1},
          %{tenant: tenant}
        )

      {:error, _reason} ->
        :telemetry.execute(
          [:assetronics, :assets, :transfer, :stop],
          %{duration: duration},
          %{tenant: tenant, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :assets, :transfer, :failure],
          %{count: 1},
          %{tenant: tenant}
        )
    end

    result
  end

  @doc """
  Changes asset status and records transaction.

  ## Examples

      iex> change_asset_status("acme", asset, "in_repair", "user@example.com")
      {:ok, %Asset{}}

  """
  def change_asset_status(tenant, %Asset{} = asset, new_status, performed_by, opts \\ []) do
    metadata = Keyword.get(opts, :metadata, %{})

    Repo.transaction(fn ->
      # Update asset
      {:ok, updated_asset} =
        asset
        |> Asset.changeset(%{status: new_status})
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

      # Create transaction record
      Transaction.status_change_changeset(asset, new_status, performed_by, metadata)
      |> Repo.insert!(prefix: Triplex.to_prefix(tenant))

      # Broadcast event
      broadcast_asset_event(tenant, "asset_status_changed", updated_asset)

      updated_asset
    end)
  end

  @doc """
  Gets asset history (transactions).

  ## Examples

      iex> get_asset_history("acme", asset_id)
      [%Transaction{}, ...]

  """
  def get_asset_history(tenant, asset_id) do
    query =
      from t in Transaction,
        where: t.asset_id == ^asset_id,
        order_by: [desc: t.performed_at],
        preload: [:employee, :from_employee, :to_employee, :from_location, :to_location]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists assets by status.

  ## Examples

      iex> list_assets_by_status("acme", "assigned")
      [%Asset{}, ...]

  """
  def list_assets_by_status(tenant, status) do
    query = from(a in Asset, where: a.status == ^status, preload: [:employee, :location])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists assets assigned to an employee.

  ## Examples

      iex> list_assets_for_employee("acme", employee_id)
      [%Asset{}, ...]

  """
  def list_assets_for_employee(tenant, employee_id) do
    query = from(a in Asset, where: a.employee_id == ^employee_id, preload: [:location])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Search assets by various criteria with pagination support.

  ## Parameters

  - `query` - Search term for name, asset_tag, model, make
  - `category` - Filter by category
  - `status` - Filter by status
  - `tags` - Filter by tags
  - `page` - Page number (default: 1)
  - `per_page` - Items per page (default: 50, max: 100)

  ## Examples

      iex> search_assets("acme", %{query: "macbook", category: "laptop"})
      %{assets: [%Asset{}, ...], total: 10, page: 1, per_page: 50, total_pages: 1}

  """
  def search_assets(tenant, params) do
    page = Map.get(params, :page, 1) |> max(1)
    per_page = Map.get(params, :per_page, 50) |> min(100) |> max(1)
    offset = (page - 1) * per_page

    base_query = from(a in Asset, order_by: [desc: a.inserted_at])
    filtered_query = apply_search_filters(base_query, params)

    # Get total count for pagination metadata
    total = Repo.aggregate(filtered_query, :count, :id, prefix: Triplex.to_prefix(tenant))

    # Get paginated results
    assets =
      filtered_query
      |> limit(^per_page)
      |> offset(^offset)
      |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))

    %{
      assets: assets,
      total: total,
      page: page,
      per_page: per_page,
      total_pages: ceil(total / per_page)
    }
  end

  @doc """
  Registers an agent check-in.

  Finds asset by serial number (using hash search) and updates it.
  If not found, creates a new asset with status 'in_stock' (or 'discovered').
  """
  def register_agent_checkin(tenant, attrs) do
    serial = attrs["serial_number"]
    # We need to search by hash for encrypted field
    serial_hash = :crypto.hash(:sha256, serial)

    # Try to find existing asset
    query = from(a in Asset, where: a.serial_number_hash == ^serial_hash)
    existing_asset = Repo.one(query, prefix: Triplex.to_prefix(tenant))

    case existing_asset do
      nil ->
        # Create new asset
        # We need a unique asset tag. For now, generate a temp one if not provided.
        # In prod, this might need a sequence generator.
        asset_tag = attrs["asset_tag"] || "DISC-#{Nanoid.generate()}"
        
        create_attrs = %{
          asset_tag: asset_tag,
          name: attrs["hostname"] || "Discovered Device",
          serial_number: serial,
          category: identify_category(attrs["os"], attrs["platform"]),
          status: "in_stock", # Default status
          hostname: attrs["hostname"],
          os_info: attrs["os"],
          ip_address: attrs["ip_address"],
          mac_address: attrs["mac_address"],
          installed_software: attrs["installed_software"] || [],
          last_checkin_at: DateTime.utc_now() |> DateTime.to_naive()
        }
        
        create_asset(tenant, create_attrs)

      %Asset{} = asset ->
        # Update existing asset
        update_attrs = %{
          hostname: attrs["hostname"],
          os_info: attrs["os"],
          ip_address: attrs["ip_address"],
          mac_address: attrs["mac_address"],
          installed_software: attrs["installed_software"] || [],
          last_checkin_at: DateTime.utc_now() |> DateTime.to_naive()
        }
        
        update_asset(tenant, asset, update_attrs)
    end
  end

  defp identify_category(os, platform) do
    os = String.downcase(os || "")
    platform = String.downcase(platform || "")
    
    cond do
      String.contains?(os, "server") -> "server"
      String.contains?(platform, "darwin") -> "laptop" # Assumption for MVP
      String.contains?(platform, "windows") -> "desktop" # Assumption, refine later
      true -> "other"
    end
  end

  @doc """
  Processes network scan results.
  """
  def process_network_scan(tenant, %{"devices" => devices}) do
    results = 
      Enum.map(devices, fn device ->
        register_scanned_device(tenant, device)
      end)
    
    success_count = Enum.count(results, fn {status, _} -> status == :ok end)
    {:ok, success_count}
  end

  defp register_scanned_device(tenant, device) do
    # Try to find by IP (weak) or Hostname
    # In future, match by MAC if available
    
    ip = device["ip"]
    hostname = device["hostname"]
    
    query = from(a in Asset, 
      where: a.ip_address == ^ip or (not is_nil(a.hostname) and a.hostname == ^hostname)
    )
    
    existing = Repo.one(query, prefix: Triplex.to_prefix(tenant))
    
    tags = ["network_scan"]
    
    case existing do
      nil ->
        # Create new discovered asset
        asset_tag = "NET-#{Nanoid.generate()}"
        
        attrs = %{
          asset_tag: asset_tag,
          name: hostname || ip,
          category: "network_equipment", # Default guess
          status: "in_stock", # Or discovered
          ip_address: ip,
          hostname: hostname,
          last_checkin_at: DateTime.utc_now() |> DateTime.to_naive(),
          tags: tags,
          custom_fields: %{"open_ports" => device["open_ports"]}
        }
        
        create_asset(tenant, attrs)
        
      %Asset{} = asset ->
        # Update existing
        tags = Enum.uniq((asset.tags || []) ++ tags)
        
        attrs = %{
          ip_address: ip,
          last_checkin_at: DateTime.utc_now() |> DateTime.to_naive(),
          tags: tags,
          custom_fields: Map.put(asset.custom_fields || %{}, "open_ports", device["open_ports"])
        }
        
        update_asset(tenant, asset, attrs)
    end
  end

  @doc """
  Syncs an asset from an MDM source (Intune, Jamf).
  Prioritizes Serial Number matching.
  """
  def sync_from_mdm(tenant, attrs) do
    serial = attrs[:serial_number]

    # Handle nil or empty serial - can't deduplicate without a unique identifier
    cond do
      is_nil(serial) or serial == "" ->
        require Logger
        Logger.error("sync_from_mdm called with nil or empty serial_number. This will create duplicates! Attrs: #{inspect(attrs)}")
        # Fall back to creating without deduplication
        tags = ["mdm_managed"]
        attrs = Map.put(attrs, :tags, tags)
        create_asset(tenant, attrs)

      true ->
        serial_hash = :crypto.hash(:sha256, serial)

        query = from(a in Asset, where: a.serial_number_hash == ^serial_hash)
        existing = Repo.one(query, prefix: Triplex.to_prefix(tenant))

        tags = ["mdm_managed"]

        case existing do
          nil ->
            # Create new
            attrs = Map.put(attrs, :tags, tags)
            create_asset(tenant, attrs)

          %Asset{} = asset ->
        # Update existing
        # Merge tags
        updated_tags = Enum.uniq((asset.tags || []) ++ tags)
        
        # Merge custom fields
        updated_custom = Map.merge(asset.custom_fields || %{}, attrs[:custom_fields] || %{})
        
        # Trust MDM as source of truth for device information
        # Update hardware specs, name, and dynamic fields

        update_attrs = %{
          name: attrs[:name] || asset.name,
          model: attrs[:model] || asset.model,
          make: attrs[:make] || asset.make,
          category: attrs[:category] || asset.category,
          description: attrs[:description] || asset.description,
          last_checkin_at: attrs[:last_checkin_at],
          os_info: attrs[:os_info],
          tags: updated_tags,
          custom_fields: updated_custom
        }

            # Only update status/assignment if specifically provided by MDM
            update_attrs =
              if attrs[:status] == "assigned" and attrs[:employee_id] do
                 Map.merge(update_attrs, %{status: "assigned", employee_id: attrs[:employee_id]})
              else
                 update_attrs
              end

            update_asset(tenant, asset, update_attrs)
        end
    end
  end

  @doc """
  Creates or updates assets based on invoice data.
  """
  def create_from_invoice(tenant, invoice_data) do
    # invoice_data is the JSON from Ollama
    
    vendor = invoice_data["vendor"]
    invoice_number = invoice_data["invoice_number"]
    
    purchase_date = case Date.from_iso8601(invoice_data["date"] || "") do
      {:ok, date} -> date
      _ -> Date.utc_today()
    end
    
    results = Enum.map(invoice_data["assets"] || [], fn item ->
      serial = item["serial_number"]
      
      price = case item["unit_price"] do
        p when is_number(p) -> Decimal.new("#{p}")
        p when is_binary(p) -> Decimal.new(p)
        _ -> nil
      end
      
      base_attrs = %{
        name: item["description"] || "#{item["manufacturer"]} #{item["model"]}",
        description: item["description"],
        make: item["manufacturer"],
        model: item["model"],
        category: "other",
        purchase_date: purchase_date,
        purchase_cost: price,
        vendor: vendor,
        invoice_number: invoice_number,
        status: "on_order",
        custom_fields: %{
          "invoice_currency" => invoice_data["currency"]
        }
      }

      if serial && serial != "" do
         serial_hash = :crypto.hash(:sha256, serial)
         existing = Repo.one(from(a in Asset, where: a.serial_number_hash == ^serial_hash), prefix: Triplex.to_prefix(tenant))
         
         case existing do
           nil -> 
              asset_tag = "PUR-#{Nanoid.generate()}"
              create_asset(tenant, Map.merge(base_attrs, %{asset_tag: asset_tag, serial_number: serial}))
           %Asset{} = asset ->
              update_asset(tenant, asset, base_attrs) 
         end
      else
         qty = item["quantity"] || 1
         
         for _ <- 1..qty do
            asset_tag = "PUR-#{Nanoid.generate()}"
            create_asset(tenant, Map.put(base_attrs, :asset_tag, asset_tag))
         end
      end
    end)
    
    flat_results = List.flatten(results)
    {:ok, length(flat_results)}
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:q, search_query}, query when is_binary(search_query) and search_query != "" ->
        search_term = "%#{search_query}%"
        from(a in query,
          where:
            ilike(a.name, ^search_term) or
              ilike(a.asset_tag, ^search_term) or
              ilike(a.model, ^search_term) or
              ilike(a.make, ^search_term)
        )

      {:status, status}, query ->
        from(a in query, where: a.status == ^status)

      {:category, category}, query ->
        from(a in query, where: a.category == ^category)

      {:employee_id, employee_id}, query ->
        from(a in query, where: a.employee_id == ^employee_id)

      {:location_id, location_id}, query ->
        from(a in query, where: a.location_id == ^location_id)

      {:preload, preloads}, query ->
        from(a in query, preload: ^preloads)

      _, query ->
        query
    end)
  end

  defp apply_search_filters(query, params) do
    Enum.reduce(params, query, fn
      {:query, search_query}, query ->
        search_term = "%#{search_query}%"

        from(a in query,
          where:
            ilike(a.name, ^search_term) or
              ilike(a.asset_tag, ^search_term) or
              ilike(a.model, ^search_term) or
              ilike(a.make, ^search_term)
        )

      {:category, category}, query ->
        from(a in query, where: a.category == ^category)

      {:status, status}, query ->
        from(a in query, where: a.status == ^status)

      {:tags, tags}, query ->
        from(a in query, where: fragment("? && ?", a.tags, ^tags))

      _, query ->
        query
    end)
  end

  defp broadcast_asset_event(tenant, event, asset) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "assets:#{tenant}",
      {event, asset}
    )
  end
end
