# Pilr.jl Documentation

Tools for accessing and analyzing PiLR data.

## Installation

You can install Pilr.jl by typing the following in the Julia REPL:
```julia
] add Pilr
```

followed by 
```julia
using Pilr
```
to load the package.

## Overview

* [`Pilr.database`](@ref) returns a [`Pilr.Database`](@ref) connected to a PiLR Mongo database via a tunnel.
