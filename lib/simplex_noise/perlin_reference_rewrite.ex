# Reference:
# http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf

# A complete implementation of a function returning a value that
# conforms to the new method is given below.
# Translated from Java class definition to Elixir module.
defmodule SimplexNoise.PerlinReferenceRewrite do
  use Bitwise
  use OctaveNoise.Mixin

  # Kernel Summation Radius Squared
  # 0.5 for no discontinuities
  # 0.6 in original code
  @radius_squared 0.6

  # Kernel Contribution Amplitude
  # kernel contribution is raised to this power
  # smooths and reduces contribution
  @amplitude 4

  # Normalization factor
  # used to bring noise into a -1 -> +1 range
  # dependant on kernal radius, amplitude and dimension of noise
  @normalization_factor 8

  # Gradient Pattern Table
  # this table was designed for a 3D noise gradient index
  # 6 bits per entry- 3 set, 3 clear
  @gradient_pattern_table {
    0b010101, 0b111000, 0b110010, 0b101100,
    0b001101, 0b010011, 0b000111, 0b101010
  }

  # Noise Dimensions
  # the reference implementation gradient hashing only works in 3D
  @dimensions 3

  # 3D Skewing and Unskewing Factors
  # 1.0 / 3.0 is the 3D skewing factor
  # 1.0 / 6.0 is the 3D unskewing factor
  @skewing_factor ( :math.sqrt(@dimensions + 1) - 1 ) / @dimensions
  @unskewing_factor ( 1 - ( 1 / :math.sqrt(@dimensions + 1) ) ) / @dimensions

  # Other Constants
  @zero_bit_index 2
  @sign_bit_index 3

  # Noise Function Aliases
  def noise(x, y, z), do: noise [x, y, z]
  def noise(input_point) when is_tuple(input_point), do: input_point |> Tuple.to_list |> noise

  def noise(input_point) when is_list(input_point) do
    input_point # for input point
    |> vertex_list # get vertices for the simplex it is in
    |> Enum.map(&vertex_contribution(input_point, &1)) # get contribution from each simplex
    |> Enum.sum # add contributions
    |> Kernel.*(@normalization_factor) # normalize to a range of -1 -> +1
  end

  def vertex_list(input_point) do
    # origin of unit hypercube the input point is in; simplical grid space
    unit_hypercube_origin = input_point
    |> unit_hypercube_origin

    # relative position in unit hypercube; original grid space
    position_in_unit_hypercube = input_point
    |> position_in_unit_hypercube(unit_hypercube_origin)

    # verticies of the simplex; simplical grid space
    position_in_unit_hypercube
    |> component_rank
    |> simplex_vertices(unit_hypercube_origin)
  end

  def unit_hypercube_origin(input_point) do
    input_point # for input point
    |> skew_to_simplical_grid # skew to simplicial grid space
    |> Enum.map(&(&1 |> Float.floor |> trunc)) # discard fractional component
  end

  def position_in_unit_hypercube(input_point, unit_hypercube_origin) do
    input_point # take input point
    |> Enum.zip(unit_hypercube_origin |> unskew_to_original_grid) # and unit hypercube origin in original grid space
    |> Enum.map(fn {input, origin} -> input - origin end) # subtract origin xyz components from input xyz components
  end

  # [0, -1, 0] -> [1, 0, 2]
  def component_rank(input_point) do
    input_point # for input point
    |> Enum.with_index() # get original index
    |> Enum.sort() # sort by value
    |> Enum.with_index # get rank order
    |> Enum.sort_by(&elem(elem(&1,0),1)) # sort by original index
    |> Enum.map(&elem(&1,1)) # discard all but rank; resulting list in orginal order
  end

  # [1, 0, 2]=rank, [0, 0, 0]=origin -> [ [0, 0, 0], [0, 0, 1], [1, 0, 1], [1, 1, 1] ]
  def simplex_vertices(component_rank, simplex_origin) do
    vertex_prototype = component_rank # all verticies are calculated from
    |> Enum.zip(simplex_origin) # the simplex origin and rank of each component
    @dimensions..0 # N+1 vertices in N dimensions
    |> Enum.to_list # for each vertex index in decreasing order
    |> Enum.map(
      fn vertex_index ->
        vertex_prototype # create a new vertex
        |> Enum.map(
          # vertex components increase in component rank order (highest -> lowest)
          fn {component_rank, origin_component_value} ->
            if component_rank < vertex_index do
              origin_component_value
            else
              origin_component_value + 1
            end
          end
        )
      end
    )
  end

  def vertex_contribution(input_point, vertex) do
    # displacement from vertex to input point
    # negative displacement components are valid
    displacement_vector = input_point
    |> displacement_vector( vertex |> unskew_to_original_grid )

    # kernel radius squared - distance squared
    # is this point close enough to the vertex to get any contribution at all?
    contribution = displacement_vector
    |> Enum.reduce(@radius_squared, fn displacement, acc -> acc - displacement*displacement end)

    if 0.0 < contribution do # if this vertex contributes
      contribution = contribution # raise contribution to the power of amplitude
      |> List.duplicate(@amplitude - 1)
      |> Enum.reduce(contribution, &Kernel.*/2)
      extrapolated_gradient = displacement_vector # calculate extrapolated gradient
      |> dot( vertex |> gradient ) # from displacement vector and gradient
      |> Kernel.*(contribution) # scale result by contribution
    else
      0.0 # non-contributing vertex
    end
  end

  def displacement_vector(point_a, point_b) do
    point_a
    |> Enum.zip(point_b)
    |> Enum.map(fn {a, b} -> a - b end) # point a relative to point b
  end

  # this is a 3D spatial hash function optimized to run in silicon, not Elixir
  # it is ingenious if you understand the moving parts
  # as written, this will only work for 3D noise
  def gradient(vertex) do
    gradient_index = vertex # for this vertex
    |> gradient_index # get gradient index

    # extract bits used to generate gradient from index
    # note that this was written so it might be modified to support higher dimensions
    # the bit index arithmetic could be simplified for 3D
    rotate = gradient_index &&& 0x3
    zero_bit = bit(gradient_index, @zero_bit_index)
    sign_bits = @sign_bit_index..(@sign_bit_index + @dimensions - 2)
    |> Enum.map(&bit(gradient_index, &1))
    last_sign_bit = bit(gradient_index, @sign_bit_index + @dimensions - 1)

    # the last gradient bit is different
    # this might make the hash function more random
    last_gradient_bit = sign_bits # last sign bit uses a different calculation
    |> Enum.reduce(0, &(&1 ^^^ &2)) # XOR all but last sign bit
    |> (&(&1 != last_sign_bit)).() # result is != to last sign bit

    # as written, the first two sign bits are the same and this works well in 3D
    # given more bits in the gradient index, this pattern can be generalized for higher dimensions
    # using the same mechanism for N-1 dimensions may or may not be random enough
    sign_bits
    |> Enum.map(&(&1 == last_sign_bit)) # true if sign bit == last sign bit
    |> Kernel.++([last_gradient_bit]) # add last gradient bit to list
    |> Enum.map(&(if &1 do -1.0 else 1.0 end)) # map true -> -1, false -> 1
    |> (
      fn gradient ->
        # the procedure of rotating and potentially zeroing a component is ingenious
        # rotate can take 4 values, 0..3
        # zero_bit can take 2 values, 0..1
        case {rotate, zero_bit} do
          # if rotate is 0, no components are zeroed
          {0, _} -> gradient # if rotate is 1..3, a fixed gradient position is zeroed
          {_, 0} -> gradient |> List.replace_at(-1, 0) # the last one if zero_bit is 0
          _ -> gradient |> List.replace_at(-2, 0) # and the middle one if zero_bit is 1
        end
      end
    ).()
    # this is where things get very interesting
    # for rotate in 1..3, the zeros originally in fixed positions # can now be rotated into any xyz position
    # in addition, if rotate is 0 all components are non-zero regardless of the zero bit
    # doubling up on a gradient like this is not a problems because the sign bits add sufficient variation
    # there is a 6:2 ratio of (single 0 component cube edge midpoint):(no 0 component cube vertex) gradients
    # having 6 kinds of midpoint gradients may be significant; 6 = 3! = dimensions!
    # NOTE: the reference paper says the gradient should not be rotated for a rotation value of 0
    # this does not appear to be consistent with the original Java implementation
    # this may indicate a bug in the original, where rotation is off by one
    # if this is a bug, it has been intentionally reproduced
    |> Enum.split(1 - rotate) # rotate gradient components
    |> (fn {a, b} -> b ++ a end).() # done rotating; return gradient
  end

  def gradient_index(list) do
    0..7
    |> Enum.map(
      fn bit ->
        list
        |> Enum.split(bit |> rem(@dimensions)) # rotate by bit
        |> (fn {a,b} -> b ++ a end).() # done rotating
        |> gradient_pattern(bit) # get gradient pattern at bit
      end
    )
    |> Enum.sum # sum bits
  end

  # does not scale beyond 3 dimensions
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

