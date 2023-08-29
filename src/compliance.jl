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
    summary = mfind(db, projectcode, APP_LOG, "data.tag"=>"SURVEY_QUEUE", filter...; kw...)
    nrow(summary) == 0 && error("nothing found for $projectcode $filter")
    summary.timestamp = pilrZonedTime(summary)
    select!(summary,
        :timestamp, :metadata!pt => :pt, #:data!args,
        :data!args=>ByRow(a->
            ["""($(obj["code"]), $(get(obj, "notificationId", missing)))"""
                for item in a 
                for obj in [get(item, "obj", nothing)] if obj !== nothing ]
                #for obj in [get(item, "obj", Dict("code"=>"(none)"))] ]
        )=>:content,
        :localTimestamp,
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
    df = mfind(db, projectcode, APP_LOG, 
            "data.tag"=>+:in=>[ "SYNC", "LOGIN" ], query...,
            limitstage...,
            +:group=>(:_id=>+:metadata!pt, :v=>+:addToSet=>(SETEXPRS...,)),   
            +:unwind=>+:v,
            +:sort=>:metadata!timestamp=>1)
    rename!(df, :v!time=>:time, :v!pt=>:pt, (Symbol("v!$f") => Symbol(f) for f in F)...)
    select!(df, :time, :pt, Not([:_id]))
    sort!(df, :time; rev=false)
    unique!(df, F)
    sort!(df, :time; rev)
    #df.projectcode .= projectcode
    #df
end

export notifications
"""
Notifications that were scheduled when the notification time arrived.
TODO: take LOGOUT into account
"""
function notifications(db, projectcode, filter...)
    @info "" projectcode filter
    summary = dfind(db, projectcode, APP_LOG, 
        :data!tag=>"NOTIFICATION_SUMMARY", filter...
        # ; options = bson(:limit=>500) # for development
    )
    #@info "summary fields:" names(summary)
    select!(summary, :metadata!timestamp => :scheduledat, :metadata!pt, :data!args!scheduled)
    sort!(summary, :scheduledat)

    notifs = combine(groupby(summary, :metadata!pt)) do sdf
        sdf.unscheduledat = vcat(sdf.scheduledat[2:end], [missing])
        notifs = flatten(sdf, :data!args!scheduled)
        #@info "notif fields" names(notifs) maxlog=2
        select!(notifs, 
            :metadata!pt,
            [:data!args!scheduled, :scheduledat]=>ByRow((s,sat)->(
                    notifid=s["notificationId"], 
                    title=s["title"],
                    text=s["text"],
                    notifyat=astimezone(ZonedDateTime(s["scheduleDate"]), timezone(sat)), 
                    expireat=astimezone(ZonedDateTime(s["expireDate"]), timezone(sat)),
                )
             )=>AsTable,
            :scheduledat, :unscheduledat,
        )
    end
    subset!(notifs, [:notifyat, :unscheduledat]=>(n,u) -> ismissing.(u) .|| n .< u)        
end


function notifications2(db, projcode, filter...)
    df = mfind(db, projcode, PARTICIPANT_EVENTS,
            filter...,
            :data!event_type => "notification_requested")
    # groupby(df, [ :metadata!pt, data!args!key  ])
    groupby(df, [ :metadata!pt, :metadata!timestamp,  ])
end

export participant_events
function participant_events(db, projcode, filter...; kw...)
    ptevents = pilrshorten!(mfind(db, projcode, PARTICIPANT_EVENTS, filter...; kw... ))
    
    nrow(ptevents) > 0 || return ptevents

    ptevents.T = map(eachrow(ptevents)) do r
        if r.d!event_type == "notification_requested"
            pilrZonedTime(r.da!notif_time)
        else
            r.timestamp
        end
    end
    transform!(ptevents, :T => ByRow(t->Date.(t)) => :day)
    select!(ptevents, :T, :m!pt, :d!event_type, :d!session, r"survey", r"data!", Not(r"epoch"), :)
    sort!(ptevents, :T)
end

ispresent = (!) ∘ ismissing

export compliance
"""
Initial stab at compliance.

Columns
pt,  day, session, notif_time (ptevent), survey_code,  trigger_code, window_start, #starts, submitted_at, expired_at, error_description

# Enhancements
Did pt miss notifications due to not logging in time?
"""
function compliance(db, project, filter...=())
    ptevents = participant_events(db, project, filter..., 
        :date!event_type=> +:in=> [
            :push_notification, :notification_requested, 
            :survey_started, :survey_submitted, :episode_expired, :episode_error ],
    )
    @info "names" names(ptevents)
    transform!(ptevents, :T => (t->Date.(t)) => :day)

    sessions = filter(groupby(ptevents, :data!session)) do s
        ispresent(s.data!args!survey_code[1]) &&
        s.data!event_type[1] in string.([:push_notification, :notification_requested, :survey_started])
    end

    session_kind = Dict( 
        "push_notification" => "push",
        "notification_requested" => "scheduled",
        "survey_started" => "self")

    combine(sessions) do s
        
        ( pt=s.metdata!pt, s.day, 
          notified_at=Time(s.T),
          kind=session_kind[s.data!event_type[1]], 
          s.survey_code,
          starts=count(==("survey_started"), s.data!event_type),
          submited = any(==("survey_submitted"), s.data!event_type),
          session=s.data!session
        )
    end
end

export apiConsumer
"""
Fetch apiConsumers for a participant
"""
function apiConsumer(db, projcode, ptcode)
    t=dfind(db.project, :code=>projcode, tomany(:project, :participant, :device), :participant!code=>ptcode);
    select(dfind(db.apiConsumer, :_id=>+:in=>t.device!apiConsumer), :accessCode, :)
end