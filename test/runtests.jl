using Pilr
using Test
import Mongoc as M

@testset "Pilr.jl" begin

    beq(a::M.BSON,b::M.BSON) = M.as_json(a) == M.as_json(b)
    beq(a,b) = beq(M.BSON(a), M.BSON(b))
    #beq(a,b) = a == b

    @testset "bson" begin
        for doc in [ bson(a=1, b=bson(c=3)),
                     bson("a"=>1, "b"=>bson(c=3))]
            @test doc isa M.BSON
            @test beq(doc, M.BSON("""{ "a": 1, "b": { "c" : 3 }}"""))
        end

        #@test beq(bson([1,2,3]), M.BSON(""" [1,2,3] """))
        @test beq(bson([1,2,3]), [1,2,3])
        @test beq(bson(:a => [1,2,3]), M.BSON(""" { "a" : [1,2,3]} """))
        @test beq(
            bson(:a => ( :b => [1,2], :c => 3, :d => (:e => "OK!") )),
            M.BSON("""
                { "a": { "b" : [1,2], "c": 3, "d": { "e" : "OK!"} } }
            """)
        )
        @test beq(
            [ O( "\$group" => O( :id => "\$metadata.pt" ) ),
              O( "\$sort" =>  O( :a => -1 ) ) ],
            [ M.BSON(raw"""{ "$group" : { "id" : "$metadata.pt" } }"""),
              M.BSON(raw"""{ "$sort" : { "a" : -1 } }""") ] 
        )

        @test beq(
            bson([ ( "\$group" => ( :id => "\$metadata.pt",), ),
                   ( "\$sort" =>  ( :a => -1, ), )
                   ]),
            [ M.BSON(raw"""{ "$group" : { "id" : "$metadata.pt" } }"""),
              M.BSON(raw"""{ "$sort" : { "a" : -1 } }""") ] 
        )

    end


    db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"])

    @testset "dataset_collection" begin
        applog = dataset_collection(db, "base_pilr_ema", "pilrhealth:mobile:app_log")
        @test M.count_documents(applog) > 0
    end

    @testset "flatdict" begin
        fakecursor = [
            bson(:meta=>bson(:id=>"1"),
                 :data=>bson(:type=>"type-a", :obs_a1=>42, :extra=>"extra")),
            bson(:meta=>bson(:id=>"2"),
                 :data=>bson(:type=>"type-b", :obs_b1=>"42b", :extra=>bson(:x=>0)))
        ]

    end
        
    @testset "MongoTable flatdict" begin
        applog = dataset_collection(db, "base_pilr_ema", "pilrhealth:mobile:app_log")
        cursor() = M.find(applog, bson(), options=bson(limit=10))

        table = flatdict(cursor(),
                        replace=[:_id => nothing, :metadata!timestamp => :t],
                        order=[:t])

        @test :_id ∉ keys(table)
        @test first(keys(table)) == :t

        #cursor = M.find(applog, bson(), options=bson(limit=10))
        function myreplacer(name, value)
            if name == "_id"
                nothing, nothing
            elseif name == "metadata!timestamp" && value !== missing
                "t", string(value)
            else
                name, value
            end
        end
        table2 = flatdict(cursor(),
                         replace=myreplacer,
                         order=[:t])

        @test :_id ∉ keys(table2)
        @test first(keys(table2)) == :t
        @test table2[:t] == string.(table[:t])

        @test flatdict(cursor()) != nothing
    end
    
    #@testset "RemoteFile" begin
    #    RemoteFile("beta", "/var/log/upstart/tomcat.log-20220430.gz")
    #end
    
end