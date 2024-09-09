# Changelog
### KiteSimulators v0.4.1 - 2024-09-09
#### Changed
- the build script now only installs `matplotlib` if it is not yet installed on the system
- improved the example `joystick.jl` and its documentation
- bump KiteControllers to 0.2.10
- bump KiteModels to 0.6.6  
A new kite model (KPS4_3L) was added, that uses three winches at the ground to steer the kite.
The new variant (version 3) of the KPS4 kite model allows to define polars that do not depend on the steering input, which makes it easier to define new kites.
- bump KitePodModels to 0.3.3  
A simplified KitePodModel was added with a linear relationship between depower setting and depower angle, which makes it easier to define new KCUs.
#### Added
- a new, torque controlled winch model
- you can now define the diameter and the aerodynamic drag coefficient of the KCU
- plot `aerodynamics`
#### Fixed
- changes of the polars had no effect
- changes of ```max_steering``` had no effect
#### Braking
- the function `next_step!` now requires either the parameter `set_speed`, which replaces `v_ro`, or the parameter `set_torque`, depending on the question if you use the `AsynchGenerator` or `TorqueControlledWinch` in the settings
- the function `init_sim` has the new parameter `delta`. It should be between 0.0 and 0.03 and defines the pre-tension of the tether. The parameter `stiffness_factor` should be between 0.1 and 1.0 and not longer smaller than 0.1.
- the constructor `FPCSettings` now requires the named parameter `dt`
- the constructor `SystemStateControl` now requires the named parameter `u_d0` and `u_d`

### KiteSimulators v0.3.13 - 2024-07-30
#### Fixed
- freeze KitePodModels at version 0.3.1

### KiteSimulators v0.3.12 - 2024-07-16
#### Changed
- bump KiteControllers to 0.2.9
- bump GLMakie to 0.10.5
#### Added
- add project hydra10_951
#### Fixed
- fix the wind profile for the hydra20 projects
- saving of plots works again
- all examples have been tested and fixed where needed

### KiteSimulators v0.3.11 - 2024-07-08
#### Added
- add documentation `joystick.md`

#### Changed
- reduced simulation frequency to 20 Hz as required for Windows
- reduced default time-lapse to 6x as required for Windows
- use FAST_EXP instead of EXP law for the hydra20 settings to improve performance
- smaller font for Windows
- fix the example `joystick.jl`
- update README.md

### KiteSimulators v0.3.10 - 2024-07-04
#### Added
- add control_plots_II diagram
- add hydra20_926 project with high wind speed
- add copyright waiver from TU Delft
- add section kps4_3l to settings files
- add function `fulldir()` to this package
- add documentation page `autopilot.md`
#### Changed
- the script `autopilot.jl` is logging additional fields
- update the hydra20 projects, both work fine now
- bump KiteControllers to 0.2.6
- bump KiteModels to 0.5.16
- bump KiteUtils to 0.6.16
- remove support of Julia 1.9
- fix the example plot_log.jl
- update documentation of logging

###  KiteSimulators v0.3.9 - 2024-05-10
#### Fixes
- all batch files now use `.so` as the filename extension of the system image instead of `.dll`

###  KiteSimulators v0.3.8 - 2024-05-09
#### Fixes
- fix the .bat files needed for Windows using Julia 1.10
- update the documentation

### KiteSimulators v0.3.7 - 2024-05-09
#### Changes
- replace the plotting library `Plots` with `ControlPlots` to speed up compilation and avoid error messages
- the autopilot example GUI provides now the possibility to load three different projects (well, any project file that has the ending .yml and exists in the data folder)
- the configuration of the flight path controller and flight path planner happens now using the related .yaml files
- more diagrams added, statistics dialog extended
- log files are now stored in the `output` folder by default

### KiteSimulators v0.3.6 - 2024-04-04
#### Fixes
- displaying the statistics of a simulation using the menu entry `print_statistics` works again

### KiteSimulators v0.3.5 - 2024-04-03
#### Changed
- updated the example `autopilot.jl`  
  - the example can now be launched directly by executing `bash/autopilot` on Linux  
  - the GUI is now updated 40x per second which gives a smoother visual experience
  - default simulation speed is set to 4x
- a new solver, `DFBDF` was added. It is much faster, uses less memory and is 10x more accurate  
  when using a relative accuracy of $5 \cdot 10^{-4}$

### KiteSimulators v0.3.0 - 2024-03-30
#### Changed
- the log file format changed, old log files cannot be opened with this version
- the number of segments is added as metadata to the log files
- five variables have been added to the SystemState that can be freely used, their names can be  
  added as metadata to the log file

#### Added
- the example autopilot.jl was vastly improved
- a menu with 6 pre-defined plots was added to the GUI
- a statistics dialog was added
- saving and loading of log files added
- a second menu was added that allows to change the tolerance of the solver
