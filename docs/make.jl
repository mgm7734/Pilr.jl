using Documenter, Mongoc, Pilr

DocMeta.setdocmeta!(Pilr, :DocTestSetup,
                    :(using Pilr, Dates, Mongoc, TimeZones;import DataFrames); recursive=true)

ENV["COLUMNS"] = 80
makedocs(
    modules = [Pilr],
    sitename = "Pilr",
    format = Documenter.HTML(),
    authors = "Mark Mendel",
    pages = [
        "Home" => "index.md",
        "Mongo" => "mongo.md",
    ],
    # doctest = :fix,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/mgm7734/Pilr.jl",
    devbranch = "main"
)
