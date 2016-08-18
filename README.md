# SimplexNoise

**!!! Work in progress.  This repository is very messy and not ready for public viewing. !!!**

An elixir implementation of simplex noise.
The goal is to clean this up and release it as a proper hex package.

This project contains the followng notable files.

- **lib/simplex_noise.ex** Elixir translation of Stefan Gustavson's Java implementation
- **lib/simplex_noise/improved.ex** Elixir translation of Stefan Gustavson's improved Java implementation
- **lib/simplex_noise/reference.ex** Liberal Elixir translation of Ken Perlin's Java reference implementation
- **lib/simplex_noise/reference2.ex** Even more liberal and hopefull descriptive Elixir translation of Ken Perlin's Java reference implementation
- **lib/simplex_noise/overview.ex** Incomplete original elixir implementation
- **lib/simplex_noise/octave_noise.ex** Functions to generate octave noise from the various implementations.

The **snippets/\*_noise\*_png.exs** files can be run to generate PNG files in the **snippets** directory
with the various simplex noise implementations.

```sh
mix run snippets/simplex_noise_improved_png.exs
# imgcat is a utility to view images in an OSX iTerm 2 terminal
imgcat snippets/noise.png
```

The **snippets** directory also contains other assorted scripts.

## Note on the Patent

Simplex noise has been [patented][patent]
"for producing images with texture that do not have visible grid artifacts".
Netizens believe that this patent only covers procedural texture generation.
Netizens do not believe it covers other procedural content generation like worlds in video games.
Please speak to an attorney if you are concerned about your particular use case.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `simplex_noise` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:simplex_noise, "~> 0.1.0"}]
    end
    ```

  2. Ensure `simplex_noise` is started before your application:

    ```elixir
    def application do
      [applications: [:simplex_noise]]
    end

    ```

References:

- [Wikipedia, Simplex Noise](https://en.wikipedia.org/wiki/Simplex_noise)
- [Ken Perlin's "Noise Hardware" Reference Implementation](http://www.csee.umbc.edu/~olano/s2002c36/ch02.pdf)
- [Patent, Standard for perlin noise][patent]
- [Stefan Gustavson's Simplex noise demystified](http://webstaff.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf)
- [Improved Simplex noise demystified Java Implementation](http://webstaff.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java)
- [Optimized Spatial Hashing for Collision Detection of Deformable Objects](http://www.beosil.com/download/CollisionDetectionHashing_VMV03.pdf)

[patent]: https://www.google.com/patents/US6867776

