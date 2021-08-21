defmodule MidtermWeb.Resolvers.User do
  alias Midterm.Accounts

  def find(%{id: id}, _) do
    id = String.to_integer(id)

    Accounts.find_user(%{id: id})
  end

  def all(args, _) do
    Accounts.all(args)
  end

  def create(args, _) do
    Accounts.create_user(args)
  end

  def total_balance(args, _) do
    args = %{args | user_id: String.to_integer(args.user_id)}

    Accounts.total_balance(args)
  end
end
