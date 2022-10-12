module MongoDataFrames

# DataFrames also exports aggregate
export aggr, aggregate, find, pilrfind

using ..Pilr
using DataFrames: DataFrame, Not, select!
using Pilr: bson
import Mongoc as M

@doc raw"""
    find(collection [ , field => match_expr ]... ; [ , option => value ])

Short-hand syntax for invoking `Mongoc.find` and converting result to a `DataFrame`.

# Example

```jldoctest test
julia> using Pilr, Pilr.MongoDataFrames, DataFrames

julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);

julia> find(db["project"], :code=>+:regex=>"^test"; :limit=>2) |>
       df->select(df, :code, :dateCreated)
2×2 DataFrame
 Row │ code    dateCreated             
     │ String  DateTime                
─────┼─────────────────────────────────
   1 │ test1   2014-12-20T06:14:10.810
   2 │ test2   2015-01-12T17:28:50.481
```
"""
find(collection::M.AbstractCollection, pairs::Pair...; kw...) =
    M.find(collection, bson(pairs...); options=bson(kw)) |> DataFrame

aggregate(collection::M.AbstractCollection, pipeline...; kw...) =
    M.aggregate(collection, bson([pipeline...]); options=bson(kw)) |> DataF

#=
"""
    aggr(collection, pipeline ; [ , option => value ])

Short-hand syntax for invoking `Mongoc.aggreate` and converting result to a `DataFrame`.

# Example

```jldoctest test
julia> using Pilr, Pilr.MongoDataFrames

julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);

julia> aggr(dataset_collection(db, "base_pilr_ema", SURVEY_DATA),
                 [
                   +:match => :data!event_type => "survey_submitted",
                   +:limit => 1000,
                   +:group => (:_id => +:metadata!pt,
                               :surveys_submitted => +:sum => 1,
                               :t => +:max => +:metadata!timestamp),
                   +:limit=>2
                 ]; :allowDiskUse => true)
2×3 DataFrame
 Row │ _id       surveys_submitted  t                   
     │ String    Int64              DateTime            
─────┼──────────────────────────────────────────────────
   1 │ mei01                     7  2022-06-08T12:22:05
   2 │ amios-01                 14  2021-10-14T15:42:12

```
"""
=#
aggr(collection::M.AbstractCollection, pipeline::AbstractVector; kw...) = 

    M.aggregate(collection, bson(pipeline); options=bson(kw)) |> DataFrame
@deprecate aggr pilrfind

"""
    pilrfind(collection, queryitem...; limit=0, option...)
    pilrfind(database, project_code, dataset_code, queritem...; limit=0, option...)

Query mongodb with a powerful short-hand syntax and return a dataframe.

Each `queryitem` can be a `Pair` or vector of pairs using `bson` syntax.

The vectors are flattened so you don't need `...` after `tomany`[@ref].  

If any item looks like a pipeline stage (starts with '"'), `Mongoc.aggregate` is called; 
otherwise `Mongoc.find`.

# Examples

```jldoctest test
julia> db = database("mmendel",QA);

julia> pilrfind(db.project, :code=>+:regex=>"^test"; :limit=>1, :skip=>1)
1×12 DataFrame
 Row │ _id                       active  code    dateCreated              isDe ⋯
     │ String                    Bool    String  DateTime                 Bool ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 54b40452e4b098676ab9f366    true  test2   2015-01-12T17:28:50.481       ⋯
                                                               8 columns omitted
julia> configs = pilrfind(db.project, 
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
function pilrfind(
    collection::M.AbstractCollection, 
    queryitems::Union{Pair,AbstractArray}...
    ; limit=0, showquery=false, options...
    )
    pipeline = Pair{Any,Any}[]
    for item in queryitems
        if item isa AbstractVector 
            push!(pipeline, item...)
        else
            push!(pipeline, item)
        end
    end
    function isstage(i) 
        op = i |> first |> string
        startswith(op, '$') && !(op in ["\$or", "\$and"])
    end
    if any(isstage, pipeline)
        pipeline = [ (isstage(i) ? i : +:match=>i) for i in pipeline ]
        if limit > 0
            push!(pipeline, +:limit=>limit)
        end
        showquery && @info "pilrfind" collection pipeline
        c = M.aggregate(collection, bson(pipeline); options=bson(options...))
    else
        if limit > 0
            options = (:limit => limit, options...)
        end
        showquery && @info "pilrfind" collection pipeline options
        c = M.find(collection, bson(pipeline...); options=bson(options...))
    end
    DataFrame(c)
end

pilrfind(db, project_code::AbstractString, dataset_code::AbstractString, query::Union{Pair,AbstractArray}...; kw...) = 
    select!(
        pilrfind(dataset_collection(db, project_code, dataset_code), query...; kw...), 
        Not(Regex("^($( join(Pilr.DEFAULT_REMOVE, '|') ))\$")), :)

#"""
#TODO: document
#"""
#function aggr(collection::M.Collection, item::Union{Pair,Vector{Pair}}, items... ) 
#    pipeline = [
#        (if item isa Vector && startswith(first(item[1]), "\$") 
#            item
#        else
#            [+:match=>el]
#        end) for item in [item, items...]
#    ]
#    M.aggregate( collection, bson(pipeline)) |> DataFrame
#end

end