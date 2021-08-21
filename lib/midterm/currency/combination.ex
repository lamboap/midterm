defmodule Midterm.Currency.Combination do
  def create_currency_pairs([], _num_pair), do: [[]]
  def create_currency_pairs(_currency_list, 0), do: [[]]

  def create_currency_pairs(currency_list, num_pair) do
    for head <- currency_list,
        tail <- create_currency_pairs(currency_list, num_pair - 1),
        do: [head | tail]
  end

  def create_name(currency_pair) do
    currency_pair
    |> Tuple.to_list()
    |> Enum.join("_")
    |> String.to_atom()
  end
end
