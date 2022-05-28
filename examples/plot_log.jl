using KiteSimulators, Plots.PlotMeasures

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = KPS4(kcu); end

# the following values can be changed to match your interest
const dt = 0.05
LOG_FILE_NAME = "sim_log" # without extension!
PARTICLES = 7 + 4         # 7 for tether and KCU, 4 for the kite
# end of user parameter section #

log = load_log(PARTICLES, LOG_FILE_NAME)
ma = -2mm
p1 = plot(log.syslog.time, log.z,  ylabel="height [m]", link=:x, bottom_margin=ma, xformatter=_->"", legend=false)
p2 = plot(log.syslog.time, rad2deg.(log.syslog.elevation), top_margin=ma, bottom_margin=ma, xformatter=_->"", ylabel="elevation [°]", legend=false)
p3 = plot(log.syslog.time, rad2deg.(log.syslog.azimuth), top_margin=ma, bottom_margin=ma, ylabel="azimuth [°]", legend=false)
p4 = plot(log.syslog.time, log.syslog.l_tether, top_margin=ma, bottom_margin=ma, ylabel="length [m]", legend=false)
p5 = plot(log.syslog.time, log.syslog.force, top_margin=ma, bottom_margin=ma, ylabel="force [N]", legend=false)
p6 = plot(log.syslog.time, log.syslog.v_reelout, top_margin=ma, xlabel="Simulation time [s]", ylabel="v_ro [m/s]", legend=false)

width = 800
height = 800
plot(p1, p2, p3, p4, p5, p6, layout=(6,1), size = (width, height), legend = false)