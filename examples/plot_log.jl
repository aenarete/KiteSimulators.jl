using KiteSimulators, LaTeXStrings
using ControlPlots

# the following values can be changed to match your interest
LOG_FILE_NAME = "sim_log" # without extension!
# end of user parameter section #

log = load_log(LOG_FILE_NAME)
include("plots.jl")
plot_main(log)