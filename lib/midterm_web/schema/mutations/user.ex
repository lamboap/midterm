defmodule MidtermWeb.Schema.Mutations.User do
  use Absinthe.Schema.Notation

  alias MidtermWeb.Resolvers.{User, Wallet}

  object :user_mutations do
    @desc "This mutation creates a user account"
    field :create_user, :user do
      arg :name, non_null(:string)
      arg :email, non_null(:string)

      resolve &User.create/2
    end

    @desc "This mutation creates a user wallet"
    field :create_wallet, :wallet do
      arg :currency, non_null(:currency_types)
      arg :balance, non_null(:float)
      arg :user_id, non_null(:id)

      resolve &Wallet.create/2
    end

    @desc "This mutation transfers money from 1 user to another"
    field :transfer_currency, :transfer_wallets do
      arg :from_wallet, non_null(:transfer_input)
      arg :to_wallet, non_null(:transfer_input)
      arg :amount, non_null(:float)

      resolve &Wallet.transfer_currency/2
    end
  end
end
