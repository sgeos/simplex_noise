defmodule Gradient do
  def table(dimensions) do
    permutations = dimensions * :math.pow(2, dimensions - 1)
    last_index = trunc(permutations) - 1
    0..last_index
    |> Enum.map(&from_index(&1, dimensions))
  end

  def from_index(index, dimensions) do
    {axis_index_list, zero_index} = 0..(dimensions-2)
    |> Enum.map_reduce(index, fn (_iteration, index_acc) -> rem_div(index_acc, 2) end)
    # safe zero_index
    # zero_index = rem(zero_index, dimensions)
    from_list(axis_index_list, zero_index)
  end

  def from_list(axis_index_list, zero_index) do
    # safe zero_index
    # dimensions = length(axis_index_list) + 1
    # zero_index = rem(zero_index, dimensions)
    axis_index_list
    |> Enum.map(&axis_index_to_direction/1)
    |> List.to_tuple
    |> Tuple.insert_at(zero_index, 0)
    |> Tuple.to_list
  end

  def axis_index_to_direction(0), do: -1
  def axis_index_to_direction(_), do: 1

  def div_rem(dividend, divisor), do: {div(dividend,divisor), rem(dividend,divisor)}
  def rem_div(dividend, divisor), do: {rem(dividend,divisor), div(dividend,divisor)}
end

2..4
|> Enum.each(&IO.puts "#{&1}D => #{inspect Gradient.table(&1)}")

0..9

0..9 |> Enum.map(&([3,0,&1] |> IO.iodata_to_binary |> CRC.crc_16 |> rem(12)))

IO.puts ""
IO.puts "> 2D Gradients"
size = 7
0..(size-1)
|> Enum.map(
  fn x ->
    0..(size-1)
    |> Enum.map(
      &(
        [x,&1]
        |> IO.iodata_to_binary
        |> CRC.ccitt_16
        |> rem(4)
        |> Gradient.from_index(2)
      )
    )
  end
)
|> Enum.each(&IO.puts("> #{inspect &1}"))

IO.puts ""
IO.puts "> 3D Gradients"
size = 7
0..(size-1)
|> Enum.map(
  fn x ->
    0..(size-1)
    |> Enum.map(
      &(
        [x,&1, 0]
        |> IO.iodata_to_binary
        #|> CRC.ccitt_16_xmodem
        #|> CRC.crc_16_modbus
        |> CRC.checksum_xor
        |> rem(12)
        |> Gradient.from_index(3)
      )
    )
  end
)
|> Enum.each(&IO.puts("> #{inspect &1}"))

