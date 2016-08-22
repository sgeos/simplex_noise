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
  @r2 0.6

  # kernel contribution amplitude
  # 4 in reference implementation
  @a 4

  # normalization factor
  # used to clamp output to -1 -> +1 range
  @n 8

  # bit pattern table
  @t { 0x15, 0x38, 0x32, 0x2c, 0x0d, 0x13, 0x07, 0x2a }

  # Noise Function Alias
  def noise(x, y, z), do: noise [x, y, z]
  def noise({x, y, z}), do: noise [x, y, z]

  def noise([x, y, z]) do
    # (1 / 3) is the 3D skewing factor
    # s is the skewing offset
    s = (x + y + z) / 3

    # [i, j, k] is the unit hypercube origin; simplicial grid space
    i = Float.floor(x + s) |> trunc
    j = Float.floor(y + s) |> trunc
    k = Float.floor(z + s) |> trunc

    # (1 / 6) is the 3D unskewing factor
    # s is now the unskewing offset
    s = (i + j + k) / 6

    # [u, v, w] is the position in the unit hypercube; original grid space
    u = x - i + s
    v = y - j + s
    w = z - k + s

    # vertex component offset from unit hypercube origin; simplicial space
    a = {0, 0, 0}

    # rank order components of relative position for simplicial subdivision
    hi = hi([u, v, w])
    lo = lo([u, v, w])

    # kernel contributions for each vertex
    # process vertices in order from offset [0, 0, 0] -> [1, 1, 1]
    {k0, a} = k(hi, a, [i, j, k], [u, v, w])
    {k1, a} = k(3-hi-lo, a, [i, j, k], [u, v, w])
    {k2, a} = k(lo, a, [i, j, k], [u, v, w])
    {k3, _a} = k(0, a, [i, j, k], [u, v, w])

    # return sum of kernel contributions
    k0 + k1 + k2 + k3
  end

  # kernel contribution
  def k(vertex_index, {a0, a1, a2} = a, [i, j, k], [u, v, w]) do
    # (1 / 6) is the 3D unskewing factor
    # s is the unskewing offset
    s = (a0 + a1 + a2) / 6

    # [x, y, z] is the displacement vector from the given vertex; original grid space
    x = u - a0 + s
    y = v - a1 + s
    z = w - a2 + s

    # t is kernel contribution factor
    t = @r2 - x*x - y*y - z*z

    # h is the gradient index
    h = shuffle([i + a0, j + a1, k + a2])

    # next vertex to process
    a = a |> put_elem(vertex_index, elem(a, vertex_index) + 1)

    if t < 0 do
      # too far, no contribution
      {0, a}
    else
      # b5, b4 and b3 are sign bits
      b5 = h >>> 5 &&& 0x1
      b4 = h >>> 4 &&& 0x1
      b3 = h >>> 3 &&& 0x1

      # b2 is a zero bit
      b2 = h >>> 2 &&& 0x1

      # b is a two bit rotation index
      b = h &&& 0x3

      # pqr is the extrapolated gradient = displacement vector dot gradient
      # at this point it contains the displacement vector rotated by the rotation index b
      p = case b do 1->x; 2->y; _->z end
      q = case b do 1->y; 2->z; _->x end
      r = case b do 1->z; 2->x; _->y end

      # apply sign bits to extrapolated gradient
      p = if b5 == b3 do -p else p end
      q = if b5 == b4 do -q else q end
      r = if b5 != (b4 ^^^ b3) do -r else r end

      # apply amplitude to kernel contribution
      t = :math.pow(t, @a)

      # potentially zero q or r and return contribution
      { @n * t * (p + case {b, b2} do {0, _} -> q + r; {_, 0} -> q; _ -> r end), a }
    end
  end

  def gradient(vertex) do
    h = shuffle(vertex)

    # b5, b4 and b3 are sign bits
    b5 = h >>> 5 &&& 0x1
    b4 = h >>> 4 &&& 0x1
    b3 = h >>> 3 &&& 0x1

    # b2 is a zero bit
    b2 = h >>> 2 &&& 0x1

    # b is a two bit rotation index
    b = h &&& 0x3

    # pqr is the gradient
    # apply sign bits
    p = if b5 == b3 do -1.0 else 1.0 end
    q = if b5 == b4 do -1.0 else 1.0 end
    r = if b5 != (b4 ^^^ b3) do -1.0 else 1.0 end

    # potentially zero q or r
    {q, r} = case {b, b2} do
      {0, _} -> {q, r}
      {_, 0} -> {q, 0}
      _ -> {0, r}
    end

    # rotate gradient components by the rotation index b
    case b do
      1-> [p, q, r]
      2-> [r, p, q]
      _-> [q, r, p]
    end
  end

  def hi([u, v, w]) when w <= u and v <= u, do: 0
  def hi([u, v, w]) when u < w and v < w, do: 2
  def hi(_uvw), do: 1

  # not the same as hi([w,v,u]) when u==v or v==w
  def lo([u, v, w]) when u < w and u < v, do: 0
  def lo([u, v, w]) when w <= u and w <= v, do: 2
  def lo(_uvw), do: 1

  def shuffle([i, j, k]) do
    b([i, j, k], 0) + b([j, k, i], 1) + b([k, i, j], 2) + b([i, j, k], 3) +
      b([j, k, i], 4) + b([k, i, j], 5) + b([i, j, k], 6) + b([j, k, i], 7)
  end

  def b([i, j, k], b) do
    @t |> elem( (b(i, b) <<< 2) + (b(j, b) <<< 1) + b(k, b) )
  end

  def b(n, b), do: n >>> b &&& 0x1
end

