using DataFrames, Dates, TimeZones

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
    proj == nothing && error("no project exists with code=$proj")
    dataset = M.find_one(db["dataset"], bson(code=dataset_code, project=proj["_id"]))
    dataset == nothing && error("project $project_code has no dataset with code '$dataset_code' ")
    db["$(dataset["_id"]):$(kind)"]
end

dataset_collection(db::Database, project_code, dataset_code, kind = data) =
    dataset_collection(db.mongo_database, project_code, dataset_code, kind)


struct PilrDataFrame <: AbstractDataFrame
    df::DataFrame
end


DEFAULT_REMOVE=[
    :_id, :rawId, :schemaVersion, :dateReceived, :dataSource, :dataSourceId, :dateProcessed, :timestampString, "metadata.id"
]

"""
    PilrDataFrame(db, project_code, dataset_code, [ filter... ]; [ sort ] [ limit ])

# TODO

- Convert all DateTime columns to ZonedDateTime.  Have option to list fields that are actually local time.

# Examples

```jldoctest
julia> df = PilrDataFrame(database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]),
                          "base_pilr_ema", APP_LOG,
                          "data.tag" => "SURVEY_QUEUE";
                          sort=:_id=>1, limit=1)
1×8 DataFrame
 Row │ timestamp                  metadata!pt  data!tag      data!msg          ⋯
     │ ZonedDat…                  String       String        String            ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 2018-01-10T18:39:34-06:00  pb1          SURVEY_QUEUE  Surveys displayed ⋯
                                                               5 columns omitted

```
"""
function PilrDataFrame(db, project_code, dataset_code, query::Pair...=[] ;
                       projection=Dict(f=>0 for f in DEFAULT_REMOVE),
                       kw...)
    options = bson(:projection => projection, kw...)
    df = M.find(dataset_collection(db, project_code, dataset_code), bson(query...); options) |>
        flatdict |> DataFrame
    dt = df.localTimestamp .- df.metadata!timestamp
    zone = FixedTimeZone.("", getfield.(round.(dt, Second), :value))
    df.timestamp = ZonedDateTime.(df.metadata!timestamp, zone; from_utc=true)
    select!(df, :timestamp, DataFrames.Not([:metadata!timestamp, :localTimestamp]), :)
end
