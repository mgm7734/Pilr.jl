"""
    surveyqueue(db, projectcode, field=>bsonquery... [ ; mongo_find_options...])

Create a dataframe from matching app_log tag=SURVEY_QUEUE entries.

Shows timestamped values of what a participant sees in their survey queue whenever EMA recalculates it.

# Example

```
julia> surveyqueue(db, projcode, "metadata.pt"=>"278", "metadata.timestamp"=>"\$gt"=>t)
```

"""
function surveyqueue(db, projectcode, filter::Pair... = []; kw...)
    summary = pilrDataFrame(db, projectcode, APP_LOG, "data.tag"=>"SURVEY_QUEUE", filter...; kw...)
    select!(summary,
        :timestamp, :metadata!pt, #:data!args,
        :data!args=>ByRow(a->
            [(trigger=obj["code"], 
              notifId=get(obj, "notificationId", missing) )
                for item in a 
                for obj in [get(item, "obj", Dict("code"=>"(none)"))] ]
        )=>:content
    )
end

function deviceinfo(db, projectcode, query::Pair{Symbol}... = (); limit = nothing, rev = true)
    F = ["app_version", "platform", "os_version", "device", "git"]
    SETEXPRS = [
        :time=>+:metadata!timestamp, 
        :pt=>+:metadata!pt,
        (f => "\$data.args.$f" for f in F)...
    ]
    limitstage = limit === nothing ? [] : [ +:limit=>limit ]
    df = M.aggregate(dataset_collection(db, projectcode, APP_LOG), bson([
            +:match=>("data.tag"=>+:in=>[ "SYNC", "LOGIN" ], query...),
            limitstage...,
            +:group=>(:_id=>+:metadata!pt, :v=>+:addToSet=>(SETEXPRS...,)),   
            +:unwind=>+:v,
            +:sort=>:metadata!timestamp=>1
            ])
        ) |> flatdict |> DataFrame
    rename!(df, :v!time=>:time, :v!pt=>:pt, (Symbol("v!$f") => Symbol(f) for f in F)...)
    select!(df, :time, :pt, Not([:_id]))
    sort!(df, :time; rev=false)
    unique!(df, F)
    sort!(df, :time; rev)
end
