@enum DataCollectionKind data rawData deleted

"""
Return a mongo collection associated with a given PiLR dataset.

# Examples

julia> db = database("mmendel")
[...]

"""
function dataset_collection(
    db::M.Database, project_code::String, dataset_code::String, kind::Union{DataCollectionKind,String} = data)

    proj = M.find_one(db["project"], bson(:code=>project_code))
    proj == nothing && error("no project exists with code=$proj")
    dataset = M.find_one(db["dataset"], bson(code=dataset_code, project=proj["_id"]))
    dataset == nothing && error("project $project_code has no dataset with code '$dataset_code' ")
    db["$(dataset["_id"]):$(kind)"]
end
dataset_collection(db::Database, project_code, dataset_code, kind = data) =
    dataset_collection(db.mongo_database, project_code, dataset_code, kind)
