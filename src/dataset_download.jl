export download_all_datasets, download_dataset

using CSV, Dates, Printf

"""
Download all datasets for a project and range of days
"""
function download_all_datasets(db, projectcode
    ; start=Date(2000,1,1), stop=Dates.today(), excludecodes=[] )

    datasetcodes = 
        mfind(db.project, :code=>projectcode, tomany(:project, :dataset),
            "dataset.calculationServiceName" => +:exists => false,
            "dataset.code" => +:nin => excludecodes
        ).dataset!code

    for dc in datasetcodes
        download_dataset(db, projectcode, dc; start, stop)
    end
end

"""
Download all data for a given project, dataset, and range of full days
"""
function download_dataset(db, projectcode, datasetcode, filter...
    ; start=Date(2000,1,1), stop=Dates.today())
    #; suffix="", file="$projectcode-$datasetcode$suffix.csv")

    suffix = @sprintf("%4d%02d%02d-%02d%02d", year(start), month(start), day(start), month(stop), day(stop))
    file = "$projectcode-$datasetcode-$suffix.csv"

    @info "Downloading" datasetcode
    df = mfind(db, projectcode, datasetcode, filter..., 
            :metadata!timestamp=>(+:gte=>DateTime(start), +:lt=>DateTime(stop)))
    
    if nrow(df) > 0
        # calculated datasets won't have a metadata!id
        if !("metadata!id" in names(df))
            df.metadata!id = df._id
        end
        # Format like PiLR CSV downloads
        if issubset(["metadata!pt", "metadata!timestamp", "localTimestamp"], names(df))
            select!(df,
                :metadata!id=>"id", :metadata!pt=>"pt", 
                :metadata!timestamp=>"timestamp(UTC)", :localTimestamp=>"timestamp(local)", 
                [:metadata!timestamp, :localTimestamp] => ByRow((u,l) -> (l-u).value / 3600000) => :time_zone_offset,
                [(old => new) for old in names(df) if match(r"^data!", old) !== nothing for new in [ SubString(old, 6) ]]...)
        end
        df
    end

    # CSV requires mapping `nothing` to `missing`
    transform!(df, names(df) .=> (v -> something.(v,missing)) .=> names(df))
    
    @info "Writing" file nrow(df)
    CSV.write(file, df)
end