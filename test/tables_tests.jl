
Tables.istable(::Vector{M.BSON}) = true

Tables.rowaccess(::M.Vector{M.BSON}) = true

Tables.rows(c::M.Vector{M.BSON}) = FlatteningDictIterator(c)

@testset "Tables" begin 
    objs = [ 
        M.BSON("""{ "data" : { "level" : "info", "args" : { "friendCsv" : "FRIENDS" }, "tag" : "PLOT_PROJECTS", "msg" : "mei.ble.EncountersApi: setFriendList" } }"""),
        M.BSON("""{ "data" : { "level" : "info", "args" : { "property" : "TRANSIENT_TIMEOUT", "savedValue" : "90" }, "tag" : "PLOT_PROJECTS", "msg" : "meipp.PersistentProperties: restore" } }"""),
    ]
    df = DataFrame(Pilr.flatten_dicts(objs))

    @test isequal( df.data!args!property,  [missing, "TRANSIENT_TIMEOUT"] )
    @test isequal( df.data!args!friendCsv, ["FRIENDS", missing] )
end