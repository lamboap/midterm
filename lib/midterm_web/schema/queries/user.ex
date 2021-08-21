defmodule MidtermWeb.Schema.Queries.User do
  use Absinthe.Schema.Notation
  alias MidtermWeb.Resolvers.{User, Wallet}

  object :user_queries do
    @desc "This query returns a user for a given ID"
    field :user, :user do
      arg :id, non_null(:id)

      resolve &User.find/2
    end

    @desc "This query returns a list of users based on search criteria"
    field :users, list_of(:user) do
      arg :email, :string
      arg :name, :string

      resolve &User.all/2
    end

    @desc "This query returns all of a user's wallets"
    field :user_wallets, list_of(:wallet) do
      arg :user_id, non_null(:id)

      resolve &Wallet.find/2
    end

    @desc "This query returns all wallets of a particular currency"
    field :curr_wallets, list_of(:wallet) do
      arg :currency, non_null(:currency_types)

      resolve &Wallet.find/2
    end

    @desc "This query returns a user's total balance in USD"
    field :user_total_balance, :total_balance do
      arg :user_id, non_null(:id)

      resolve &User.total_balance/2
    end
  end
end
