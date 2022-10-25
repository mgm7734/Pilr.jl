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

"""
    tomany(parent, children...)

Pipeline helper TODO

# Examples


"""
function tomany(parent, children...; unwind=true)
    result = []
    parent = string(parent)
    if startswith(parent, '$')
        parent = parent[2:end]
        pk = "$parent._id"
    else
        pk = "_id"
    end
    for c in children
        (fk, child) = c isa Union{Pair,Tuple} ? string.(Tuple(c)) : (parent, string(c))
        push!(result, (
            +:lookup => (:from => child, :localField => pk, :foreignField => fk, :as => child)))
        unwind && push!(result, (+:unwind => "\$$child"))
        parent = child
        pk = "$(parent)._id"
    end
    result
end

"""
    toparent(key...; skipmissing=false)

Join with a chain of parents specified by the keys.
o

# Examples

```julia
pilrfind(db.participant, toparent(:project))
pilrfind(db.trigger. topparent(:configuration => :instrumentConfig))
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
        as = localField
        push!(result,
            +:lookup => (:from => from, :localField => localField, :foreignField => "_id", :as => as),
            +:unwind => (:path => "\$$as", :preserveNullAndEmptyArrays => !skipmissing))
    end
    result
end 