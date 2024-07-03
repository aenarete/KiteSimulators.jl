### The autopilot app

#### Starting the app
There are two ways to launch this app:

Firstly, you can launch it from the command line:
```bash
cd bin
./autopilot # Linux
autopilot   # Windows
```
Secondly, you can launch it from the Julia command prompt:
```julia
include("examples/autopilot.jl")
```
after launching Julia with
```bash
bin/run_julia # Linux or bash terminal on Mac/Windows
bin\run_julia # Windows
```

#### The graphical user interface (GUI)
At the bottom of the user interface, you can see seven buttons and one switch.
Clicking the "RUN" button starts the simulation, the STOP button stops it and saves the log file in the output folder.
<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/GUI.png?raw=true" width="500" /></p>
 You can see the name of the current log file at the bottom right. The Zoom buttons allow you to zoom in or out, and the RESET button resets the zoom level to the default (sometimes you have to click it twice). The Autopilot button activates the autopilot (which is the default), and the Parking button puts the kite into the parking position. The repeat switch allows you to run the simulation again and again.

##### The drop-down menus
On the top left of the user interface, you see several drop-down menus. The first one allows you to select one of the many default plots. They get displayed if you select them, if you have closed a plot and want to show it again you can click the OK button.

The default plot looks like this:
<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/main.png?raw=true" width="500" /></p>

If you select the menu entry **print_stats** you can see the statistics of the last three power cycles, for example like this:
<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/statistics.png?raw=true" width="500" /></p>
The power is the mechanical power.

The second drop-down menu allows selecting different simulation tolerances. The default is usually a good compromise between accuracy and performance.

The third dropdown menu allows to change the speed of the simulation between reel-time (1x) and 12 times faster than reel-time. Choose a value that suits your needs and that your computer can handle well.

The fourth dropdown menu allows loading one of the project files that are present in the **data** folder. Saving and editing have not yet been implemented. To save and edit a project file use an editor of your choice.

The following project files are provided by default:
- hydra10_951.yml: hydra kite with 10 m² projected area at 9.51 m/s wind speed at 6m height
- hydra20_426.yml: hydra kite with 20 m² projected area at 4.26 m/s wind speed at 6m height
- hydra20_600.yml: hydra kite with 20 m² projected area at 6.00 m/s wind speed at 6m height
- hydra20_920.yml: hydra kite with 20 m² projected area at 9.20 m/s wind speed at 6m height
