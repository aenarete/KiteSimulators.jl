using KiteSimulators

# the following values can be changed to match your interest
LOG_FILE_NAME = "output/last_sim_log" # without extension!
# end of user parameter section #

log_file = load_log(basename(LOG_FILE_NAME), path=fulldir(LOG_FILE_NAME))
export_log(log_file, path=fulldir(LOG_FILE_NAME))
# log_file.name="sim_log_uncompressed"
# save_log(log_file, false)
