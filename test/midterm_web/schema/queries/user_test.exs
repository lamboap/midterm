defmodule MidtermWeb.Schema.Queries.UserTest do
  use Midterm.DataCase

  alias Midterm.Schema
  alias Midterm.Accounts
  alias Midterm.Currency.CurrencyServer

  @user_doc """
  query($id: ID!) {
  	user(id: $id) {
  		id
  		name
  		email
  		wallets {
  			balance
  			currency
  		}
  	}
  }
  """

  @users_doc """
  query($name: String, $email: String) {
  	users(name: $name, email: $email) {
  		id
  		name
  		email
  		wallets {
  			balance
  			currency
  		}
  	}
  }
  """

  @user_wallets_doc """
  query($user_id: ID!) {
  	user_wallets(userId: $user_id) {
  		userId
  		balance
  		currency
  	}
  }
  """

  @curr_wallets_doc """
  query($currency: CurrencyTypes!) {
    currWallets(currency: $currency) {
      balance
      currency
      userId
    }
  }
  """

  @user_total_balance_doc """
  query($user_id: ID!) {
    userTotalBalance(userId: $user_id) {
      totalBalance
      currency
    }
  }
  """

  setup do
    {:ok, kanon} = Accounts.create_user(%{name: "KANNON", email: "kanon@gakko.com"})

    {:ok, kanon_wallet_usd} =
      Accounts.create_wallet(%{currency: "USD", balance: 10.0, user_id: kanon.id})

    {:ok, kanon_wallet_cad} =
      Accounts.create_wallet(%{currency: "CAD", balance: 10.0, user_id: kanon.id})

    {:ok, rin} = Accounts.create_user(%{name: "RIN", email: "rin@gakko.com"})

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

  describe "@user" do
    test "find_user_by_id", context do
      assert {:ok, %{data: data}} =
               Absinthe.run(@user_doc, Schema, variables: %{"id" => context.kanon.id})

      assert data["user"]["id"] === to_string(context.kanon.id)
      assert data["user"]["wallets"] |> Enum.count() === 2
    end
  end

  describe "@users" do
    test "find_users_by_name", context do
      assert {:ok, %{data: data}} =
               Absinthe.run(@users_doc, Schema, variables: %{"name" => context.rin.name})

      rin = Enum.find(data["users"], fn user -> user["name"] == context.rin.name end)
      assert rin["name"] === context.rin.name
    end
  end

  describe "@userWallets" do
    test "find_wallets_by_user_id", context do
      assert {:ok, %{data: data}} =
               Absinthe.run(@user_wallets_doc, Schema, variables: %{"user_id" => context.rin.id})

      curr_data = data["user_wallets"] |> Enum.map(& &1["currency"])

      Enum.each(["JPY", "USD"], fn curr ->
        assert curr in curr_data
      end)
    end
  end

  describe "@currWallets" do
    test "get_wallets_by_currency" do
      assert {:ok, %{data: data}} =
               Absinthe.run(@curr_wallets_doc, Schema, variables: %{"currency" => "USD"})

      # assert 2 come back
      assert Enum.count(data["currWallets"]) === 2
    end
  end

  describe "@userTotalBalance" do
    test "get_total_balance_in_USD", context do
      exchange_rate = :rand.uniform(4) / 1

      CurrencyServer.override_scheduler({"JPY", "USD"}, exchange_rate)
      CurrencyServer.override_scheduler({"USD", "USD"}, 1.0)

      assert {:ok, %{data: data}} =
               Absinthe.run(@user_total_balance_doc, Schema,
                 variables: %{"user_id" => context.rin.id}
               )

      calculated = data["userTotalBalance"]["totalBalance"]

      expected =
        context.rin_wallet_jpy.balance * exchange_rate + context.rin_wallet_jpy.balance * 1.0

      assert expected === calculated
    end
  end
end
