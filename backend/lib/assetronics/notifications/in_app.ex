defmodule Assetronics.Notifications.InApp do
  @moduledoc """
  Handles in-app notifications: storing in database and broadcasting via Phoenix Channels.
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Notifications.InAppNotification
  alias AssetronicsWeb.Endpoint
  require Logger

  @doc """
  Creates and broadcasts an in-app notification to a user.
  """
  def create_and_broadcast(tenant, user_id, notification_type, data) do
    attrs = %{
      user_id: user_id,
      notification_type: notification_type,
      title: data[:title] || "Notification",
      body: data[:body] || "",
      action_url: data[:action_url],
      action_text: data[:action_text]
    }

    case create_notification(tenant, attrs) do
      {:ok, notification} ->
        # Broadcast to user's channel
        broadcast_to_user(user_id, notification)
        {:ok, notification}

      {:error, changeset} ->
        Logger.error("[InApp] Failed to create notification: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  @doc """
  Creates a notification in the database.
  """
  def create_notification(tenant, attrs) do
    %InAppNotification{}
    |> InAppNotification.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets all notifications for a user.
  """
  def list_notifications(tenant, user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    unread_only = Keyword.get(opts, :unread_only, false)

    query =
      from n in InAppNotification,
        where: n.user_id == ^user_id,
        order_by: [desc: n.inserted_at],
        limit: ^limit

    query =
      if unread_only do
        from n in query, where: n.read == false
      else
        query
      end

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets the count of unread notifications for a user.
  """
  def unread_count(tenant, user_id) do
    query =
      from n in InAppNotification,
        where: n.user_id == ^user_id and n.read == false,
        select: count(n.id)

    Repo.one(query, prefix: Triplex.to_prefix(tenant)) || 0
  end

  @doc """
  Marks a notification as read.
  """
  def mark_as_read(tenant, user_id, notification_id) do
    case Repo.get_by(
           InAppNotification,
           [id: notification_id, user_id: user_id],
           prefix: Triplex.to_prefix(tenant)
         ) do
      nil ->
        {:error, :not_found}

      notification ->
        notification
        |> InAppNotification.mark_as_read_changeset()
        |> Repo.update(prefix: Triplex.to_prefix(tenant))
    end
  end

  @doc """
  Marks all notifications as read for a user.
  """
  def mark_all_as_read(tenant, user_id) do
    now = DateTime.utc_now()

    {count, _} =
      from(n in InAppNotification,
        where: n.user_id == ^user_id and n.read == false
      )
      |> Repo.update_all([set: [read: true, read_at: now]], prefix: Triplex.to_prefix(tenant))

    {:ok, count}
  end

  @doc """
  Deletes old read notifications (older than 30 days).
  """
  def delete_old_notifications(tenant, days \\ 30) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    {count, _} =
      from(n in InAppNotification,
        where: n.read == true and n.read_at < ^cutoff_date
      )
      |> Repo.delete_all(prefix: Triplex.to_prefix(tenant))

    {:ok, count}
  end

  ## Private Functions

  defp broadcast_to_user(user_id, notification) do
    topic = "user:#{user_id}"

    payload = %{
      id: notification.id,
      notification_type: notification.notification_type,
      title: notification.title,
      body: notification.body,
      action_url: notification.action_url,
      action_text: notification.action_text,
      read: notification.read,
      inserted_at: notification.inserted_at
    }

    Endpoint.broadcast(topic, "new_notification", payload)
    Logger.info("[InApp] Broadcasted notification to #{topic}")
  end
end
