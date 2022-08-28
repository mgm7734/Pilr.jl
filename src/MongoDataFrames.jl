module MongoDataFrames

export find

using DataFrames: DataFrame
using Pilr: bson
import Mongoc as M

find(collection, pairs::Pair...; kw...) where T =
    M.find(collection, bson(pairs...); options=bson(kw)) |> DataFrame
end
