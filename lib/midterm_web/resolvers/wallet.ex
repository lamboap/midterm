defmodule MidtermWeb.Resolvers.Wallet do
  alias Midterm.Accounts

  def find(%{user_id: user_id} = args, _) do
    args
    |> Map.put(:user_id, String.to_integer(user_id))
    |> Accounts.list_wallets()
  end

  # by currency
  def find(args, _), do: Accounts.list_wallets(args)

  def create(args, _) do
    # IO.inspect(args)
    args = %{args | user_id: String.to_integer(args.user_id)}

    Accounts.create_wallet(args)
  end

  def transfer_currency(args, _) do
    args =
      args
      |> update_in([:from_wallet, :user_id], &String.to_integer(&1))
      |> update_in([:to_wallet, :user_id], &String.to_integer(&1))

    Accounts.transfer_currency(args)
  end
end
