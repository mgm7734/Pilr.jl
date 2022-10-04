using DataStructures

const Key = Union{AbstractString,Symbol}

@doc raw"""
    bson(pair...) => Mongoc.BSON
    bson(AbstractVector{pair}) => Vector{Mongoc.BSON}

Construct a BSON object using keyword arguments or pairs to reduce quote clutter.

# Examples

```jldoctest
julia> bson("metadata.pt" => "xyz", :project => +:in => ["proj1", "proj2"])
Mongoc.BSON with 2 entries:
  "metadata.pt" => "xyz"
  "project"     => Dict{Any, Any}("\$in"=>Any["proj1", "proj2"])

julia> bson([
         +:match => :type=>"SUBMIT", 
         +:group => (:_id=>+:pt, :N=>+:sum=>1)
       ])
Mongoc.BSON with 2 entries:
  "0" => Dict{Any, Any}("\$match"=>Dict{Any, Any}("type"=>"SUBMIT"))
  "1" => Dict{Any, Any}("\$group"=>Dict{Any, Any}("_id"=>"\$pt", "N"=>Dict{Any,…
julia> bson(a=1, b=2)
Mongoc.BSON with 2 entries:
  "a" => 1
  "b" => 2
```
"""
bson(; nt...) = M.BSON((Pair(bson(k), _bson(v)) for (k, v) in pairs(nt))...)
bson(ps::Pair...) = M.BSON((Pair(bson(k), _bson(v)) for (k, v) in ps)...)
bson(t::Tuple) = bson(t...)
bson(d::AbstractDict) = bson(pairs(d)...)
bson(s::Symbol) = replace(string(s), "!!" => "!", "!" => ".")
bson(x) = x

# Mongoc.aggregate should accept Array{BSON} but doesn't
bson(a::AbstractVector) = M.BSON(map(bson, a))
_bson(a::AbstractVector) = map(bson, a)
_bson(x) = bson(x)

Base.:(~)(s::Symbol) = raw"$" * bson(s)
Base.:(+)(s::Symbol) = ~s


"""
    tomany(parent, children...)

Pipeline helper TODO

# Examples


"""
function tomany(parent, children...; unwind=true, root=true)
  result = []
  if root
    pk = "_id"
  else
    pk = "$parent._id"
  end
  for c in children
    (fk, child) = c isa Tuple ? c : (parent, c)
    push!(result, (
      +:lookup => (:from => child, :localField => pk, :foreignField => fk, :as => child)))
    unwind && push!(result, (+:unwind => "\$$child"))
    parent = child
    pk = "$(parent)._id"
  end
  result
end

#=
function toowner(collection...; unwind = true, root=true)
  result = []
    fk = ""
    for i in 1:length(collection)-1
        parent = collection[i+1]
        c = collection[i]
        if c isa tuple
          (child, fk) = c
        else
          child = c
          fk = coll
        (pk, parent) = p isa Tuple ? p : (parent, p)
        push!(result, (
            +:lookup => ( :from => parent, :localField => pk, :foreignField => fk, :as => child )))
        unwind && push!(result,  ( +:unwind=>"\$$child" ))
        parent = child
        pk = "$(parent)._id"
    end
    result
  if 
=#