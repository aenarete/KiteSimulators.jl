using KiteSimulators, LaTeXStrings
using ControlPlots

# the following values can be changed to match your interest
LOG_FILE_NAME = "output/last_sim_log" # without extension!
# end of user parameter section #

include("plots.jl")

log = load_log(basename(LOG_FILE_NAME), path=fulldir(LOG_FILE_NAME))
plot_main(log)