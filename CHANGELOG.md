# Changelog

### Unreleased
#### Added
- add control_plots_II diagram
- add hydra20_926 project with high wind speed
- add copyright waiver from TU Delft
- add section kps4_3l to settings files
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
