# Pilr

Tools for working with PiLR data in Julia

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://mgm7734.github.io/Pilr.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://mgm7734.github.io/Pilr.jl/dev)

GitHub Actions : [![Build Status](https://github.com/mgm7734/Pilr.jl/workflows/CI/badge.svg)](https://github.com/mgm7734/Pilr.jl/actions?query=workflow%3ACI+branch%3Amaster)

[![Coverage Status](https://coveralls.io/repos/mgm7734/Pilr.jl/badge.svg?branch=master)](https://coveralls.io/r/mgm7734/Pilr.jl?branch=master)
[![codecov.io](http://codecov.io/github/mgm7734/Pilr.jl/coverage.svg?branch=master)](http://codecov.io/github/mgm7734/Pilr.jl?branch=master)


## Requirements

* Julia v1.5 or newer.

* ssh access to jenkins w/o prompt (unless running on instance inside PiLR firewall)


## Development

Typical work flow. (You can paste this directly in a julia repl.)
```julia-repl
julia> using Revise

(@v1.7) pkg> activate .
  Activating project at `~/.julia/dev/Pilr`

(Pilr) pkg> test
[...]

julia> import Mongoc as M

julia> using Pilr
[...]
```

## TODO

- Tables interface to remote log files, for both files in directory by type & date and parsed log records
