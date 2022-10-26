module Pilr

import Mongoc as M

export bson, tomany, toparent
export unflatten
export database, QA, BETA, STAGING, RemoteFile
export dataset_collection, pilrShorten!, pilrZonedTime, pilrZonedTime!, APP_LOG, NOTIFICATION_LOG, PARTICIPANT_EVENTS, SURVEY_DATA
export pilrDataFrame
export remotefile, parse_tomcatlog, parse_nginxlog
export surveyqueue, deviceinfo
export mfind

include("bson.jl")
include("database.jl")
include("mongo_tables.jl")
#include("cursor_tables.jl")
include("MongoDataFrames.jl")
include("remote_file.jl")
include("compliance.jl")

_opts(x::Pair{Symbol}) = bson(x)
_opts(xs::Tuple{Vararg{Pair{Symbol}}}) = bson(xs...)

"""
Create [`Mongoc.BSON`](https://felipenoris.github.io/Mongoc.jl/stable/api/#BSON) arguments from pairs & invoke
[`Mongoc.find`](https://felipenoris.github.io/Mongoc.jl/stable/api/#find)
"""
M.find(collection, pairs::Pair...; options=()) = M.find(collection, bson(pairs...); options=_opts(options))
M.find_one(collection, pairs::Pair...; options=()) = M.find_one(collection, bson(pairs...); options=_opts(options))

include("dataset_collection.jl")

#M.aggregate(collection, pipeline::AbstractVector; flags::M.QueryFlags=M.QUERY_FLAG_NONE) =
#    M.aggregate(collection, bson(pipeline); flags)

end # module Pilr
