# KiteSimulators

Meta-package, providing "Julia Kite Power Tools", consisting of the following packages:
<p align="center"><img src="./docs/kite_power_tools.png" width="500" /></p>

## Installation
If you do not have Julia installed yet, please read [Installation](docs/Installation.md).

For the installation of this package, please read [Installation of KiteSimulators](docs/PackageInstallation.md)

## Copy and run an example
From the Julia prompt execute:
```julia
using KiteSimulators
cp_examples()
```
If you have a Joystick connected, you can run the simulator with joystick control
```julia
./bin/run_julia or bin\run_julia

using KiteSimulators
include("examples\\joystick.jl)
```
You should now see the kite attached to the tether:
<p align="center"><img src="docs/kite_4p.png" width="500" /></p>


To view and modify the example, you can use the command:
```julia
@edit examples/joystick.jl  # Linux
@edit examples\\joystick.jl # Windows
```
The x axis of the Joystick controls steering, y-axis depowering and z-axis the
reel-in and reel-out of the winch. With button one you can start the simulation,
with button two you can stop it.

## See also
- [Research Fechner](https://research.tudelft.nl/en/publications/?search=wind+Fechner&pageSize=50&ordering=rating&descending=true) for the scientic background of this code
- The packages [KiteModels](https://github.com/ufechner7/KiteModels.jl) and [WinchModels](https://github.com/aenarete/WinchModels.jl) and [KitePodModels](https://github.com/aenarete/KitePodModels.jl) and [AtmosphericModels](https://github.com/aenarete/AtmosphericModels.jl)
- the package [KiteUtils](https://github.com/ufechner7/KiteUtils.jl) and [KiteControllers](https://github.com/aenarete/KiteControllers.jl)
