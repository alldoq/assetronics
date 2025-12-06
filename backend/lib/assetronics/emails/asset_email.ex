defmodule Assetronics.Emails.AssetEmail do
  @moduledoc """
  Email templates for asset-related notifications.
  """

  import Swoosh.Email

  alias Assetronics.Accounts.User
  alias Assetronics.Assets.Asset

  @doc """
  Sends an asset assignment notification email.
  """
  def asset_assigned(%User{} = user, %Asset{} = asset, tenant) do
    app_url = Application.get_env(:assetronics, :app_url)
    asset_url = "#{app_url}/assets/#{asset.id}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Asset assigned to you: #{asset.name}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Asset Assigned</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            An asset has been assigned to you in your <strong>#{tenant}</strong> workspace.
          </p>

          <div style="background-color: white; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">#{asset.name}</h3>
            #{if asset.asset_tag, do: "<p style='color: #666; margin: 5px 0;'><strong>Asset Tag:</strong> #{asset.asset_tag}</p>", else: ""}
            #{if asset.category, do: "<p style='color: #666; margin: 5px 0;'><strong>Category:</strong> #{format_category(asset.category)}</p>", else: ""}
            #{if asset.serial_number, do: "<p style='color: #666; margin: 5px 0;'><strong>Serial Number:</strong> #{asset.serial_number}</p>", else: ""}
            #{if asset.make && asset.model, do: "<p style='color: #666; margin: 5px 0;'><strong>Make/Model:</strong> #{asset.make} #{asset.model}</p>", else: ""}
          </div>

          <div style="margin: 30px 0;">
            <a href="#{asset_url}"
               style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              View Asset Details
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Please take good care of this asset and report any issues to your manager.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Asset Assigned

    Hi #{user.first_name || "there"},

    An asset has been assigned to you in your #{tenant} workspace.

    Asset Details:
    - Name: #{asset.name}
    #{if asset.asset_tag, do: "- Asset Tag: #{asset.asset_tag}\n", else: ""}#{if asset.category, do: "- Category: #{format_category(asset.category)}\n", else: ""}#{if asset.serial_number, do: "- Serial Number: #{asset.serial_number}\n", else: ""}
    View details: #{asset_url}

    Please take good care of this asset and report any issues to your manager.
    """)
  end

  @doc """
  Sends an asset return reminder email.
  """
  def asset_return_reminder(%User{} = user, %Asset{} = asset, return_date, _tenant) do
    app_url = Application.get_env(:assetronics, :app_url)
    asset_url = "#{app_url}/assets/#{asset.id}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Reminder: Return asset - #{asset.name}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Asset Return Reminder</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            This is a reminder that you need to return the following asset by <strong>#{format_date(return_date)}</strong>.
          </p>

          <div style="background-color: white; border: 2px solid #ffc107; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">#{asset.name}</h3>
            #{if asset.asset_tag, do: "<p style='color: #666; margin: 5px 0;'><strong>Asset Tag:</strong> #{asset.asset_tag}</p>", else: ""}
          </div>

          <div style="margin: 30px 0;">
            <a href="#{asset_url}"
               style="background-color: #ffc107; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              View Asset Details
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Please contact your manager if you need an extension or have any questions.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Asset Return Reminder

    Hi #{user.first_name || "there"},

    This is a reminder that you need to return the following asset by #{format_date(return_date)}.

    Asset: #{asset.name}
    #{if asset.asset_tag, do: "Asset Tag: #{asset.asset_tag}\n", else: ""}
    View details: #{asset_url}

    Please contact your manager if you need an extension or have any questions.
    """)
  end

  # Private helper functions

  defp from_address do
    email = Application.get_env(:assetronics, :from_email)
    name = Application.get_env(:assetronics, :from_name)
    {name, email}
  end

  defp full_name(%User{first_name: first, last_name: last}) when is_binary(first) and is_binary(last) do
    "#{first} #{last}"
  end

  defp full_name(%User{first_name: first}) when is_binary(first), do: first
  defp full_name(%User{}), do: nil

  defp format_category(category) do
    category
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  defp format_date(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%B %d, %Y")
  defp format_date(_), do: "N/A"
end
