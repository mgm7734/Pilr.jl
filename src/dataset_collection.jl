using Dates, DataFrames, Mongoc, TimeZones, Pilr, Pilr.MongoDataFrames

SURVEY_DATA = "pilrhealth:mobile:survey_data"
APP_LOG = "pilrhealth:mobile:app_log"
PARTICIPANT_EVENTS= "pilrhealth:mobile:participant_events"

@enum DataCollectionKind data rawData deleted

"""
    dataset_collection(db, project_code, dataset_code, [ data | rawData | deleted ])

Return a [`Mongoc.Collection`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Collection) associated with a given PiLR dataset.

# Examples

```jldoctest
julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);

```

"""
function dataset_collection(
    db::M.Database, project_code, dataset_code, kind::Union{DataCollectionKind,AbstractString} = data)

    proj = M.find_one(db["project"], bson(:code=>project_code))
    proj === nothing && error("no project exists with code=$proj")
    dataset = M.find_one(db["dataset"], bson(code=dataset_code, project=proj["_id"]))
    dataset === nothing && error("project $project_code has no dataset with code '$dataset_code' ")
    db["$(dataset["_id"]):$(kind)"]
end

dataset_collection(db::Database, project_code, dataset_code, kind = data) =
    dataset_collection(db.mongo_database, project_code, dataset_code, kind)


# struct PilrDataFrame <: AbstractDataFrame
    # df::DataFrame
# end


DEFAULT_REMOVE=[
    :_id, :rawId, :schemaVersion, :dateReceived, :dataSource, :dataSourceId, :dateProcessed, :timestampString, :metadata!id
]

"""
    pilrDataFrame(db, project_code, dataset_code, [ (field=>value)... ]; [ sort ] [ limit ])

Fetch data froma PiLR dataset and convert it to a DataFrame with optional, common transformations.

A convenience function for invoking
```
Mongoc.find(dataset_collection(...), ...) |> flatdict |> DataFrame
```
with common default projections and conversions.

By default, it will project out the fields listed in `DEFAULT_REMOVE` and convert all DateTime fields to ZonedDateTime.

# Arguments

- `db::Union{Pilr.Database,Mongoc.Database}` - typically the result of [`Pilr.Database`](@ref)
- `filter::Pair

# Keyword arguments

The following options are passed along to `Mongoc.find` with `bson` automatically applied.

- projection
- sort

All other keyword arguments are passed on to [`Mongoc.find`](@ref).

# TODO

- Convert all DateTime columns to ZonedDateTime.  Have option to list fields that are actually local time.

# Examples

```jldoctest
julia> df = pilrDataFrame(database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]),
                          "base_pilr_ema", APP_LOG,
                          "data.tag" => "SURVEY_QUEUE";
                          :sort=>:_id=>1, :limit=>1)
1×8 DataFrame
 Row │ timestamp                  metadata!pt  data!tag      data!msg          ⋯
     │ ZonedDat…                  String       String        String            ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 2018-01-10T18:39:34-06:00  pb1          SURVEY_QUEUE  Surveys displayed ⋯
                                                               5 columns omitted

```
"""
function pilrDataFrame(db, project_code, dataset_code, query::Pair...; kw...)
    if !(:projection in  keys(kw))
        kw = (kw..., :projection=>default_projection())
    end
    df = find(dataset_collection(db, project_code, dataset_code), query...; kw...)
    if nrow(df) == 0
        return df
    end
    dt = df.localTimestamp .- df.metadata!timestamp
    zone = FixedTimeZone.("", getfield.(round.(dt, Second), :value))
    df.timestamp = ZonedDateTime.(df.metadata!timestamp, zone; from_utc=true)
    select!(df, :timestamp, Not([:metadata!timestamp, :localTimestamp]), :)
end

default_projection() = Dict(f=>0 for f in DEFAULT_REMOVE)

#Base.@deprecate PilrDataFrame(args...; kw...) pilrDataFrame(args...; kw...)
