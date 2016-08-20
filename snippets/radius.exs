min_dimensions=1
max_dimensions=10

# In 2D, we have two 2-simplices (triangles), OAL and OBL.
# O is the origin of the unit hypercube and simplices it contains.
# L is the last point, also shared by all simplices.
#
# In simplicial grid space it looks like this:
# 
# A---L
# |  /|
# |/  |
# O---B
#
# O = [0.0, 0.0]
# A = [0.0, 1.0]
# B = [1.0, 0.0]
# L = [1.0, 1.0]
#
# In the original grid space, OAL and OBL are equilateral triangles.
# They looks something like this:
#
# A
# |----L
#  |  /|
#   |/  |
#   O----|
#        B
#
# O = [0.0, 0.0]
# A = [-0.21132486540518708, 0.7886751345948129]
# B = [0.7886751345948129, -0.21132486540518708]
# L = [0.5773502691896258, 0.5773502691896258]
#
# The gradient contribution from A should be zero at the boundry of OBL.
# That means that the kernel summation radius is the height of the triangle.
#
# This extends to N-dimensions.
# The N-dimensional kernal summation radius is the height of the n-simplex.
#
# The height of an n-simplex is:
#   radius = edge_length * :math.sqrt((dimensions + 1) / (2 * dimensions))
#
# Ultimately, the summation radius squared is need:
#   radius_squared = edge_length_squared * (dimensions + 1) / (2 * dimensions)

min_dimensions..max_dimensions
|> Enum.map(
  fn dimensions ->
    List.duplicate(1.0, dimensions) # N-dimensional point L; simplicial grid space
    |> SimplexNoise.Overview.unskew_to_original_grid(dimensions) # unskew to original grid
    |> Enum.reduce(0, &(&1*&1+&2)) # edge_length_squared; distance from O to L squared
    |> (&(&1 * (dimensions + 1) / (2 * dimensions))).() # radius_squared
  end
)
|> Enum.map(&([Float.round(&1, 5), &1]))
|> Enum.with_index
|> Enum.map(fn {[rounded, original], index} -> {index, rounded, original} end)
|> Enum.each(&IO.puts("#{elem(&1, 0) + min_dimensions}D: #{elem(&1, 1)} (#{elem(&1, 2)})"))

