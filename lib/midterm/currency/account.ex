defmodule Midterm.Currency.Account do
  use Agent

  @default_name __MODULE__

  def start_link(opts \\ []) do
    # IO.puts("start agent")
    initial_state = Keyword.get(opts, :state, fn -> %{} end)
    name = Keyword.get(opts, :name, @default_name)

    Agent.start_link(initial_state, name: name)
  end

  def get_total_balance(name \\ @default_name, account_name) do
    # IO.puts("get agent / get action")

    balance =
      Agent.get(name, fn state ->
        Map.get(state, account_name)
      end)

    %{balance: balance}
  end

  def set_balance(name \\ @default_name, account_name, total) do
    # IO.puts("add action")

    Agent.update(name, fn state ->
      Map.put(state, account_name, total)
    end)
  end

  def get_and_set_balance(name \\ @default_name, account_name, total) do
    # IO.puts("get and update action")
    Agent.get_and_update(name, fn state ->
      {state, Map.put(state, account_name, total)}
    end)
    |> Map.get(account_name)
  end

  def reset(name \\ @default_name) do
    Agent.update(name, fn _state -> %{} end)
  end

  def get_all_accounts(name \\ @default_name) do
    Agent.get(name, fn state ->
      state
    end)
  end
end
