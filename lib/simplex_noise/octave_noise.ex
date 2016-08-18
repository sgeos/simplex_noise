# Reference
# http://www.java-gaming.org/topics/generating-2d-perlin-noise/31637/msg/294195/view.html#msg294195

# Octave Noise Behavior
defmodule OctaveNoise do
  @doc "Returns a noise value for a given n-tuple coordinate."
  @callback octave_noise(tuple, map) :: number
end

# Octave Noise Mixin, Default Implementation
defmodule OctaveNoise.Mixin do
  defmacro __using__(_) do
    quote location: :keep do

      @behaviour NoiseGenerator
      @behaviour OctaveNoise

      # default empty options, filled in below
      def octave_noise(coordinate, options \\ %{})

      # return result for denominator of zero
      def octave_noise(
        _coordinate,
        %{
          octaves: 0,
          weight_sum: 0
        }
      ), do: 0

      # return result
      def octave_noise(
        _coordinate,
        %{
          octaves: 0,
          noise_sum: noise_sum,
          weight_sum: weight_sum
        }
      ), do: noise_sum / weight_sum

      # iterate and sum octaves
      def octave_noise(
        coordinate,
        %{
          octaves: octaves,
          roughness: roughness,
          layer_frequency: layer_frequency,
          layer_weight: layer_weight,
          noise_sum: noise_sum,
          weight_sum: weight_sum
        } = options
      ) do
        ocatve_coordinate = coordinate
        |> Tuple.to_list
        |> Enum.map(&(&1 / layer_frequency))
        |> List.to_tuple

        octave_noise(
          coordinate,
          options
          |> Map.merge(%{
            octaves: octaves - 1,
            layer_frequency: layer_frequency * 2,
            layer_weight: layer_weight * roughness,
            noise_sum: noise_sum + noise(ocatve_coordinate) * layer_weight,
            weight_sum: weight_sum + layer_weight
          })
        )
      end

      # add default values for missing options
      def octave_noise(coordinate, %{} = options) do
        default_options = %{
          octaves: 3,
          roughness: 2.0,
          layer_frequency: 1.0,
          layer_weight: 1.0,
          noise_sum: 0.0,
          weight_sum: 0.0
        }

        octave_noise(
          coordinate,
          default_options |> Map.merge(options)
        )
      end

    end # quote
  end # using
end

