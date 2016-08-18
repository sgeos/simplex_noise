defmodule RankOrder do
  def permute([], result), do: result
  def permute([h|t], result) do
    permutations = t |> Enum.map(&({h,&1}))
    permute(t, result ++ permutations)
  end
  def permute([h|t]), do: permute([h|t], [])
  def generate_table(dimensions) do
    0..(dimensions-1)
    |> Enum.to_list
    |> permute
    |> List.to_tuple
  end
end

# RankOrder.permute [0,1,2,3]
# [{0, 1}, {0, 2}, {0, 3}, {1, 2}, {1, 3}, {2, 3}]
# RankOrder.generate_table 4
# [{0, 1}, {0, 2}, {0, 3}, {1, 2}, {1, 3}, {2, 3}]
