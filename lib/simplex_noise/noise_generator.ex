defmodule NoiseGenerator do
  @doc "Returns a noise value for a given n-tuple coordinate."
  @callback noise(tuple) :: number
end

