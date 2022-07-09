@enum DataCollectionKind data rawData deleted

"""
    dataset_collection(db, project_code, dataset_code, [ data | rawData | deleted ])

Return a [`Mongoc.Collection`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Collection) associated with a given PiLR dataset.

# Examples

julia> db = database("mmendel")
[...]

"""
function dataset_collection(
    db::M.Database, project_code, dataset_code, kind::Union{DataCollectionKind,AbstractString} = data)

    proj = M.find_one(db["project"], bson(:code=>project_code))
    proj == nothing && error("no project exists with code=$proj")
    dataset = M.find_one(db["dataset"], bson(code=dataset_code, project=proj["_id"]))
    dataset == nothing && error("project $project_code has no dataset with code '$dataset_code' ")
    db["$(dataset["_id"]):$(kind)"]
end
dataset_collection(db::Database, project_code, dataset_code, kind = data) =
    dataset_collection(db.mongo_database, project_code, dataset_code, kind)
