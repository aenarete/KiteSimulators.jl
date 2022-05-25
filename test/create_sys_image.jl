# activate the test environment if needed
using Pkg
if ! ("PackageCompiler" ∈ keys(Pkg.project().dependencies))
    using TestEnv; TestEnv.activate()
end
@info "Loading packages ..."
# using StaticArrays, LinearAlgebra, Parameters, KiteViewers, KiteUtils, KitePodModels, KiteModels, GLMakie, Plots
using KiteSimulators
using PackageCompiler

@info "Creating sysimage ..."
push!(LOAD_PATH,joinpath(pwd(),"src"))

PackageCompiler.create_sysimage(
    # [:StaticArrays, :Parameters, :KiteViewers, :KiteUtils, :KitePodModels, :KiteModels, :GLMakie, :Plots];
    [:KiteSimulators]
    sysimage_path="kps-image_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)