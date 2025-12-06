defmodule AssetronicsWeb.AssetController do
  use AssetronicsWeb, :controller

  alias Assetronics.Assets
  alias Assetronics.Assets.Asset

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all assets for the tenant with pagination.

  Query params:
  - page: Page number (default: 1)
  - per_page: Items per page (default: 50, max: 100)
  - q: Search query (searches name, asset_tag, model, make)
  - status: Filter by status
  - category: Filter by category
  - employee_id: Filter by assigned employee (assignee)
  - location_id: Filter by location

  Note: Serial numbers are encrypted and cannot be searched via the q parameter.
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]

    opts =
      []
      |> maybe_add_filter(:page, parse_int(params["page"]))
      |> maybe_add_filter(:per_page, parse_int(params["per_page"]))
      |> maybe_add_filter(:q, params["q"])
      |> maybe_add_filter(:status, params["status"])
      |> maybe_add_filter(:category, params["category"])
      |> maybe_add_filter(:employee_id, params["employee_id"])
      |> maybe_add_filter(:location_id, params["location_id"])
      |> Keyword.put(:preload, [:employee, :location])

    result = Assets.list_assets(tenant, opts)
    render(conn, :index, result: result)
  end

  @doc """
  Creates a new asset.
  """
  def create(conn, %{"asset" => asset_params}) do
    tenant = conn.assigns[:tenant]

    with {:ok, %Asset{} = asset} <- Assets.create_asset(tenant, asset_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/assets/#{asset.id}")
      |> render(:show, asset: asset)
    end
  end

  @doc """
  Shows a single asset.
  """
  def show(conn, %{"id" => id}) do
    with :ok <- validate_uuid(id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, id)
      render(conn, :show, asset: asset)
    end
  end

  @doc """
  Updates an asset.
  """
  def update(conn, %{"id" => id, "asset" => asset_params}) do
    with :ok <- validate_uuid(id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, id)

      with {:ok, %Asset{} = asset} <- Assets.update_asset(tenant, asset, asset_params) do
        render(conn, :show, asset: asset)
      end
    end
  end

  @doc """
  Deletes an asset.
  """
  def delete(conn, %{"id" => id}) do
    with :ok <- validate_uuid(id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, id)

      with {:ok, %Asset{}} <- Assets.delete_asset(tenant, asset) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  @doc """
  Assigns an asset to an employee.

  POST /api/v1/assets/:asset_id/assign
  Body: {"employee_id": "uuid", "assignment_type": "permanent"}
  """
  def assign(conn, %{"asset_id" => asset_id} = params) do
    employee_id = params["employee_id"]

    with :ok <- validate_uuid(asset_id),
         :ok <- validate_uuid(employee_id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, asset_id)
      employee = Assetronics.Employees.get_employee!(tenant, employee_id)
      performed_by = get_current_user_email(conn)

      opts = [
        assignment_type: params["assignment_type"] || "permanent",
        expected_return_date: params["expected_return_date"]
      ]

      with {:ok, %Asset{} = asset} <- Assets.assign_asset(tenant, asset, employee, performed_by, opts) do
        render(conn, :show, asset: asset)
      end
    end
  end

  @doc """
  Returns an asset from an employee.

  POST /api/v1/assets/:asset_id/return
  Body: {"employee_id": "uuid"}
  """
  def return(conn, %{"asset_id" => asset_id} = params) do
    with :ok <- validate_uuid(asset_id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, asset_id)
      employee_id = params["employee_id"] || asset.employee_id

      if employee_id do
        with :ok <- validate_uuid(employee_id) do
          employee = Assetronics.Employees.get_employee!(tenant, employee_id)
          performed_by = get_current_user_email(conn)

          with {:ok, %Asset{} = asset} <- Assets.return_asset(tenant, asset, employee, performed_by) do
            render(conn, :show, asset: asset)
          end
        end
      else
        {:error, :employee_required}
      end
    end
  end

  @doc """
  Transfers an asset between employees.

  POST /api/v1/assets/:asset_id/transfer
  Body: {"from_employee_id": "uuid", "to_employee_id": "uuid"}
  """
  def transfer(conn, %{"asset_id" => asset_id, "from_employee_id" => from_id, "to_employee_id" => to_id}) do
    with :ok <- validate_uuid(asset_id),
         :ok <- validate_uuid(from_id),
         :ok <- validate_uuid(to_id) do
      tenant = conn.assigns[:tenant]
      asset = Assets.get_asset!(tenant, asset_id)

      from_employee = Assetronics.Employees.get_employee!(tenant, from_id)
      to_employee = Assetronics.Employees.get_employee!(tenant, to_id)
      performed_by = get_current_user_email(conn)

      with {:ok, %Asset{} = asset} <-
             Assets.transfer_asset(tenant, asset, from_employee, to_employee, performed_by) do
        render(conn, :show, asset: asset)
      end
    end
  end

  @doc """
  Gets asset history (transactions).

  GET /api/v1/assets/:asset_id/history
  """
  def history(conn, %{"asset_id" => asset_id}) do
    with :ok <- validate_uuid(asset_id) do
      tenant = conn.assigns[:tenant]
      transactions = Assets.get_asset_history(tenant, asset_id)
      render(conn, :history, transactions: transactions)
    end
  end

  @doc """
  Searches assets with pagination.

  GET /api/v1/assets/search?q=macbook&category=laptop&page=1&per_page=25
  """
  def search(conn, params) do
    tenant = conn.assigns[:tenant]

    search_params =
      %{}
      |> maybe_add_search_param(:query, params["q"])
      |> maybe_add_search_param(:category, params["category"])
      |> maybe_add_search_param(:status, params["status"])
      |> maybe_add_search_param(:tags, parse_tags(params["tags"]))
      |> maybe_add_search_param(:page, parse_int(params["page"]))
      |> maybe_add_search_param(:per_page, parse_int(params["per_page"]))

    result = Assets.search_assets(tenant, search_params)
    render(conn, :index, result: result)
  end

  # Private helpers

  defp validate_uuid(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _uuid} -> :ok
      :error -> {:error, :invalid_id}
    end
  end

  defp parse_int(nil), do: nil
  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp maybe_add_filter(opts, _key, nil), do: opts
  defp maybe_add_filter(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_add_search_param(params, _key, nil), do: params
  defp maybe_add_search_param(params, key, value), do: Map.put(params, key, value)

  defp parse_tags(nil), do: nil
  defp parse_tags(tags) when is_binary(tags), do: String.split(tags, ",")
  defp parse_tags(tags) when is_list(tags), do: tags

  defp get_current_user_email(conn) do
    # TODO: Get from authenticated user (Guardian)
    # For now, return a placeholder
    conn.assigns[:current_user_email] || "system@assetronics.com"
  end
end
