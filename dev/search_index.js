var documenterSearchIndex = {"docs":
[{"location":"mongo/#Mongo","page":"Mongo","title":"Mongo","text":"","category":"section"},{"location":"mongo/","page":"Mongo","title":"Mongo","text":"Pages = [\"mongo.md\"]","category":"page"},{"location":"mongo/#API-Reference","page":"Mongo","title":"API Reference","text":"","category":"section"},{"location":"mongo/","page":"Mongo","title":"Mongo","text":"Modules = [Pilr]\nOrder   = [:function, :constant, :type]","category":"page"},{"location":"mongo/#Base.getproperty-Tuple{Pilr.Database, Symbol}","page":"Mongo","title":"Base.getproperty","text":"Overload property access as shortcut for collections.\n\ndb.project == db[\"project\"]\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Mongoc.find-Tuple{Any, Vararg{Pair}}","page":"Mongo","title":"Mongoc.find","text":"Create Mongoc.BSON arguments from pairs & invoke Mongoc.find\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.bson-Tuple{}","page":"Mongo","title":"Pilr.bson","text":"bson(pair...) => Mongoc.BSON\nbson(AbstractVector{pair}) => Vector{Mongoc.BSON}\n\nConstruct a BSON object using keyword arguments or pairs to reduce quote clutter.\n\nTime Zone Warning\n\nTLDR: TimeZones.now(localzone()) when inserting into Mongo. Use ZonedDateTime whenever you need to create a TimeType.\n\nJava, Javscript and Mongodb Date objects all represent milliseconds since the Unix epoch (Jan 1, 1970). Julia DateTime do not. They are a wrapper around a calendar date and clock time.\n\nThis is not a problem if you read a DateTime from Mongo, calculate with it and write it back out.  Your implied TimeZone will be UTC.\n\nHowever, if you write Dates.now() to a mongo field, it will be wrong.\n\nbson will correctly convert ZonedDateTime objects to a DateTime in UTC.\n\nIn PiLR dataset terms, \n\nDateTime(metadata!timestamp::ZonedDateTime) == localTimestamp\nDateTime(metadata!timestamp::ZonedDateTime, UTC) == metadata!timestamp == bson(metadata!timestamp::ZonedDateTime)`\n\nRepresenting BSON keys with a Julia Symbol\n\njulia> bson(:metadata!pt => \"mei01\")\nMongoc.BSON with 1 entry:\n  \"metadata.pt\" => \"mei01\"\n\nSymbols are converted to strings. Embeded \"!' characters are converted to \".\" so you can write  :metadata!pt instead of \"metadata.pt\".   [This makes data frame columns of flattened result into valid Julia identifiers.]\n\nExamples\n\njulia> bson(:metadata!pt => r\"^mei.*1$\", :project => +:in => [\"proj1\", \"proj2\"])\nMongoc.BSON with 2 entries:\n  \"metadata.pt\" => Dict{Any, Any}(\"\\$regex\"=>\"^mei.*1\\$\")\n  \"project\"     => Dict{Any, Any}(\"\\$in\"=>Any[\"proj1\", \"proj2\"])\n\njulia> bson([\n         +:match => :type=>\"SUBMIT\", \n         +:group => (:_id=>+:pt, :N=>+:sum=>1)\n       ])\nMongoc.BSON with 2 entries:\n  \"0\" => Dict{Any, Any}(\"\\$match\"=>Dict{Any, Any}(\"type\"=>\"SUBMIT\"))\n  \"1\" => Dict{Any, Any}(\"\\$group\"=>Dict{Any, Any}(\"_id\"=>\"\\$pt\", \"N\"=>Dict{Any,…\njulia> bson(a=1, b=2)\nMongoc.BSON with 2 entries:\n  \"a\" => 1\n  \"b\" => 2\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.compliance-Tuple{Any, Any, Vararg{Any}}","page":"Mongo","title":"Pilr.compliance","text":"Initial stab at compliance.\n\nColumns pt,  day, session, notiftime (ptevent), surveycode,  triggercode, windowstart, #starts, submittedat, expiredat, error_description\n\nEnhancements\n\nDid pt miss notifications due to not logging in time?\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.compressed_survey_data-Tuple{Any, Any, Any, Vararg{Pair}}","page":"Mongo","title":"Pilr.compressed_survey_data","text":"compressed_results(db, projectcode, surveycode, [ field => queryexpr ]... [ ; mongo_find_options...]) -> DataFrame\n\nCreate a PiLR compressed [aka \"unstacked\", \"wide\"] survey result.\n\nExample\n\nCSV.write(\"daily_ema.csv\", compressed_survey_data(db, jit, \"Daily_EMA\", :metadata!pt=>\"test08\"))\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.database-Tuple{Any, Any, Any}","page":"Mongo","title":"Pilr.database","text":"database(jenkins_user, db_name, db_password [, localport = 29030]) => Database\ndatabase(mongodb_url)\n\nReturn a Database connection.\n\nThe first form uses an ssh tunnel to PiLR's mongodb server.\n\nThe second form uses a standard mongo URL \"mongodb://user:password@host[:port]/db\".   If running inside the firewall, replset URIs are supprted.\n\nOptions\n\nssh_opts::AbstractVector{String}: extra arguments for the ssh tunnel command. Example: [\"-Fnone\", \"\"-i/home/me/.ssh/alt_rsa\"]\n\nExamples\n\njulia> db = database(\"mmendel\", \"mei-s4r-qa\", ENV[\"MONGO_PASSWORD\"]) [...]\n\njulia> import Mongoc\n\njulia> Mongoc.count_documents(db[\"project\"]) 1056\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.dataset_collection","page":"Mongo","title":"Pilr.dataset_collection","text":"dataset_collection(db, project_code, dataset_code, [ data | rawData | deleted ])\n\nReturn a Mongoc.Collection associated with a given PiLR dataset.\n\nExamples\n\njulia> db = database(ENV[\"JENKINS_USER\"], QA, ENV[\"MONGO_PASSWORD\"]);\n\n\n\n\n\n\n","category":"function"},{"location":"mongo/#Pilr.dfind-Tuple","page":"Mongo","title":"Pilr.dfind","text":"A wrapper around mfind with some PiLR data specific enhancements\n\nPost-process the mfind result as follows.\n\nAll DateTime values are replaced with a ZonedDateTime except for the localTimestamp column.  If the timezone will be derived from the row's :metadata!timestamp and :localTimestamp values if  they are present.  Otherwize, the timezone will be UTC\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.download_all_datasets-Tuple{Any, Any}","page":"Mongo","title":"Pilr.download_all_datasets","text":"Download all datasets for a project and range of days\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.download_dataset-Tuple{Any, Any, Any, Vararg{Any}}","page":"Mongo","title":"Pilr.download_dataset","text":"Download all data for a given project, dataset, and range of full days\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.flatten_dicts-Tuple{Any}","page":"Mongo","title":"Pilr.flatten_dicts","text":"flatten_dicts(cursor ; [separator = \"!\"])\n\nConvert an iterable of nested Dict{String,Any} (such as a Cursor returned by Mongoc.find) into a dictonary of equal length columns.\n\nThe returned dictionary can be converted to a DataFrame.\n\nEach field value that is a dictionary is replaced a field for every entry. The field names are the path.\n\nUsing \"!\" does not require quoting in Symbol names, so you can type :metadata!pt instead of \"metadata.pt\".\n\nOption Arguments\n\nseparator : path separator for flattened column names. \n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.lookup-Tuple{Any, Any}","page":"Mongo","title":"Pilr.lookup","text":"Construct lookup and optional unwind stages for a pipeline.\n\nThe defaults work for a to-many relation where the child collection's foreign key is the parent collection name.  \n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.mfind-Tuple{Mongoc.AbstractCollection, Vararg{Union{AbstractArray, Pair}}}","page":"Mongo","title":"Pilr.mfind","text":"mfind(collection, queryitem...; limit=0, option...)\nmfind(database, project_code, dataset_code, queritem...; limit=0, option...)\n\nQuery mongodb with a powerful short-hand syntax and return a dataframe.\n\nEach queryitem can be a Pair or vector of pairs using bson syntax.\n\nThe vectors are flattened so you don't need ... after tomany[@ref].  \n\nIf any item looks like a pipeline stage (starts with '$(Expr(:incomplete, \"incomplete: invalid character literal\"))\n\nExamples\n\njulia> db = database(\"mmendel\",QA);\n\njulia> mfind(db.project, :code=>+:regex=>\"^test\"; :limit=>1, :skip=>1)\n1×12 DataFrame\n Row │ active  code    dateCreated              isDeleted  lastUpdated         ⋯\n     │ Bool    String  DateTime                 Bool       DateTime            ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │   true  test2   2015-01-12T17:28:50.481      false  2015-01-12T17:28:50 ⋯\n                                                               8 columns omitted\njulia> configs = mfind(db.project, \n         :code=>+:regex=>\"^test\",\n         tomany(\"project\", \"instrument\", \"instrumentConfig\"; skipmissing=true)\n         ; limit=3);\n\njulia> configs[!, [:name, :instrumentConfig!name]]\n3×2 DataFrame\n Row │ name            instrumentConfig!name \n     │ String          String                \n─────┼───────────────────────────────────────\n   1 │ Test Run        Protocol 1 Config\n   2 │ Test James 102  test config #asdf\n   3 │ Test Import     Branching Example\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.notifications-Tuple{Any, Any, Vararg{Any}}","page":"Mongo","title":"Pilr.notifications","text":"Notifications that were scheduled when the notification time arrived. TODO: take LOGOUT into account\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.parse_nginxlog-Tuple{Any}","page":"Mongo","title":"Pilr.parse_nginxlog","text":"parse_nginxlog(lines) => DataFrame\n\nCreates a dataframe from nginx log file lines in NCSA Common Log format.\n\nExamples\n\njulia> lines = [\n       \"54.245.168.29 - - [26/Apr/2022:17:12:11 -0500] \\\"GET /login/auth HTTP/1.1\\\" 200 5603 \\\"-\\\" \\\"Amazon-Route53-Health-Check-Service (ref b1f0ca2a-3996-40b1-8f2e-6cf7267efa54; report http://amzn.to/1vsZADi)\\\"\", \n       \"128.148.225.62 - - [26/Apr/2022:17:12:12 -0500] \\\"POST /project/bluetooth_demo/emaOtsConfig/updateSurveyRules?config=82003&cardstack=Morning_Survey HTTP/1.1\\\" 302 0 \\\"https://cloud.pilrhealth.com/project/bluetooth_demo/emaOtsConfig/editSurveyRules?config=82003&cardstack=Morning_Survey\\\" \\\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36\\\"\"\n       ];\n\njulia> DataFrames.select(parse_nginxlog(lines), :status, :bytes, DataFrames.Not(:user))\n2×7 DataFrame\n Row │ status  bytes  time                       remote_addr     request       ⋯\n     │ UInt16  Int64  ZonedDat…                  SubString…      SubString…    ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │    200   5603  2022-04-26T17:12:11-05:00  54.245.168.29   GET /login/au ⋯\n   2 │    302      0  2022-04-26T17:12:12-05:00  128.148.225.62  POST /project\n                                                               3 columns omitted\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.parse_timestamp-Tuple{Any, Any}","page":"Mongo","title":"Pilr.parse_timestamp","text":"Parse a timestamp string as with optional \"Z\" suffix as UTC\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.parse_tomcatlog-Tuple{Any}","page":"Mongo","title":"Pilr.parse_tomcatlog","text":"parse_tomcatlog(stream) => (servletdf, rawdf)\n\nThere are 3 kinds of in the upstart/tomcat.log:\n\nOutput from the servlet loggers that start with timestamps like \"2022-04-29 06:43:44,746\" \nOutput from the tomcat server that start with timestamps like \"Apr 29, 2022 9:50:48 AM\"\nLines without a recognizable timestamp\n\nThe 1st kind are returned as rows in servletdf with all the fields parsed into columns. [TODO: describe columns] The rawdf has a row for each input line containing the original text plus...[TODO]\n\nExample\n\njulia> lines = [\n       \"2022-09-02 06:44:08,475 [307,ANONYMOUS,login/auth] INFO  pilrhealth.ActivityFilters  - >>\",\n       \"2022-09-02 06:44:08,477 [307,ANONYMOUS,login/auth] INFO  pilrhealth.ActivityFilters  - << action processed in 2 millis\"\n       ];\n\njulia> parse_tomcatlog(lines)\n(2×8 DataFrame\n Row │ reqid     time                           user       action      level   ⋯\n     │ Tuple…    ZonedDat…                      SubStrin…  SubStrin…   SubStri ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │ (307, 1)  2022-09-02T06:44:08.475-05:00  ANONYMOUS  login/auth  INFO    ⋯\n   2 │ (307, 1)  2022-09-02T06:44:08.477-05:00  ANONYMOUS  login/auth  INFO\n                                                               4 columns omitted, 2×4 DataFrame\n Row │ id     ref    time                           line                       ⋯\n     │ Int64  Int64  ZonedDat…                      String                     ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1      1  2022-09-02T06:44:08.475-05:00  2022-09-02 06:44:08,475 [3 ⋯\n   2 │     2      2  2022-09-02T06:44:08.477-05:00  2022-09-02 06:44:08,477 [3\n                                                                1 column omitted)\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.pilrZonedTime","page":"Mongo","title":"Pilr.pilrZonedTime","text":"pilrZonedTime(row, field = :metadata!timestamp) => ZonedDateTime\npilrZonedTime(dataframe, field = :metadata!timestamp) => Vector{ZonedDateTime}\n\nConvert a Mongo date field to ZonedDateTime using the metadata!timestamp and localTimestamp to determine the offset.\n\n\n\n\n\n","category":"function"},{"location":"mongo/#Pilr.pilrZonedTime-Tuple{AbstractString}","page":"Mongo","title":"Pilr.pilrZonedTime","text":" pilrZonedTime(timestamp_with_offset) => ZonedDateTime\n\nParse a timestamp with offset string to a ZonedDateTime using standard PiLR format\n\njulia> pilrZonedTime(\"2021-09-29T11:04:41-04:00\")\n2021-09-29T11:04:41-04:00\n\n\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.pilrfind-Tuple{Any, Any, Any, Vararg{Pair}}","page":"Mongo","title":"Pilr.pilrfind","text":"pilrfind(db, project_code, dataset_code, [ (field=>value)... ]; [kw...])\n\nShort-hand for invoking mfind on a PiLR dataset_collectiion and selecting moving nuisance columns to the right.\n\nAll other keyword arguments are passed on to  Mongoc.find.\n\nTODO\n\nConvert all DateTime columns to ZonedDateTime.  Have option to list fields that are actually local time.\n\nExamples\n\njulia> df = pilrfind(database(ENV[\"JENKINS_USER\"], QA, ENV[\"MONGO_PASSWORD\"]),\n                          \"base_pilr_ema\", APP_LOG,\n                          \"data.tag\" => \"SURVEY_QUEUE\";\n                          :sort=>:_id=>1, :limit=>1)\n1×17 DataFrame\n Row │ timestamp                  metadata!pt  data!tag      data!msg          ⋯\n     │ ZonedDat…                  String       String        String            ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │ 2018-01-10T18:39:34-06:00  pb1          SURVEY_QUEUE  Surveys displayed ⋯\n                                                              14 columns omitted\n\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.pilrshorten!-Tuple{DataFrames.AbstractDataFrame}","page":"Mongo","title":"Pilr.pilrshorten!","text":"Add a ZoneDateTime timestamp column to dataset DataFrame that combines metadata!timestamp and localTimestamp. Shorten path names\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.remotelines-Tuple{Any, Any}","page":"Mongo","title":"Pilr.remotelines","text":"remotelines(host, path; gunzip=true)\n\nCreate an iterator over lines in a remote file.\n\nIf the gunzip is true and the path ends with \".gz\", it will be decompressed.\n\nIntended for use with parse_tomcatlog and parse_nginxlog;\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.shorten_paths-Tuple{Any}","page":"Mongo","title":"Pilr.shorten_paths","text":"Collapse nested object paths into short unique names.\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.surveyqueue-Tuple{Any, Any, Vararg{Pair}}","page":"Mongo","title":"Pilr.surveyqueue","text":"surveyqueue(db, projectcode, field=>bsonquery... [ ; mongo_find_options...])\n\nCreate a dataframe from matching applog tag=SURVEYQUEUE entries.\n\nShows timestamped values of what a participant sees in their survey queue whenever EMA recalculates it.\n\nExample\n\njulia> surveyqueue(db, projcode, \"metadata.pt\"=>\"278\", \"metadata.timestamp\"=>\"$gt\"=>t)\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.tomany-Tuple{Any, Vararg{Any}}","page":"Mongo","title":"Pilr.tomany","text":"tomany(parent, children...)\n\nConstruct a pipeline traversing a chain of to-many relations\n\nExamples\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.toparent-Tuple","page":"Mongo","title":"Pilr.toparent","text":"toparent(key...; skipmissing=false)\n\nJoin with a chain of parents specified by the keys. o\n\nExamples\n\nmfind(db.participant, toparent(:project))\nmfind(db.trigger. topparent(:configuration => :instrumentConfig))\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.unflatten-Tuple{Any}","page":"Mongo","title":"Pilr.unflatten","text":"unflatten(row)\nunflatten(::Vector{row})\nunflatten(::AbstractDataFrame)\n\nConvert flattened mongo docs to its original shape\n\n\n\n\n\n","category":"method"},{"location":"mongo/#Pilr.APP_LOG","page":"Mongo","title":"Pilr.APP_LOG","text":"Dataset code for use with dataset_collection\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.ENCOUNTER","page":"Mongo","title":"Pilr.ENCOUNTER","text":"Dataset code for use with dataset_collection\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.NOISE_COLUMNS","page":"Mongo","title":"Pilr.NOISE_COLUMNS","text":"Columns that are moved to the end of returned DataFrames\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.NOTIFICATION_LOG","page":"Mongo","title":"Pilr.NOTIFICATION_LOG","text":"Dataset code for use with dataset_collection\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.PARTICIPANT_EVENTS","page":"Mongo","title":"Pilr.PARTICIPANT_EVENTS","text":"Dataset code for use with dataset_collection\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.SURVEY_DATA","page":"Mongo","title":"Pilr.SURVEY_DATA","text":"Dataset code for use with dataset_collection\n\n\n\n\n\n","category":"constant"},{"location":"mongo/#Pilr.Database","page":"Mongo","title":"Pilr.Database","text":"Wrap a Mongoc.Database and a Mongoc.Client\n\n\n\n\n\n","category":"type"},{"location":"#Pilr.jl-Documentation","page":"Home","title":"Pilr.jl Documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Tools for accessing and analyzing PiLR data.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This is a hodge-podge set of tools for pulling data from Mongodb & PiLR log files into DataFrames to leverage Julia's analysis tools.","category":"page"},{"location":"#Install","page":"Home","title":"Install","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pilr is not a registered Julia package, so you must use the github URL to install it:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using Pkg; Pkg.add(\"https://github.com/mgm7734/Pilr.jl\");","category":"page"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"database returns a Pilr.Database connected to a PiLR Mongo database via a tunnel.  It is mostly a wrapper for Mongoc.Database.\njulia> using Pilr\n\njulia> db = database(ENV[\"JENKINS_USER\"], QA, ENV[\"MONGO_PASSWORD\"]);\nPilr provides an implementation of the Tables.jl interface for Mongoc.Cursor. This lets you do things like constructing a DataFrame directly from a query:\njulia> using DataFrames, Mongoc\n\njulia> DataFrame(Mongoc.find(db.project; options=Mongoc.BSON(\"\"\"{\"limit\": 1}\"\"\")))\n1×12 DataFrame\n Row │ _id                       active  code    dateCreated              isDe ⋯\n     │ String                    Bool    String  DateTime                 Bool ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │ 549513b2e4b0b40e50e6527d    true  test1   2014-12-20T06:14:10.810       ⋯\n                                                               8 columns omitted\ndataset_collection returns the Mongoc.Collection for a give project and dataset code. You rarely need to use it directly, though, since mfind(db, projectcode, datasetcode, query...) uses it under the hood.\nbson implements a concise syntax for generating Mongoc.BSON queries with much less puncuation.\nmfind accepts bson syntax, invokes Mongoc.find or Mongoc.aggregate as needed,  then returns a DataFrame.\nunflatten reverses the conversion performed by Pilr's Tables implementation, converting a DataFrame or DataFrameRow  back into the original Mongoc.BSON object. You'll need this to write data to Mongodb.\nConversions between PiLR & Mongodb date-time representations to ZonedDateTime or DateTime (for local date-times).","category":"page"},{"location":"#Examples","page":"Home","title":"Examples","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"julia> proj = mfind(db.project, :code=>\"base_pilr_ema\");\n\njulia> mfind(db, proj.code[1], SURVEY_DATA,\n                   :data!event_type => \"survey_submitted\", # `+:match=>` optional\n                   +:limit => 1000,\n                   +:group => (:_id => +:metadata!pt,\n                               :surveys_submitted => +:sum => 1,\n                               :t => +:max => +:metadata!timestamp),\n                   ; limit=5\n                 )\n5×3 DataFrame\n Row │ surveys_submitted  t                    _id         \n     │ Int64              DateTime             String      \n─────┼─────────────────────────────────────────────────────\n   1 │                 7  2022-06-08T12:22:05  mei01\n   2 │                14  2021-10-14T15:42:12  amios-01\n   3 │                 2  2022-04-20T16:27:50  sbmeitest01\n   4 │                 1  2021-03-16T19:29:57  pb112020\n   5 │                15  2021-02-01T05:09:47  amandroid","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can use Mongoc functions directly.  Pilr implements the Tables.jl interface for Mongoc.Cursor.","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using DataFrames, Mongoc\n\njulia> Mongoc.find(db.project, bson(:code=>\"base_pilr_ema\")) |> DataFrame\n1×21 DataFrame\n Row │ _id                       autoRegistrationEnabled  code           dateC ⋯\n     │ String                    Bool                     String         DateT ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │ 58827b04e4b0507240a4e127                    false  base_pilr_ema  2017- ⋯\n                                                              18 columns omitted","category":"page"},{"location":"#main-index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"mongo.md\"]","category":"page"}]
}
