module MongoDataFrames

export aggregate, find

using DataFrames: DataFrame
using Pilr: bson
import Mongoc as M

@doc raw"""
    find(collection [ , field => match_expr ]... ; [ , option => value ])

Short-hand syntax for invoking `Mongoc.find` and converting result to a `DataFrame`.

# Example

```jldoctest
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
find(collection::M.AbstractCollection, pairs::Pair...; kw...) where T =
    M.find(collection, bson(pairs...); options=bson(kw)) |> DataFrame

"""
    aggregate(collection, pipeline ; [ , option => value ])

Short-hand syntax for invoking `Mongoc.aggreate` and converting result to a `DataFrame`.

# Example

```jldoctest
julia> using Pilr, Pilr.MongoDataFrames

julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);

julia> aggregate(dataset_collection(db, "base_pilr_ema", SURVEY_DATA),
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
aggregate(collection::M.AbstractCollection, pipeline; kw...) =
    M.aggregate(collection, bson(pipeline); options=bson(kw)) |> DataFrame

end
