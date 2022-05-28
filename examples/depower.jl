using KiteSimulators

set_data_path(joinpath(@__DIR__, "..", "data"))
tic()

const Model = KPS4

set = se()

if ! @isdefined kcu;  const kcu = KCU(set);   end
if ! @isdefined kps4; const kps4 = Model(kcu); end

# the following values can be changed to match your interest
const dt = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_KITE = true
PLOT_PERFORMANCE = false
LOGGING = true
# end of user parameter section #

if Model==KPS3 SHOW_KITE = true end

if ! @isdefined time_vec_gc; const time_vec_gc = zeros(STEPS); end
if ! @isdefined time_vec_sim; const time_vec_sim = zeros(STEPS); end
if ! @isdefined time_vec_tot; const time_vec_tot = zeros(div(STEPS, TIME_LAPSE_RATIO)); end
if ! @isdefined viewer; const viewer = Viewer3D(SHOW_KITE); end

logger=Logger(se().segments + 5)

function simulate(integrator, steps)
    global logger
    start = integrator.p.iter
    start_time_ns = time_ns()
    j=0; k=0
    KiteViewers.clear_viewer(viewer)
    GC.gc()
    max_time = 0
    for i in 1:steps
        if i == 300
            set_depower_steering(kps4.kcu, 0.30, 0.0)
        elseif i == 640
            set_depower_steering(kps4.kcu, 0.35, 0.0)    
        end
        t_sim = @elapsed KiteModels.next_step!(kps4, integrator, dt=dt)
        t_gc = 0.0
        if t_sim < 0.08*dt
            t_gc = @elapsed GC.gc(false)
        end
        t_show = 0.0
        state = SysState(kps4)
        if LOGGING log!(logger, state) end
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            t_show = @elapsed update_system(viewer, state; scale = 0.08, kite_scale=3.0)
            end_time_ns = time_ns()
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            mtime = 0
            if i > 10/dt 
                # if we missed the deadline by more than 2 ms
                mtime = time_ns() - start_time_ns
                if mtime > dt*1e9 + 2e6
                    print(".")
                    j += 1
                end
                k +=1
            else
                t_show = 0.0
            end
            if mtime > max_time
                max_time = mtime
            end
            time_tot = end_time_ns - start_time_ns
            start_time_ns = time_ns()
            time_vec_tot[div(i, TIME_LAPSE_RATIO)] = time_tot/1e9/dt*1000*dt
        end
      
        time_vec_gc[i]=t_gc/dt*100.0
        time_vec_sim[i]=t_sim/dt*100.0
        if viewer.stop break end
        if LOGGING save_log(logger) end
    end
    misses=j/k * 100
    println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    (integrator.p.iter - start) / steps
end

function play()
    integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04, prn=STATISTIC)
    simulate(integrator, STEPS)
end

on(viewer.btn_PLAY.clicks) do c
    if viewer.stop
        @async begin
            play()
            stop(viewer)
        end
    end
end
on(viewer.btn_STOP.clicks) do c
   stop(viewer)
end

toc()
play()
stop(viewer)
if PLOT_PERFORMANCE
    using Plots
    if true
        plt=plot(range(dt,TIME,step=dt), time_vec_gc, ylabel="time [%]", xlabel="Simulation time [s]", label="GC time")
        plt=plot!(range(dt,TIME,step=dt), time_vec_sim, label="sim_time")
        plt=plot!(range(dt,TIME,step=dt), time_vec_sim.+time_vec_gc, label="total_time")
    else
        plt2=plot(range(3*TIME_LAPSE_RATIO*dt,TIME,step=dt*TIME_LAPSE_RATIO), time_vec_tot[4:end],  xlabel="Simulation time [s]", ylabel="time per frame [ms]", legend=false)
    end
end