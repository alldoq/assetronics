defmodule AssetronicsWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "user:*", AssetronicsWeb.UserChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # Verify the token and get user + tenant
    case verify_token(token) do
      {:ok, user_id, tenant} ->
        # Load the user
        case Assetronics.Accounts.get_user!(tenant, user_id) do
          user ->
            socket =
              socket
              |> assign(:current_user, user)
              |> assign(:tenant, tenant)

            {:ok, socket}

          nil ->
            :error
        end

      :error ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"

  defp verify_token(token) do
    case AssetronicsWeb.Guardian.decode_and_verify(token) do
      {:ok, %{"sub" => "User:" <> user_id, "tenant" => tenant}} ->
        {:ok, user_id, tenant}

      _ ->
        :error
    end
  end
end
