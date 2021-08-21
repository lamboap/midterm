defmodule Midterm.Currency.CurrencyServerImplMock do
  def update_exchange_rate!(%{man_exchange_rate: exchange_rate} = state) do
    {from_curr, to_curr} = state[:curr_pair]

    updated_state =
      Map.merge(state, %{
        from_curr: from_curr,
        to_curr: to_curr,
        exchange_rate: exchange_rate,
        last_updated: "2021-07-10 16:35:55"
      })
      |> Map.delete(:man_exchange_rate)

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

    updated_state
  end

  def update_exchange_rate!(state) do
    # IO.inspect("clear cache/regular run")
    {from_curr, to_curr} = state[:curr_pair]

    updated_state =
      Map.merge(state, %{
        from_curr: from_curr,
        to_curr: to_curr,
        exchange_rate: gen_exchange_rate(),
        last_updated: "2021-07-10 16:35:55"
      })

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

    updated_state
  end

  # random int convert to float between 1 and 4 (keep the math simple)
  defp gen_exchange_rate do
    :rand.uniform(4) / 1
  end
end
