# First example of running a simulation

In this example we start the the kite in a position close to the equilibrium (parking kite).

The script `depower_simple.jl` starts with the following lines:

```julia
using KiteSimulators

kcu::KCU   = KCU(se())
kps4::KPS4 = KPS4(kcu)
```
In the first line, we import all functions and types from all packages of "Julia Kite Power Tools" into the current namespace.

Then we define two variables, one that represents the Kite Control Unit (KCU) and one for the Kite Power System, using the 4-point kite model. We declare the two variables to be of the type `KCU` and the type `KPS4` to avoid the performance penalty you would get if you omit the type. What cannot be changed at runtime are the CL/CD curves and the number of tether segments.

Then we define a few simulation parameters:
```julia
# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 45
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
# end of user parameter section #
```
The time-step `dt` is defined to be 50ms. This is the time step used by the control loop and the viewer, internally the solver is using a much smaller, variable time step. `TIME` is the simulation time in seconds. Without active control, the kite crashes after about 50 seconds, so making this value too high does not make sense in this example. The `TIME_LAPSE_RATIO` defines how many times faster than real-time we want to run the simulation. If you have a slow computer or want to see in more detail what is happening, then reduce this value.

```julia
viewer::Viewer3D = Viewer3D(true)
```
This line creates the 3D viewer and displays it on the screen. If you use the parameter `false` the 3D kite is omitted which can speed up the simulation further.

Now comes the function that actually runs the simulation:
```julia
function simulate(integrator, steps)
    start_time_ns = time_ns()
    KiteViewers.clear_viewer(viewer)
    for i in 1:steps
        if i == 300
            set_depower_steering(kps4.kcu, 0.30, 0.0)
        elseif i == 640
            set_depower_steering(kps4.kcu, 0.35, 0.0)    
        end
        KiteModels.next_step!(kps4, integrator, dt=dt)
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system(viewer, SysState(kps4); scale = 0.08, kite_scale=3.0)
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            start_time_ns = time_ns()
        end
    end
end
```
The variable `start_time` stores the start time of the last set of simulation steps. If we have a TIME_LAPSE_FACTOR of five we run 5 simulation steps before updating the screen, and we update the screen every 50ms. We use the function `wait_until` to achieve precise timing.

In the simulation loop, we first determine the control parameters. In this example that is very simple: After 300 steps (15s simulation time) we set the depower value to 30% and after 640 steps to 35% (the initial value is 25%).

Then we let the model simulate the next step.

Finally, after the TIME_LAPSE_RATIO steps we update the display with the function `update_system` and wait for the next time step. The parameter `always_sleep=true` is needed to call the Julia sleep function for at least 1 ms. This allows background processes to run, in this case, it is mainly the background process that updates the screen.

```julia
integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
simulate(integrator, STEPS)

stop(viewer)
```
The last three lines are the main part of the program. It 
- initializes the integrator
- runs the simulation and
- stops the viewer (displays the message "Stopped...")

The stiffness factor is the relative initial tether and bridle stiffness. If the value is choosen too large the solver will not be able to find the initial equilibrium. If the value is choosen too low it will take too long until the nominal stiffness is reached. 

You can run this example with the following commands:
```julia
include("examples/depower_simple.jl")  # Linux
include("examples\\depower_simple.jl") # Windows
```

Continue with [README](../README.md)
