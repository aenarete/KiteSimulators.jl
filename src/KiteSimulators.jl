module KiteSimulators

using Reexport

@reexport using KiteUtils
@reexport using KitePodModels
@reexport using AtmosphericModels
@reexport using KiteModels
@reexport using KiteViewers
@reexport using Timers
@reexport using Joysticks
@reexport using Plots

export cp_examples, cp_bin

"""
    copy_examples()

Copy the example scripts to the folder "examples"
(it will be created if it doesn't exist).
"""
function cp_examples()
    PATH = "examples"
    if ! isdir(PATH) 
        mkdir(PATH)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "compare_kps3_kps4.jl"), joinpath(PATH, "compare_kps3_kps4.jl"), force=true)
    cp(joinpath(src_path, "plot2d.jl"), joinpath(PATH, "plot2d.jl"), force=true)
    cp(joinpath(src_path, "simulate.jl"), joinpath(PATH, "simulate.jl"), force=true)
    chmod(joinpath(PATH, "compare_kps3_kps4.jl"), 0o664)
    chmod(joinpath(PATH, "plot2d.jl"), 0o664)
    chmod(joinpath(PATH, "simulate.jl"), 0o664)
end

"""
    cp_bin()

Copy the scripts create_sys_image and run_julia to the folder "bin"
(it will be created if it doesn't exist).
"""
function cp_bin()
    PATH = "bin"
    if ! isdir(PATH) 
        mkdir(PATH)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "create_sys_image"), joinpath(PATH, "create_sys_image"), force=true)
    cp(joinpath(src_path, "run_julia"), joinpath(PATH, "run_julia"), force=true)
    chmod(joinpath(PATH, "create_sys_image"), 0o774)
    chmod(joinpath(PATH, "run_julia"), 0o774)
    PATH = "test"
    if ! isdir(PATH) 
        mkdir(PATH)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "create_sys_image.jl"), joinpath(PATH, "create_sys_image.jl"), force=true)
    cp(joinpath(src_path, "test_for_precompile.jl"), joinpath(PATH, "test_for_precompile.jl"), force=true)
    cp(joinpath(src_path, "update_packages.jl"), joinpath(PATH, "update_packages.jl"), force=true)
    chmod(joinpath(PATH, "create_sys_image.jl"), 0o664)
    chmod(joinpath(PATH, "test_for_precompile.jl"), 0o664)
    chmod(joinpath(PATH, "update_packages.jl"), 0o664)
    copy_settings()
end

end
