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
@reexport import LaTeXStrings
@reexport import LaTeXStrings: @L_str
@reexport using StatsBase
@reexport using NativeFileDialog 

export cp_examples, init_project, fulldir

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
    copy_settings()
    if ! isdir("output") 
        mkdir("output")
    end
    bin_files = ["create_sys_image", "create_sys_image.bat", "run_julia", "run_julia.bat", "joystick", "joystick.bat", 
                 "autopilot", "autopilot.bat"]
    test_files = ["create_sys_image.jl", "test_for_precompile.jl", "update_packages.jl"]
    docs_files = ["Installation.md", "PackageInstallation.md", "kite_power_tools.png", "kite_4p.png", "dir_structure.png",
                  "vscode.png", "logging.md", "plotting.md", "main.png"]
    settings_files = ["fpc_settings_hydra20.yaml", "fpc_settings.yaml",
                      "fpp_settings_hydra20_426.yaml", "fpp_settings_hydra20_920.yaml", "fpp_settings_hydra20.yaml", "fpp_settings.yaml", "gui.yaml",
                      "settings_hydra20.yaml", "settings_hydra20_600.yaml", "settings_hydra20_920.yaml", "settings.yaml",
                      "system_8000.yaml", "system.yaml", 
                      "wc_settings_8000_426.yaml","wc_settings_8000.yaml", "wc_settings.yaml",
                      "hydra10_951.yml", "hydra20_426.yml", "hydra20_600.yml", "hydra20_920.yml"]
    copy_files("bin", bin_files)
    copy_files("test", test_files)
    copy_files("docs", docs_files)
    copy_files("data", settings_files)
    PATH = ""
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    cp(joinpath(src_path, "README.md"), joinpath(PATH, "README.md"), force=true)
    chmod(joinpath(PATH, "README.md"), 0o664)
    copy_settings()
    cp_examples()
end

"""
    fulldir(name)

Create a fully qualified directory name by
- replacing ~ with your home directory
- otherwise (no ~ in name) prepend the name with the current directory
"""
function fulldir(name)
    if occursin("~", name)
        return replace(dirname(name), "~" => homedir())
    else
        return joinpath(pwd(), dirname(name))
    end
end

end
