beq(a::M.BSON,b::M.BSON) = M.as_json(a) == M.as_json(b)
beq(a,b) = beq(M.BSON(a), M.BSON(b))
#beq(a,b) = a == b

@testset "bson" begin
    for doc in [ bson(a=1, b=bson(c=3)),
                 bson("a"=>1, "b"=>bson(c=3))]
        @test doc isa M.BSON
        @test beq(doc, M.BSON("""{ "a": 1, "b": { "c" : 3 }}"""))
    end

    @testset "bson check bson($a) == BSON($b)" for (a,b) in [
        ( (:a=>1, :b=>:x => :y),
          """ {"a": 1, "b": {"x": "y"}} """),
        ( :a => [1,2,3],
          """ { "a" : [1,2,3]} """),
        ( :a => ( :b => [1,:x=>:y], :c => 3, :d => :e => "OK!" ),
          """
          { "a": { "b" : [1,{"x": "y"}], "c": 3, "d": { "e" : "OK!"} } }
          """),
        ( [1,2,3],
          [1,2,3] ),
        ( [ "\$group"=>(:id=>"\$metadata.pt", :foo=>"\$a.foo"),
            "\$sort" =>:a=>-1 ],
         raw"""
          [ {"$group": {"id": "$metadata.pt", "foo": "$a.foo"}},
            {"$sort": {"a": -1}} ]
         """),
        ( [ ~:group=>(:_id=>~:metadata!pt, :foo=>~:a!foo),
            ~:sort=>:a!bad!!!c=>-1 ],
         raw"""
          [ {"$group": {"_id": "$metadata.pt", "foo": "$a.foo"}},
            {"$sort": {"a.bad!.c": -1}} ]
         """),
        ]
        @test M.as_json(bson(a)) == M.as_json(M.BSON(b))

    end
    @test M.as_json(bson(code=:pt1, project=1234)) == M.as_json(M.BSON("""{ "code": "pt1", "project": 1234 }"""))

    @testset "regex" begin
      @test beq(bson(:a => r"\nx$"), bson(:a => +:regex => "\\nx\$"))
    end
end
