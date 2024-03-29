using KiteSimulators

kcu::KCU   = KCU(se())
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME_LAPSE_RATIO = 5      # 1 = realtime, 2..8 faster
LOG_FILE_NAME = "sim_log" # without extension!
# end of user parameter section #

log=load_log(LOG_FILE_NAME)

viewer::Viewer3D = Viewer3D(true)

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

play(log.syslog)
stop(viewer)