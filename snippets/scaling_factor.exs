#!/usr/bin/env elixir

r2 = 0.5

IO.puts "Naive Maximum"
min_d=2
max_d=10
min_d..max_d
|> Enum.map(
  fn dimensions ->
    edge_length = List.duplicate(1.0, dimensions) # N-dimensional point L; simplicial grid space
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions) # unskew to original grid
    |> Enum.reduce(0, &(&1*&1+&2)) # edge_length_squared; distance from O to L squared
    distance = edge_length * (dimensions) / (dimensions + 1)
     1/ ( (dimensions + 1) * :math.pow(r2*(distance*distance),4)*distance )
    # &(1/ ( (&1+1) * :math.pow(r2*(8/9),4)*:math.sqrt(r2)/3 ) )
  end
)
|> Enum.with_index
|> Enum.each(&IO.puts("#{min_d+elem(&1,1)}D: #{elem(&1,0)}"))

IO.puts "Vertex Contribution A"
min_d..max_d
|> Enum.map(
  fn dimensions ->
    vertex = List.duplicate(0.0, dimensions)
    point = List.duplicate(1.0, dimensions)
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions)
    |> Enum.map(&(&1/2))
    hash_function = fn _ -> [0.0] ++ List.duplicate(1.0, dimensions - 1) end
    1.0 / (2.0 * SimplexNoise.Overview.vertex_contribution(point, vertex, dimensions, hash_function))
  end
)
|> Enum.with_index
|> Enum.each(&IO.puts("#{min_d+elem(&1,1)}D: #{elem(&1,0)}"))

IO.puts "Vertex Contribution B"
min_d..max_d
|> Enum.map(
  fn dimensions ->
    vertex = List.duplicate(0.0, dimensions)
    point = [0.5] ++ List.duplicate(0.0, dimensions)
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions)
    |> Enum.map(&(&1/2))
    hash_function = fn _ -> [0.0] ++ List.duplicate(1.0, dimensions - 1) end
    1.0 / (2.0 * SimplexNoise.Overview.vertex_contribution(point, vertex, dimensions, hash_function))
  end
)
|> Enum.with_index
|> Enum.each(&IO.puts("#{min_d+elem(&1,1)}D: #{elem(&1,0)}"))


IO.puts "Blog"
min_d..max_d
|> Enum.map(
  fn dimensions ->
    r2 = 0.5
    d2 = List.duplicate(1.0, dimensions)
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions)
    |> Enum.map(&(&1/2))
    |> Enum.reduce(0, &(&1 * &1 + &2))
    d = :math.sqrt(d2)
    1.0 / ( 2.0 * d * :math.pow(r2 - d2, 4) )
  end
)
|> Enum.with_index
|> Enum.each(&IO.puts("#{min_d+elem(&1,1)}D: #{elem(&1,0)}"))

IO.puts "Fancy"
min_d..max_d
|> Enum.map(
  fn dimensions ->
    IO.puts "#{inspect dimensions}D"
    point = [0.5] ++ List.duplicate(0.0, dimensions-1)
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions)
    hash_function = fn vertex ->
      displacement_vector = point
      |> SimplexNoise.Overview.displacement_vector( vertex |> SimplexNoise.Overview.unskew_to_original_grid(dimensions) )
      gradient = displacement_vector
      |> Enum.map(&abs/1)
      |> SimplexNoise.Overview.component_rank
      |> Enum.zip(displacement_vector)
      |> Enum.map(
        fn {rank, component} ->
          cond do
            rank == 0 -> 0
            component < 0 -> -1
            0 <= component -> 1
          end
        end
      )
      IO.puts "dispacement #{inspect displacement_vector} -> gradient #{inspect gradient}"
      gradient
    end
    SimplexNoise.Overview.noise(point, hash_function)
  end
)
|> Enum.map(&(1/&1))
|> Enum.with_index
|> Enum.each(&IO.puts("#{min_d+elem(&1,1)}D: #{8*elem(&1,0)}"))

