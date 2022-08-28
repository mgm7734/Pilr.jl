using DataStructures

const Key = Union{AbstractString,Symbol}

"""
    bson(pair...) => Mongoc.BSON
    bson(AbstractVector{pair}) => Vector{Mongoc.BSON}

Construct a BSON object using keyword arguments or pairs to reduce quote clutter.

# Examples

```jldoctest
julia> bson("metadata.pt" => "xyz", :project=>"\\\$in" => ["proj1", "proj2"])
Mongoc.BSON with 2 entries:
  "metadata.pt" => "xyz"
  "project"     => Dict{Any, Any}("\\\$in"=>Any["proj1", "proj2"])

julia> bson([
         "\\\$match"=>:type=>"SUBMIT", 
         "\\\$group"=>(:_id=>"\\\$pt", :N=>"\\\$sum"=>1)
       ])
Mongoc.BSON with 2 entries:
  "0" => Dict{Any, Any}("\\\$match"=>Dict{Any, Any}("type"=>"SUBMIT"))
  "1" => Dict{Any, Any}("\\\$group"=>Dict{Any, Any}("_id"=>"\\\$pt", "N"=>Dict{Any,…

julia> bson(a=1, b=2)
Mongoc.BSON with 2 entries:
  "a" => 1
  "b" => 2
```
"""
bson(;nt...) = M.BSON((Pair(bson(k), _bson(v)) for (k,v) in pairs(nt))...)
bson(ps::Pair...) = M.BSON((Pair(bson(k), _bson(v)) for (k,v) in ps)...)
bson(t::Tuple) = bson(t...)
bson(d::AbstractDict) = bson(pairs(d)...)
bson(s::Symbol)=replace(string(s), "!!"=>"!", "!"=>".")
bson(x) = x

# Mongoc.aggregate should accept Array{BSON} but doesn't
bson(a::AbstractVector) = M.BSON(map(bson, a))
_bson(a::AbstractVector) = map(bson, a)
_bson(x) = bson(x)

Base.:(~)(s::Symbol) =  raw"$" * bson(s)
Base.:(+)(s::Symbol) = ~s
