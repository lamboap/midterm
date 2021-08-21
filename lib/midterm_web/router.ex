defmodule MidtermWeb.Router do
  use MidtermWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: Midterm.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: Midterm.Schema,
      interface: :playground,
      socket: MidtermWeb.UserSocket
  end
end
