HOSTS=["mei-s4r-rabbit-mongo-stable0$i" for i = 1:3]  # Not work for i > 1 

@enum PilrDbName QA BETA STAGING

struct Database
    mongo_database::M.Database
    tunnels::Vector{Base.Process}
    client
end 


tunnel(host, localport, user) =
    run(Cmd(`ssh -NL $localport:$(host):27017 $user@jenkins.pilrhealth.com`), wait=false) 

"""
    database(jenkins_user, db_name, db_password [, localport = 29030 ])

Construct a connect database.

# Examples

julia> db = database("mmendel", "mei-s4r-qa", ENV["MONGO_PASSWORD"])
[...]

julia> import Mongoc

julia> Mongoc.count_documents(db["project"])
1056
"""
function database(jenkins_user, db_name::String, db_password; localport = 29030, use_replset = false) :: Database
    hosts = use_replset ? HOSTS : HOSTS[1:1]
    tunnels = [ tunnel(host, localport + i, jenkins_user) for (i, host) in enumerate(hosts) ]
    url = "mongodb://$db_name-user:$db_password@" * 
          join(["localhost:$(localport + i)" for i = eachindex(hosts)], ",") *
          "/$db_name";
    if use_replset
        pool = M.ClientPool(url, max_size = 2)
        client = M.Client(pool)
    else
        client = M.Client(url)
    end
    for i = 1:5
        try
            r = M.ping(client)
            if r["ok"] == 1.0
                return Database(client[db_name], tunnels, client)
            end
            @warn "Ping #$i:" r
        catch ex
            @warn "Ping #$i failed" ex
        end
    end
    error("failed to connect")
end

"""
    database(jenkins_user [, db_name, [, db_password]] [localport = localport])

Construct a connected database defaults.
"""
database(jenkins_user, name::PilrDbName = QA, db_password = ENV["MONGO_PASSWORD"]; kws...) =
    database(jenkins_user, "mei-s4r-$(lowercase(string(name)))", db_password; kws...)

Base.getindex(db::Database, collection_name::String):: M.Collection = db.mongo_database[collection_name]
