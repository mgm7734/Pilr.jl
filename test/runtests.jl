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

    @testset "shorten_paths" begin
        seeds = ["metadata!", "data2!", "data!", "data!args!"] 
        prefixes = ["", ("$(s1)$(s2)" for s1=seeds for s2=seeds)..., seeds...]
        df = DataFrame( ("$p$c" => ["v$p$c$r" for r=1:2] for p=prefixes for c=["a", "b"])... )
    end

    
    @testset "doctests" begin
        DocMeta.setdocmeta!(Pilr, :DocTestSetup,
                    :(using Pilr, Dates, Mongoc, TimeZones;import DataFrames); recursive=true)
        ENV["COLUMNS"] = 80
        doctest(Pilr)
    end
    
end
