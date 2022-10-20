# Pilr.jl Documentation

Tools for accessing and analyzing PiLR data.

## Quickstart

You can install Pilr.jl by typing the following in the Julia REPL:
```
] add Pilr
```

followed by 
```
using Pilr
```
to load the package.

* [`Pilr.database`](@ref) returns a [`Pilr.Database`](@ref) connected to a PiLR Mongo database via a tunnel.
* [`bson`](@ref) implements a concise syntax for generating `Mongoc.BSON` queries
* [`mfind`](@ref) accepts `bson` syntax, invokes `Mongoc.find` or `Mongoc.aggregate` as needed and returns a DataFrame

## Examples

```jldoctest test
julia> using Pilr

julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);

julia> proj = mfind(db.project, :code=>"base_pilr_ema");

julia> mfind(db, proj.code[1], SURVEY_DATA,
                   :data!event_type => "survey_submitted", # `+:match=>` optional
                   +:limit => 1000,
                   +:group => (:_id => +:metadata!pt,
                               :surveys_submitted => +:sum => 1,
                               :t => +:max => +:metadata!timestamp),
                   ; limit=5
                 )
5×3 DataFrame
 Row │ surveys_submitted  t                    _id         
     │ Int64              DateTime             String      
─────┼─────────────────────────────────────────────────────
   1 │                 7  2022-06-08T12:22:05  mei01
   2 │                14  2021-10-14T15:42:12  amios-01
   3 │                 2  2022-04-20T16:27:50  sbmeitest01
   4 │                 1  2021-03-16T19:29:57  pb112020
   5 │                15  2021-02-01T05:09:47  amandroid
```

You can use `Mongoc` functions directly. 
`Pilr` implements the [`Tables.jl`](https://tables.juliadata.org/stable/) interface for `Mongoc.Cursor`.

```jldoctest test
julia> using DataFrames, Mongoc

julia> Mongoc.find(db.project, bson(:code=>"base_pilr_ema")) |> DataFrame
1×21 DataFrame
 Row │ _id                       autoRegistrationEnabled  code           dateC ⋯
     │ String                    Bool                     String         DateT ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 58827b04e4b0507240a4e127                    false  base_pilr_ema  2017- ⋯
                                                              18 columns omitted
```

## [Index](@id main-index)

```@index
Pages = ["mongo.md"]
```
