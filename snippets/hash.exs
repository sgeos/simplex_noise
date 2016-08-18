#!/usr/bin/env elixir

# Reference:
# http://www.beosil.com/download/CollisionDetectionHashing_VMV03.pdf

defmodule Prime do
  def to(max) when max < 2, do: []
  def to(max) when max < 3, do: [2]
  def to(max) do
    5..max
    |> Enum.take_every(2)
    |> Enum.reduce([2, 3],
      fn v, acc ->
        if is_prime?(v, acc) do
          acc ++ [v]
        else
          acc
        end
      end)
  end

  def is_prime?(v, [h|_t]) when v < h*h, do: true
  def is_prime?(v, [h|_t]) when 0 == rem(v, h), do: false
  def is_prime?(v, [_h|t]), do: is_prime?(v, t)
end

defmodule Hash do
  import Bitwise

  def buckets(dimensions) do
    (:math.pow(2, dimensions - 1) * dimensions)
    |> trunc
  end

  def list(dimensions) do
    dimensions
    |> buckets
    |> Prime.to
    |> Enum.shuffle
    |> Enum.take(dimensions + 1)
  end

  def function(dimensions) when is_number(dimensions) do
    dimensions
    |> trunc
    |> list
    |> function
  end

  def function(hash_list) when is_list(hash_list) do
    acc = hash_list |> List.first
    hash_list = hash_list |> List.delete_at(0)
    dimensions = length(hash_list)
    buckets = buckets(dimensions)
    fn coordinate ->
      coordinate
      |> Enum.zip(hash_list)
      |> Enum.reduce(acc,
        fn {v, m}, acc ->
          (v * m) ^^^ acc
        end)
      |> rem(buckets)
    end
  end
end

dimensions = 4
hash_list = Hash.list(dimensions)
function = Hash.function(hash_list)
IO.puts("Hash List: #{inspect hash_list}")

side_length = 4
max_index = (:math.pow(side_length, dimensions) - 1) |> trunc
0..max_index
|> Enum.map(
  fn index ->
    0..(dimensions - 1)
    |> Enum.map(&(rem(div(index, :math.pow(side_length, &1) |> trunc), side_length)))
  end)
|> Enum.map(&({&1, function.(&1)}))
|> Enum.each(&IO.puts("#{inspect elem(&1, 0)} -> #{inspect elem(&1, 1)}"))

