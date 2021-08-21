# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :midterm, Midterm.Repo,
  database: "midterm_repo",
  username: "postgres",
  hostname: "localhost"

config :midterm,
  ecto_repos: [Midterm.Repo],
  currencies: ["EUR", "CAD", "USD", "JPY", "CNY", "GBP"],
  interval: 60_000,
  # currency_url: "https://www.alphavantage.co/query",
  currency_url: "http://localhost:4001/query",
  api_key: "E6YA3EYPJHMS99R6"

config :ecto_shorts,
  repo: Midterm.Repo,
  error_module: EctoShorts.Actions.Error

if Mix.env() === :test do
  config :midterm, source_module: Midterm.Currency.CurrencyServerImplMock
else
  config :midterm, source_module: Midterm.Currency.CurrencyServerImpl
end

# Configures the endpoint
config :midterm, MidtermWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "oQ/Ty5aGpRurs2LY9ScDdcHztHA6QVB+O5wyBzBFdrM54fDID0rZUPZadd7Ob5sT",
  render_errors: [view: MidtermWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Midterm.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
