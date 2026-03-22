__PRECOMPILE__ = true
let    
    include("../examples/autopilot.jl")
end

GC.gc(true)
let mem = Sys.free_memory() / 1024^2
    @info "Free memory: $(round(mem; digits=1)) MB"
    if haskey(ENV, "JULIA_IMAGE_THREADS")
        @info "JULIA_IMAGE_THREADS: $(ENV["JULIA_IMAGE_THREADS"])"
    else
        @info "JULIA_IMAGE_THREADS not defined!"
    end
end

@info "Precompile script has completed execution."