using DataStructures, Tables
using DataFrames: AbstractDataFrame

#=
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
    flatten_dicts(cursor ; [separator = "!"])

Convert an iterable of nested Dict{String,Any} (such as a Cursor returned by
[`Mongoc.find`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Mongoc.find)) into a dictonary of equal length columns.

The returned dictionary can be converted to a DataFrame.

Each field value that is a dictionary is replaced a field for every entry. The field names are the path.

Using "!" does not require quoting in Symbol names, so you can type `:metadata!pt` instead of `"metadata.pt"`.

# Option Arguments

- `separator` : path separator for flattened column names. 
"""
function flatten_dicts(
    cursor; 
    separator::String="!",
    # replace=[],
    )::OrderedDict
    
    # Initializign with keys from order loses the column type
    columns = OrderedDict{Symbol,Vector}()  #key => [] for key in Symbol.(order))
    rowcount = 0

    function pushvalue!(::Nothing, ::Nothing, prefix) end

    function pushvalue!(key, dict::AbstractDict, prefix)
        #key, dict = _runreplace(replace, "$prefix$key", dict)
        #if key === nothing
        #    return
        #end
        prefix = "$prefix$key$separator"
        for (k, v) in dict
            pushvalue!(k, v, prefix)
        end
    end
    function pushvalue!(key, value, prefix)
        #key, value = _runreplace(replace, "$prefix$key", value)
        #if key === nothing
        #    return
        #end
        key = Symbol("$prefix$key")
        if rowcount == 1
            columns[key] = [value]
        elseif !haskey(columns, key)
            col = Vector{Union{Missing,typeof(value)}}(missing, rowcount)
            col[end] = value
            columns[key] = col 
        else
            col = columns[key]
            if typeof(value) <: eltype(col)
                push!(col, value)
            else
                #new = Vector{promote_type(eltype(col), typeof(value))}(missing, rowcount)
                new = Vector{Union{ eltype(col), typeof(value) }}(undef, rowcount)
                @debug "promote" key value typeof(new) new
                copyto!(new, col)
                new[end] = value
                columns[key] = new
            end
        end
    end

    for doc in cursor
        rowcount += 1
        for (key, value) in doc
            pushvalue!(key, value, "")
        end
        for (key, vector) in columns
            @debug "fix" key length(vector)
            if length(vector) < rowcount
                pushvalue!(key, missing, "")
                @debug "fixed" length(columns[key])
            end
        end
    end
    columns
    #OrderedDict(
    #    (Pair(k, columns[k]) for k in order)...,
    #    (Pair(k, v) for (k,v) in pairs(columns) if !(k ∈ order))...)
end

#### Tables implementation for Mongoc.Cursor

Tables.istable(::M.Cursor) = true
Tables.columnaccess(::M.Cursor) = true
Tables.columns(c::M.Cursor) = flatten_dicts(c)

"""
    unflatten(row)
    unflatten(::Vector{row})
    unflatten(::AbstractDataFrame)

Convert flattened mongo docs to its original shape
"""
function unflatten(row)
    result = Dict{String,Any}()
    for path in sort(collect(keys(row)))
        value = row[path]
        ismissing(value) && continue
        keys = split(string(path), '!')
        d = result
        for k in keys[1:end-1]
            d = get!(d, k) do
                Dict{String,Any}()
            end
        end
        d[keys[end]] = value
    end
    result
end
unflatten(v::AbstractVector) = map(unflatten, v)
unflatten(v::AbstractDataFrame) = map(unflatten, eachrow(v))
unflatten(v::Pair...) = unflatten(Dict(v...))
