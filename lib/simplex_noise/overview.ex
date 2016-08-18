# References:
#   https://en.wikipedia.org/wiki/Simplex_noise
#   http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf
#   http://webstaff.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
#   http://webstaff.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java
#   http://www.beosil.com/download/CollisionDetectionHashing_VMV03.pdf

defmodule SimplexNoise.Overview do

  # Skewing Factor 1D to 5D with dummy 0D value
  @precomputed_dimensions 5
  @skewing_factor ([1.0] ++
    (1..@precomputed_dimensions |> Enum.map(&SimplexNoise.Skew.skewing_factor_to_simplical_grid/1)))
    |> List.to_tuple
  @unskewing_factor ([1.0] ++
    (1..@precomputed_dimensions |> Enum.map(&SimplexNoise.Skew.skewing_factor_from_simplical_grid/1)))
    |> List.to_tuple

  # Aliases
  def noise(x, y, z, w), do: noise [x, y, z, w]
  def noise(x, y, z), do: noise [x, y, z]
  def noise(x, y), do: noise [x, y]
  def noise(x) when is_number(x), do: noise [x]
  def noise(point) when is_tuple(point), do: point |> Tuple.to_list

  # Noise Function
  def noise(point) when is_list(point) do
    point
    #|> vertex_list
    #|> Enum.map(vertex_contribution)
    |> Enum.sum

    #|> gradient_select
    #|> kernel_summation


    #dimensions = length(point)
    #point
    #|> gradient_index
    #|> gradient(dimensions)

    #point
    #|> skew_to_simplical_grid(dimensions)
    #|> simplical_subdivide
  end

  def vertex_list(point, dimensions) do
    # origin of unit hypercube in simplical grid space
    unit_hypercube_origin = point
    |> unit_hypercube_origin(dimensions)

    # position in unit hypercube in original grid space
    position_in_unit_hypercube = point
    |> position_in_unit_hypercube(unit_hypercube_origin, dimensions)

    # simplex vertices in simplical grid space
    position_in_unit_hypercube
    |> component_rank
    |> simplex_vertices(unit_hypercube_origin, dimensions)
  end

  def unit_hypercube_origin(point, dimensions) do
    point
    |> skew_to_simplical_grid(dimensions)
    |> Enum.map(&(&1 |> Float.floor |> trunc))
  end

  def position_in_unit_hypercube(point, cell_origin, dimensions) do
    cell_origin
    |> unskew_to_original_grid(dimensions)
    |> Enum.zip(point)
    |> Enum.map(&(elem(&1, 1) - elem(&1, 0))) # original_x - origin_x
  end

  # [0, -1, 1, 0, 0] ->
  #   [1, 0, 4, 2, 3]
  def component_rank(point) do
    point
    |> Enum.with_index() # add index
    |> Enum.sort() # sort by value
    |> Enum.with_index # add rank
    |> Enum.sort_by(&elem(elem(&1,0),1)) # sort by original index
    |> Enum.map(&elem(&1,1)) # discard all but rank in orginal order
  end

  # [1, 0, 4, 2, 3]=rank, [0, 0, 0, 0, 0]=origin ->
  #   [0, 0, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 1, 0, 1],
  #   [0, 0, 1, 1, 1], [1, 0, 1, 1, 1], [1, 1, 1, 1, 1]
  def simplex_vertices(component_rank, simplex_origin, dimensions) do
    vertex_blueprint = component_rank
    |> Enum.zip(simplex_origin)
    dimensions..0 # N+1 vertices in N dimensions
    |> Enum.to_list
    |> Enum.map(
      fn vertex_index ->
        vertex_blueprint
        |> Enum.map(
          fn {component_rank, component_base_value} ->
            if component_rank < vertex_index do
              component_base_value
            else
              component_base_value + 1
            end
          end
        )
      end
    )
  end

  # use precomputed skewing factor for commonly used dimensions
  # is_list(point) guard would be safer
  def skew_to_simplical_grid(point, dimensions) when dimensions <= @precomputed_dimensions do
    skewing_factor = @skewing_factor |> elem(dimensions)
    point |> SimplexNoise.Skew.skew(skewing_factor)
  end

  # calculate skewing factor for not commonly used dimensions
  # is_list(point) guard would be safer
  def skew_to_simplical_grid(point, dimensions) do
    skewing_factor = dimensions |> SimplexNoise.Skew.skewing_factor_to_simplical_grid
    point |> SimplexNoise.Skew.skew(skewing_factor)
  end

  # use precomputed unskewing factor for commonly used dimensions
  # uses Wikipedia style single additive skewing function
  # is_list(point) guard would be safer
  def unskew_to_original_grid(point, dimensions) when dimensions <= @precomputed_dimensions do
    unskewing_factor = @unskewing_factor |> elem(dimensions)
    point |> SimplexNoise.Skew.skew(unskewing_factor)
  end

  # calculate unskewing factor for not commonly used dimensions
  # uses Wikipedia style single additive skewing function
  # is_list(point) guard would be safer
  def unskew_to_original_grid(point, dimensions) do
    unskewing_factor = dimensions |> SimplexNoise.Skew.skewing_factor_from_simplical_grid
    point |> SimplexNoise.Skew.skew(unskewing_factor)
  end
end

