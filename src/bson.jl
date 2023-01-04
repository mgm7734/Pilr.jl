using DataStructures

const Key = Union{AbstractString,Symbol}

@doc raw"""
    bson(pair...) => Mongoc.BSON
    bson(AbstractVector{pair}) => Vector{Mongoc.BSON}

Construct a BSON object using keyword arguments or pairs to reduce quote clutter.

# Examples

```jldoctest
julia> bson(:metadata!pt => r"^mei.*1$", :project => +:in => ["proj1", "proj2"])
Mongoc.BSON with 2 entries:
  "metadata.pt" => Dict{Any, Any}("\$regex"=>"^mei.*1\$")
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
bson(re::Regex) = bson(+:regex => re.pattern)
bson(x) = x

# Mongoc.aggregate should accept Array{BSON} but doesn't
bson(a::AbstractVector) = M.BSON(map(bson, a))
_bson(a::AbstractVector) = map(bson, a)
_bson(x) = bson(x)

Base.:(~)(s::Symbol) = raw"$" * bson(s)
Base.:(+)(s::Symbol) = ~s

#=
bsonify(io::IO, d::AbstractDict) = begin
    @info("dict", d)
    if (length(d) != 1)
        print(io, "(")
    end
    join(sprint(bsonify, pairs(d)), ", ")
    if (length(d) != 1)
        print(io, ")")
    end
end
bsonify(io::IO, p::Pair) = begin
    @info "pair" p
    (key,value) = p
    if startswith(string(key), '$')
      print(io, "+")
    end
    print(io, string(key))
    print(io, " => ")
    bsonify(io, value)
end
bsonify(io::IO, a::AbstractArray) = begin
    print(io, "[")
    join(io, sprint(bsonify, a), ", ")
    print(io, "]")
end
bsonify(io::IO, x) = print(io, x)
=#

export lookup
"""
Construct lookup and optional unwind stages for a pipeline.

The defaults work for a to-many relation where the child collection's foreign key is the parent collection name.  
"""
function lookup(from, foreignField; localField=:_id, as=from, unwind=true, skipmissing=false)
    result = Pair[
        +:lookup => (:from => from, :foreignField => foreignField, :localField => localField, :as => as)
    ]
    unwind && push!(result, (+:unwind => (:path => "\$$as", :preserveNullAndEmptyArrays => !skipmissing)))
    result
end

"""
    tomany(parent, children...)

Construct a pipeline traversing a chain of to-many relations

# Examples


"""
function tomany(parent, children...; unwind=true, skipmissing=false)
    result = []
    parent = string(parent)
    if startswith(parent, '$')
        parent = parent[2:end]
        localField = "$parent._id"
    else
        localField = "_id"
    end
    for c in children
        (foreignField, child) = c isa Union{Pair,Tuple} ? string.(Tuple(c)) : (parent, string(c))
        push!(result, lookup(child, foreignField; localField, as=child, unwind, skipmissing)...)
        #push!(result, (
        #    +:lookup => (:from => child, :foreignField => foreignField, :localField => localField, :as => child)))
        #unwind && push!(result, (+:unwind => "\$$child"))
        parent = child
        localField = "$(parent)._id"
    end
    result
end

"""
    toparent(key...; skipmissing=false)

Join with a chain of parents specified by the keys.
o

# Examples

```julia
mfind(db.participant, toparent(:project))
mfind(db.trigger. topparent(:configuration => :instrumentConfig))
```
"""
function toparent(fk...; skipmissing=false)
    result = []
    for item in fk
        (localField, from) =
            if item isa Pair
                string.(Tuple(item))
            else
                item = string(item)
                (_, parts...) = rsplit(item, '!'; limit=2)
                if length(parts) == 0
                    (item, item)
                else
                    (item, parts[1])
                end
            end
        as = from
        push!(result,
            +:lookup => (:from => from, :localField => localField, :foreignField => "_id", :as => as),
            +:unwind => (:path => "\$$as", :preserveNullAndEmptyArrays => !skipmissing))
    end
    result
end 