### The joystick app

#### Starting the app
There are two ways to launch this app:

Firstly, you can launch it from the command line:
```bash
cd bin
./joystick # Linux or bash terminal on Mac/Windows
joystick   # Windows
```
Secondly, you can launch it from the Julia command prompt:
```julia
include("examples/joystick.jl")
```
after launching Julia with
```bash
bin/run_julia # Linux or bash terminal on Mac/Windows
bin\run_julia # Windows
```

#### The graphical user interface (GUI)
At the bottom of the user interface, you can see seven buttons and one switch.
Clicking the "RUN" button starts the simulation, the STOP button stops it.
<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/kite_4p.png?raw=true" width="500" /></p>
 You can see the controller state on the bottom left. The Zoom buttons allow you to zoom in or out, and the RESET button resets the zoom level to the default (sometimes you have to click it twice). The WinchON button activates the winch controller, and the Parking button puts the kite into the parking position (steering towards zenith).

 #### The joystick buttons
 The numbering of the buttons is as shown in the following picture:

<p align="center"><img src="https://github.com/aenarete/KiteSimulators.jl/blob/main/docs/joystick_buttons.png?raw=true" width="500" /></p>
The x-axis of the Joystick controls steering, but only when in state ssWinchControl, in state ssParking the parking controller controls the steering. By pressing the joystick forward you can depower the kite.

Button 3 starts the reel-out, button 4 the reel-in, and button 5 switches to parking mode (no reel-in or reel-out). With button one, you can start the simulation, with button two you can stop it.