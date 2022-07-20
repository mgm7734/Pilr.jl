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

```
julia> using Mongoc
julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);
julia> proj = Mongoc.find_one(db["project"], bson(:code=>"base_pilr_ema"));
julia> Mongoc.aggregate(
         dataset_collection(db, proj["code"], SURVEY_DATA),
         bson([
           "\$match" => "data.event_type" => "survey_submitted",
           "\$limit" => 1000,
           "\$group" => (:_id => "\$metadata.pt", :surveys_submitted=>"\$sum"=>1)
         ])) |> 
         flatdict |> DataFrame |> df->first(df,5)
5×2 DataFrame
 Row │ _id          surveys_submitted 
     │ String       Int64             
─────┼────────────────────────────────
   1 │ mei01                        7
   2 │ amios-01                    14
   3 │ sbmeitest01                  2
   4 │ pb112020                     1
   5 │ amandroid                   15


```
