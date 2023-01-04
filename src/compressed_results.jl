export compressed_survey_data

"""
    compressed_results(db, projectcode, [ field => queryexpr ]... [ ; mongo_find_options...]) -> DataFrame

Create a PiLR compressed [aka "unstacked", "wide"] survey result.

# Example

```julia
CSV.write("daily_ema.csv", compressed_survey_data(db, jit, "Daily_EMA", :metadata!pt=>"test08"))
```
"""
function compressed_survey_data(db, projectcode, surveycode, filter::Pair... ; kw...)
    stacked = mfind(db, projectcode, SURVEY_DATA, :data!survey_code => surveycode, filter...; kw...)
    select!(stacked, :metadata!pt=>:pt, :data!survey_code=>:survey_code, :data!session=>:session, :)
    choose_many_opts = Dict()
    t = combine(groupby(stacked, [:pt, :survey_code, :session])) do sdf
            transform!(sdf, :timestampString => (ts -> fill(last(ts), length(ts))) => :time_submitted)
            select(
                sdf[sdf.data!event_type .== "response" #= .&& sdf.data!question_type .!= "q_select_multiple" =#, :], 
                :pt, :survey_code, :session, :time_submitted, 
                :data!question_code => :variable, 
                Cols(:data!response_value, :data!response_values, :data!more_data!options, :data!question_code, :data!question_type) =>
                    ByRow((value, values, options, question, qtype) -> 
                        if qtype != "q_select_multiple"
                            value
                        else
                            if !ismissing(options)
                                choose_many_opts[question] = [o["value"] for o in options]
                            end
                            values
                        end
                    ) => :value)
        end
    result = unstack(t; allowmissing=true, combine=last)
    for (question_code, opts) in choose_many_opts
        values = result[!, question_code] 
        for opt in opts
            transform!(result, question_code => ByRow(values -> opt in values) => "$(question_code)_$(opt)")
        end
    end
    select!(result, Not(keys(choose_many_opts)...))
    result
end