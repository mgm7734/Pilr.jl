module Pilr

import Mongoc as M

export bson, O, database, flatdict, CanFlatten, QA, BETA, STAGING, RemoteFile
export dataset_collection, APP_LOG, PARTICIPANT_EVENTS, SURVEY_DATA
export PilrDataFrame

debug(x) = begin println("debug>",x); x end

include("bson.jl")
include("database.jl")
include("mongo_tables.jl")


_opts(x::Pair{Symbol}) = bson(x)
_opts(xs::Tuple{Vararg{Pair{Symbol}}}) = bson(xs...)

M.find(collection, pairs::Pair...; options=()) = M.find(collection, bson(pairs...); options=_opts(options))
M.find_one(collection, pairs::Pair...; options=()) = M.find_one(collection, bson(pairs...); options=_opts(options))

include("dataset_collection.jl")

#M.aggregate(collection, pipeline::AbstractVector; flags::M.QueryFlags=M.QUERY_FLAG_NONE) =
#    M.aggregate(collection, bson(pipeline); flags)

end # module Pilr
