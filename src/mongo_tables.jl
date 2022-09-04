using DataStructures
using SimpleTraits: istrait, @traitdef, @traitimpl, @traitfn
#import SimpleTraits


#=
canFlatten(T) = istrait(SimpleTraits.BaseTraits.IsIterator{T}) && eltype(T) <: AbstractDict

@traitdef CanFlatten{T}

@traitimpl CanFlatten{M.Cursor}

@traitimpl CanFlatten{T} <- canFlatten(T)

function _runreplace(pairs::Vector, k, v) where {T <: Union{Symbol,Nothing}}
    if k == nothing
        return nothing, nothing
    end
    for (from, to) in pairs
        from = string(from)
        if startswith(k, from)
            k = to == nothing ? nothing : string(to) * k[1 + length(from):end]
            break
        end
    end
    return k, v
end

function _runreplace(f::Function, k::String, v)
    f(k, v)
end
=#

"""
    flatdict(cursor ; [separator = "!"])

Convert an iterable of nested Dict{String,Any} (such as a Cursor returned by
[`Mongoc.find`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Mongoc.find)) into a dictonary of equal length columns.

The returned dictionary can be converted to a DataFrame.

Each field value that is a dictionary is replaced a field for every entry. The field names are the path.

Using "!" does not require quoting in Symbol names, so you can type `:metadata!pt` instead of `"metadata.pt"`.

# Option Arguments

- `separator` : path separator for flattened column names. 
- `replace` : either a vector of Pair{Symbol,Any} or a function (key, value) -> (key, value).
- `order` : a vector of columns that should appear first.
"""
#@traitfn flatdict(cursor::::CanFlatten; kws...) = _flatdict(cursor; kws...)
# this is handled by Tables implementation
Base.@deprecate flatdict(x) FlatteningDictIterator(x) 

function _flatdict(
    cursor; 
    separator::String="!",
    replace=[],
    order=[]
    )::OrderedDict
    
    # Initializign with keys from order loses the column type
    columns = OrderedDict{Symbol,Vector}()  #key => [] for key in Symbol.(order))
    rowcount = 0

    function pushvalue!(::Nothing, ::Nothing, prefix) end

    function pushvalue!(key, dict::AbstractDict, prefix)
        key, dict = _runreplace(replace, "$prefix$key", dict)
        if key === nothing
            return
        end
        for (k, v) in dict
            pushvalue!(k, v, "$key$separator")
        end
    end
    function pushvalue!(key, value, prefix)
        key, value = _runreplace(replace, "$prefix$key", value)
        if key === nothing
            return
        end
        key = Symbol(key)
        if rowcount == 0
            columns[key] = [value]
        else
            col = get!(columns, key) do
                Vector{Union{Missing,typeof(value)}}(missing, rowcount)
            end
            if typeof(value) <: eltype(col)
                push!(col, value)
            else
                columns[key] = [col..., value]
            end
        end
    end

    for doc in cursor
        for (key, value) in doc
            pushvalue!(key, value, "")
        end
        rowcount += 1
        for (key, vector) in columns
            if length(vector) < rowcount
                pushvalue!(key, missing, "")
            end
        end
    end
    OrderedDict(
        (Pair(k, columns[k]) for k in order)...,
        (Pair(k, v) for (k,v) in pairs(columns) if !(k ∈ order))...)
end

#using Tables
#Tables.columns(table::AbstractDict) = flatten(table)
#Tables.getcolumn(table::AbstractDict, i::Int) = table[collect(keys(table))[i]]
#Tables.getcolumn(table::OrderedDict, nm::Symbol) = table[nm]
#Tables.columnnames(table::OrderedDict) = collect(keys(table))
#Tables.istable(::OrderedDict) = true
#
#Tables.istable(::M.Cursor) = true
#
#Tables.columnaccess(::M.Cursor) = true
#
#Tables.columns(cursor::M.Cursor) = MongoTable(cursor)
