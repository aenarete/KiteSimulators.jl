using KiteSimulators, LaTeXStrings
using ControlPlots

# the following values can be changed to match your interest
LOG_FILE_NAME = "output/last_sim_log" # without extension!

include("plots.jl")

log = load_log(basename(LOG_FILE_NAME), path=fulldir(LOG_FILE_NAME))
plot_main(log)

# Also available:
#
# plot_timing(log)
# plot_power(log)
# plot_control(log)
# plot_control_II(log)
# plot_winch_control(log)
# plot_elev_az(log)
# plot_elev_az2(log)
# plot_elev_az3(log)
# plot_side_view(log)
# plot_side_view2(log)
# plot_side_view3(log)
# plot_front_view3(log)
# plot_aerodynamics(log)
