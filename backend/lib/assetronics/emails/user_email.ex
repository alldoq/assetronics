defmodule Assetronics.Emails.UserEmail do
  @moduledoc """
  Email templates for user-related notifications.
  """

  import Swoosh.Email

  alias Assetronics.Accounts.User

  @doc """
  Sends a welcome email to a new user.
  """
  def welcome_email(%User{} = user, tenant) do
    app_url = Application.get_env(:assetronics, :app_url)

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Welcome to Assetronics!")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Welcome to Assetronics!</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Welcome to <strong>#{tenant}</strong>'s Assetronics workspace! We're excited to have you on board.
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Assetronics helps your team manage company assets, track workflows, and stay organized.
          </p>

          <div style="margin: 30px 0;">
            <a href="#{app_url}"
               style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Get Started
            </a>
          </div>

          <p style="color: #555; font-size: 14px; line-height: 1.6;">
            Your login email: <strong>#{user.email}</strong>
          </p>

          <p style="color: #777; font-size: 14px; margin-top: 30px;">
            If you have any questions, feel free to reach out to #{support_email()}.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Welcome to Assetronics!

    Hi #{user.first_name || "there"},

    Welcome to #{tenant}'s Assetronics workspace! We're excited to have you on board.

    Assetronics helps your team manage company assets, track workflows, and stay organized.

    Get started: #{app_url}

    Your login email: #{user.email}

    If you have any questions, feel free to reach out to #{support_email()}.
    """)
  end

  @doc """
  Sends an email verification email.
  """
  def email_verification(%User{} = user, token, tenant) do
    api_url = Application.get_env(:assetronics, :api_url) || "http://localhost:4000"
    verify_url = "#{api_url}/api/v1/auth/email/verify?token=#{token}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Verify your email address")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Verify Your Email</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Please verify your email address for your <strong>#{tenant}</strong> Assetronics account.
          </p>

          <div style="margin: 30px 0;">
            <a href="#{verify_url}"
               style="background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Verify Email
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Or copy and paste this link into your browser:<br>
            <code style="background-color: #e9ecef; padding: 5px 10px; border-radius: 3px; font-size: 12px;">
              #{verify_url}
            </code>
          </p>

          <p style="color: #999; font-size: 12px; margin-top: 30px;">
            If you didn't create this account, you can safely ignore this email.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Verify Your Email

    Hi #{user.first_name || "there"},

    Please verify your email address for your #{tenant} Assetronics account.

    Click here to verify: #{verify_url}

    If you didn't create this account, you can safely ignore this email.
    """)
  end

  @doc """
  Sends a password reset email.
  """
  def password_reset(%User{} = user, token, tenant) do
    app_url = Application.get_env(:assetronics, :app_url)
    reset_url = "#{app_url}/reset-password?token=#{token}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Reset your password")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Reset Your Password</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            We received a request to reset the password for your <strong>#{tenant}</strong> Assetronics account.
          </p>

          <div style="margin: 30px 0;">
            <a href="#{reset_url}"
               style="background-color: #dc3545; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Reset Password
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Or copy and paste this link into your browser:<br>
            <code style="background-color: #e9ecef; padding: 5px 10px; border-radius: 3px; font-size: 12px;">
              #{reset_url}
            </code>
          </p>

          <p style="color: #555; font-size: 14px; line-height: 1.6;">
            This link will expire in <strong>1 hour</strong>.
          </p>

          <p style="color: #999; font-size: 12px; margin-top: 30px;">
            If you didn't request a password reset, you can safely ignore this email. Your password will not be changed.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Reset Your Password

    Hi #{user.first_name || "there"},

    We received a request to reset the password for your #{tenant} Assetronics account.

    Click here to reset your password: #{reset_url}

    This link will expire in 1 hour.

    If you didn't request a password reset, you can safely ignore this email. Your password will not be changed.
    """)
  end

  @doc """
  Sends a password changed confirmation email.
  """
  def password_changed(%User{} = user, tenant) do
    support = support_email()

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Your password has been changed")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Password Changed</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            This is a confirmation that the password for your <strong>#{tenant}</strong> Assetronics account has been successfully changed.
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            If you made this change, no further action is required.
          </p>

          <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
            <p style="color: #856404; font-size: 14px; margin: 0;">
              <strong>⚠️ Didn't make this change?</strong><br>
              If you didn't change your password, please contact us immediately at #{support}.
            </p>
          </div>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Password Changed

    Hi #{user.first_name || "there"},

    This is a confirmation that the password for your #{tenant} Assetronics account has been successfully changed.

    If you made this change, no further action is required.

    ⚠️ Didn't make this change?
    If you didn't change your password, please contact us immediately at #{support}.
    """)
  end

  # Private helper functions

  defp from_address do
    email = Application.get_env(:assetronics, :from_email)
    name = Application.get_env(:assetronics, :from_name)
    {name, email}
  end

  defp support_email do
    Application.get_env(:assetronics, :support_email)
  end

  defp full_name(%User{first_name: first, last_name: last}) when is_binary(first) and is_binary(last) do
    "#{first} #{last}"
  end

  defp full_name(%User{first_name: first}) when is_binary(first), do: first
  defp full_name(%User{}), do: nil
end
