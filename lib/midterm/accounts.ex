defmodule Midterm.Accounts do
  alias Midterm.Accounts.{User, Wallet}
  alias EctoShorts.Actions
  alias MidtermWeb.Schema.ChangesetErrors
  alias Midterm.Currency.CurrencyClient
  alias Ecto.Multi
  alias Midterm.Repo

  def all(params \\ %{}) do
    {:ok, Actions.all(User, params)}
  end

  def find_user(params) do
    Actions.find(User, params)
  end

  def create_user(params) do
    Actions.create(User, params)
  end

  def total_balance(params) do
    # IO.inspect(params)

    total_balance =
      Wallet
      |> Actions.all(params)
      |> Stream.map(fn %{currency: currency, balance: balance} ->
        # IO.inspect("curr: #{currency} - balance: #{balance}")
        balance * CurrencyClient.get_exchange_rate({currency, "USD"})
      end)
      |> Enum.sum()

    {:ok, %{total_balance: total_balance, currency: "USD"}}
  end

  # wallet functions

  def list_wallets(params) do
    {:ok, Actions.all(Wallet, params)}
  end

  @spec create_wallet(any) :: any
  def create_wallet(params) do
    with {:error, changeset} <- Actions.create(Wallet, params) do
      {:error,
       message: "could not create wallet", details: ChangesetErrors.error_details(changeset)}
    end
  end

  def transfer_currency(params) do
    # IO.inspect(params)
    to_wallet = params.to_wallet
    from_wallet = params.from_wallet
    amount = params.amount

    maybe_transfer_currency =
      create_transfer_multi(from_wallet, to_wallet, amount)
      |> Repo.transaction()

    case maybe_transfer_currency do
      {:error, :validate_sender_wallet, :wallet_not_found, _prevsteps} ->
        {:error, message: "sender does not have wallet with currency type"}

      {:error, :validate_recipient_wallet, :wallet_not_found, _prevsteps} ->
        {:error, message: "recipient does not have wallet with currency type"}

      {:error, :debit_sender_wallet, %Ecto.Changeset{} = changeset, _prevsteps} ->
        {:error,
         message: "insufficient funds for transfer",
         details: ChangesetErrors.error_details(changeset)}

      {:ok,
       %{
         debit_sender_wallet: %Wallet{} = send_wallet,
         credit_sender_wallet: %Wallet{} = rec_wallet
       }} ->
        {:ok, %{sender_wallet: send_wallet, receiver_wallet: rec_wallet}}
    end
  end

  defp create_transfer_multi(from_wallet, to_wallet, amount) do
    Multi.new()
    |> Multi.run(
      :validate_recipient_wallet,
      Wallet.validate_wallet_has_currency(to_wallet.user_id, to_wallet.currency)
    )
    |> Multi.run(
      :validate_sender_wallet,
      Wallet.validate_wallet_has_currency(from_wallet.user_id, from_wallet.currency)
    )
    |> Multi.run(:debit_sender_wallet, Wallet.debit_wallet(amount))
    |> Multi.run(:credit_sender_wallet, Wallet.credit_wallet(amount))
  end
end
