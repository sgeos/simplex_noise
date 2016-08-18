# A speed-improved simplex noise algorithm for 2D, 3D and 4D
# translated from Java into Elixir.
#
# Based on example code by Stefan Gustavson (stegu@itn.liu.se).
# Optimisations by Peter Eastman (peastman@drizzle.stanford.edu).
# Better rank ordering method for 4D by Stefan Gustavson in 2012.
# Translated into Elixir by Brendan Sechter (bsechter@sennue.com).
#
# The Java version could be speeded up even further, but it's useful
# as it is.  Assessment of Java optimazations for the Elixir version
# has not been perfomed.
#
# Java Version 2012-03-09
#
# This code was placed in the public domain by its original author,
# Stefan Gustavson. You may use it as you see fit, but
# attribution is appreciated.
#
# References:
# http://webstaff.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
# http://webstaff.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java

defmodule Utility do
  # Elixir needs a custom mod function to emulate Java && masking
  # Assume x is always an integer
  def mod(x, y) when 0 < x, do: rem(x, y)
  def mod(x, y) when x < 0, do: y + rem(x, y)
  def mod(0, _y), do: 0
end

# Java version uses Inner class to speed up gradient computations
# (In Java, array access is a lot slower than member access)
defmodule Grad do
  defstruct x: 0.0, y: 0.0, z: 0.0, w: 0.0
end

