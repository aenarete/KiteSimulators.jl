# activate the test environment if needed
using Pkg

@info "Loading packages ..."
using KiteSimulators, ControlPlots

@info "Creating sysimage ..."
push!(LOAD_PATH,joinpath(pwd(),"src"))

PackageCompiler.create_sysimage(
    [:KiteSimulators, :ControlPlots];
    sysimage_path="kps-image_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)