using Dates, DataFrames, TimeZones, Pilr
import Mongoc as M

"""
Dataset code for use with `dataset_collection`
"""
APP_LOG = "pilrhealth:mobile:app_log"
"""
Dataset code for use with `dataset_collection`
"""
NOTIFICATION_LOG =  "pilrhealth:mobile:notification_log"
"""
Dataset code for use with `dataset_collection`
"""
PARTICIPANT_EVENTS= "pilrhealth:mobile:participant_events"
"""
Dataset code for use with `dataset_collection`
"""
SURVEY_DATA = "pilrhealth:mobile:survey_data"
"""
Dataset code for use with `dataset_collection`
"""
ENCOUNTER = "pilrhealth:mobile:encounter"

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

export dfind
"""
A wrapper around `mfind` with some PiLR data specific enhancements

Post-process the `mfind` result as follows.

* All DateTime values are replaced with a ZonedDateTime *except* for the `localTimestamp` column. 
  If the timezone will be derived from the row's `:metadata!timestamp` and `:localTimestamp` values if 
  they are present.  Otherwize, the timezone will be UTC

"""
function dfind(args...; kw...)
    df = mfind(args...; kw...)
    dtnames = names(df, Union{Missing, Nothing, DateTime})
    transform!(df, 
        AsTable(dtnames) => ByRow(r ->
        begin
            if :localTimestamp in keys(r) && !ismissing(r.localTimestamp)
                dt = round(r.localTimestamp - r.metadata!timestamp, Second)
                zone = FixedTimeZone("", dt.value)
            else
                zone = TimeZones.UTC_ZERO
            end
            #@info zone lt=("localTimestamp" in keys(r)) keys(r)
            d = []
            for f in keys(r) 
                v = getfield(r, f)
                if f == :localTimestamp || !(v isa DateTime)
                    push!(d, f => v)
                else 
                    push!(d, f => ZonedDateTime(v, zone; from_utc=true))
                end
            end
            NamedTuple(d)
        end) => AsTable
        #; renamecols = false
        )
    if ("localTimestamp" in dtnames)
        select!(df, Not(:localTimestamp), :localTimestamp)
    end
    df
end

"""
Columns that are moved to the end of returned DataFrames
"""
NOISE_COLUMNS=[
    :_id, :rawId, :schemaVersion, :dateReceived, :dataSource, :dataSourceId, :dateProcessed, :timestampString, :metadata!id
]

"""
    pilrfind(db, project_code, dataset_code, [ (field=>value)... ]; [kw...])

Short-hand for invoking [`mfind`](@ref) on a PiLR [`dataset_collectiion`](@ref) and [`select`](https://dataframes.juliadata.org/stable/lib/functions/#DataFrames.select@ref)ing
moving nuisance columns to the right.

All other keyword arguments are passed on to 
[`Mongoc.find`](https://felipenoris.github.io/Mongoc.jl/stable/api/#find).

# TODO

- Convert all DateTime columns to ZonedDateTime.  Have option to list fields that are actually local time.

# Examples

```jldoctest test
julia> df = pilrfind(database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]),
                          "base_pilr_ema", APP_LOG,
                          "data.tag" => "SURVEY_QUEUE";
                          :sort=>:_id=>1, :limit=>1)
1×17 DataFrame
 Row │ timestamp                  metadata!pt  data!tag      data!msg          ⋯
     │ ZonedDat…                  String       String        String            ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 2018-01-10T18:39:34-06:00  pb1          SURVEY_QUEUE  Surveys displayed ⋯
                                                              14 columns omitted

```
"""
function pilrfind(db, project_code, dataset_code, query::Pair...; kw...)
    df = mfind(dataset_collection(db, project_code, dataset_code), query...; kw...)
    if nrow(df) == 0
        return df
    end
    cruff = [ :metadata!timestamp, :localTimestamp, :timestampString, Pilr.NOISE_COLUMNS... ]
    pat = Regex("^($( join(cruff, '|') ))\$")
    df.timestamp = pilrZonedTime(df)
    select!(df, :timestamp, Not(pat), :)
end

"""
    pilrZonedTime(row, field = :metadata!timestamp) => ZonedDateTime
    pilrZonedTime(dataframe, field = :metadata!timestamp) => Vector{ZonedDateTime}

Convert a Mongo date field to ZonedDateTime using the metadata!timestamp and localTimestamp to
determine the offset.
"""
function pilrZonedTime(row, field = "metadata!timestamp")
    dt = row.localTimestamp - row.metadata!timestamp
    zone = FixedTimeZone("", getfield(round.(dt, Second), :value))
    ZonedDateTime(row[field], zone; from_utc=true)
end
pilrZonedTime(df::AbstractDataFrame, field = "metadata!timestamp") = map(eachrow(df)) do row
    pilrZonedTime(row)
end
@deprecate pilrZonedTime! pilrshorten!

"""
Add a `ZoneDateTime` `timestamp` column to dataset DataFrame that combines `metadata!timestamp` and `localTimestamp`.
Shorten path names
"""
function pilrshorten!(df::AbstractDataFrame)
    (nrow(df) > 0 && "metadata!timestamp" in names(df)) || return df

    cruff = [ :metadata!timestamp, :localTimestamp, :timestampString, Pilr.NOISE_COLUMNS... ]
    pat = Regex("^($( join(cruff, '|') ))\$")
    df.timestamp = pilrZonedTime(df)
    select!(df, :timestamp, Not(pat), :)
    select!(df, names(df) .=> replace.(names(df), r"^metadata!"=>"m!", r"^data!args!"=>"da!", r"^data!"=>"d!"))
    df
end

 """
     pilrZonedTime(timestamp_with_offset) => ZonedDateTime

Parse a timestamp with offset string to a ZonedDateTime using standard PiLR format

```jldoctest
julia> pilrZonedTime("2021-09-29T11:04:41-04:00")
2021-09-29T11:04:41-04:00
```
 """
function pilrZonedTime(s::AbstractString)
    ZonedDateTime(s, "yyyy-mm-ddTHH:MM:SSzzzz")
end

"""
Parse a timestamp string as with optional "Z" suffix as UTC
"""
function parse_timestamp(utc, zone) #; zone=TimeZones.UTC_ZERO)
    zdt = ZonedDateTime(DateTime(replace(utc, r"Z$" => "", )), tz"UTC")
    astimezone(zdt, zone)
    #DateTime(replace(ts, r"Z$" => "", ))
end


default_projection() = Dict(f=>0 for f in NOISE_COLUMNS)
