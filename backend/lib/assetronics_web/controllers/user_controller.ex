defmodule AssetronicsWeb.UserController do
  @moduledoc """
  Handles user registration and profile management.

  Endpoints:
  - POST /api/users - Register new user
  - GET /api/users - List all users (admin only)
  - GET /api/users/:id - Get user by ID
  - PATCH /api/users/:id - Update user profile
  - DELETE /api/users/:id - Delete user
  - PATCH /api/users/:id/role - Update user role (admin only)
  - PATCH /api/users/:id/status - Update user status (admin only)
  - POST /api/users/:id/unlock - Unlock user account (admin only)
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Accounts
  alias Assetronics.Emails.UserEmail
  alias Assetronics.Mailer

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all users for the current tenant.

  Requires admin or manager role.
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Check if user has permission (will be replaced with Bodyguard policy)
    unless current_user.role in ["super_admin", "admin", "manager"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to list users")
    else
      # Apply filters from query params
      opts = build_filter_opts(params)
      users = Accounts.list_users(tenant, opts)

      conn
      |> put_status(:ok)
      |> render(:index, users: users)
    end
  end

  @doc """
  Creates a new user.

  Public endpoint for user registration (no authentication required).
  """
  def create(conn, %{"user" => user_params}) do
    tenant = get_tenant(conn)

    case Accounts.create_user(tenant, user_params) do
      {:ok, user} ->
        # Send welcome email
        user
        |> UserEmail.welcome_email(tenant)
        |> Mailer.deliver()

        # Send email verification
        if user.email_verification_token do
          user
          |> UserEmail.email_verification(user.email_verification_token, tenant)
          |> Mailer.deliver()
        end

        conn
        |> put_status(:created)
        |> render(:show, user: user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to create user: #{inspect(reason)}")
    end
  end

  @doc """
  Shows a specific user.

  Users can view their own profile.
  Admins and managers can view any user.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    case Accounts.get_user!(tenant, id) do
      user ->
        # Check if user has permission to view this profile
        if can_view_user?(current_user, user) do
          conn
          |> put_status(:ok)
          |> render(:show, user: user)
        else
          conn
          |> put_status(:forbidden)
          |> render(:error, message: "You don't have permission to view this user")
        end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  @doc """
  Updates a user's profile.

  Users can update their own profile.
  Admins can update any user's profile.
  """
  def update(conn, %{"id" => id, "user" => user_params}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    case Accounts.get_user!(tenant, id) do
      user ->
        # Check if user has permission to update this profile
        if can_edit_user?(current_user, user) do
          case Accounts.update_user(tenant, user, user_params) do
            {:ok, user} ->
              conn
              |> put_status(:ok)
              |> render(:show, user: user)

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, changeset: changeset)

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> render(:error, message: "Failed to update user: #{inspect(reason)}")
          end
        else
          conn
          |> put_status(:forbidden)
          |> render(:error, message: "You don't have permission to update this user")
        end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  @doc """
  Deletes a user.

  Admins only.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Only admins can delete users
    unless current_user.role in ["super_admin", "admin"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to delete users")
    else
      case Accounts.get_user!(tenant, id) do
        user ->
          case Accounts.delete_user(tenant, user) do
            {:ok, _user} ->
              conn
              |> send_resp(:no_content, "")

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> render(:error, message: "Failed to delete user: #{inspect(reason)}")
          end
      end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  @doc """
  Updates a user's role.

  Admins only.
  """
  def update_role(conn, %{"id" => id, "role" => role}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Only admins can update roles
    unless current_user.role in ["super_admin", "admin"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to update user roles")
    else
      case Accounts.get_user!(tenant, id) do
        user ->
          case Accounts.update_user_role(tenant, user, role) do
            {:ok, user} ->
              conn
              |> put_status(:ok)
              |> render(:show, user: user)

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, changeset: changeset)

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> render(:error, message: "Failed to update role: #{inspect(reason)}")
          end
      end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  @doc """
  Updates a user's status.

  Admins only.
  """
  def update_status(conn, %{"id" => id, "status" => status}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Only admins can update status
    unless current_user.role in ["super_admin", "admin"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to update user status")
    else
      case Accounts.get_user!(tenant, id) do
        user ->
          case Accounts.update_user_status(tenant, user, status) do
            {:ok, user} ->
              conn
              |> put_status(:ok)
              |> render(:show, user: user)

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(:error, changeset: changeset)

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> render(:error, message: "Failed to update status: #{inspect(reason)}")
          end
      end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  @doc """
  Unlocks a locked user account.

  Admins only.
  """
  def unlock(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Only admins can unlock accounts
    unless current_user.role in ["super_admin", "admin"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to unlock user accounts")
    else
      case Accounts.get_user!(tenant, id) do
        user ->
          case Accounts.unlock_user(tenant, user) do
            {:ok, user} ->
              conn
              |> put_status(:ok)
              |> render(:show, user: user)

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> render(:error, message: "Failed to unlock user: #{inspect(reason)}")
          end
      end
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> render(:error, message: "User not found")
  end

  # Private functions

  defp get_tenant(conn) do
    # Check if tenant is in assigns (from TenantResolver plug or AuthPlug)
    case conn.assigns[:tenant] do
      nil ->
        # Fallback to tenant header
        case get_req_header(conn, "x-tenant") do
          [tenant] -> tenant
          _ -> raise "Tenant not found in request"
        end

      tenant ->
        tenant
    end
  end

  defp can_view_user?(current_user, user) do
    # Users can view their own profile
    # Admins and managers can view any profile
    current_user.id == user.id || current_user.role in ["super_admin", "admin", "manager"]
  end

  defp can_edit_user?(current_user, user) do
    # Users can edit their own profile
    # Admins can edit any profile
    current_user.id == user.id || current_user.role in ["super_admin", "admin"]
  end

  defp build_filter_opts(params) do
    []
    |> maybe_add_filter(:role, params["role"])
    |> maybe_add_filter(:status, params["status"])
    |> maybe_add_filter(:email, params["email"])
  end

  defp maybe_add_filter(opts, _key, nil), do: opts
  defp maybe_add_filter(opts, key, value), do: [{key, value} | opts]
end
