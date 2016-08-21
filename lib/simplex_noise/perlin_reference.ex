# Reference:
# http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf

# A complete implementation of a function returning a value that
# conforms to the new method is given below.
# Translated from Java class definition to Elixir module.
defmodule SimplexNoise.PerlinReference do
  use Bitwise
  use OctaveNoise.Mixin

  # kernel summation radius squared
  # 0.5 for no discontinuities
  # 0.6 in original code
  @r2 0.5

  # bit pattern table
  @t { 0x15, 0x38, 0x32, 0x2c, 0x0d, 0x13, 0x07, 0x2a }

  # Noise Function Alias
  def noise(x, y, z), do: noise {x, y, z}

  # 1.0 / 3.0 is the 3D skew factor
  # 1.0 / 6.0 is the 3D unskew factor

  def noise(xyz) when is_tuple(xyz) do
    size = tuple_size(xyz)
    max = size - 1

    s = xyz
    |> Tuple.to_list
    |> Enum.reduce(0, &(&1+&2))
    s = s / (size * 1.0)
    ijk = 0..max
    |> Enum.map(&((elem(xyz,&1) + s) |> Float.floor |> trunc))
    |> List.to_tuple

    s = ijk
    |> Tuple.to_list
    |> Enum.reduce(0, &(&1+&2))
    s = s / (size * 2.0)
    uvw = 0..max
    |> Enum.map(&(elem(xyz,&1)-elem(ijk,&1)+s))
    |> List.to_tuple

    hi = hi(uvw)
    lo = lo(uvw)

    {result, _a} = [hi, 3-hi-lo, lo, 0]
    |> Enum.reduce({0.0, Tuple.duplicate(0,size)},
      fn index, {total, a} ->
        {result, a} = k(ijk, uvw, a, index)
        {total+result, a}
      end)
    result
  end

  def k(ijk, uvw, a, index) do
    size = tuple_size(ijk)
    max = size - 1

    s = a
    |> Tuple.to_list
    |> Enum.reduce(0, &(&1+&2))
    s = s / (size * 2.0)
    xyz = 0..max
    |> Enum.map(&(elem(uvw,&1)-elem(a,&1)+s))
    |> List.to_tuple
    {x,y,z} = xyz

    t = xyz
    |> Tuple.to_list
    |> Enum.reduce(@r2, &(&2-&1*&1))

    result = if t < 0 do
      0
    else
      h = 0..max
      |> Enum.map(&(elem(ijk,&1)+elem(a,&1)))
      |> List.to_tuple
      |> shuffle

      [b1, b2, b3, b4, b5] = 1..5
      |> Enum.map(&(if 1<&1 do b(h,&1) else h &&& 0x3 end))
      [p, q, r] = [b3==b5, b4==b5, (b4^^^b3)!=b5]
      |> Enum.map(&(if &1 do -1.0 else 1.0 end))
      {p, q, r} = case b1 do
        1 -> {p*x, q*y, r*z}
        2 -> {p*y, q*z, r*x}
        _ -> {p*z, q*x, r*y} # 0==b1 or 3==b1
      end
      c = case {b1, b2} do
        {0, _} -> q+r
        {_, 0} -> q
        _ -> r # b2==1
      end
      8*t*t*t*t * (p+c)
    end

    a = a |> put_elem(index, elem(a,index) + 1)
    {result, a}
  end

  def gradient(vertex) when is_list(vertex), do: vertex |> List.to_tuple |> gradient
  def gradient(vertex) do
    h = vertex
    |> shuffle

    [b1, b2, b3, b4, b5] = 1..5
    |> Enum.map(&(if 1<&1 do b(h,&1) else h &&& 0x3 end))
    [p, q, r] = [b3==b5, b4==b5, (b4^^^b3)!=b5]
    |> Enum.map(&(if &1 do -1.0 else 1.0 end))
    {p, q, r} = case b1 do
      # put p, q, r in corresponding x, y, z position
      1 -> {p, q, r}
      2 -> {r, p, q}
      _ -> {q, r, p} # 0==b1 or 3==b1
    end
    case {b1, b2} do
      {0, _} -> [p, q, r]
      # zero equivalent of r component; rotate to corresponding x, y, z
      {_, 0} -> [p, q, r] |> List.replace_at(b1 - 2, 0)
      # zero equivalent of q component; rotate to corresponding x, y, z
      _ -> [p, q, r] |> List.replace_at(b1 - 3, 0) # b2==1
    end
  end

  def hi({u, v, w}) when w <= u and v <= u, do: 0
  def hi({u, v, w}) when u < w and v < w, do: 2
  def hi(_uvw), do: 1

  # not the same as hi([w,v,u])
  def lo({u, v, w}) when u < w and u < v, do: 0
  def lo({u, v, w}) when w <= u and w <= v, do: 2
  def lo(_uvw), do: 1

  def shuffle(t) when is_tuple(t) do
    0..7
    |> Enum.reduce(0, fn bit, acc -> acc + b(t, bit) end)
  end

  # probably does not scale beyond 3 dimensions
  def b(t, b_in) when is_tuple(t) do
    max = tuple_size(t) - 1
    index = 0..max
    |> Enum.map(&({t |> elem(&1), max - &1}))
    |> Enum.reduce(0, fn {value, shift}, acc -> (b(value, b_in) <<< shift) + acc end)
    @t
    |> elem(index)
  end

  def b(n_in, b_in), do: n_in >>> b_in &&& 0x1
end

