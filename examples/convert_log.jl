using KiteSimulators

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = KPS4(kcu); end

# the following values can be changed to match your interest
const dt = 0.05
TIME_LAPSE_RATIO = 5      # 1 = realtime, 2..8 faster
LOG_FILE_NAME = "sim_log" # without extension!
PARTICLES = 7 + 4         # 7 for tether and KCU, 4 for the kite
# end of user parameter section #

log_file = load_log(PARTICLES, LOG_FILE_NAME)
export_log(log_file)
# log_file.name="sim_log_uncompressed"
# save_log(log_file, compress=false)
