defmodule AssetronicsWeb.UserChannel do
  @moduledoc """
  Channel for user-specific real-time updates including notifications.
  Users join their own channel: "user:{user_id}"
  """

  use AssetronicsWeb, :channel
  require Logger

  @doc """
  Authorizes the user to join their own channel.
  """
  def join("user:" <> user_id, _params, socket) do
    # Verify the user is joining their own channel
    if socket.assigns.current_user.id == user_id do
      Logger.info("[UserChannel] User #{user_id} joined their channel")
      {:ok, socket}
    else
      Logger.warning("[UserChannel] User #{socket.assigns.current_user.id} attempted to join user:#{user_id}")
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("mark_read", %{"notification_id" => notification_id}, socket) do
    tenant = socket.assigns.tenant
    user_id = socket.assigns.current_user.id

    case Assetronics.Notifications.InApp.mark_as_read(tenant, user_id, notification_id) do
      {:ok, _notification} ->
        {:reply, {:ok, %{notification_id: notification_id}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("mark_all_read", _params, socket) do
    tenant = socket.assigns.tenant
    user_id = socket.assigns.current_user.id

    case Assetronics.Notifications.InApp.mark_all_as_read(tenant, user_id) do
      {:ok, count} ->
        {:reply, {:ok, %{count: count}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end
end
