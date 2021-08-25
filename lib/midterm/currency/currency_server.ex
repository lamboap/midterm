defmodule Midterm.Currency.CurrencyServer do
  use GenServer

  ###############
  # Public API  #
  ###############

  def start_link(args, opts \\ []) do
    pair = Map.get(args, :curr_pair)
    opts = Keyword.put_new(opts, :name, create_name(pair))
    GenServer.start_link(__MODULE__, args, opts)
  end

  # retrieve exchange rate for currency pair
  def get_exchange_rate(currency_pair) do
    GenServer.call(create_name(currency_pair), :exchange_rate)
  end

  # peek into state
  def get_state(currency_pair) do
    GenServer.call(create_name(currency_pair), :get_state)
  end

  # clear cache
  def override_scheduler(currency_pair) do
    GenServer.call(create_name(currency_pair), :override_scheduler)
  end

  # clear cache and override rate
  def override_scheduler(currency_pair, exchange_rate) do
    GenServer.call(create_name(currency_pair), {:override_scheduler, exchange_rate})
  end

  ###############
  #  Callbacks  #
  ###############

  def init(state) do
    # call task
    task = update_exchange_rate!(state)

    {:ok, %{state | ref: task.ref}}
  end

  def handle_call(:exchange_rate, _from, state) do
    {:reply, state[:exchange_rate], state}
  end

  def handle_call(:override_scheduler, _from, state) do
    {:reply, :ok, source_module().update_exchange_rate!(state)}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:override_scheduler, exchange_rate}, _from, state) do
    man_state = Map.merge(state, %{man_exchange_rate: exchange_rate})
    {:reply, :ok, source_module().update_exchange_rate!(man_state)}
  end

  def handle_info(:currency_fetch, %{ref: ref} = state) when is_reference(ref) do
    {:noreply, state}
  end

  def handle_info(:currency_fetch, %{ref: nil} = state) do
    task = update_exchange_rate!(state)
    {:noreply, %{state | ref: task.ref}}
  end

  # https://hexdocs.pm/elixir/1.12/Task.Supervisor.html
  def handle_info({ref, updated_state}, %{ref: ref} = _state) do
    # No need to continue to monitor
    Process.demonitor(ref, [:flush])
    # reschedule
    schedule_exchange_fetch!(updated_state)

    {:noreply, %{updated_state | ref: nil}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{ref: ref} = state) do
    # restart the task...
    schedule_exchange_fetch!(state)
    # reset
    {:noreply, %{state | ref: nil}}
  end

  defp update_exchange_rate!(state) do
    Task.Supervisor.async_nolink(Currency.TaskSupervisor, fn ->
      source_module().update_exchange_rate!(state)
    end)
  end

  # helper functions
  defp schedule_exchange_fetch!(state) do
    # remove any previous runs
    if state[:timer] do
      :timer.cancel(state.timer)
    end

    # schedule
    timer = :timer.send_interval(state[:interval], self(), :currency_fetch)
    Map.merge(state, %{timer: timer})
  end

  defp create_name(currency_pair) do
    currency_pair
    |> Tuple.to_list()
    |> Enum.join("_")
    |> String.to_atom()
  end

  defp source_module do
    Application.get_env(:midterm, :source_module)
  end
end
