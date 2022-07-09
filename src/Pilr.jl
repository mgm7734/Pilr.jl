module Pilr

import Mongoc as M

export bson, O, database, dataset_collection, flatdict, CanFlatten, QA, BETA, STAGING, RemoteFile

debug(x) = begin println("debug>",x); x end

include("bson.jl")
include("database.jl")
include("dataset_collection.jl")
include("mongo_tables.jl")


_opts(x::Pair{Symbol}) = bson(x)
_opts(xs::Tuple{Vararg{Pair{Symbol}}}) = bson(xs...)

M.find(collection, pairs::Pair...; options=()) = M.find(collection, bson(pairs...); options=_opts(options))
M.find_one(collection, pairs::Pair...; options=()) = M.find_one(collection, bson(pairs...); options=_opts(options))
end # module Pilr
