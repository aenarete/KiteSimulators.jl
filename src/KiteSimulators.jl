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
@reexport using PackageCompiler

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
    cp(joinpath(src_path, "joystick.jl"), joinpath(PATH, "joystick.jl"), force=true)
    chmod(joinpath(PATH, "joystick.jl"), 0o664)
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
    cp(joinpath(src_path, "create_sys_image.bat"), joinpath(PATH, "create_sys_image.bat"), force=true)
    cp(joinpath(src_path, "run_julia"), joinpath(PATH, "run_julia"), force=true)
    cp(joinpath(src_path, "run_julia.bat"), joinpath(PATH, "run_julia.bat"), force=true)
    chmod(joinpath(PATH, "create_sys_image"), 0o774)
    chmod(joinpath(PATH, "create_sys_image.bat"), 0o774)
    chmod(joinpath(PATH, "run_julia"), 0o774)
    chmod(joinpath(PATH, "run_julia.bat"), 0o774)
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
    PATH = ""
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "README.md"), joinpath(PATH, "README.md"), force=true)
    chmod(joinpath(PATH, "README.md"), 0o664)
    PATH = "docs"
    if ! isdir(PATH) 
        mkdir(PATH)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "Installation.md"), joinpath(PATH, "Installation.md"), force=true)
    cp(joinpath(src_path, "kite_power_tools.png"), joinpath(PATH, "kite_power_tools.png"), force=true)
    chmod(joinpath(PATH, "Installation.md"), 0o664)
    chmod(joinpath(PATH, "kite_power_tools.png"), 0o664)
end

end
