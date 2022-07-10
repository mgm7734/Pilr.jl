var documenterSearchIndex = {"docs":
[{"location":"mongo/#Mongo","page":"Mongo","title":"Mongo","text":"","category":"section"},{"location":"mongo/","page":"Mongo","title":"Mongo","text":"Pages = [\"mongo.md\"]","category":"page"},{"location":"mongo/#API-Reference","page":"Mongo","title":"API Reference","text":"","category":"section"},{"location":"mongo/","page":"Mongo","title":"Mongo","text":"Pilr.bson\nPilr.database\nPilr.dataset_collection\nPilr.Database\nPilr.flatdict","category":"page"},{"location":"mongo/#Pilr.bson","page":"Mongo","title":"Pilr.bson","text":"bson(pair...) => Mongoc.BSON\nbson(AbstractVector{pair}) => Vector{Mongoc.BSON}\n\nConstruct a BSON object using keyword arguments or pairs to reduce quote clutter.\n\nExamples\n\njulia> bson(\"metadata.pt\" => \"xyz\", :project=>\"\\$in\" => [\"proj1\", \"proj2\"])\nMongoc.BSON with 2 entries:\n  \"metadata.pt\" => \"xyz\"\n  \"project\"     => Dict{Any, Any}(\"\\$in\"=>Any[\"proj1\", \"proj2\"])\n\njulia> bson([\n         \"\\$match\"=>:type=>\"SUBMIT\", \n         \"\\$group\"=>(:_id=>\"\\$pt\", :N=>\"\\$sum\"=>1)\n       ])\nMongoc.BSON with 2 entries:\n  \"0\" => Dict{Any, Any}(\"\\$match\"=>Dict{Any, Any}(\"type\"=>\"SUBMIT\"))\n  \"1\" => Dict{Any, Any}(\"\\$group\"=>Dict{Any, Any}(\"_id\"=>\"\\$pt\", \"N\"=>Dict{Any,…\n\njulia> bson(a=1, b=2)\nMongoc.BSON with 2 entries:\n  \"a\" => 1\n  \"b\" => 2\n\n\n\n\n\n","category":"function"},{"location":"mongo/#Pilr.database","page":"Mongo","title":"Pilr.database","text":"database(jenkins_user, db_name, db_password [, localport = 29030]) => Database\n\nReturn a Database connection.\n\nExamples\n\njulia> db = database(\"mmendel\", \"mei-s4r-qa\", ENV[\"MONGO_PASSWORD\"]) [...]\n\njulia> import Mongoc\n\njulia> Mongoc.count_documents(db[\"project\"]) 1056\n\n\n\n\n\ndatabase(jenkins_user [, db_name, [, db_password]] [localport = localport])\n\nConstruct a connected database defaults.\n\n\n\n\n\n","category":"function"},{"location":"mongo/#Pilr.dataset_collection","page":"Mongo","title":"Pilr.dataset_collection","text":"dataset_collection(db, project_code, dataset_code, [ data | rawData | deleted ])\n\nReturn a Mongoc.Collection associated with a given PiLR dataset.\n\nExamples\n\njulia> db = database(\"mmendel\") [...]\n\n\n\n\n\n","category":"function"},{"location":"mongo/#Pilr.Database","page":"Mongo","title":"Pilr.Database","text":"Wrap a Mongoc.Database and a Mongoc.Client\n\n\n\n\n\n","category":"type"},{"location":"mongo/#Pilr.flatdict","page":"Mongo","title":"Pilr.flatdict","text":"flatdict(cursor ; [separator = \"!\"])\n\nConvert an iterable of nested Dict{String,Any} (such as a Cursor returned by Mongoc.find) into a dictonary of equal length columns.\n\nThe returned dictionary can be converted to a DataFrame.\n\nEach field value that is a dictionary is replaced a field for every entry. The field names are the path.\n\nUsing \"!\" does not require quoting in Symbol names, so you can type :metadata!pt instead of \"metadata.pt\".\n\nOption Arguments\n\nseparator : path separator for flattened column names. \nreplace : either a vector of Pair{Symbol,Any} or a function (key, value) -> (key, value).\norder : a vector of columns that should appear first.\n\n\n\n\n\n","category":"function"},{"location":"#Pilr.jl-Documentation","page":"Home","title":"Pilr.jl Documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Tools for accessing and analyzing PiLR data.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can install Pilr.jl by typing the following in the Julia REPL:","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add Pilr","category":"page"},{"location":"","page":"Home","title":"Home","text":"followed by ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pilr","category":"page"},{"location":"","page":"Home","title":"Home","text":"to load the package.","category":"page"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pilr.database returns a Pilr.Database connected to a PiLR Mongo database via a tunnel.","category":"page"},{"location":"#Examples","page":"Home","title":"Examples","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"julia> using Pilr, DataFrames, Mongoc\n\njulia> db = database(ENV[\"JENKINS_USER\"], QA, ENV[\"MONGO_PASSWORD\"]);\n┌ Info: reusing tunnel\n│   host = \"mei-s4r-rabbit-mongo-stable01\"\n│   localport = 29031\n└   user = \"mmendel\"\n\njulia> proj = Mongoc.find_one(db[\"project\"], bson(:code=>\"base_pilr_ema\"));\n\njulia> Mongoc.aggregate(\n         dataset_collection(db, proj[\"code\"], SURVEY_DATA),\n         bson([\n           \"\\$match\" => \"data.event_type\" => \"survey_submitted\",\n           \"\\$limit\" => 1000,\n           \"\\$group\" => (:_id => \"\\$metadata.pt\", :surveys_submitted=>\"\\$sum\"=>1)\n         ])) |> \n         flatdict |> DataFrame |> df->first(df,5)\n5×2 DataFrame\n Row │ _id          surveys_submitted \n     │ String       Int64             \n─────┼────────────────────────────────\n   1 │ mei01                        7\n   2 │ amios-01                    14\n   3 │ sbmeitest01                  2\n   4 │ pb112020                     1\n   5 │ amandroid                   15\n\n","category":"page"}]
}
