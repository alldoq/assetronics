defmodule AssetronicsWeb.TransactionJSON do
  alias Assetronics.Transactions.Transaction

  @doc """
  Renders a list of transactions.
  """
  def index(%{transactions: transactions}) do
    %{data: for(transaction <- transactions, do: data(transaction))}
  end

  @doc """
  Renders a single transaction.
  """
  def show(%{transaction: transaction}) do
    %{data: data(transaction)}
  end

  defp data(%Transaction{} = transaction) do
    %{
      id: transaction.id,
      transaction_type: transaction.transaction_type,
      asset_id: transaction.asset_id,
      employee_id: transaction.employee_id,
      from_status: transaction.from_status,
      to_status: transaction.to_status,
      from_location_id: transaction.from_location_id,
      to_location_id: transaction.to_location_id,
      from_employee_id: transaction.from_employee_id,
      to_employee_id: transaction.to_employee_id,
      description: transaction.description,
      notes: transaction.notes,
      performed_by: transaction.performed_by,
      performed_at: transaction.performed_at,
      transaction_amount: transaction.transaction_amount,
      metadata: transaction.metadata,
      ip_address: transaction.ip_address,
      user_agent: transaction.user_agent,
      inserted_at: transaction.inserted_at,
      updated_at: transaction.updated_at,
      # Associations
      asset: asset_data(transaction.asset),
      employee: employee_data(transaction.employee),
      from_employee: employee_data(transaction.from_employee),
      to_employee: employee_data(transaction.to_employee)
    }
  end

  defp asset_data(nil), do: nil
  defp asset_data(asset) do
    %{
      id: asset.id,
      name: asset.name,
      asset_tag: asset.asset_tag,
      serial_number: asset.serial_number
    }
  end

  defp employee_data(nil), do: nil
  defp employee_data(employee) do
    %{
      id: employee.id,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email
    }
  end
end
