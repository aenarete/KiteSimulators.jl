using KiteSimulators

# example program that shows
# a. how to create a video
# b. how to create a performance plot (simulation speed vs time)

set = deepcopy(load_settings("system.yaml"))
set.version = 2

kcu::KCU   = KCU(set)
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS::Int64 = Int64(round(TIME/dt))
STATISTIC = false
SHOW_VIEWER = true
SHOW_KITE = true
SAVE_PNG  = false
PLOT_PERFORMANCE = true
# end of user parameter section #

if ! @isdefined time_vec; const time_vec = zeros(div(STEPS, TIME_LAPSE_RATIO)); end
viewer::Viewer3D = Viewer3D(SHOW_KITE)

# ffmpeg -r:v 20 -i "video%06d.png" -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 10 -an "video.mp4"

function update_system2(kps)
     sys_state = SysState(kps)
     KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3.0)
end 

function simulate(integrator, steps; log=false)
    iter = 0
    start_time_ns = time_ns()
    time_ = 0.0
    v_ro = 0.0
    acc = 0.1
    clear_viewer(viewer)
    time_ = 0.0
    for i in 1:steps
        iter = kps4.iter
        if i > 300
            v_ro += acc*dt
        end
        time_ += @elapsed KiteModels.next_step!(kps4, integrator; set_speed=v_ro, dt=dt)     
        iter += kps4.iter
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            if SHOW_VIEWER update_system2(kps4) end
            if log
                save_png(viewer, index=div(i, TIME_LAPSE_RATIO))
            end
            if SHOW_VIEWER
                wait_until(start_time_ns+dt*1e9, always_sleep=true) 
            end
            start_time_ns = time_ns()
            time_vec[div(i, TIME_LAPSE_RATIO)]=time_/(TIME_LAPSE_RATIO*dt)*100.0
            time_ = 0.0
        end
    end
    iter / steps
end

integrator = KiteModels.init_sim!(kps4; delta=0, stiffness_factor=1.0, prn=STATISTIC)

av_steps = simulate(integrator, STEPS, log=SAVE_PNG)
if PLOT_PERFORMANCE
    using ControlPlots
    p = plot(range(0.25,TIME,step=0.25), time_vec, ylabel="CPU time [%]", xlabel="Simulation time [s]")
    display(p)
    # plots.savefig("performance.png")
end
# mean with :Dense integrator: 6.66% CPU time, 15 times realtime
# mean with :GMRES integrator: 1.96% CPU time, 51 times realtime
