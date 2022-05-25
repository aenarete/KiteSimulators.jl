# KiteSimulators

Meta-package, providing "Julia Kite Power Tools", consisting of the following packages:
<p align="center"><img src="./docs/kite_power_tools.png" width="500" /></p>

## Installation
If you do not have Julia installed yet, please read [Installation](docs/Installation.md).

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
cp_bin()
exit()
```
It is suggested that you now create a Julia image that contains a compiled version off all the packages.

On the command line, enter:
```bash
cd bin
./create_sys_image
```
This will take 10 to 20 minutes but is only required once.

