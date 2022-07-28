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
pkg"add KiteSimulators"
pkg"add Plots"
pkg"add Timers"

using KiteSimulators
init_project()
exit()
```
The commands above create the following directory structure:

<p align="center"><img src="dir_structure.png" width="300" /></p>

It is suggested that you now create a Julia image that contains a compiled version off all the packages.

On the command line, enter for Linux:
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
