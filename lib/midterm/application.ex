defmodule Midterm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @valid_currencies Application.get_env(:midterm, :currencies)

  def start(_type, _args) do
    # List all child processes to be supervised
    children =
      [
        # Start the Ecto repository
        # Start the endpoint when the application starts
        {Midterm.Repo, []},
        MidtermWeb.Endpoint,
        {Absinthe.Subscription, [MidtermWeb.Endpoint]},
        Midterm.Currency.Account,
        {Task.Supervisor, name: Currency.TaskSupervisor}
        # {Midterm.Currency.CurrencyGenserver, %{curr_pair: {"USD", "JPY"}}}

        # Starts a worker by calling: Midterm.Worker.start_link(arg)
        # {Midterm.Worker, arg},
      ] ++ get_currency_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Midterm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MidtermWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp get_currency_children do
    # change to get currency from configuration file
    @valid_currencies
    |> Midterm.Currency.Combination.create_currency_pairs(2)
    |> Enum.map(fn pair -> List.to_tuple(pair) end)
    |> Enum.map(fn {from_curr, to_curr} ->
      Supervisor.child_spec(
        {Midterm.Currency.CurrencyServer,
         %{curr_pair: {from_curr, to_curr}, interval: Application.get_env(:midterm, :interval)}},
        id: Midterm.Currency.Combination.create_name({from_curr, to_curr})
      )
    end)
  end
end
