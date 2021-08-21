defmodule Midterm.Accounts.Wallet do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Midterm.Accounts.Wallet
  alias Midterm.Currency.CurrencyClient

  @valid_currencies Application.get_env(:midterm, :currencies)

  schema "wallets" do
    field :balance, :float
    field :currency, :string
    belongs_to :user, Midterm.Accounts.User
  end

  @available_fields [:balance, :currency, :user_id]

  def create_changeset(params) do
    changeset(%Midterm.Accounts.Wallet{}, params)
  end

  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, @available_fields)
    |> validate_required(@available_fields)
    |> unique_constraint(:one_wallet_per_currency,
      name: :user_currency_uniq_index,
      message: "only one wallet per currency"
    )
    |> validate_number(:balance, greater_than: 0, message: "insufficient funds for transfer")
    |> validate_inclusion(:currency, @valid_currencies, message: "unsupported currency")
  end

  def validate_wallet_has_currency(user_id, currency) do
    fn repo, _ ->
      case from(w in Wallet,
             where: w.user_id == ^user_id and w.currency == ^currency
           )
           |> repo.all() do
        [] -> {:error, :wallet_not_found}
        [recip_wallet] -> {:ok, recip_wallet}
      end
    end
  end

  def debit_wallet(amount) do
    fn repo, %{validate_sender_wallet: wallet} ->
      wallet
      |> Wallet.changeset(%{balance: wallet.balance - amount})
      |> repo.update()
    end
  end

  def credit_wallet(amount) do
    fn repo, %{validate_sender_wallet: send_wallet, validate_recipient_wallet: wallet} ->
      converted_amount =
        amount * CurrencyClient.get_exchange_rate({send_wallet.currency, wallet.currency})

      # IO.inspect(converted_amount)
      wallet
      |> Wallet.changeset(%{balance: wallet.balance + converted_amount})
      |> repo.update()
    end
  end
end
