struct PilrEnvironment
    domain::String
end

export PROD = PilrEnvironment("mei-s4r-beta")
export QA = PilrEnvironment("mei-s4r-qa")
export STAGING = PilrEnvironment("mei-s3r-staging")
