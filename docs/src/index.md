# Pilr.jl Documentation

*Tools for accessing and analyzing PiLR data.*

This is a hodge-podge set of tools for pulling data from Mongodb & PiLR log files into [DataFrames](https://dataframes.juliadata.org/stable/) to leverage Julia's analysis tools.

## Install

`Pilr` is not a registered Julia package, so you must use the github URL to install it:

```julia
julia> using Pkg; Pkg.add("https://github.com/mgm7734/Pilr.jl");
```

## Overview

* [`database`](@ref) returns a [`Pilr.Database`](@ref) connected to a PiLR Mongo database via a tunnel. 
  It is mostly a wrapper for [`Mongoc.Database`](https://felipenoris.github.io/Mongoc.jl/stable/api/#Database).
  ```jldoctest test
  julia> using Pilr

  julia> db = database(ENV["JENKINS_USER"], QA, ENV["MONGO_PASSWORD"]);
  ```

* `Pilr` provides an implementation of the [`Tables.jl`](https://tables.juliadata.org/stable/) interface for `Mongoc.Cursor`.
  This lets you do things like constructing a `DataFrame` directly from a query:
  ```jldoctest test
  julia> using DataFrames, Mongoc

  julia> DataFrame(Mongoc.find(db.project; options=Mongoc.BSON("""{"limit": 1}""")))
  1×12 DataFrame
   Row │ _id                       active  code    dateCreated              isDe ⋯
       │ String                    Bool    String  DateTime                 Bool ⋯
  ─────┼──────────────────────────────────────────────────────────────────────────
     1 │ 549513b2e4b0b40e50e6527d    true  test1   2014-12-20T06:14:10.810       ⋯
                                                                 8 columns omitted
  ```

* [`dataset_collection`](@ref) returns the `Mongoc.Collection` for a give project and dataset code. You rarely
  need to use it directly, though, since `mfind(db, projectcode, datasetcode, query...)` uses it under the hood.

* [`bson`](@ref) implements a concise syntax for generating `Mongoc.BSON` queries with much less puncuation.

* [`mfind`](@ref) accepts `bson` syntax, invokes `Mongoc.find` or `Mongoc.aggregate` as needed,  then returns a `DataFrame`.

* [`unflatten`](@ref) reverses the conversion performed by Pilr's `Tables` implementation, converting a `DataFrame` or `DataFrameRow` 
  back into the original `Mongoc.BSON` object. You'll need this to write data to Mongodb.

* Conversions between PiLR & Mongodb date-time representations to `ZonedDateTime` or `DateTime` (for local date-times).

## Examples

```jldoctest test
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
