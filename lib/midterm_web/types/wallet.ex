defmodule MidtermWeb.Types.Wallet do
  use Absinthe.Schema.Notation

  @desc "this is the user wallet return type"
  object :wallet do
    field :balance, :float
    field :currency, :currency_types
    field :user_id, :id
  end

  object :transfer_wallets do
    field :sender_wallet, :wallet
    field :receiver_wallet, :wallet
  end

  @desc "this is a list of currency types"
  enum :currency_types do
    value(:EUR, as: "EUR")
    value(:CAD, as: "CAD")
    value(:USD, as: "USD")
    value(:CNY, as: "CNY")
    value(:JPY, as: "JPY")
    value(:GBP, as: "GBP")
  end

  @desc "this is a transfer input type"
  input_object :transfer_input do
    field :user_id, non_null(:id)
    field :currency, :currency_types
  end

  @desc "this is the total balance type"
  object :total_balance do
    field :total_balance, :float
    field :currency, :currency_types
  end

  @desc "This is the currency state in the genserver for a curr pair exchange rate"
  object :exchange_rate do
    field :from_curr, :currency_types
    field :to_curr, :currency_types
    field :exchange_rate, :float
    field :last_updated, :string
  end
end
