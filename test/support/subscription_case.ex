defmodule MidtermWeb.SubscriptionCase do
  @moduledoc """
  This module defines the test case to be used by
  subscription tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use MidtermWeb.ChannelCase

      use Absinthe.Phoenix.SubscriptionTest,
        schema: Midterm.Schema

      setup do
        {:ok, socket} = Phoenix.ChannelTest.connect(MidtermWeb.UserSocket, %{})
        {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)
        {:ok, socket: socket}
      end
    end
  end
end
