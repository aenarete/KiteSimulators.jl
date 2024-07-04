# KiteSimulators

Meta-package, providing "Julia Kite Power Tools", consisting of the following packages:
<p align="center"><img src="https://raw.githubusercontent.com/ufechner7/KiteUtils.jl/main/docs/src/kite_power_tools.png" width="500" /></p>

## KiteApps for non-programmers
This package provides two GUI applications that can be used by non-programmers:
- [autopilot](docs/autopilot.md)
- [joystick](docs/joystick.md)

The first app can be used to run one of the provided demo simulations, but you can also run your own simulation by copying and modifying the configuration files.

The second app can be used to learn how to steer a kite and how to operate the winch manually using a joystick.

## Hardware requirements
A fast computer helps to reduce the installation time, otherwise, it works well even on dual-core computers with 4G RAM, and 2G RAM might be sufficient. OpenGL is a hard requirement. A dedicated graphics card is useful, but not always required. If you have a Windows laptop please enable the dedicated graphics card in the settings.

The program was tested with a "Logitech Extreme 3D pro" Joystick, but most likely any Joystick will do. If not, please create an issue on GitHub. The installation was tested on Windows 10 and Ubuntu 18.04, 20.04, 22.04 and 24.04, but should also work on Mac.

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
include("examples/joystick.jl")  # Linux
include("examples\\joystick.jl") # Windows
```
You should now see the kite attached to the tether:
<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/kite_4p.png?raw=true" width="500" /></p>


To view and modify the example, you can use the command:
```julia
edit("examples/joystick.jl")  # Linux
edit("examples\\joystick.jl") # Windows
```
For details how to use this example see [joystick](docs/joystick.md) .

If you don't have a Joystick, try the following example:

```julia
./bin/run_julia or bin\run_julia

using KiteSimulators
include("examples/autopilot.jl")  # Linux
include("examples\\autopilot.jl") # Windows
```
You should see that the autopilot starts at 10s and that it is controlling the full power cycle, kite and winch.
For details how to use this example see [autopilot](docs/autopilot.md) .

## Documentation
- The first example explained: [First Example](docs/first_example.md).  
- Reading and writing log files: [Logging](docs/logging.md)
- Plotting results in 2D:  [Plotting](docs/plotting.md)

Most of the packages have their own documentation. See for example:
- [KiteModels](https://ufechner7.github.io/KiteModels.jl/dev/)
- [KiteUtils](https://ufechner7.github.io/KiteUtils.jl/stable/)

and the README files of the other packages, listed below.

## License
This project is licensed under the MIT License. Please see the below WAIVER in association with the license.

## WAIVER
Technische Universiteit Delft hereby disclaims all copyright interest in the package “KiteSimulators.jl” (simulators for airborne wind energy systems) written by the Author(s).

Prof.dr. H.G.C. (Henri) Werij, Dean of Aerospace Engineering

## Donations
If you like this software, please consider donating to https://gofund.me/508e041b .

## See also
- [Research Fechner](https://research.tudelft.nl/en/publications/?search=wind+Fechner&pageSize=50&ordering=rating&descending=true) for the scientic background of this code
- the packages [KiteControllers](https://github.com/aenarete/KiteControllers.jl) and [KiteViewers](https://github.com/aenarete/KiteViewers.jl)
- The packages [KiteModels](https://github.com/ufechner7/KiteModels.jl) and [WinchModels](https://github.com/aenarete/WinchModels.jl) and [KitePodModels](https://github.com/aenarete/KitePodModels.jl) and [AtmosphericModels](https://github.com/aenarete/AtmosphericModels.jl)
- the package [KiteUtils](https://github.com/ufechner7/KiteUtils.jl) 
