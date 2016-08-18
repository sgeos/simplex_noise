# Procedural Gradient Generator
defmodule Gradient do
  def permute(list), do: permute(list, length(list))
  def permute([], _), do: [[]]
  def permute(_,  0), do: [[]]
  def permute(list, i) do
    for h <- list, t <- permute(list, i-1), do: [h|t]
  end

  def generate_table(dimensions) do
    # Get a permutation of 1 and -1 for one fewer dimensions than we need
    midpoint_template = permute([1, -1], dimensions - 1)

    # Insert 0 into complete permutation for each axis
    # This takes us to the total number of dimensions requested
    0..(dimensions-1)
    |> Enum.to_list
    |> Enum.reduce([],
      fn(axis_index, result) ->
        midpoints = midpoint_template
        # insert 0 at axis_index here
        |> Enum.map(&(&1 |> List.insert_at(axis_index, 0)))
        result ++ midpoints
      end)

    # Ultimately return a look up table of fixed size
    |> Enum.map(&List.to_tuple/1)
    |> List.to_tuple
  end
end

