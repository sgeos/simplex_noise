# Reference:
# http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf

# A complete implementation of a function returning a value that
# conforms to the new method is given below.
# Translated from Java class definition to Elixir module.
defmodule SimplexNoise.PerlinReferenceRewrite do
  use Bitwise
  use OctaveNoise.Mixin

  # kernel summation radius squared
  # 0.5 for no discontinuities
  # 0.6 in original code
  @radius_squared 0.6

  # gradient pattern table
  # 6 bits per entry- 3 set, 3 clear
  @gradient_pattern_table {
    0b010101, 0b111000, 0b110010, 0b101100,
    0b001101, 0b010011, 0b000111, 0b101010
  }

  # constants
  @zero_bit_index 2
  @sign_bit_index 3
  @dimensions 3 # Only works with 3D noise
  # 1.0 / 3.0 is the 3D skewing factor
  @skewing_factor ( :math.sqrt(@dimensions + 1) - 1 ) / @dimensions
  # 1.0 / 6.0 is the 3D unskewing factor
  @unskewing_factor ( 1 - ( 1 / :math.sqrt(@dimensions + 1) ) ) / @dimensions
  @normalization_factor 8

  # Noise Function Alias
  def noise(x, y, z), do: noise [x, y, z]
  def noise(input_point) when is_tuple(input_point), do: input_point |> Tuple.to_list |> noise

  def noise(input_point) when is_list(input_point) do
    input_point
    |> vertex_list
    |> Enum.map(&vertex_contribution(input_point, &1))
    |> Enum.sum
    |> Kernel.*(@normalization_factor)
  end

  def vertex_list(input_point) do
    # origin of unit hypercube; simplical grid space
    unit_hypercube_origin = input_point
    |> unit_hypercube_origin

    # position in unit hypercube; original grid space
    position_in_unit_hypercube = input_point
    |> position_in_unit_hypercube(unit_hypercube_origin)

    # simplex vertices in simplical grid space
    position_in_unit_hypercube
    |> component_rank
    |> simplex_vertices(unit_hypercube_origin)
  end

  def unit_hypercube_origin(input_point) do
    input_point
    |> skew_to_simplical_grid
    |> Enum.map(&(&1 |> Float.floor |> trunc))
  end

  def position_in_unit_hypercube(input_point, unit_hypercube_origin) do
    unit_hypercube_origin
    |> unskew_to_original_grid
    |> Enum.zip(input_point)
    |> Enum.map(&(elem(&1, 1) - elem(&1, 0))) # input_x - origin_x
  end

  # [0, -1, 0] -> [1, 0, 2]
  def component_rank(input_point) do
    input_point
    |> Enum.with_index() # add index
    |> Enum.sort() # sort by value
    |> Enum.with_index # add rank
    |> Enum.sort_by(&elem(elem(&1,0),1)) # sort by original index
    |> Enum.map(&elem(&1,1)) # discard all but rank in orginal order
  end

  # [1, 0, 2]=rank, [0, 0, 0]=origin -> [ [0, 0, 0], [0, 0, 1], [1, 0, 1], [1, 1, 1] ]
  def simplex_vertices(component_rank, simplex_origin) do
    vertex_blueprint = component_rank
    |> Enum.zip(simplex_origin)
    @dimensions..0 # N+1 vertices in N dimensions
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

  def vertex_contribution(input_point, vertex) do
    displacement_vector = input_point
    |> displacement_vector( vertex |> unskew_to_original_grid )

    contribution = displacement_vector
    |> Enum.reduce(@radius_squared, fn displacement, acc -> acc - displacement*displacement end)

    if 0.0 < contribution do
      contribution = contribution * contribution * contribution * contribution
      extrapolated_gradient = displacement_vector
      |> dot( vertex |> gradient )
      contribution * extrapolated_gradient
    else
      0
    end
  end

  def displacement_vector(point_a, point_b) do
    point_a
    |> Enum.zip(point_b)
    |> Enum.map(fn {a, b} -> a - b end)
  end

  def gradient(vertex) do
    gradient_index = vertex
    |> gradient_index

    rotate = gradient_index &&& 0x3
    zero_bit = bit(gradient_index, @zero_bit_index)
    sign_bits = @sign_bit_index..(@sign_bit_index + @dimensions - 2)
    |> Enum.map(&bit(gradient_index, &1))
    last_sign_bit = bit(gradient_index, @sign_bit_index + @dimensions - 1)

    last_gradient_bit = sign_bits # last sign bit uses a different calculation
    |> Enum.reduce(0, &(&1 ^^^ &2)) # XOR all but last sign bit
    |> (&(&1 != last_sign_bit)).() # result is != to last sign bit

    sign_bits
    |> Enum.map(&(&1 == last_sign_bit)) # true if sign bit == last sign bit
    |> Kernel.++([last_gradient_bit]) # add last gradient bit to list
    |> Enum.map(&(if &1 do -1.0 else 1.0 end)) # map true -> -1, false -> 1
    |> Enum.split(1 - rotate) # rotate gradient components
    |> (fn {a, b} -> b ++ a end).() # done rotating
    |> ( # zero a component
      fn gradient ->
        case {rotate, zero_bit} do
          {0, _} -> gradient # do not zero displacement vector contribution
          {_, 0} -> gradient |> List.replace_at(rotate-2, 0) # zero displacement vector contribution
          _ -> gradient |> List.replace_at(rotate-3, 0) # zero displacement vector contribution
        end
      end
    ).() # return gradient
  end

  def gradient_index(list) do
    0..7
    |> Enum.reduce(0, fn bit_index, acc -> acc + gradient_pattern(list, bit_index) end)
  end

  # probably does not scale beyond 3 dimensions
  def gradient_pattern(list, bit_index) do
    gradient_pattern_index = list
    |> Enum.split(@dimensions) |> elem(0) # only works for 3D noise
    |> Enum.reverse |> Enum.with_index # append descending index
    |> Enum.reduce(0, fn {value, shift}, acc -> (bit(value, bit_index) <<< shift) + acc end)
    @gradient_pattern_table
    |> elem(gradient_pattern_index)
  end

  def bit(value, bit_index) do
    value >>> bit_index &&& 0x1
  end

  def dot(point_a, point_b) do
    point_a
    |> Enum.zip(point_b)
    |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
  end

  def skew_to_simplical_grid(input_point) do
    skewing_constant = input_point
    |> Enum.sum
    |> Kernel.*(@skewing_factor)
    input_point
    |> Enum.map(&(&1 + skewing_constant))
  end

  def unskew_to_original_grid(input_point) do
    unskewing_constant = input_point
    |> Enum.sum
    |> Kernel.*(@unskewing_factor)
    input_point
    |> Enum.map(&(&1 - unskewing_constant))
  end
end

