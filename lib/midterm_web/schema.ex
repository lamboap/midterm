defmodule Midterm.Schema do
  use Absinthe.Schema

  import_types MidtermWeb.Types.User
  import_types MidtermWeb.Types.Wallet
  import_types MidtermWeb.Schema.Queries.User
  import_types MidtermWeb.Schema.Mutations.User
  import_types MidtermWeb.Schema.Subscriptions.Exchange

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_mutations
  end

  subscription do
    import_fields :user_subscriptions
  end

  def context(ctx) do
    source = Dataloader.Ecto.new(Midterm.Repo)
    dataloader = Dataloader.add_source(Dataloader.new(), Midterm.Account, source)

    Map.put(ctx, :loader, dataloader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
