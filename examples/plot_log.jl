using KiteSimulators
using PyPlot
using ControlPlots

function configure_matplotlib_backend()
	if !Sys.isapple()
		return nothing
	end
	for backend in ("qtagg", "QtAgg", "macosx")
		try
			PyPlot.matplotlib.use(backend, force = true)
			return backend
		catch
		end
	end
	return nothing
end

configure_matplotlib_backend()

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
