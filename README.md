# Pilr

Tools for working with PiLR data in Julia


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
