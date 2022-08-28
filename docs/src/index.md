# Pilr.jl Documentation

Tools for accessing and analyzing PiLR data.

## Installation

You can install Pilr.jl by typing the following in the Julia REPL:
```julia
] add Pilr
```

followed by 
```julia
using Pilr
```
to load the package.

## Overview

* [`Pilr.database`](@ref) returns a [`Pilr.Database`](@ref) connected to a PiLR Mongo database via a tunnel.

## Examples

```jltest
julia> using Pilr
julia> using Pilr.MongoDataFrames
julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);
julia> proj = find(db["project"], :code=>"base_pilr_ema")
julia> aggregate(dataset_collection(db, proj.code[1], SURVEY_DATA),
                 [
                   +:match => :data!event_type => "survey_submitted",
                   +:limit => 1000,
                   +:group => (:_id => +:metadata!pt,
                               :surveys_submitted => +:sum => 1,
                               :t => +:max => +:metadata!timestamp),
                   +:limit=>5
                 ])
5×3 DataFrame
 Row │ _id          surveys_submitted  t                   
     │ String       Int64              DateTime            
─────┼─────────────────────────────────────────────────────
   1 │ mei01                        7  2022-06-08T12:22:05
   2 │ amios-01                    14  2021-10-14T15:42:12
   3 │ sbmeitest01                  2  2022-04-20T16:27:50
   4 │ pb112020                     1  2021-03-16T19:29:57
   5 │ amandroid                   15  2021-02-01T05:09:47


```

## [Index](@id main-index)

```@index
Pages = ["mongo.md"]
```
