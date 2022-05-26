using KiteSimulators

# example program that shows
# a. how to create a video
# b. how to create a performance plot (simulation speed vs time)
const Model = KPS4

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = Model(kcu); end

# the following values can be changed to match your interest
dt = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_VIEWER = true
SHOW_KITE = true
SAVE_PNG  = false
PLOT_PERFORMANCE = false
# end of user parameter section #

if ! @isdefined time_vec; const time_vec = zeros(div(STEPS, TIME_LAPSE_RATIO)); end
if ! @isdefined viewer; const viewer = Viewer3D(SHOW_KITE); end

# ffmpeg -r:v 20 -i "video%06d.png" -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 10 -an "video.mp4"

function update_system2(kps)
     sys_state = SysState(kps)
     KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3.0)
end 

function simulate(integrator, steps; log=false)
    start = integrator.p.iter
    start_time_ns = time_ns()
    time_ = 0.0
    v_ro = 0.0
    acc = 0.1
    clear_viewer(viewer)
    for i in 1:steps
        iter = kps4.iter
        if i > 300
            v_ro += acc*dt
        end
        KiteModels.next_step!(kps4, integrator, v_ro=v_ro, dt=dt)     
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
        time_ += (kps4.iter - iter)*1.5e-6
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04, prn=STATISTIC)

av_steps = simulate(integrator, STEPS, log=SAVE_PNG)
if PLOT_PERFORMANCE
    using Plots
    plot(range(0.5,TIME,step=0.5), time_vec, ylabel="CPU time [%]", xlabel="Simulation time [s]", legend=false)
    savefig("performance.png")
end
# mean with :Dense integrator: 6.66% CPU time, 15 times realtime
# mean with :GMRES integrator: 1.96% CPU time, 51 times realtime
