using DataFrames: DataFrame, Not, select!
import Mongoc as M

"""
    mfind(collection, queryitem...; limit=0, option...)
    mfind(database, project_code, dataset_code, queritem...; limit=0, option...)

Query mongodb with a powerful short-hand syntax and return a dataframe.

Each `queryitem` can be a `Pair` or vector of pairs using `bson` syntax.

The vectors are flattened so you don't need `...` after `tomany`[@ref].  

If any item looks like a pipeline stage (starts with '"'), `Mongoc.aggregate` is called; 
otherwise `Mongoc.find`.

# Examples

```jldoctest test
julia> db = database("mmendel",QA);

julia> mfind(db.project, :code=>+:regex=>"^test"; :limit=>1, :skip=>1)
1×12 DataFrame
 Row │ _id                       active  code    dateCreated              isDe ⋯
     │ String                    Bool    String  DateTime                 Bool ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 54b40452e4b098676ab9f366    true  test2   2015-01-12T17:28:50.481       ⋯
                                                               8 columns omitted
julia> configs = mfind(db.project, 
         :code=>+:regex=>"^test",
         tomany("project", "instrument", "instrumentConfig"),
         ; limit=3);

julia> configs[!, [:name, :instrumentConfig!name]]
3×2 DataFrame
 Row │ name            instrumentConfig!name 
     │ String          String                
─────┼───────────────────────────────────────
   1 │ Test Run        Protocol 1 Config
   2 │ Test James 102  test config #asdf
   3 │ Test Import     Branching Example
```
"""
function mfind(
    collection::M.AbstractCollection, 
    queryitems::Union{Pair,AbstractArray}...
    ; limit=0, showquery=false, options...
    )
    pairs = Pair{Any,Any}[]
    for item in queryitems
        if item isa AbstractVector 
            push!(pairs, item...)
        else
            push!(pairs, item)
        end
    end
    if any(_isstage, pairs)
        pipeline = [ (_isstage(i) ? i : +:match=>i) for i in pairs ]
        if limit > 0
            push!(pipeline, +:limit=>limit)
        end
        showquery && @info "mfind" collection pipeline
        c = M.aggregate(collection, bson(pipeline); options=bson(options...))
    else
        if limit > 0
            options = (:limit => limit, options...)
        end
        showquery && @info "mfind" collection pairs options
        c = M.find(collection, bson(pairs...); options=bson(options...))
    end
    DataFrame(c)
end

function _isstage(i) 
    op = i |> first |> string
    startswith(op, '$') && !(op in ["\$or", "\$and"])
end

mfind(db, project_code::AbstractString, dataset_code::AbstractString, query::Union{Pair,AbstractArray}...; kw...) = 
    select!(
        mfind(dataset_collection(db, project_code, dataset_code), query...; kw...), 
        Not(Regex("^($( join(Pilr.DEFAULT_REMOVE, '|') ))\$")), :)