# Simplex noise in 2D, 3D and 4D
defmodule SimplexNoiseImproved do
  import Utility

  use OctaveNoise.Mixin

  @grad3 {
    %Grad{ x: 1.0, y: 1.0, z: 0.0 }, %Grad{ x: -1.0, y: 1.0, z: 0.0 },
    %Grad{ x: 1.0, y: -1.0, z: 0.0 }, %Grad{ x: -1.0, y: -1.0, z: 0.0 },
    %Grad{ x: 1.0, y: 0.0, z: 1.0 }, %Grad{ x: -1.0, y: 0.0, z: 1.0 },
    %Grad{ x: 1.0, y: 0.0, z: -1.0 }, %Grad{ x: -1.0, y: 0.0, z: -1.0 },
    %Grad{ x: 0.0, y: 1.0, z: 1.0 }, %Grad{ x: 0.0, y: -1.0, z: 1.0 },
    %Grad{ x: 0.0, y: 1.0, z: -1.0 }, %Grad{ x: 0.0, y: -1.0, z: -1.0 }
  }
  @grad4 {
    %Grad{ x: 0.0, y: 1.0, z: 1.0, w: 1.0 }, %Grad{ x: 0.0, y: 1.0, z: 1.0, w: -1.0 },
    %Grad{ x: 0.0, y: 1.0, z: -1.0, w: 1.0 }, %Grad{ x: 0.0, y: 1.0, z: -1.0, w: -1.0 },
    %Grad{ x: 0.0, y: -1.0, z: 1.0, w: 1.0 }, %Grad{ x: 0.0, y: -1.0, z: 1.0, w: -1.0 },
    %Grad{ x: 0.0, y: -1.0, z: -1.0, w: 1.0 }, %Grad{ x: 0.0, y: -1.0, z: -1.0, w: -1.0 },
    %Grad{ x: 1.0, y: 0.0, z: 1.0, w: 1.0 }, %Grad{ x: 1.0, y: 0.0, z: 1.0, w: -1.0 },
    %Grad{ x: 1.0, y: 0.0, z: -1.0, w: 1.0 }, %Grad{ x: 1.0, y: 0.0, z: -1.0, w: -1.0 },
    %Grad{ x: -1.0, y: 0.0, z: 1.0, w: 1.0 }, %Grad{ x: -1.0, y: 0.0, z: 1.0, w: -1.0 },
    %Grad{ x: -1.0, y: 0.0, z: -1.0, w: 1.0 }, %Grad{ x: -1.0, y: 0.0, z: -1.0, w: -1.0 },
    %Grad{ x: 1.0, y: 1.0, z: 0.0, w: 1.0 }, %Grad{ x: 1.0, y: 1.0, z: 0.0, w: -1.0 },
    %Grad{ x: 1.0, y: -1.0, z: 0.0, w: 1.0 }, %Grad{ x: 1.0, y: -1.0, z: 0.0, w: -1.0 },
    %Grad{ x: -1.0, y: 1.0, z: 0.0, w: 1.0 }, %Grad{ x: -1.0, y: 1.0, z: 0.0, w: -1.0 },
    %Grad{ x: -1.0, y: -1.0, z: 0.0, w: 1.0 }, %Grad{ x: -1.0, y: -1.0, z: 0.0, w: -1.0 },
    %Grad{ x: 1.0, y: 1.0, z: 1.0, w: 0.0 }, %Grad{ x: 1.0, y: 1.0, z: -1.0, w: 0.0 },
    %Grad{ x: 1.0, y: -1.0, z: 1.0, w: 0.0 }, %Grad{ x: 1.0, y: -1.0, z: -1.0, w: 0.0 },
    %Grad{ x: -1.0, y: 1.0, z: 1.0, w: 0.0 }, %Grad{ x: -1.0, y: 1.0, z: -1.0, w: 0.0 },
    %Grad{ x: -1.0, y: -1.0, z: 1.0, w: 0.0 }, %Grad{ x: -1.0, y: -1.0, z: -1.0, w: 0.0 }
  }
  @p {
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
    140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
    247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
    57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
    74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
    60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
    65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
    200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
    52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
    207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
    119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
    129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
    218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
    81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
    184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
    222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
  }
  # To remove the need for index wrapping, double the permutation table length
  @perm (@p |> Tuple.to_list) ++ (@p |> Tuple.to_list) |> List.to_tuple
  @perm_mod_12 @perm |> Tuple.to_list |> Enum.map(&(&1 |> mod(12))) |> List.to_tuple

  # Skewing and unskewing factors for 2, 3, and 4 dimensions
  @skewing_factor_f2 0.5 * (:math.sqrt(3.0) - 1.0)
  @unskewing_factor_g2 (3.0 - :math.sqrt(3.0)) / 6.0
  @skewing_factor_f3 1.0 / 3.0
  @unskewing_factor_g3 1.0 / 6.0
  @skewing_factor_f4 (:math.sqrt(5.0) - 1.0) / 4.0
  @unskewing_factor_g4 (5.0 - :math.sqrt(5.0)) / 20.0

  # In Java, this method is a *lot* faster than using (int)Math.floor(x)
  #   int xi = (int)x; return x<xi ? xi-1 : xi;
  # The goal is to floor x and truncate it to an integer
  def fastfloor(x) do
    xi = x |> trunc
    if x < xi, do: xi-1, else: xi
  end

  def dot(%Grad{} = grad, x, y) do
    grad.x*x + grad.y*y
  end

  def dot(%Grad{} = grad, x, y, z) do
    grad.x*x + grad.y*y + grad.z*z
  end

  def dot(%Grad{} = grad, x, y, z, w) do
    grad.x*x + grad.y*y + grad.z*z + grad.w*w
  end

  # split these into functions because Java style array indexing is verbose in Elixir
  # replaced magic number mod(32) with  mod(@grad4 |> tuple_size)
  def gradient_hash_index(x, y) do
    hash_y = @perm |> elem(y)
    @perm_mod_12 |> elem(x + hash_y)
  end

  def gradient_hash_index(x, y, z) do
    hash_z = @perm |> elem(z)
    hash_y = @perm |> elem(y + hash_z)
    @perm_mod_12 |> elem(x + hash_y)
  end

  def gradient_hash_index(x, y, z, w) do
    hash_w = @perm |> elem(w)
    hash_z = @perm |> elem(z + hash_w)
    hash_y = @perm |> elem(y + hash_z)
    hash_x = @perm |> elem(x + hash_y)
    hash_x |> mod(@grad4 |> tuple_size)
  end

  # Noise Function Aliases
  def noise(x, y), do: noise {x, y}
  def noise(x, y, z), do: noise {x, y, z}
  def noise(x, y, z, w), do: noise {x, y, z, w}

  # 2D simplex noise
  def noise({x_in, y_in}) do
    # Noise contributions from the three corners
    # float type
    # n0, n1, n2

    # Skew the input space to determine which simplex cell we're in
    s = (x_in + y_in) * @skewing_factor_f2 # Hairy factor for 2D
    i = fastfloor(x_in + s)
    j = fastfloor(y_in + s)

    t = (i + j) * @unskewing_factor_g2
    unskewed_x0 = i - t # Unskew the cell origin back to (x,y) space
    unskewed_y0 = j - t
    x0 = x_in - unskewed_x0 # The x,y distances from the cell origin
    y0 = y_in - unskewed_y0

    # For the 2D case, the simplex shape is an equilateral triangle.
    # Determine which simplex we are in.
    {i1, j1} = # Offsets for second (middle) corner of simplex in (i,j) coords
      if (y0 < x0) do
        {1, 0} # lower triangle, XY order: (0,0)->(1,0)->(1,1)
      else
        {0, 1} # upper triangle, YX order: (0,0)->(0,1)->(1,1)
      end

    # A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
    # a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
    # c = (3-sqrt(3))/6
    x1 = x0 - i1 + @unskewing_factor_g2 # Offsets for middle corner in (x,y) unskewed coords
    y1 = y0 - j1 + @unskewing_factor_g2
    x2 = x0 - 1.0 + 2.0 * @unskewing_factor_g2 # Offsets for last corner in (x,y) unskewed coords
    y2 = y0 - 1.0 + 2.0 * @unskewing_factor_g2

    # Work out the hashed gradient indices of the three simplex corners
    # replaced magic number mod(256) with  mod(@p |> tuple_size)
    ii = i |> mod(@p |> tuple_size)
    jj = j |> mod(@p |> tuple_size)
    gi0 = gradient_hash_index(ii, jj)
    gi1 = gradient_hash_index(ii+i1, jj+j1)
    gi2 = gradient_hash_index(ii+1, jj+1)

    # Calculate the contribution from the three corners
    t0 = 0.5 - x0*x0 - y0*y0
    n0 =
      if (t0 < 0.0) do
        0.0
      else
        # (x,y) of grad3 used for 2D gradient }
        gradient = @grad3 |> elem(gi0)
        t0*t0*t0*t0 * dot(gradient, x0, y0)
      end

    t1 = 0.5 - x1*x1 - y1*y1
    n1 =
      if (t1 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi1)
        t1*t1*t1*t1 * dot(gradient, x1, y1)
      end

    t2 = 0.5 - x2*x2 - y2*y2
    n2 =
      if (t2 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi2)
        t2*t2*t2*t2 * dot(gradient, x2, y2)
      end

    # Add contributions from each corner to get the final noise value.
    # The result is scaled to return values in the interval [-1,1].
    70.0 * (n0 + n1 + n2)
  end

  # 3D simplex noise
  def noise({x_in, y_in, z_in}) do
    # Noise contributions from the four corners
    # float type
    # n0, n1, n2, n3

    # Skew the input space to determine which simplex cell we're in
    s = (x_in + y_in + z_in) * @skewing_factor_f3 # Very nice and simple skew factor for 3D
    i = fastfloor(x_in + s)
    j = fastfloor(y_in + s)
    k = fastfloor(z_in + s)

    t = (i + j + k) * @unskewing_factor_g3
    unskewed_x0 = i - t # Unskew the cell origin back to (x,y,z) space
    unskewed_y0 = j - t
    unskewed_z0 = k - t
    x0 = x_in - unskewed_x0 # The x,y,z distances from the cell origin
    y0 = y_in - unskewed_y0
    z0 = z_in - unskewed_z0

    # For the 3D case, the simplex shape is a slightly irregular tetrahedron.
    # Determine which simplex we are in.
    {
      i1, j1, k1, # Offsets for second corner of simplex in (i,j,k) coords
      i2, j2, k2 # Offsets for third corner of simplex in (i,j,k) coords
    } =
    cond do
      z0 <= y0 and y0 <= x0 -> {1, 0, 0, 1, 1, 0} # X Y Z order
      y0 <= z0 and z0 <= x0 -> {1, 0, 0, 1, 0, 1} # X Z Y order
      y0 <= x0 and x0 <= z0 -> {0, 0, 1, 1, 0, 1} # Z X Y order
      x0 <= y0 and y0 <= z0 -> {0, 0, 1, 0, 1, 1} # Z Y X order
      x0 <= z0 and z0 <= y0 -> {0, 1, 0, 0, 1, 1} # Y Z X order
      z0 <= x0 and x0 <= y0 -> {0, 1, 0, 1, 1, 0} # Y X Z order
    end

    # A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
    # a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
    # a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
    # c = 1/6.
    x1 = x0 - i1 + @unskewing_factor_g3 # Offsets for second corner in (x,y,z) coords
    y1 = y0 - j1 + @unskewing_factor_g3
    z1 = z0 - k1 + @unskewing_factor_g3
    x2 = x0 - i2 + 2.0*@unskewing_factor_g3 # Offsets for third corner in (x,y,z) coords
    y2 = y0 - j2 + 2.0*@unskewing_factor_g3
    z2 = z0 - k2 + 2.0*@unskewing_factor_g3
    x3 = x0 - 1.0 + 3.0 * @unskewing_factor_g3 # Offsets for last corner in (x,y,z) coords
    y3 = y0 - 1.0 + 3.0 * @unskewing_factor_g3
    z3 = z0 - 1.0 + 3.0 * @unskewing_factor_g3

    # Work out the hashed gradient indices of the four simplex corners
    # replaced magic number mod(256) with  mod(@p |> tuple_size)
    ii = i |> mod(@p |> tuple_size)
    jj = j |> mod(@p |> tuple_size)
    kk = k |> mod(@p |> tuple_size)
    gi0 = gradient_hash_index(ii, jj, kk)
    gi1 = gradient_hash_index(ii+i1, jj+j1, kk+k1)
    gi2 = gradient_hash_index(ii+i2, jj+j2, kk+k2)
    gi3 = gradient_hash_index(ii+1, jj+1, kk+1)

    # Calculate the contribution from the four corners
    t0 = 0.5 - x0*x0 - y0*y0 - z0*z0
    n0 =
      if (t0 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi0)
        t0*t0*t0*t0 * dot(gradient, x0, y0, z0)
      end

    t1 = 0.5 - x1*x1 - y1*y1 - z1*z1
    n1 =
      if (t1 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi1)
        t1*t1*t1*t1 * dot(gradient, x1, y1, z1)
      end

    t2 = 0.5 - x2*x2 - y2*y2 - z2*z2
    n2 =
      if (t2 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi2)
        t2*t2*t2*t2 * dot(gradient, x2, y2, z2)
      end

    t3 = 0.5 - x3*x3 - y3*y3 - z3*z3
    n3 =
      if (t3 < 0.0) do
        0.0
      else
        gradient = @grad3 |> elem(gi3)
        t3*t3*t3*t3 * dot(gradient, x3, y3, z3)
      end

    # Add contributions from each corner to get the final noise value.
    # The result is scaled to stay just inside [-1,1]
    32.0 * (n0 + n1 + n2 + n3)
  end

  # 4D simplex noise
  # better simplex rank ordering method 2012-03-09
  def noise({x_in, y_in, z_in, w_in}) do
    # Noise contributions from the five corners
    # float type
    # n0, n1, n2, n3, n4

    # Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
    s = (x_in + y_in + z_in + w_in) * @skewing_factor_f4 # Factor for 4D skewing
    i = fastfloor(x_in + s);
    j = fastfloor(y_in + s);
    k = fastfloor(z_in + s);
    l = fastfloor(w_in + s);

    t = (i + j + k + l) * @unskewing_factor_g4 # Factor for 4D unskewing
    unskewed_x0 = i - t # Unskew the cell origin back to (x,y,z,w) space
    unskewed_y0 = j - t
    unskewed_z0 = k - t
    unskewed_w0 = l - t
    x0 = x_in - unskewed_x0 # The x,y,z,w distances from the cell origin
    y0 = y_in - unskewed_y0
    z0 = z_in - unskewed_z0
    w0 = w_in - unskewed_w0

    # For the 4D case, the simplex is a 4D shape I won't even try to describe.
    # To find out which of the 24 possible simplices we're in, we need to
    # determine the magnitude ordering of x0, y0, z0 and w0.
    # 
    # Six pair-wise comparisons are performed between each possible pair
    # of the four coordinates, and the results are used to rank the numbers.
    {rankx, ranky, rankz, rankw} = {0, 0, 0, 0}
    {rankx, ranky} = if (y0 < x0), do: {rankx+1, ranky}, else: {rankx, ranky+1}
    {rankx, rankz} = if (z0 < x0), do: {rankx+1, rankz}, else: {rankx, rankz+1}
    {rankx, rankw} = if (w0 < x0), do: {rankx+1, rankw}, else: {rankx, rankw+1}
    {ranky, rankz} = if (z0 < y0), do: {ranky+1, rankz}, else: {ranky, rankz+1}
    {ranky, rankw} = if (w0 < y0), do: {ranky+1, rankw}, else: {ranky, rankw+1}
    {rankz, rankw} = if (w0 < z0), do: {rankz+1, rankw}, else: {rankz, rankw+1}

    # The integer offsets for the simplex corners
    # i1, j1, k1, l1 # second corner
    # i2, j2, k2, l2 # third corner
    # i3, j3, k3, l3 # fourth corner

    # {rankx, ranky, rankz, rankw} is a 4-vector with the numbers 0, 1, 2 and 3
    # in some order. We use a thresholding to set the coordinates in turn.

    # Rank 3 denotes the largest coordinate.
    i1 = if (3 <= rankx), do: 1, else: 0
    j1 = if (3 <= ranky), do: 1, else: 0
    k1 = if (3 <= rankz), do: 1, else: 0
    l1 = if (3 <= rankw), do: 1, else: 0
    # Rank 2 denotes the second largest coordinate.
    i2 = if (2 <= rankx), do: 1, else: 0
    j2 = if (2 <= ranky), do: 1, else: 0
    k2 = if (2 <= rankz), do: 1, else: 0
    l2 = if (2 <= rankw), do: 1, else: 0
    # Rank 1 denotes the second smallest coordinate.
    i3 = if (1 <= rankx), do: 1, else: 0
    j3 = if (1 <= ranky), do: 1, else: 0
    k3 = if (1 <= rankz), do: 1, else: 0
    l3 = if (1 <= rankw), do: 1, else: 0
    # The fifth corner has all coordinate offsets = 1, so no need to compute that.

    x1 = x0 - i1 + @unskewing_factor_g4 # Offsets for second corner in (x,y,z,w) coords
    y1 = y0 - j1 + @unskewing_factor_g4
    z1 = z0 - k1 + @unskewing_factor_g4
    w1 = w0 - l1 + @unskewing_factor_g4
    x2 = x0 - i2 + 2.0*@unskewing_factor_g4 # Offsets for third corner in (x,y,z,w) coords
    y2 = y0 - j2 + 2.0*@unskewing_factor_g4
    z2 = z0 - k2 + 2.0*@unskewing_factor_g4
    w2 = w0 - l2 + 2.0*@unskewing_factor_g4
    x3 = x0 - i3 + 3.0*@unskewing_factor_g4 # Offsets for fourth corner in (x,y,z,w) coords
    y3 = y0 - j3 + 3.0*@unskewing_factor_g4
    z3 = z0 - k3 + 3.0*@unskewing_factor_g4
    w3 = w0 - l3 + 3.0*@unskewing_factor_g4
    x4 = x0 - 1.0 + 4.0 * @unskewing_factor_g4 # Offsets for last corner in (x,y,z,w) coords
    y4 = y0 - 1.0 + 4.0 * @unskewing_factor_g4
    z4 = z0 - 1.0 + 4.0 * @unskewing_factor_g4
    w4 = w0 - 1.0 + 4.0 * @unskewing_factor_g4

    # Work out the hashed gradient indices of the five simplex corners
    # replaced magic number mod(256) with  mod(@p |> tuple_size)
    ii = i |> mod(@p |> tuple_size)
    jj = j |> mod(@p |> tuple_size)
    kk = k |> mod(@p |> tuple_size)
    ll = l |> mod(@p |> tuple_size)
    gi0 = gradient_hash_index(ii, jj, kk, ll)
    gi1 = gradient_hash_index(ii+i1, jj+j1, kk+k1, ll+l1)
    gi2 = gradient_hash_index(ii+i2, jj+j2, kk+k2, ll+l2)
    gi3 = gradient_hash_index(ii+i3, jj+j3, kk+k3, ll+l3)
    gi4 = gradient_hash_index(ii+1, jj+1, kk+1, ll+1)

    # Calculate the contribution from the five corners
    t0 = 0.5 - x0*x0 - y0*y0 - z0*z0 - w0*w0
    n0 =
      if (t0 < 0.0) do
        0.0
      else
        gradient = @grad4 |> elem(gi0)
        t0*t0*t0*t0 * dot(gradient, x0, y0, z0, w0)
      end

    t1 = 0.5 - x1*x1 - y1*y1 - z1*z1 - w1*w1
    n1 =
      if (t1 < 0.0) do
        0.0
      else
        gradient = @grad4 |> elem(gi1)
        t1*t1*t1*t1 * dot(gradient, x1, y1, z1, w1)
      end

    t2 = 0.5 - x2*x2 - y2*y2 - z2*z2 - w2*w2
    n2 =
      if (t2 < 0.0) do
        0.0
      else
        gradient = @grad4 |> elem(gi2)
        t2*t2*t2*t2 * dot(gradient, x2, y2, z2, w2)
      end

    t3 = 0.5 - x3*x3 - y3*y3 - z3*z3 - w3*w3
    n3 =
      if (t3 < 0.0) do
        0.0
      else
        gradient = @grad4 |> elem(gi3)
        t3*t3*t3*t3 * dot(gradient, x3, y3, z3, w3)
      end

    t4 = 0.5 - x4*x4 - y4*y4 - z4*z4 - w4*w4
    n4 =
      if (t4 < 0.0) do
        0.0
      else
        gradient = @grad4 |> elem(gi4)
        t4*t4*t4*t4 * dot(gradient, x4, y4, z4, w4)
      end

    # Sum up and scale the result to cover the range [-1,1]
    27.0 * (n0 + n1 + n2 + n3 + n4)
  end
end

