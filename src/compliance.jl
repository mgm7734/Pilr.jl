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
    summary = pilrfind(db, projectcode, APP_LOG, "data.tag"=>"SURVEY_QUEUE", filter...; kw...)
    nrow(summary) == 0 && error("nothing found for $projectcode $filter")
    select!(summary,
        :metadata!timestamp, :metadata!pt, #:data!args,
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

"""
Notifications that were scheduled when the notification time arrived.
TODO: take LOGOUT into account
"""
function notifications(db, projectcode, filter...)
    @info "" projectcode filter
    summary = pilrDataFrame(db, projectcode, APP_LOG, 
        "data.tag"=>"NOTIFICATION_SUMMARY", filter...
        # ; options = bson(:limit=>500) # for development
    )
    #@info "summary fields:" names(summary)
    select!(summary, AsTable(:) => ByRow(pilrZonedTime) => :timestamp, :metadata!pt, :data!args!scheduled)
    sort!(summary, :timestamp)

    transform!(summary, :timestamp=>:scheduledat)

    notifs = combine(groupby(summary, :metadata!pt)) do sdf
        sdf.unscheduledat = vcat(sdf.scheduledat[2:end], [missing])
        notifs = flatten(sdf, :data!args!scheduled)
        #@info "notif fields" names(notifs) maxlog=2
        select!(notifs, 
            :metadata!pt,
            [:data!args!scheduled, :scheduledat]=>ByRow((s,sat)->(
                    notifid=s["notificationId"], 
                    notifyat=parse_timestamp(s["scheduleDate"], timezone(sat)), 
                    expireat=parse_timestamp(s["expireDate"], timezone(sat)))
             )=>AsTable,
            :scheduledat, :unscheduledat,
        )
    end
    subset!(notifs, [:notifyat, :unscheduledat]=>(n,u) -> ismissing.(u) .|| n .< u)        
end

function parse_timestamp(utc, zone) #; zone=TimeZones.UTC_ZERO)
    zdt = ZonedDateTime(DateTime(replace(utc, r"Z$" => "", )), tz"UTC")
    astimezone(zdt, zone)
    #DateTime(replace(ts, r"Z$" => "", ))
end

function notifications2(db, projcode, filter...)
    df = pilrfind(db, projcode, PARTICIPANT_EVENTS,
            filter...,
            :data!event_type => "notification_requested")
    # groupby(df, [ :metadata!pt, data!args!key  ])
    groupby(df, [ :metadata!pt, :metadata!timestamp,  ])
end