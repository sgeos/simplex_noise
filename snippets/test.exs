
[0, 0, 1, 0, 2, 0, 1, 0] = 0..7
  |> Enum.map(&({&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2}))
  |> Enum.map(&SimplexNoiseReference.hi/1)

[0, 0, 1, 0, 2, 0, 1, 0] = 0..7
  |> Enum.map(&([&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2]))
  |> Enum.map(&SimplexNoiseReference2.hi/1)

[2, 2, 2, 2, 1, 1, 0, 2] = 0..7
  |> Enum.map(&({&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2}))
  |> Enum.map(&SimplexNoiseReference.lo/1)

[2, 2, 2, 2, 1, 1, 0, 2] = 0..7
  |> Enum.map(&([&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2]))
  |> Enum.map(&SimplexNoiseReference.lo/1)

[
  0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 
  0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 
  0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 
] = 0..0x3F
  |> Enum.map(&({&1 &&& 0xF, (&1 >>> 4) &&& 0x3}))
  |> Enum.map(&(SimplexNoiseReference.b(elem(&1,0), elem(&1,1))))

[
  0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 
  0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 
  0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 
] = 0..0x3F
  |> Enum.map(&({&1 &&& 0xF, (&1 >>> 4) &&& 0x3}))
  |> Enum.map(&(SimplexNoiseReference2.b(elem(&1,0), elem(&1,1))))

[168, 160, 197, 154, 203, 166, 191, 189] = 0..7
  |> Enum.map(&({&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2}))
  |> Enum.map(&SimplexNoiseReference.shuffle/1)

[168, 160, 197, 154, 203, 166, 191, 189] = 0..7
  |> Enum.map(&([&1 &&& 1, (&1 &&& 2) >>> 1, (&1 &&& 4) >>> 2]))
  |> Enum.map(&SimplexNoiseReference2.gradient_hash/1)

