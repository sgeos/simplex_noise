# Reference:
# http://webstaff.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf

# Classic Perlin noise in 3D, for comparison 
defmodule ClassicNoise do
  use OctaveNoise.Mixin

  @grad3 {
    {1, 1, 0}, {-1, 1, 0}, {1, -1, 0}, {-1, -1, 0},
    {1, 0, 1}, {-1, 0, 1}, {1, 0, -1}, {-1, 0, -1},
    {0, 1, 1}, {0, -1, 1}, {0, 1, -1}, {0, -1, -1}
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

  # In Java, this method is a *lot* faster than using (int)Math.floor(x)
  #   return x>0 ? (int)x : (int)x-1
  # This idiom does not exist in Elixir
  # The goal is to truncate x to an integer
  def fastfloor(x) when x < 0, do: (x - 1) |> trunc
  def fastfloor(x), do: x |> trunc 

  def dot({g0, g1, g2}, x, y, z) do
    g0*x + g1*y + g2*z
  end

  def mix(a, b, t) do
    (1.0-t)*a + t*b
  end

  def fade(t) do
    t*t*t*(t*(t*6.0-15.0)+10.0)
  end

  # Elixir needs a custom mod function to emulate Java && masking
  # Assume x is always an integer
  def mod(x,y) when 0 < x, do: rem(x, y)
  def mod(x,y) when x < 0, do: y + rem(x, y)
  def mod(0,_y), do: 0

  # split this into a function because Java style array indexing is verbose in Elixir
  # replaced magic number mod(12) with  mod(@grad3 |> tuple_size)
  def gradient_hash_index(x, y, z) do
    hash_z = @perm |> elem(z)
    hash_y = @perm |> elem(y + hash_z)
    hash_x = @perm |> elem(x + hash_y)
    hash_x |> mod(@grad3 |> tuple_size)
  end

  # Classic Perlin noise, 3D version
  def noise(x, y, z), do: noise {x, y, z}
  def noise({x, y, z}) do

    # Find unit grid cell containing point
    # integer type
    unit_x = x |> fastfloor
    unit_y = y |> fastfloor
    unit_z = z |> fastfloor

    # Get relative xyz coordinates of point within that cell
    # float type
    relative_x = 1.0 * x - unit_x
    relative_y = 1.0 * y - unit_y
    relative_z = 1.0 * z - unit_z

    # Wrap the integer cells at 255 (smaller integer period can be introduced here)
    # replaced magic number mod(256) with  mod(@p |> tuple_size)
    # integer type
    index_x = unit_x |> mod(@p |> tuple_size)
    index_y = unit_y |> mod(@p |> tuple_size)
    index_z = unit_z |> mod(@p |> tuple_size)

    # Calculate a set of eight hashed gradient indices
    # integer type
    gi000 = gradient_hash_index(index_x, index_y, index_z)
    gi001 = gradient_hash_index(index_x, index_y, index_z+1)
    gi010 = gradient_hash_index(index_x, index_y+1, index_z)
    gi011 = gradient_hash_index(index_x, index_y+1, index_z+1)
    gi100 = gradient_hash_index(index_x+1, index_y, index_z)
    gi101 = gradient_hash_index(index_x+1, index_y, index_z+1)
    gi110 = gradient_hash_index(index_x+1, index_y+1, index_z)
    gi111 = gradient_hash_index(index_x+1, index_y+1, index_z+1)

    # The gradients of each corner are now:
    # integer triple type
    g000 = @grad3 |> elem(gi000)
    g001 = @grad3 |> elem(gi001)
    g010 = @grad3 |> elem(gi010)
    g011 = @grad3 |> elem(gi011)
    g100 = @grad3 |> elem(gi100)
    g101 = @grad3 |> elem(gi101)
    g110 = @grad3 |> elem(gi110)
    g111 = @grad3 |> elem(gi111)

    # Calculate noise contributions from each of the eight corners
    # float type
    n000 = dot(g000, relative_x, relative_y, relative_z)
    n100 = dot(g100, relative_x-1, relative_y, relative_z)
    n010 = dot(g010, relative_x, relative_y-1, relative_z)
    n110 = dot(g110, relative_x-1, relative_y-1, relative_z)
    n001 = dot(g001, relative_x, relative_y, relative_z-1)
    n101 = dot(g101, relative_x-1, relative_y, relative_z-1)
    n011 = dot(g011, relative_x, relative_y-1, relative_z-1)
    n111 = dot(g111, relative_x-1, relative_y-1, relative_z-1)

    # Compute the fade curve value for each of x, y, z
    # float type
    u = fade(relative_x)
    v = fade(relative_y)
    w = fade(relative_z)

    # Interpolate along x the contributions from each of the corners
    # float type
    nx00 = mix(n000, n100, u)
    nx01 = mix(n001, n101, u)
    nx10 = mix(n010, n110, u)
    nx11 = mix(n011, n111, u)

    # Interpolate the four results along y
    # float type
    nxy0 = mix(nx00, nx10, v)
    nxy1 = mix(nx01, nx11, v)

    # Interpolate the two last results along z
    # float type
    nxyz = mix(nxy0, nxy1, w)

    # float type
    nxyz
  end
end

