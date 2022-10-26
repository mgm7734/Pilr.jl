using Pilr, DataFrames
using Test, Documenter
import Mongoc as M

@testset "Pilr.jl" begin

    include("bson_tests.jl")
    include("tables_tests.jl")

    db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"])

    @testset "dataset_collection" begin
        applog = dataset_collection(db, "base_pilr_ema", "pilrhealth:mobile:app_log")
        @test M.count_documents(applog) > 0
    end

    # @testset "MongoTable flatdict" begin
    #     applog = dataset_collection(db, "base_pilr_ema", "pilrhealth:mobile:app_log")
    #     cursor() = M.find(applog, bson(), options=bson(limit=10))

    #     table = flatdict(cursor(),
    #                     replace=[:_id => nothing, :metadata!timestamp => :t],
    #                     order=[:t])

    #     @test :_id ∉ keys(table)
    #     @test first(keys(table)) == :t

    #     #cursor = M.find(applog, bson(), options=bson(limit=10))
    #     function myreplacer(name, value)
    #         if name == "_id"
    #             nothing, nothing
    #         elseif name == "metadata!timestamp" && value !== missing
    #             "t", string(value)
    #         else
    #             name, value
    #         end
    #     end
    #     table2 = flatdict(cursor(),
    #                      replace=myreplacer,
    #                      order=[:t])

    #     @test :_id ∉ keys(table2)
    #     @test first(keys(table2)) == :t
    #     @test table2[:t] == string.(table[:t])

    #     @test flatdict(cursor()) != nothing
    # end

    #@testset "RemoteFile" begin
    #    RemoteFile("beta", "/var/log/upstart/tomcat.log-20220430.gz")
    #end
    
    # @testset "wrappers" begin
    #     projcode=M.find_one(db["project"], :code=>"\$regex"=>"test")["code"]

    # end
    
    @testset "doctests" begin
        DocMeta.setdocmeta!(Pilr, :DocTestSetup,
                    :(using Pilr, Dates, Mongoc, TimeZones;import DataFrames); recursive=true)
        ENV["COLUMNS"] = 80
        doctest(Pilr)
    end
    
end
