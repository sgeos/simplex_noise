#!/usr/bin/env elixir

defmodule Factor do
  def skew(n), do: (:math.sqrt(n + 1) - 1) / n
  def unskew(n), do: ((1 / :math.sqrt(n + 1)) - 1) / n
end

IO.puts "2D Skew  = #{inspect Factor.skew(2)}"
IO.puts "2D Unkew = #{inspect Factor.unskew(2)}"
IO.puts "3D Skew  = #{inspect Factor.skew(3)}"
IO.puts "3D Unkew = #{inspect Factor.unskew(3)}"
IO.puts "4D Skew  = #{inspect Factor.skew(4)}"
IO.puts "4D Unkew = #{inspect Factor.unskew(4)}"
