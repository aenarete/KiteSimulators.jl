## Logging

### Creating a log file
If you run the following command with `LOGGING = true` in line 19
```julia
 include("examples/depower.jl")
```
A log file with the name `sim_log.arrow` will be created in the output folder. It uses an .xz compressed [arrow](https://arrow.apache.org/) format which is fast to load and small. This actually the same as the "Feather V2" file format.

### Add logging to your own scripts
The following functions are needed to add logging to your script:
```julia
LOG_FILE = "output/sim_log"                 # name of the log file without file ending 
logger = Logger(se().segments + 5, steps)   # create a logger when using the 4 point model
# logger = Logger(se().segments + 1, steps) # create a logger when using the 1 point model

# each time step
state = SysState(kps4)
log!(logger, state)

# save the log file
save_log(logger, basename(LOG_FILE); path=dirname(LOG_FILE))
```
If you do not pass a path name to save_log the `data_path` is being used. You can check the data_path using the function `get_data_path()`.

### Playing a log file in the 3D viewer
Open the file `examples/play_log.jl` and change the following lines according to your needs:

```julia
TIME_LAPSE_RATIO = 5             # 1 = realtime, 2..10 faster
LOG_FILE      = "output/sim_log" # without extension!
PARTICLES = 7 + 4                # 7 for tether and KCU, 4 for the kite
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
include("examples/convert_log.jl")
```
This script loads the log file with the name `sim_log.arrow` and exports it to .csv format under the name `sim_log.csv`.

### Reading .arrow files in Python
It is very easy to read .arrow files and convert them to Pandas dataframes which is a kind of standard data format
for tabular data in Python.

Example:
```Python
import pandas as pd
import pyarrow as pa

print("Reading arrow file...")
mmap = pa.memory_map('../data/sim_log.arrow')

with mmap as source:
    array = pa.ipc.open_file(source).read_all()

table = array.to_pandas()
print(table)
```

Continue with [README](../README.md)
