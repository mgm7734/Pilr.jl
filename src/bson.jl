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

julia> bson(:a => 2, :b=>"\$ne" => 2)
Mongoc.BSON with 2 entries:
  "a" => 2
  "b" => Dict{Any, Any}("\$ne"=>2)
```
"""
bson(;nt...) = M.BSON((Pair(string(k), _bson(v)) for (k,v) in pairs(nt))...)
bson(ps::Pair...) = M.BSON((Pair(string(k), _bson(v)) for (k,v) in ps)...)
bson(t::Tuple) = bson(t...)
bson(d::AbstractDict) = bson(pairs(d)...)
bson(s::Symbol)=string(s)
bson(x) = x

# Mongoc.aggregate should accept Array{BSON} but doesn't
bson(a::AbstractVector) = M.BSON(map(bson, a))
_bson(a::AbstractVector) = map(bson, a)
_bson(x) = bson(x)
