defmodule MidtermWeb.Schema.Mutations.UserTest do
  use Midterm.DataCase
  alias Midterm.Schema
  alias Midterm.Accounts
  alias Midterm.Accounts.Wallet
  alias Midterm.Currency.CurrencyServer

  @create_user_doc """
  mutation($name: String!, $email: String!) {
  	createUser(name: $name, email: $email) {
  		id
  		name
  		email
  	}
  }
  """

  @create_wallet_doc """
  mutation($currency:  CurrencyTypes!, $balance: Float!, $user_id: ID!) {
  	createWallet(user_id: $user_id, currency: $currency, balance: $balance) {
  		user_id
  		balance
  		currency
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

  @mizyu %{name: "MIZYU", email: "suzuka@gakko.com"}

  @usd_wallet %{currency: "USD", balance: 10.0}

  # @cad_wallet %{currency: "CAD", balance: 10.0}

  # @jpy_wallet %{currency: "JPY", balance: 10.0}

  # @gbp_wallet %{currency: "GBP", balance: 10.0}

  setup do
    {:ok, kanon} = Accounts.create_user(@kanon)

    {:ok, kanon_wallet_usd} =
      Accounts.create_wallet(%{currency: "USD", balance: 10.0, user_id: kanon.id})

    {:ok, kanon_wallet_cad} =
      Accounts.create_wallet(%{currency: "CAD", balance: 10.0, user_id: kanon.id})

    {:ok, rin} = Accounts.create_user(@rin)

    {:ok, rin_wallet_jpy} =
      Accounts.create_wallet(%{currency: "JPY", balance: 10.0, user_id: rin.id})

    {:ok, rin_wallet_usd} =
      Accounts.create_wallet(%{currency: "USD", balance: 10.0, user_id: rin.id})

    {:ok,
     %{
       kanon: kanon,
       rin: rin,
       kanon_wallet_usd: kanon_wallet_usd,
       kanon_wallet_cad: kanon_wallet_cad,
       rin_wallet_jpy: rin_wallet_jpy,
       rin_wallet_usd: rin_wallet_usd
     }}
  end

  describe "createUser" do
    test "test_create_user" do
      suzuka = %{"name" => "SUZUKA", "email" => "suzuka@gakko.com"}

      assert {:ok, %{data: data}} = Absinthe.run(@create_user_doc, Schema, variables: suzuka)

      calculated = data["createUser"]

      Enum.map(suzuka, fn {k, v} ->
        assert v === calculated[k]
      end)
    end
  end

  describe "createWallet" do
    test "test_create_wallet_to_user" do
      # given
      {:ok, mizyu} = Accounts.create_user(@mizyu)
      jpy_wallet = %{"currency" => "JPY", "balance" => 10.0}
      mizyu_wallet = Map.merge(jpy_wallet, %{"user_id" => to_string(mizyu.id)})
      # when

      # IO.inspect(mizyu_wallet)
      assert {:ok, %{data: data}} =
               Absinthe.run(@create_wallet_doc, Schema, variables: mizyu_wallet)

      # then
      assert mizyu_wallet === data["createWallet"]
    end

    test "validate_one_wallet_per_currency_per_user" do
      # given
      {:ok, mizyu} = Accounts.create_user(@mizyu)
      Accounts.create_wallet(%{currency: "JPY", balance: 10.0, user_id: mizyu.id})

      # when
      jpy_wallet = %{"currency" => "JPY", "balance" => 10.0}
      mizyu_wallet = Map.merge(jpy_wallet, %{"user_id" => to_string(mizyu.id)})

      assert {:ok,
              %{
                errors: [%{details: %{one_wallet_per_currency: ["only one wallet per currency"]}}]
              }} = Absinthe.run(@create_wallet_doc, Schema, variables: mizyu_wallet)
    end

    test "validate_allowable_currency_in_wallet" do
      {:ok, mizyu} = Accounts.create_user(@mizyu)

      attrs = %{@usd_wallet | currency: "ZZZ"}
      attrs = Map.merge(attrs, %{user_id: mizyu.id})
      changeset = Wallet.changeset(%Wallet{}, attrs)

      assert %{currency: ["unsupported currency"]} = errors_on(changeset)
    end
  end

  describe "transferCurrency" do
    test "test_transfer_currency", context do
      # given
      exchange_rate = :rand.uniform(4) / 1
      CurrencyServer.override_scheduler({"USD", "JPY"}, exchange_rate)

      transfer = %{
        "from_wallet" => %{
          "user_id" => context.kanon.id,
          "currency" => "USD"
        },
        "to_wallet" => %{
          "user_id" => context.rin.id,
          "currency" => "JPY"
        },
        "amount" => 3.0
      }

      # when
      assert {:ok, %{data: data}} =
               Absinthe.run(@transfer_currency_doc, Schema, variables: transfer)

      # then
      %{"receiverWallet" => to_wallet, "senderWallet" => from_wallet} = data["transferCurrency"]
      assert from_wallet["balance"] === 7.0
      assert to_wallet["balance"] === 10.0 + 3.0 * exchange_rate
    end

    test "test_recipient_currency", context do
      # given
      exchange_rate = :rand.uniform(4) / 1
      CurrencyServer.override_scheduler({"USD", "CNY"}, exchange_rate)

      transfer = %{
        "from_wallet" => %{
          "user_id" => context.kanon.id,
          "currency" => "USD"
        },
        "to_wallet" => %{
          "user_id" => context.rin.id,
          "currency" => "CNY"
        },
        "amount" => 3.0
      }

      # when / then
      err_msg = "recipient does not have wallet with currency type"

      assert {:ok, %{errors: [%{message: ^err_msg}]}} =
               Absinthe.run(@transfer_currency_doc, Schema, variables: transfer)
    end

    test "test_sender_currency", context do
      # given
      exchange_rate = :rand.uniform(4) / 1
      CurrencyServer.override_scheduler({"CNY", "JPY"}, exchange_rate)

      transfer = %{
        "from_wallet" => %{
          "user_id" => context.kanon.id,
          "currency" => "CNY"
        },
        "to_wallet" => %{
          "user_id" => context.rin.id,
          "currency" => "JPY"
        },
        "amount" => 3.0
      }

      # when / then
      err_msg = "sender does not have wallet with currency type"

      assert {:ok, %{errors: [%{message: ^err_msg}]}} =
               Absinthe.run(@transfer_currency_doc, Schema, variables: transfer)
    end

    test "test_sender_wallet_insufficient", context do
      # given
      exchange_rate = :rand.uniform(4) / 1
      CurrencyServer.override_scheduler({"USD", "JPY"}, exchange_rate)

      transfer = %{
        "from_wallet" => %{
          "user_id" => context.kanon.id,
          "currency" => "USD"
        },
        "to_wallet" => %{
          "user_id" => context.rin.id,
          "currency" => "JPY"
        },
        "amount" => 300.0
      }

      # when / then
      err_msg = "insufficient funds for transfer"

      assert {:ok, %{errors: [%{message: ^err_msg}]}} =
               Absinthe.run(@transfer_currency_doc, Schema, variables: transfer)
    end
  end
end
