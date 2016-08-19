# References:
#   https://en.wikipedia.org/wiki/Simplex_noise
#   http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf
#   http://webstaff.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
#   http://webstaff.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java
#   http://www.beosil.com/download/CollisionDetectionHashing_VMV03.pdf

defmodule SimplexNoise.Overview do
  use OctaveNoise.Mixin
  import Bitwise

  # Skewing Factor 1D to 5D with dummy 0D value
  @precomputed_dimensions 5
  @skewing_factor ([1.0] ++
    (1..@precomputed_dimensions |> Enum.map(&SimplexNoise.Skew.skewing_factor_to_simplical_grid/1)))
    |> List.to_tuple
  @unskewing_factor ([1.0] ++
    (1..@precomputed_dimensions |> Enum.map(&SimplexNoise.Skew.skewing_factor_from_simplical_grid/1)))
    |> List.to_tuple
  @radius_squared 0.5

  # Noise Function
  # when is_list(point) would be safer
  def noise(point) when is_tuple(point) do
    point = point |> Tuple.to_list
    noise point, point |> length |> default_hash_function
  end
  def noise(point), do: noise point, point |> length |> default_hash_function
  def noise(point, hash_function) when is_tuple(point), do: noise point |> Tuple.to_list, hash_function
  def noise(point, hash_function) do
    dimensions = length(point)

    point
    |> vertex_list(dimensions)
    |> Enum.map(&vertex_contribution(point, &1, dimensions, hash_function))
    |> Enum.sum

    #point
    #|> gradient_index
    #|> gradient(dimensions)
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

  def vertex_contribution(point, vertex, dimensions, hash_function) do
    displacement_vector = point
    |> displacement_vector( vertex |> unskew_to_original_grid(dimensions) )

    contribution = displacement_vector
    |> Enum.reduce(@radius_squared, fn displacement, acc -> acc - displacement*displacement end)

    if 0.0 < contribution do
      contribution = 8 * contribution * contribution * contribution * contribution
      extrapolated_gradient = displacement_vector |> dot( hash_function.(vertex) )
      contribution * extrapolated_gradient
    else
      0.0
    end
  end

  def default_hash_function(dimensions) do
    fn (point) ->
      {gradient, hash_value} = point
      |> Enum.with_index
      |> Enum.map_reduce(0x156E9,
        fn {value, shift}, acc ->
          hash_value = (trunc(value) * (shift + 1)) >>> shift ^^^ acc
          if 0x0 == (hash_value &&& 0x1) do
            {1, hash_value}
          else
            {-1, hash_value} 
          end
        end
      )
      gradient
      |> List.replace_at(rem(hash_value, dimensions), 0)
    end
  end

  def dot(point_a, point_b) do
    point_a
    |> Enum.zip(point_b)
    |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
  end

  def unit_hypercube_origin(point, dimensions) do
    point
    |> skew_to_simplical_grid(dimensions)
    |> Enum.map(&(&1 |> Float.floor |> trunc))
  end

  def displacement_vector(point_a, point_b) do
    point_a
    |> Enum.zip(point_b)
    |> Enum.map(fn {a, b} -> a - b end)
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

