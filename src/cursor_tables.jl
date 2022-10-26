using Tables
using DataFrames: AbstractDataFrame

struct FlatteningDictIterator{T}
    iterator::T
end

struct FlattenedRow
    pairs
end

separator = "!"

function Base.iterate(x::FlatteningDictIterator, state = nothing)
    r = iterate(x.iterator, state)
    r === nothing && return
    doc, newstate = r
    pairs = []

    function pushpathvalue(path, value::AbstractDict)
        @info "pushpathvalue" path value
        prefix =
            if path == ""
                ""
            else
                path * separator
            end
        
        for (k, v) in value
            p = prefix * replace(k, separator => separator * separator)
            pushpathvalue(p, v)
        end
    end

    function pushpathvalue(path, value)
        @info "pushpathvalue v v" path value
        push!(pairs, (path=Symbol(path), value))
    end

    pushpathvalue("", doc)

    (FlattenedRow(pairs), newstate)
end


Base.IteratorSize(::Type{<:FlatteningDictIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:FlatteningDictIterator}) = Base.HasEltype()
Base.eltype(::Type{<:FlatteningDictIterator}) = FlattenedRow

Tables.getcolumn(row::FlattenedRow, i::Int) = row.pairs[i].value

function Tables.getcolumn(row::FlattenedRow, nm::Symbol) 
    for p in row.pairs
        if p.path == nm
            return p.value
        end
    end
    return missing
end

Tables.columnnames(row::FlattenedRow) = map(first, row.pairs)

#### Mongoc.Cursor

Tables.istable(::M.Cursor) = true

Tables.columnaccess(::M.Cursor) = true

function Tables.columns(c::M.Cursor) 
    @debug "Tables.columns(::M.Cursor)"
    t = Tables.dictcolumntable(FlatteningDictIterator(c))
    @info "DEBUG" t
    Tables.columns(t)
end


