defmodule MidtermWeb.Schema.Subscriptions.Exchange do
  use Absinthe.Schema.Notation
  alias MidtermWeb.Resolvers.User

  object :user_subscriptions do
    field :total_worth_change, :total_balance do
      arg(:user_id, non_null(:id))

      trigger(:transfer_currency,
        topic: fn
          %{sender_wallet: send_wallet, receiver_wallet: recipient_wallet} ->
            [
              "total_#{send_wallet.user_id}",
              "total_#{recipient_wallet.user_id}"
            ]

          _ ->
            []
        end
      )

      config(fn args, _ ->
        {:ok, topic: "total_#{args.user_id}"}
      end)

      resolve(&User.total_balance/2)
    end

    field :updated_exchange_rate, :exchange_rate do
      arg(:from_curr, non_null(:currency_types))
      arg(:to_curr, non_null(:currency_types))

      config(fn args, _ ->
        {:ok, topic: "#{args.from_curr}_#{args.to_curr}"}
      end)
    end
  end
end
