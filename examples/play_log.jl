using KiteSimulators

kcu::KCU   = KCU(se())
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME_LAPSE_RATIO = 5        # 1 = realtime, 2..8 faster
LOG_FILE = "output/sim_log" # without extension!
# end of user parameter section #

function fulldir(name)
    if occursin("~", name)
        return replace(dirname(name), "~" => homedir())
    else
        return joinpath(pwd(), dirname(name))
    end
end

log=load_log(basename(LOG_FILE); path=fulldir(LOG_FILE))

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