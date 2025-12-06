defmodule AssetronicsWeb.PasswordController do
  @moduledoc """
  Handles password reset and password change operations.

  Endpoints:
  - POST /api/auth/password/reset - Request password reset (sends email with token)
  - POST /api/auth/password/confirm - Confirm password reset using token
  - PATCH /api/auth/password/change - Change password for authenticated user
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Accounts
  alias Assetronics.Emails.UserEmail
  alias Assetronics.Mailer

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Requests a password reset.

  Sends a password reset email with a token.
  Returns success even if email doesn't exist (security best practice).

  ## Parameters
  - email: User's email address
  """
  def request_reset(conn, %{"email" => email}) do
    tenant = get_tenant(conn)

    case Accounts.request_password_reset(tenant, email) do
      {:ok, user} ->
        # Send password reset email
        user
        |> UserEmail.password_reset(user.password_reset_token, tenant)
        |> Mailer.deliver()

        conn
        |> put_status(:ok)
        |> render(:reset_requested, message: "If the email exists, a password reset link has been sent")

      {:error, :not_found} ->
        # Don't reveal if email exists - return same message
        conn
        |> put_status(:ok)
        |> render(:reset_requested, message: "If the email exists, a password reset link has been sent")

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to process reset request: #{inspect(reason)}")
    end
  end

  @doc """
  Confirms password reset using the token.

  ## Parameters
  - token: Password reset token from email
  - password: New password
  """
  def confirm_reset(conn, %{"token" => token, "password" => password}) do
    tenant = get_tenant(conn)

    case Accounts.reset_password(tenant, token, %{password: password}) do
      {:ok, user} ->
        # Send password changed confirmation email
        user
        |> UserEmail.password_changed(tenant)
        |> Mailer.deliver()

        conn
        |> put_status(:ok)
        |> render(:reset_confirmed, message: "Password has been reset successfully")

      {:error, :invalid_token} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Invalid or expired reset token")

      {:error, :token_expired} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Reset token has expired. Please request a new one")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to reset password: #{inspect(reason)}")
    end
  end

  @doc """
  Changes password for the authenticated user.

  Requires current password for verification.

  ## Parameters
  - current_password: User's current password
  - password: New password
  """
  def change_password(conn, %{"current_password" => current_password, "password" => new_password}) do
    tenant = conn.assigns[:tenant]
    user = conn.assigns[:current_user]

    # Verify current password
    if Assetronics.Accounts.User.verify_password(user, current_password) do
      case Accounts.change_password(tenant, user, %{password: new_password}) do
        {:ok, updated_user} ->
          # Send password changed confirmation email
          updated_user
          |> UserEmail.password_changed(tenant)
          |> Mailer.deliver()

          conn
          |> put_status(:ok)
          |> render(:password_changed, message: "Password has been changed successfully")

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, changeset: changeset)

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> render(:error, message: "Failed to change password: #{inspect(reason)}")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "Current password is incorrect")
    end
  end

  @doc """
  Verifies an email address using the verification token.

  ## Parameters
  - token: Email verification token
  """
  def verify_email(conn, %{"token" => token}) do
    tenant = get_tenant(conn)

    case Accounts.verify_email(tenant, token) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> render(:email_verified, message: "Email has been verified successfully")

      {:error, :invalid_token} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Invalid verification token")

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to verify email: #{inspect(reason)}")
    end
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
end
