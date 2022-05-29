## Plotting results in 2D

If you have created a log file of a simulation, you can plot the result using the following commands:

```julia
include("examples/plot_log.jl")  # Linux
include("examples\\plot_log.jl") # Windows
```

You can save the plot using the following command:
```julia
savefig("data/2d_plot.png")
```
<p align="center"><img src="2d_plot.png" width="600" /></p>

To modify the plot, create a copy of plot_log.jl and modify this file according to your needs.

Read more about plotting in Julia at https://docs.juliaplots.org/latest/

Continue with [README](../README.md)