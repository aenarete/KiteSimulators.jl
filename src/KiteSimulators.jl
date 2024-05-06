module KiteSimulators

using Reexport

@reexport using KiteUtils
@reexport using KitePodModels
@reexport using AtmosphericModels
@reexport using KiteModels
@reexport using KiteViewers
@reexport using KiteControllers
@reexport using Timers
@reexport using Joysticks
@reexport using Printf
@reexport using PackageCompiler
@reexport using StatsBase
@reexport using NativeFileDialog 

export cp_examples, init_project

"""
    cp_examples()

Copy all example scripts to the folder "examples"
(it will be created if it doesn't exist).
"""
function cp_examples()
    PATH = "examples"
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    copy_files("examples", readdir(src_path))
end

function copy_files(relpath, files)
    if ! isdir(relpath) 
        mkdir(relpath)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", relpath)
    for file in files
        cp(joinpath(src_path, file), joinpath(relpath, file), force=true)
        chmod(joinpath(relpath, file), 0o774)
    end
    files
end

"""
    init_project()

Copy the scripts create_sys_image and run_julia to the folder "bin"
(it will be created if it doesn't exist).
In addition it copies the README.md file, the default settings in
the folder data  and helper scripts in the folder test.
"""
function init_project()
    bin_files = ["create_sys_image", "create_sys_image.bat", "run_julia", "run_julia.bat", "joystick", "joystick.bat", 
                 "autopilot", "autopilot.bat"]
    test_files = ["create_sys_image.jl", "test_for_precompile.jl", "update_packages.jl"]
    docs_files = ["Installation.md", "PackageInstallation.md", "kite_power_tools.png", "kite_4p.png", "dir_structure.png",
                  "vscode.png", "logging.md", "plotting.md", "2d_plot.png"]
    copy_files("bin", bin_files)
    copy_files("test", test_files)
    copy_files("docs", docs_files)
    PATH = ""
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "README.md"), joinpath(PATH, "README.md"), force=true)
    chmod(joinpath(PATH, "README.md"), 0o664)
    copy_settings()
    cp_examples()
end

end
