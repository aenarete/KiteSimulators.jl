## Logging

### Creating a log file
If you run the following command:
```julia
 include("examples/depower.jl")
```
A log file with the name `sim_log.arrow` will be created in the data folder. It uses an .xz compressed [arrow](https://arrow.apache.org/) format which is fast to load and small.

### Add logging to your own scripts
The following functions are needed to add logging to your script:
```julia
logger = Logger(se().segments + 5)   # create a logger when using the 4 point model
# logger = Logger(se().segments + 1) # create a logger when using the 1 point model

# each time step
state = SysState(kps4)
log!(logger, state)

# save the log file
save_log(logger) 
```

### Playing a log file in the 3D viewer
Open the file `examples/play_log.jl` and change the following lines according to your needs:

```julia
TIME_LAPSE_RATIO = 5      # 1 = realtime, 2..8 faster
LOG_FILE_NAME = "sim_log" # without extension!
PARTICLES = 7 + 4         # 7 for tether and KCU, 4 for the kite
```
Now you can play the log file with the following command:

```julia
include("examples/play_log.jl")
```

### Converting log files

#### Converting into .csv format
The function `export_log(log_file)` can be used to export a log file to .csv format.

Example:
```julia
include("examples/convert.log.jl")
```
This script loads the log file with the name `sim_log.arrow` and exports it to .csv format under the name `sim_log.csv`.

Continue with [README](../README.md)
