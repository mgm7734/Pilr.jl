struct RemoteFile
    host::String
    path::String
    cachedir::String
end

function RemoteFile(host, path; cachedir = "$(ENV["HOME"])/.cache/pilr-remotefile", ignorecache=false)
    self = RemoteFile(host, path, cachedir)
    localpath = cachepath(self)
    if ignorecache || !isfile(localpath)
        mkpath(dirname(localpath))
        println("DEBUG>>> ssh $host sudo cat $path")
        run(pipeline(`ssh $host "sudo cat $path"`, stdout=localpath))
    end
    self
end

cachepath(r::RemoteFile) = joinpath(r.cachedir, r.host, basename(r.path))
