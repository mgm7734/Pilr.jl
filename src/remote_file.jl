using Dates
using TimeZones

#=
struct RemoteFile
    host::String
    path::String
    cachedir::String
end

function RemoteFile(host, path; cachedir = "$(ENV["HOME"])/.cache/pilr-remotefile", ignorecache=false)
    self = RemoteFile(host, path, cachedir)
    localpath = cachepath(self)
    if ignorecache || !isfile(localpath)
        mkpath(dirname(localpath))
        println("DEBUG>>> ssh $host sudo cat $path")
        run(pipeline(`ssh $host "sudo cat $path"`, stdout=localpath))
    end
    self
end

cachepath(r::RemoteFile) = joinpath(r.cachedir, r.host, basename(r.path))

=#
"""
    remotefile(host, path; gunzip=true) -> IO

# Examples

```
julia> x=Pilr.remotefile("qa", "/var/log/upstart/tomcat.log");

julia> first(readlines(x), 5)
5-element Vector{String}:
 "2022-09-03 07:19:23,588 [495,AN" ⋯ 34 bytes ⋯ "ilrhealth.ActivityFilters  - >>"
 "2022-09-03 07:19:23,589 [496,AN" ⋯ 34 bytes ⋯ "ilrhealth.ActivityFilters  - >>"
 "2022-09-03 07:19:23,592 [497,AN" ⋯ 34 bytes ⋯ "ilrhealth.ActivityFilters  - >>"
 "2022-09-03 07:19:23,596 [498,AN" ⋯ 34 bytes ⋯ "ilrhealth.ActivityFilters  - >>"
 "2022-09-03 07:19:23,603 [499,AN" ⋯ 34 bytes ⋯ "ilrhealth.ActivityFilters  - >>"
```
"""
function remotefile(host, path; gunzip=true) 
    sshopts=split(get(ENV, "SSH_OPTS", ""), "")
    cmds = [`ssh $(host) $(sshopts) "sudo cat $(path)"`]
    if endswith(path, ".gz") && gunzip
        push!(cmds, `zcat`)
    end
    pipeline(cmds...)
end

"""
   parse_tomcatlog(stream) => (servletdf, rawdf)

There are 3 kinds of in the upstart/tomcat.log:

1. Output from the servlet loggers that start with timestamps like "2022-04-29 06:43:44,746" 
2. Output from the tomcat server that start with timestamps like "Apr 29, 2022 9:50:48 AM"
3. Lines without a recognizable timestamp

The 1st kind are returned as rows in `servletdf` with all the fields parsed into columns. [TODO: describe columns]
The `rawdf` has a row for each input line containing the original text plus...[TODO]
"""
function parse_tomcatlog(stream::IO)
    parseTime(str, dateformat) = ZonedDateTime(DateTime(str, dateformat), tz"America/Chicago")
    
    # 2022-04-29 06:43:44,746 [315,ANONYMOUS,login/auth] INFO  pilrhealth.ActivityFilters  - >>
    webapppat = r"^(?<date>\d\d\d\d-\d\d-\d\d [^,]+,\d\d\d) \[(?<worker>[^,]+),(?<user>[^,]+),(?<action>[^\]]+)\] (?<level>\w+) +(?<logger>\S+) +- (?<text>.*)" 
    webappfmt = dateformat"yyyy-mm-dd HH:MM:SS,sss"

    # Apr 29, 2022 9:50:48 AM org.apache.catalina.startup.Catalina load
    tomcatpat  = r"^(?<date>(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d+, \d{4}.* (AM|PM)) (?<rest>.*)" 
    tomcatfmt = dateformat"uuu dd, yyyy HH:MM:SS pp"
    
    function pushcolval!(d, c::Symbol, v) 
        if (c in [:id, :ref, :worker] && v isa AbstractString)
            v = parse(Int, v)
        end
        t = get(d,c, typeof(v)[])
        push!(get!(d,c, t), v)
    end
    pushcolval!(d, c::AbstractString, v) = pushcolval!(d, Symbol(c), v)
    
    webapp = OrderedDict()
    raw = OrderedDict()
    ref = 0
    for (id, line) in enumerate(eachline(stream))
        local m = nothing
        try
            if (m = match(webapppat, line)) !== nothing
                ref = id
                time = parseTime(m["date"], webappfmt)
                for c in keys(m)
                    pushcolval!(webapp, c, m[c])
                end
                pushcolval!(webapp, :id, id)
                pushcolval!(webapp, :time, time)
            elseif (m = match(tomcatpat, line)) !== nothing
                ref = id
                time = parseTime(m["date"], tomcatfmt)
            else
                # Lines w/o timestamp will use the id of the previous timestamp line (ref) 
                time = raw[:time][end]
            end
            pushcolval!(raw, :id, id)
            pushcolval!(raw, :ref, ref)
            pushcolval!(raw, :time, time)
            pushcolval!(raw, :line, line)
        catch e
            display((err=e, m, id, line))
            display(raw)
            rethrow(e)
        end
    end
    df = DataFrame(webapp)
    df.startsreq = [(text == ">>" ? 1 : 0) for text in df.text]
    df = combine(groupby(df, :worker)) do sdf
        t = transform(sdf, [:worker, :startsreq]=>((w,s)->tuple.(w, cumsum(s)))=>:reqid)
    end
    select!(df, :reqid, :time, Not([:date, :worker, :startsreq]))
    df, DataFrame(raw)
end

parse_tomcatlog(cmd::Base.AbstractCmd) = cmd |> open |> parse_tomcatlog