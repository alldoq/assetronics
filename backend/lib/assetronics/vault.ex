defmodule Assetronics.Vault do
  @moduledoc """
  Encryption vault for sensitive data using Cloak.

  This module handles encryption/decryption of sensitive fields like:
  - Employee personal information (SSN, date of birth, addresses)
  - Integration credentials (API keys, OAuth tokens)
  - Asset serial numbers and warranty information
  - Financial data (purchase costs, vendor information)
  """

  use Cloak.Vault, otp_app: :assetronics

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")
        }
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    var
    |> System.get_env()
    |> case do
      nil -> raise "Environment variable #{var} is not set"
      key -> key |> String.trim() |> Base.decode64!()
    end
  end
end
