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

using KiteSimulators
cp_bin()
exit()
```
The commands above create the following directory structure:
```
├── bin
│   ├── create_sys_image
│   ├── kps-image-1.7.so
│   └── run_julia
├── data
│   ├── settings.yaml
│   └── system.yaml
├── examples
│   └── joystick.jl
└── test
    ├── create_sys_image.jl
    ├── test_for_precompile.jl
    └── update_packages.jl

```
It is suggested that you now create a Julia image that contains a compiled version off all the packages.

On the command line, enter:
```bash
cd bin
./create_sys_image
```
This will take 6 to 20 minutes but is only required once.

You can now execute Julia with the commands:
```bash
cd ..
./bin/run_julia
```

## Copy and run an example
From the Julia prompt execute:
```julia
using KiteSimulators
cp_examples()
```
If you have a Joystick connected, you can run the simulator with joystick control
```julia
./bin/run_julia

using KiteSimulators
include("examples/joystick.jl)
```

To view and modify the example, you can use the command:
```julia
@edit examples/joystick.jl
```
The x axis of the Joystick controls steering, y-axis depowering and z-axis the
reel-in and reel-out of the winch. With button one you can start the simulation,
with button two you can stop it.

## See also
- [Research Fechner](https://research.tudelft.nl/en/publications/?search=wind+Fechner&pageSize=50&ordering=rating&descending=true) for the scientic background of this code
- The packages [KiteModels](https://github.com/ufechner7/KiteModels.jl) and [WinchModels](https://github.com/aenarete/WinchModels.jl) and [KitePodModels](https://github.com/aenarete/KitePodModels.jl) and [AtmosphericModels](https://github.com/aenarete/AtmosphericModels.jl)
- the package [KiteUtils](https://github.com/ufechner7/KiteUtils.jl) and [KiteControllers](https://github.com/aenarete/KiteControllers.jl)
