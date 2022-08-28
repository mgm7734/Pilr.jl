using Tables

Tables.istable(::M.Cursor) = true

Tables.rowaccess(::M.Cursor) = true

struct MongoRowIterator
    cursor::M.Cursor
end

struct MongoRow
    pairs
end

Tables.rows(c::M.Cursor) = MongoRowIterator(c)

separator = "!"

function Base.iterate(itr::MongoRowIterator, state = nothing)
    r = iterate(itr.cursor, state)
    r === nothing && return
    doc, newstate = r
    pairs = []

    function pushpathvalue(path, value::AbstractDict)
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
        push!(pairs, (path=Symbol(path), value))
    end

    pushpathvalue("", doc)

    (MongoRow(pairs), newstate)
end


Base.IteratorSize(::Type{MongoRowIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{MongoRowIterator}) = Base.HasEltype()
Base.eltype(::Type{MongoRowIterator}) = MongoRow

Tables.getcolumn(row::MongoRow, i::Int) = row.pairs[i].value

function Tables.getcolumn(row::MongoRow, nm::Symbol) 
    for p in row.pairs
        if p.path == nm
            return p.value
        end
    end
    return missing
end

Tables.columnnames(row::MongoRow) = map(first, row.pairs)
