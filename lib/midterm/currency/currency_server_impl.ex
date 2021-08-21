defmodule Midterm.Currency.CurrencyServerImpl do
  @currency_url Application.get_env(:midterm, :currency_url)
  @api_key Application.get_env(:midterm, :api_key)

  def update_exchange_rate!(state) do
    curr_pair = state[:curr_pair]

    updated_state =
      Task.Supervisor.async_nolink(Currency.TaskSupervisor, fn ->
        http_fetch_exchange_rate(curr_pair)
      end)
      |> Task.await()
      |> update_state(state)

    if updated_state[:exchange_rate] != state[:exchange_rate] do
      IO.inspect(
        "updated: #{updated_state[:from_curr]}_#{updated_state[:to_curr]}  #{
          updated_state[:exchange_rate]
        }"
      )

      # fire event
      Absinthe.Subscription.publish(MidtermWeb.Endpoint, updated_state,
        updated_exchange_rate: "#{updated_state[:from_curr]}_#{updated_state[:to_curr]}"
      )
    end

    # return new state
    updated_state
  end

  defp update_state(
         %{
           "Realtime Currency Exchange Rate" => %{
             "1. From_Currency Code" => from_curr,
             "3. To_Currency Code" => to_curr,
             "5. Exchange Rate" => exchange_rate,
             "6. Last Refreshed" => last_refreshed
           }
         },
         current_state
       ) do
    Map.merge(current_state, %{
      from_curr: from_curr,
      to_curr: to_curr,
      exchange_rate: String.to_float(exchange_rate),
      last_updated: last_refreshed
    })
  end

  def http_fetch_exchange_rate({from_curr, to_curr}) do
    # ?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=JPY&apikey=demo

    query_params = %{
      "function" => "CURRENCY_EXCHANGE_RATE",
      "apikey" => @api_key,
      "from_currency" => from_curr,
      "to_currency" => to_curr
    }

    http_get(query_params)
  end

  defp http_get(query_params) do
    @currency_url
    |> HTTPoison.get!([], params: query_params)
    |> Map.get(:body)
    |> Jason.decode!()
  end
end
