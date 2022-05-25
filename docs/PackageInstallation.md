## Installation of Julia Kite Power Tools

It is suggested that you create your own folder for your kite simulators.
```bash
mkdir kitesims
cd kitesims
julia --project="."
```
On the Julia prompt install the package:
```julia
using Pkg
pkg"add https://github.com/aenarete/KiteSimulators.jl"

using KiteSimulators
cp_bin()
exit()
```
The commands above create the following directory structure:
```
├── bin
│   ├── create_sys_image
│   ├── create_sys_image.bat
│   ├── run_julia
│   └── run_julia.bat
├── data
│   ├── settings.yaml
│   └── system.yaml
├── docs
│   ├── Installation.md
│   └── kite_power_tools.png
├── Manifest.toml
├── Project.toml
├── README.md
└── test
    ├── create_sys_image.jl
    ├── test_for_precompile.jl
    └── update_packages.jl


```
It is suggested that you now create a Julia image that contains a compiled version off all the packages.

On the command line, enter for Linux
```bash
cd bin
./create_sys_image
```
and for Windows:
```bash
cd bin
create_sys_image
```
This will take 6 to 20 minutes but is only required once.

You can now execute Julia on Linux with the commands:
```bash
cd ..
./bin/run_julia
```
and on Windows:
```bash
cd ..
bin\run_julia
```

Continue with [README](../README.md)