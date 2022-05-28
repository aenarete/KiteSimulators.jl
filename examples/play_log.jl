using KiteSimulators

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = KPS4(kcu); end

# the following values can be changed to match your interest
const dt = 0.05
TIME_LAPSE_RATIO = 5
# end of user parameter section #

log=load_log(7+4, "sim_log")

if ! @isdefined viewer; const viewer = Viewer3D(true); end

function play(syslog)
    steps = length(syslog.time)
    start_time_ns = time_ns()
    KiteViewers.clear_viewer(viewer)
    for i in 1:steps
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system(viewer, syslog[i]; scale = 0.08, kite_scale=3.0)
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            start_time_ns = time_ns()
        end
    end
end

integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
play(log.syslog)

stop(viewer)