defmodule MidtermWeb.Schema.Subscriptions.UserTest do
  use MidtermWeb.SubscriptionCase

  alias Midterm.Accounts
  alias Midterm.Currency.CurrencyServer

  @total_worth_change_sub_doc """
  subscription($user_id: ID!) {
  	totalWorthChange(user_id: $user_id) {
  		currency
  		totalBalance
  	}
  }
  """

  @updated_exchange_rate_sub_doc """
  subscription($from_curr: CurrencyTypes!, $to_curr: CurrencyTypes!) {
    updatedExchangeRate(fromCurr:$from_curr,toCurr:$to_curr) {
      exchangeRate
      fromCurr
      toCurr
      lastUpdated
    }
  }
  """

  @transfer_currency_doc """
  mutation($from_wallet: TransferInput!, $to_wallet: TransferInput!, $amount: Float!) {
  	transferCurrency(from_wallet: $from_wallet, to_wallet: $to_wallet, amount: $amount) {
    senderWallet{
      balance,
      currency,
      userId
    },
    receiverWallet{
      balance,
      currency,
      userId
    }
    }
  }
  """

  @kanon %{name: "KANNON", email: "kanon@gakko.com"}
  @rin %{name: "RIN", email: "rin@gakko.com"}

  describe "totalWorthChange" do
    test "subscription_test_for_currency_transfers", %{socket: socket} do
      # transfer
      CurrencyServer.override_scheduler({"USD", "JPY"}, 1.0)
      # total_balance
      CurrencyServer.override_scheduler({"JPY", "USD"}, 1.0)
      CurrencyServer.override_scheduler({"USD", "USD"}, 1.0)
      CurrencyServer.override_scheduler({"CAD", "USD"}, 1.0)

      {:ok, kanon} = Accounts.create_user(@kanon)

      {:ok, _kanon_wallet_usd} =
        Accounts.create_wallet(%{currency: "USD", balance: 10.0, user_id: kanon.id})

      {:ok, _kanon_wallet_cad} =
        Accounts.create_wallet(%{currency: "CAD", balance: 10.0, user_id: kanon.id})

      {:ok, rin} = Accounts.create_user(@rin)

      {:ok, _rin_wallet_jpy} =
        Accounts.create_wallet(%{currency: "JPY", balance: 10.0, user_id: rin.id})

      {:ok, _rin_wallet_usd} =
        Accounts.create_wallet(%{currency: "USD", balance: 10.0, user_id: rin.id})

      transfer = %{
        "from_wallet" => %{
          "user_id" => kanon.id,
          "currency" => "USD"
        },
        "to_wallet" => %{
          "user_id" => rin.id,
          "currency" => "JPY"
        },
        "amount" => 3.0
      }

      # then
      # subscribe to update

      kanon_str = to_string(kanon.id)
      rin_str = to_string(rin.id)

      ref = push_doc(socket, @total_worth_change_sub_doc, variables: %{"user_id" => kanon_str})

      # pattern match subscription id
      assert_reply ref, :ok, %{subscriptionId: subscription_id}, 5000

      ref = push_doc(socket, @transfer_currency_doc, variables: transfer)

      assert_reply ref, :ok, reply, 5000

      assert %{
               data: %{
                 "transferCurrency" => %{
                   "receiverWallet" => %{
                     "balance" => 13.0,
                     "currency" => "JPY",
                     "userId" => ^rin_str
                   },
                   "senderWallet" => %{
                     "balance" => 7.0,
                     "currency" => "USD",
                     "userId" => ^kanon_str
                   }
                 }
               }
             } = reply

      # assert the response from the subscription
      assert_push "subscription:data", data

      assert %{
               result: %{
                 data: %{
                   "totalWorthChange" => %{"currency" => "USD", "totalBalance" => 17.0}
                 }
               },
               subscriptionId: ^subscription_id
             } = data
    end
  end

  describe "subscription test for exchange rate changes" do
    test "this test tests subscriptions waiting for exhange rates updates", %{socket: socket} do
      # initialize
      CurrencyServer.override_scheduler({"USD", "JPY"}, 2.0)

      # subscription
      ref =
        push_doc(socket, @updated_exchange_rate_sub_doc,
          variables: %{"from_curr" => "USD", "to_curr" => "JPY"}
        )

      assert_reply ref, :ok, %{subscriptionId: subscription_id}, 5000

      # trigger
      CurrencyServer.override_scheduler({"USD", "JPY"}, 3.0)

      # check mailbox
      assert_push "subscription:data", data

      assert %{
               result: %{
                 data: %{
                   "updatedExchangeRate" => %{
                     "exchangeRate" => 3.0,
                     "fromCurr" => "USD",
                     "lastUpdated" => "2021-07-10 16:35:55",
                     "toCurr" => "JPY"
                   }
                 }
               },
               subscriptionId: ^subscription_id
             } = data
    end
  end

  describe "genserver test" do
    test "this test asserts the state value in the genserver " do
      # setup initialize
      [from_curr, to_curr] = Enum.take_random(Application.get_env(:midterm, :currencies), 2)
      curr_pair = [from_curr, to_curr] |> List.to_tuple()
      exchange_rate = (:rand.uniform() * (3 - 1) + 1) |> Float.round(3)

      # update GenServer state to initialized values
      CurrencyServer.override_scheduler(curr_pair, exchange_rate)

      # retrieve state
      actual_state = CurrencyServer.get_state(curr_pair)

      assert %{
               curr_pair: ^curr_pair,
               exchange_rate: ^exchange_rate,
               from_curr: ^from_curr,
               last_updated: "2021-07-10 16:35:55",
               to_curr: ^to_curr
             } = actual_state
    end
  end
end
