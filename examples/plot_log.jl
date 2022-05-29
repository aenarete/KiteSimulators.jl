using KiteSimulators, Plots.PlotMeasures, Plots
import Plots.plot

# the following values can be changed to match your interest
LOG_FILE_NAME = "sim_log" # without extension!
PARTICLES = 7 + 4         # 7 for tether and KCU, 4 for the kite
# end of user parameter section #

log = load_log(PARTICLES, LOG_FILE_NAME)
ma = -2mm
sl = log.syslog
p1 = plot(sl.time, log.z,  ylabel="height [m]", link=:x, top_margin=0, bottom_margin=ma, xformatter=_->"", legend=false)
p2 = plot(sl.time, rad2deg.(sl.elevation), bottom_margin=ma, xformatter=_->"", ylabel="elevation [°]", legend=false)
p3 = plot(sl.time, rad2deg.(sl.azimuth), bottom_margin=ma, xformatter=_->"", ylabel="azimuth [°]", legend=false)
p4 = plot(sl.time, sl.l_tether, bottom_margin=ma, xformatter=_->"", ylabel="length [m]", legend=false)
p5 = plot(sl.time, sl.force, bottom_margin=ma, xformatter=_->"", ylabel="force [N]", legend=false)
p6 = plot(sl.time, sl.v_reelout, xlabel="Simulation time [s]", ylabel="v_ro [m/s]", legend=false)

width = 800
height = 800
plot(p1, p2, p3, p4, p5, p6, layout=(6,1), top_margin=ma, size = (width, height), legend = false)
# savefig("data/2d_plot.png")