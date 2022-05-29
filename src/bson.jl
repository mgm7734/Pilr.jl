using DataStructures

const Key = Union{AbstractString,Symbol}

"""
Construct a BSON object using keyword arguments or pairs to reduce quote clutter.

# Examples

```jldoctest
julia> bson(a=1, b=2)
Mongoc.BSON with 2 entries:
  "b" => 2
  "a" => 1

julia> bson(a = 2, b=("\$ne" => 2))
Mongoc.BSON with 2 entries:
  "a" => 2
  "b" => Dict{Any, Any}("\$ne"=>2)
```
"""
bson(;nt...) = M.BSON((Pair(string(k), bson(v)) for (k,v) in pairs(nt))...)
bson(ps::Pair...) = M.BSON((Pair(string(k), bson(v)) for (k,v) in ps)...)
bson(t::Tuple) = bson(t...)

# method M.BSON(::Dict)  shoudl be ::AbstractDict
bson(d::AbstractDict) = bson(pairs(d)...)

bson(a::AbstractVector) = map(bson, a)
bson(x) = x

O(x...) = bson(x...)
