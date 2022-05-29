module Pilr

import Mongoc as M

export bson, O, database, dataset_collection, flatdict, CanFlatten, QA, BETA, STAGING, RemoteFile

debug(x) = begin println("debug>",x); x end

include("bson.jl")
include("database.jl")
include("dataset_collection.jl")
include("mongo_tables.jl")

end # module Pilr
