import pandas as pd
import pyarrow as pa

EXPORT_FEATHER = True

print("Reading arrow file...")
mmap = pa.memory_map('../data/sim_log.arrow')

with mmap as source:
    array = pa.ipc.open_file(source).read_all()

# this gives just one table; 
table = array.to_pandas()
print(table)
