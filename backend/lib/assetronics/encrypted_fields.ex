defmodule Assetronics.EncryptedFields do
  @moduledoc """
  Custom Cloak.Ecto field types for encrypting sensitive data.

  These fields automatically encrypt data when writing to the database
  and decrypt when reading from the database.
  """

  defmodule EncryptedString do
    @moduledoc "Encrypted string field"
    use Cloak.Ecto.Type, vault: Assetronics.Vault
  end

  defmodule EncryptedBinary do
    @moduledoc "Encrypted binary field"
    use Cloak.Ecto.Type, vault: Assetronics.Vault
  end

  defmodule EncryptedMap do
    @moduledoc "Encrypted map/JSON field"
    use Cloak.Ecto.Type, vault: Assetronics.Vault

    def cast(value) when is_map(value), do: {:ok, value}
    def cast(_), do: :error

    def after_decrypt(value) do
      case Jason.decode(value) do
        {:ok, decoded} -> decoded
        {:error, _} -> nil
      end
    end

    def before_encrypt(value) when is_map(value) do
      case Jason.encode(value) do
        {:ok, encoded} -> encoded
        {:error, _} -> ""
      end
    end
    def before_encrypt(_), do: ""
  end

  defmodule EncryptedDecimal do
    @moduledoc "Encrypted decimal field for financial data"
    use Cloak.Ecto.Type, vault: Assetronics.Vault

    def cast(value) when is_binary(value) do
      case Decimal.parse(value) do
        {decimal, _} -> {:ok, decimal}
        :error -> :error
      end
    end
    def cast(%Decimal{} = value), do: {:ok, value}
    def cast(value) when is_number(value), do: {:ok, Decimal.new(value)}
    def cast(_), do: :error

    def after_decrypt(value) do
      case Decimal.parse(value) do
        {decimal, _} -> decimal
        :error -> nil
      end
    end

    def before_encrypt(%Decimal{} = value), do: Decimal.to_string(value)
    def before_encrypt(value) when is_number(value), do: to_string(value)
    def before_encrypt(_), do: "0"
  end
end
