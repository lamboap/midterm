defmodule Midterm.Currency.CurrencyClient do
  # retrieve exchange rate for currency pair
  defdelegate get_exchange_rate(currency_pair), to: Midterm.Currency.CurrencyServer
end
