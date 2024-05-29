using Pilr
import Mongoc as M

ENV["SSL_CERT_FILE"]="/usr/local/etc/openssl@3/cert.pem"

# Requires ENV["MONGO_PASSWORD"] and STAGING_PASSWORD
#
odb = database("mmendel", BETA)
ndb = database(
  "mongodb+srv://staging:$STAGING_PASSWORD@cluster0.g2omy.mongodb.net/?retryWrites=true&w=majority" ; 
  dbname="staging")

"""
Copy all project-level files from an Grails2 PiLR project to project on a Grails3 server.

Note that the file_ids are unchanged--the underlying mongo objects are literally copied]
"""
function  assets_migrate(odb, ndb, oprojcode, nprojcode = oprojcode; doit=false)
  oprojid = M.find_one(odb.project, bson(:code => oprojcode))["_id"]
  nprojid = M.find_one(ndb.project, bson(:code => nprojcode))["_id"]

  ofiles = [ 
    f for f in M.find(odb["$oprojid.files"], bson(:metadata!participant=>+:exists=>false)) 
  ]
  for ofile in ofiles
    nfile = Dict(ofile)
    meta = Dict(ofile["metadata"])
    meta["md5"] = ofile["md5"]
    meta["contentType"] = ofile["contentType"]
    nfile["metadata"] = meta
    delete!(nfile, "md5")

    @info "file" nfile
    # doit && M.insert_one(ndb["$nprojid.files"], M.BSON(nfile))
    
    for chunk in M.find(odb["$oprojid.chunks"], bson(:files_id => ofile["_id"]))
      @info "chunk" chunk["n"]
      doit && M.insert_one(ndb["$nprojid.chunks"], chunk)
    end
    doit && M.insert_one(ndb["$nprojid.files"], M.BSON(nfile))
  end
  #ofiles
end
