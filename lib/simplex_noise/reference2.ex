# Reference:
# http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf

# A complete implementation of a function returning a value that
# conforms to the new method is given below.
# Translated from Java class definition to Elixir module.
defmodule SimplexNoiseReference2 do
  use Bitwise
  use OctaveNoise.Mixin

  # kernel summation radius squared
  # 0.5 for no discontinuities
  # 0.6 in original code
  @r2 0.5

  # bit pattern table
  @t { 0x15, 0x38, 0x32, 0x2c, 0x0d, 0x13, 0x07, 0x2a }

  # Noise Function Alias
  def noise(x, y, z), do: noise [x, y, z]
  def noise(input_point) when is_tuple(input_point), do: input_point |> Tuple.to_list |> noise

  # 1.0 / 3.0 is the 3D skew factor
  # 1.0 / 6.0 is the 3D unskew factor

  def noise(input_point) when is_list(input_point) do
    # vertex with lowest coordinates of surrounding unit cube
    # simplicial grid
    skewing_factor = input_point |> skew
    simplex_vertex_zero = input_point
    |> Enum.map(&((&1 + skewing_factor) |> Float.floor |> trunc))

    # relative position of point inside surround unit cube
    # original coordinate system
    unskewing_factor = simplex_vertex_zero |> unskew
    unit_cube_position = input_point
    |> combine(simplex_vertex_zero, &(&1 - &2 + unskewing_factor))

    # find simplex containing point
    # by ranking the component magnitudes
    # of the position in the surrounding unit cube
    hi = hi(unit_cube_position) # highest magnitude component
    lo = lo(unit_cube_position) # lowest magnitude component

    # add contribution of each vertex in order
    [hi, 3-hi-lo, lo, 0]
    |> Enum.reduce({0.0, List.duplicate(0,length(input_point))},
      fn index, {total, a} ->
        {result, a} = vertex_contribution(simplex_vertex_zero, unit_cube_position, a, index)
        {total+result, a}
      end)
    |> elem(0)
  end

  def vertex_contribution(simplex_vertex_zero, unit_cube_position, vertex, index) do
    s = vertex |> unskew

    input_point = unit_cube_position
    |> combine(vertex, &(&1 - &2 + s))

    t = input_point
    |> Enum.reduce(@r2, &(&2-&1*&1))

    result = if t < 0 do
      0
    else
      gradient_index = simplex_vertex_zero
      |> combine(vertex, &:erlang.+/2)
      |> gradient_hash

      # probably does not scale beyond 3 dimensions
      # b2 - b5 are one bit quantities, b1 is a two bit quantity
      [b1, b2, b3, b4, b5] = 1..5
      |> Enum.map(&(if 1<&1 do b(gradient_index,&1) else gradient_index &&& 0x3 end))

      # probably does not scale beyond 3 dimensions
      gradient_orthant = [b3==b5, b4==b5, (b4^^^b3)!=b5]
      |> Enum.map(&(if &1 do -1.0 else 1.0 end))

      gradient_magnitude_mask = case {b1, b2} do
        {0, _} -> [1.0, 1.0, 1.0]
        {_, 0} -> [1.0, 1.0, 0.0]
        _ -> [1.0, 0.0, 1.0] # b2==1
      end

      gradient = input_point
      # rotate, in 3 dimensions
      # b1==0 -> {z, x, y}
      # b1==1 -> {x, y, z}
      # b1==2 -> {y, z, x}
      |> Enum.split(b1-1)
      |> Tuple.to_list
      |> Enum.reduce([], &(&1++&2))
      # apply orthant and magnitude mask
      |> combine(gradient_orthant, &:erlang.*/2)
      |> combine(gradient_magnitude_mask, &:erlang.*/2)

      8*t*t*t*t * Enum.sum(gradient)
    end

    # next vertex
    vertex = vertex
    |> List.to_tuple
    vertex = vertex
    |> put_elem(index, elem(vertex,index) + 1)
    |> Tuple.to_list
    {result, vertex}
  end

  def combine(la, lb, f), do: combine(la, lb, f, [])
  def combine(_la, [], _f, acc), do: Enum.reverse acc
  def combine([], _lb, _f, acc), do: Enum.reverse acc
  def combine([a|la], [b|lb], f, acc), do: combine(la, lb, f, [f.(a,b)|acc])

  def hi([u, v, w]) when w <= u and v <= u, do: 0
  def hi([u, v, w]) when u < w and v < w, do: 2
  def hi(_unit_cube_position), do: 1

  # not the same as hi([w,v,u])
  def lo([u, v, w]) when u < w and u < v, do: 0
  def lo([u, v, w]) when w <= u and w <= v, do: 2
  def lo(_unit_cube_position), do: 1

  def skew(point) do
    dimensions = length(point)
    skewing_factor = (:math.sqrt(dimensions+1)-1)/dimensions

    point
    |> Enum.sum
    |> Kernel.*(skewing_factor)
  end

  def unskew(point) do
    dimensions = length(point)
    unskewing_factor = (1-(1/:math.sqrt(dimensions+1)))/dimensions

    point
    |> Enum.sum
    |> Kernel.*(unskewing_factor)
  end

  def gradient_hash(l) when is_list(l) do
    0..7
    |> Enum.reduce(0, fn bit, acc -> acc + b(l, bit) end)
  end

  # probably does not scale beyond 3 dimensions
  def b(l, b_in) when is_list(l) do
    max = length(l) - 1
    index = l
    |> Enum.zip(max..0)
    |> Enum.reduce(0, fn {value, shift}, acc -> (b(value, b_in) <<< shift) + acc end)
    @t
    |> elem(index)
  end

  def b(n_in, b_in), do: n_in >>> b_in &&& 0x1
end

