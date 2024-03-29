using KiteSimulators

# the following values can be changed to match your interest
LOG_FILE_NAME = "sim_log" # without extension!
# end of user parameter section #

log_file = load_log(LOG_FILE_NAME)
export_log(log_file)
# log_file.name="sim_log_uncompressed"
# save_log(log_file, false)
