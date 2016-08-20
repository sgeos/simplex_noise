#!/usr/bin/env elixir

vector = [2, 3, 4]
matrix = [
  [0, 1, 0],
  [0, 0, 1],
  [1, 0, 0]
]
matrix
|> Enum.map(
  fn row ->
    row
    |> Enum.zip(vector)
    |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
  end
)
|> (&IO.puts("#{inspect vector} -> #{inspect &1}")).()

IO.puts("#{inspect matrix}")
