# activate the test environment if needed
using Pkg

@info "Loading packages ..."
using KiteSimulators, ControlPlots
Pkg.instantiate()

@info "Creating sysimage ..."
push!(LOAD_PATH,joinpath(pwd(),"src"))

GC.gc(true)
let mem = Sys.free_memory() / 1024^2
    @info "Free memory: $(round(mem; digits=1)) MB"
    if haskey(ENV, "JULIA_IMAGE_THREADS")
        @info "JULIA_IMAGE_THREADS: $(ENV["JULIA_IMAGE_THREADS"])"
    else
        @info "JULIA_IMAGE_THREADS not defined!"
    end
end

PackageCompiler.create_sysimage(
    [:KiteSimulators, :ControlPlots];
    sysimage_path="kps-image_tmp.so",
    include_transitive_dependencies=false,
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)
