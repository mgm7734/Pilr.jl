using DataStructures
using Dates
using TimeZones

"""
    remotelines(host, path; gunzip=true)

Create an iterator over lines in a remote file.

If the `gunzip` is true and the path ends with ".gz", it will be decompressed.

Intended for use with `parse_tomcatlog` and `parse_nginxlog`;
"""
function remotelines(host, path; gunzip=true) 
    sshopts=split(get(ENV, "SSH_OPTS", ""), "")
    cmds = [`ssh $(host) $(sshopts) "sudo cat $(path)"`]
    if endswith(path, ".gz") && gunzip
        push!(cmds, `zcat`)
    end
    pipeline(cmds...) |> eachline 
end

"""
   parse_tomcatlog(stream) => (servletdf, rawdf)

There are 3 kinds of in the upstart/tomcat.log:

1. Output from the servlet loggers that start with timestamps like "2022-04-29 06:43:44,746" 
2. Output from the tomcat server that start with timestamps like "Apr 29, 2022 9:50:48 AM"
3. Lines without a recognizable timestamp

The 1st kind are returned as rows in `servletdf` with all the fields parsed into columns. [TODO: describe columns]
The `rawdf` has a row for each input line containing the original text plus...[TODO]

# Example

```jldoctest
julia> lines = [
       "2022-09-02 06:44:08,475 [307,ANONYMOUS,login/auth] INFO  pilrhealth.ActivityFilters  - >>",
       "2022-09-02 06:44:08,477 [307,ANONYMOUS,login/auth] INFO  pilrhealth.ActivityFilters  - << action processed in 2 millis"
       ];

julia> parse_tomcatlog(lines)
(2×8 DataFrame
 Row │ reqid     time                           user       action      level   ⋯
     │ Tuple…    ZonedDat…                      SubStrin…  SubStrin…   SubStri ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ (307, 1)  2022-09-02T06:44:08.475-05:00  ANONYMOUS  login/auth  INFO    ⋯
   2 │ (307, 1)  2022-09-02T06:44:08.477-05:00  ANONYMOUS  login/auth  INFO
                                                               4 columns omitted, 2×4 DataFrame
 Row │ id     ref    time                           line                       ⋯
     │ Int64  Int64  ZonedDat…                      String                     ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1      1  2022-09-02T06:44:08.475-05:00  2022-09-02 06:44:08,475 [3 ⋯
   2 │     2      2  2022-09-02T06:44:08.477-05:00  2022-09-02 06:44:08,477 [3
                                                                1 column omitted)
```
"""
function parse_tomcatlog(lines)
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
    for (id, line) in enumerate(lines)
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
    select!(df, :reqid, :time, DataFrames.Not([:date, :worker, :startsreq]))
    df, DataFrame(raw)
end

"""
    parse_nginxlog(lines) => DataFrame

Creates a dataframe from nginx log file lines in NCSA Common Log format.

# Examples

```jldoctest
julia> lines = [
       "54.245.168.29 - - [26/Apr/2022:17:12:11 -0500] \\"GET /login/auth HTTP/1.1\\" 200 5603 \\"-\\" \\"Amazon-Route53-Health-Check-Service (ref b1f0ca2a-3996-40b1-8f2e-6cf7267efa54; report http://amzn.to/1vsZADi)\\"", 
       "128.148.225.62 - - [26/Apr/2022:17:12:12 -0500] \\"POST /project/bluetooth_demo/emaOtsConfig/updateSurveyRules?config=82003&cardstack=Morning_Survey HTTP/1.1\\" 302 0 \\"https://cloud.pilrhealth.com/project/bluetooth_demo/emaOtsConfig/editSurveyRules?config=82003&cardstack=Morning_Survey\\" \\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36\\""
       ];

julia> DataFrames.select(parse_nginxlog(lines), :status, :bytes, DataFrames.Not(:user))
2×7 DataFrame
 Row │ status  bytes  time                       remote_addr     request       ⋯
     │ UInt16  Int64  ZonedDat…                  SubString…      SubString…    ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │    200   5603  2022-04-26T17:12:11-05:00  54.245.168.29   GET /login/au ⋯
   2 │    302      0  2022-04-26T17:12:12-05:00  128.148.225.62  POST /project
                                                               3 columns omitted
```
"""
function parse_nginxlog(lines)
    # 54.245.168.29 - - [26/Apr/2022:17:12:11 -0500] "GET /login/auth HTTP/1.1" 200 5603 "-" "Amazon-Route53-Health-Check-Service (ref b1f0ca2a-3996-40b1-8f2e-6cf7267efa54; report http://amzn.to/1vsZADi)"
    # NCSA Common log format
    #    $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"

    pat = r"^(?<remote_addr>[^ ]+) - (?<user>[^ ]+) \[(?<time>[^\]]+)\] \"(?<request>[^\"]+)\" (?<status>[^ ]+) (?<bytes>[^ ]+) \"(?<referer>[^\"]+)\" \"(?<useragent>[^\"]+)\".*"
    dateformat = dateformat"dd/uuu/yyyy:HH:MM:SS zzzz"

    optstr(x) = x == "-" ? missing : x
    parsers = [
        :time => t -> ZonedDateTime(t, dateformat), 
        :remote_addr => identity, 
        :user => optstr,
        :request => identity, 
        :status => x -> parse(UInt16, x), 
        :bytes => x -> parse(Int, x), 
        :referer => optstr, 
        :useragent => optstr
    ]

    DataFrame([ OrderedDict(k => p(m[string(k)])
                     for m in [match(pat, line)] if m !== nothing
                     for (k, p) in parsers) 
                for line in lines
              ])
end