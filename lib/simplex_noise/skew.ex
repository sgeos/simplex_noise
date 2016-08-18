defmodule SimplexNoise.Skew do
  # skew point to another grid
  # Wikipedia description only uses a single additive skewing function
  # for skewing and unskewing with a negative unskewing factor
  #   skewing_factor = skewing_factor_to_simplical_grid(length(original_point))
  #   skewed_point = skew(original_point, skewing_factor) # additive skewing
  #   skewing_factor = skewing_factor_from_simplical_grid(length(skewed_point))
  #   original_point = skew(skewed_point, skewing_factor) # additive skewing
  def skew(point, skewing_factor) do
    skewing_constant = Enum.sum(point) * skewing_factor
    point |> Enum.map(&(&1 + skewing_constant))
  end

  # unskew to original grid
  # reference code uses subtractive unskewing with a
  # positive unskewing factor
  #   unskewing_factor = unskewing_factor_from_simplical_grid(length(skewed_point))
  #   original_point = unskew(skewed_point, unskewing_factor) # subtractive unskewing
  def unskew(point, unskewing_factor) do
    skewing_constant = Enum.sum(point) * unskewing_factor
    point |> Enum.map(&(&1 - skewing_constant))
  end

  # calculate factor to skew from original grid to simplicial grid
  def skewing_factor_to_simplical_grid(dimensions) do
    (:math.sqrt(dimensions + 1) - 1) / dimensions
  end

  # calculate factor to skew from simplicial grid to original grid
  # negative value used in Wikipedia description, used for additive skewing
  #   skewing_factor = skewing_factor_from_simplical_grid(length(skewed_point))
  #   original_point = skew(skewed_point, skewing_factor) # additive skewing
  def skewing_factor_from_simplical_grid(dimensions) do
    ( (1 / :math.sqrt(dimensions + 1)) - 1 ) / dimensions
  end

  # calculate factor to unskew from simplicial grid to original grid
  # positive value used in reference code, used for subtractive unskewing
  #   unskewing_factor = unskewing_factor_from_simplical_grid(length(skewed_point))
  #   original_point = unskew(skewed_point, unskewing_factor) # subtractive unskewing
  def unskewing_factor_from_simplical_grid(dimensions) do
    ( 1 - (1 / :math.sqrt(dimensions + 1)) ) / dimensions
  end
end

