:random.seed(:os.system_time)

path = "snippets/"
width  = 512
height = 512
bit_depth = 8

# define an 8 bit RGB palette with 8 colors
palette = {
  :rgb,
  bit_depth,
  [
    {0xFF,0xFF,0xFF}, # snow
    {0x55,0x11,0x11}, # mountain
    {0x77,0x22,0xCC}, # swamp
    {0x11,0x99,0x11}, # forest
    {0x88,0xFF,0x88}, # grass
    {0xFF,0xFF,0x88}, # sand
    {0x33,0xEE,0xFF}, # shallows
    {0x33,0x66,0xFF}  # ocean
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
  fn _ ->
    1..width
    |> Enum.map(fn _ -> :random.uniform(8) - 1 end)
    |> IO.iodata_to_binary
  end
)
|> Enum.each(&(:png.append(png, {:row, &1})))

:ok = :png.close(png)
:ok = :file.close(file)

