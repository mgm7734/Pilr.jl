using Sockets

HOSTS=["mei-s4r-rabbit-mongo-stable0$i" for i = 1:3]  # Not work for i > 1 

nextport=29030

@enum PilrDbName QA BETA STAGING

"""
Wrap a [`Mongoc.Database`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Database) and a
[`Mongoc.Client`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Client)

"""
struct Database
    mongo_database::M.Database
    client
end 
"""
Overload property access as shortcut for collections.

```julia
db.project == db["project"]
```

"""
Base.getproperty(db::Database, s::Symbol) = 
    if s ∈ [:mongo_database, :client]
        getfield(db, s)
    else
        db.mongo_database[string(s)]
    end

function starttunnel(host, localport, user; verbose=false)
    try
        s = connect("localhost", localport)
        close(s)
        if verbose
            @info "reusing tunnel" host localport user
        end
    catch e
        sshopts = if haskey(ENV, "SSH_OPTS")
            split(get(ENV, "SSH_OPTS", ""), " ")
        else
            []
        end

        if verbose
            @info "starting tunnel" host localport user sshopts
        end

        p = run(`ssh $(sshopts) -NTL $localport:$(host):27017 $user@jenkins.pilrhealth.com`, wait=false) 
        atexit(()->kill(p))
    end
    Nothing
end

"""
    database(jenkins_user, db_name, db_password [, localport = $(nextport)]) => Database

Return a [`Database`](@ref) connection.

# Options

- `ssh_opts::AbstractVector{String}`: extra arguments for the `ssh` tunnel command. Example: `["-Fnone", ""-i/home/me/.ssh/alt_rsa"]`

# Examples

julia> db = database("mmendel", "mei-s4r-qa", ENV["MONGO_PASSWORD"])
[...]

julia> import Mongoc

julia> Mongoc.count_documents(db["project"])
1056
"""
function database(jenkins_user, db_name, db_password;
                  localport = 29030, use_replset = false, ssh_opts=[], verbose=false,
                  ) :: Database
    hosts = use_replset ? HOSTS : HOSTS[1:1]
    for (i, host) in enumerate(hosts)
        starttunnel(host, localport + i, jenkins_user; verbose)
    end
    url = "mongodb://$db_name-user:$db_password@" * 
          join(["localhost:$(localport + i)" for i = eachindex(hosts)], ",") *
          "/$db_name";
    #if use_replset
    #    pool = M.ClientPool(url, max_size = 2)
    #    client = M.Client(pool)
    #else
    #    client = M.Client(url)
    #end
    #return Database(client[db_name], client)
    for i = 1:10
        try
            client = M.Client(url)
            sleep(1)
            r = M.ping(client)
            if r["ok"] == 1.0
                return Database(client[db_name], client)
            end
            @error "Ping #$i:" r
        catch ex
            @error "Ping #$i failed" ex
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
