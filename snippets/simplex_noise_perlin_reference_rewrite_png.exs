:random.seed(:os.system_time)

path = "snippets/"
width  = 512
height = 512
bit_depth = 8

defmodule ColorMap do
  def index(noise_in) when noise_in < -0.05, do: 0 # ocean
  def index(noise_in) when noise_in < -0.00, do: 1 # shallows
  def index(noise_in) when noise_in < 0.05, do: 2 # sand
  def index(noise_in) when noise_in < 0.15, do: 3 # grass
  def index(noise_in) when noise_in < 0.25, do: 4 # forest
  def index(noise_in) when noise_in < 0.35, do: 5 # swamp
  def index(noise_in) when noise_in < 0.45, do: 6 # mountain
  def index(_noise_in), do: 7 # snow
end


# define an 8 bit RGB palette with 8 colors
palette = {
  :rgb,
  bit_depth,
  [
    {0x33,0x66,0xFF}, # ocean
    {0x33,0xEE,0xFF}, # shallows
    {0xFF,0xFF,0x88}, # sand
    {0x88,0xFF,0x88}, # grass
    {0x11,0x99,0x11}, # forest
    {0x77,0x22,0xCC}, # swamp
    {0x77,0x22,0x22}, # mountain
    {0xFF,0xFF,0xFF}, # snow
  ]
}

{:ok, file} = :file.open(path <> "noise.png", [:write])

config = %{
  size: {width, height},
  mode: {:indexed, bit_depth},
  file: file,
  palette: palette
}

# create an 8 bit indexed PNG
png = :png.create(config)

1..height
|> Enum.map(
  fn y_in ->
    IO.puts "#{y_in} of #{height}"
    1..width
    |> Enum.map(
      fn x_in ->
        x = 8 * x_in / width
        y = 8 * y_in / height
        z = :math.pi
        point = {x, y, z}
        options = %{octaves: 3}
        SimplexNoise.PerlinReferenceRewrite.octave_noise(point, options)
        |> ColorMap.index
      end
    )
    |> IO.iodata_to_binary
  end
)
|> Enum.each(&(:png.append(png, {:row, &1})))

:ok = :png.close(png)
:ok = :file.close(file)

