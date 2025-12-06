defmodule AssetronicsWeb.Plugs.AuthorizePlug do
  @moduledoc """
  Authorization plug using Bodyguard policies.

  ## Usage in Controllers

      # Authorize all actions using a single policy
      plug AuthorizePlug, policy: Assetronics.Policies.AssetPolicy

      # Authorize specific actions
      plug AuthorizePlug, [policy: Assetronics.Policies.UserPolicy] when action in [:update, :delete]

      # Custom resource loader
      plug AuthorizePlug, policy: Assetronics.Policies.AssetPolicy, resource: &load_asset/1

  ## How it works

  1. Extracts current_user from conn.assigns
  2. Loads the resource (if specified)
  3. Calls the policy's authorize/3 function with (action, user, resource)
  4. Returns 403 Forbidden if unauthorized

  ## Resource Loading

  By default, the plug looks for a resource in conn.assigns[:resource].
  You can specify a custom loader function that takes the conn and returns the resource.

  ## Action Naming

  The plug uses the Phoenix action name (e.g., :show, :update, :delete).
  Your policy should define authorize/3 functions for these actions.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts) do
    policy = Keyword.fetch!(opts, :policy)
    resource_loader = Keyword.get(opts, :resource, &default_resource_loader/1)

    %{
      policy: policy,
      resource_loader: resource_loader
    }
  end

  def call(conn, %{policy: policy, resource_loader: resource_loader}) do
    user = conn.assigns[:current_user]
    action = action_name(conn)
    resource = resource_loader.(conn)

    case Bodyguard.permit(policy, action, user, resource) do
      :ok ->
        conn

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"403", message: "You are not authorized to perform this action")
        |> halt()
    end
  end

  # Default resource loader - looks for :resource in conn.assigns
  defp default_resource_loader(conn) do
    conn.assigns[:resource]
  end
end
