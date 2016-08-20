#!/usr/bin/env elixir

defmodule PerlinHash do
  use Bitwise

  # 6 bits per entry- 3 set, 3 clear
  @gradient_pattern_table {
    0b010101, 0b111000, 0b110010, 0b101100,
    0b001101, 0b010011, 0b000111, 0b101010
  }

  @zero_bit_index 2
  @sign_bit_index 3
  @dimensions 3 # Only works with 3D noise

  def hash(vertex) do
    gradient_index = vertex
    |> gradient_index

    rotate = gradient_index &&& 0x3
    zero_bit = bit(gradient_index, @zero_bit_index)
    sign_bits = @sign_bit_index..(@sign_bit_index + @dimensions - 2)
    |> Enum.map(&bit(gradient_index, &1))
    last_sign_bit = bit(gradient_index, @sign_bit_index + @dimensions - 1)

    last_gradient_bit = sign_bits # last sign bit uses a different calculation
    |> Enum.reduce(0, &(&1 ^^^ &2)) # XOR all but last sign bit
    |> (&(&1 != last_sign_bit)).() # result is != to last sign bit

    sign_bits
    |> Enum.map(&(&1 == last_sign_bit)) # true if sign bit == last sign bit
    |> Kernel.++([last_gradient_bit]) # add last gradient bit to list
    |> Enum.map(&(if &1 do -1.0 else 1.0 end)) # map true -> -1, false -> 1
    |> Enum.split(rotate - 1) # rotate gradient components
    |> (fn {a, b} -> b ++ a end).() # done rotating
    |> ( # zero a component
      fn gradient ->
        case {rotate, zero_bit} do
          {0, _} -> gradient # do not zero
          {_, 0} -> gradient |> List.replace_at(-1, 0) # zero z component
          _ -> gradient |> List.replace_at(1, 0) # zero y component
        end
      end
    ).() # return gradient
  end

  def gradient_index(list) do
    0..7
    |> Enum.reduce(0, fn bit_index, acc -> acc + gradient_pattern(list, bit_index) end)
  end

  # probably does not scale beyond 3 dimensions
  def gradient_pattern(list, bit_index) do
    gradient_pattern_index = list
    |> Enum.split(@dimensions) |> elem(0) # only works for 3D noise
    |> Enum.reverse |> Enum.with_index # append descending index
    |> Enum.reduce(0, fn {value, shift}, acc -> (bit(value, bit_index) <<< shift) + acc end)
    @gradient_pattern_table
    |> elem(gradient_pattern_index)
  end

  def bit(value, bit_index) do
    value >>> bit_index &&& 0x1
  end
end

