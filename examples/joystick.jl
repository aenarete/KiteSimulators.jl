using KiteSimulators

# change this to KPS3 or KPS4
const Model = KPS4

if ! @isdefined kcu;    const kcu = KCU(se());   end
if ! @isdefined kps4;   const kps4 = Model(kcu); end
if ! @isdefined js;
    const js = open_joystick();
    const jsaxes = JSState(); 
    const jsbuttons = JSButtonState()
    async_read!(js, jsaxes, jsbuttons)
end

# the following values can be changed to match your interest
dt = 0.05
MAX_TIME=3600
TIME_LAPSE_RATIO = 1
SHOW_KITE = true
PLOT_PERFORMANCE = true
# end of user parameter section #

if ! @isdefined viewer; const viewer = Viewer3D(SHOW_KITE); end
if ! @isdefined time_vec_tot; const time_vec_tot = zeros(Int(MAX_TIME/dt)); end
if ! @isdefined time_vec_gc; const time_vec_gc = zeros(Int(MAX_TIME/dt)); end

steps=0

function update_system2(kps)
    sys_state = SysState(kps)
    KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3)
end 

function simulate(integrator)
    start = integrator.p.iter
    start_time_ns = time_ns()
    clear_viewer(viewer)
    i=1
    j=0; k=0
    GC.gc()
    max_time = 0
    t_gc_tot = 0
    while true
        v_ro = 0.0
        if i > 100
            depower = 0.25 - jsaxes.y*0.4
            if depower < 0.25; depower = 0.25; end
            set_depower_steering(kps4.kcu, depower, jsaxes.x)
            v_ro = jsaxes.u * 8.0 
        end   
        t_sim = @elapsed KiteModels.next_step!(kps4, integrator, v_ro=v_ro, dt=dt)
        if t_sim < 0.3*dt
            t_gc_tot += @elapsed GC.gc(false)
        end
        if mod(i, TIME_LAPSE_RATIO) == 0 
            update_system2(kps4) 
            end_time_ns = time_ns()
            wait_until(start_time_ns + 1e9*dt, always_sleep=true) 
            mtime = 0
            if i > 10/dt 
                # if we missed the deadline by more than 5 ms
                mtime = time_ns() - start_time_ns
                if mtime > dt*1e9 + 5e6
                    print(".")
                    j += 1
                end
                k +=1
            end
            if mtime > max_time
                max_time = mtime
            end            
            time_tot = end_time_ns - start_time_ns
            start_time_ns = time_ns()
            time_vec_tot[div(i, TIME_LAPSE_RATIO)] = time_tot/1e9/dt*1000*dt
            time_vec_gc[div(i, TIME_LAPSE_RATIO)] = t_gc_tot/dt*1000*dt
            t_gc_tot = 0
        end
        if viewer.stop break end
        i += 1
    end
    misses = j/k * 100
    println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    return div(i, TIME_LAPSE_RATIO)
end

function play()
    global steps
    integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
    steps = simulate(integrator)
end

function async_play()
    if viewer.stop
        @async begin
            play()
            stop(viewer)
            if PLOT_PERFORMANCE
                plt = plot(range(5*TIME_LAPSE_RATIO*dt,steps*dt,step=dt*TIME_LAPSE_RATIO), time_vec_tot[5:steps],  xlabel="Simulation time [s]", ylabel="time per frame [ms]", label="time_tot")
                plt = plot!(range(5*TIME_LAPSE_RATIO*dt,steps*dt,step=dt*TIME_LAPSE_RATIO), time_vec_gc[5:steps], label="time_gc")
                display(plt)
            end
        end
    end
end

on(viewer.btn_PLAY.clicks) do c; async_play(); end
on(jsbuttons.btn1) do val; if val async_play() end; end

on(viewer.btn_STOP.clicks) do c; stop(viewer); end
on(jsbuttons.btn2) do val; if val stop(viewer) end; end

stop(viewer)
async_play()
wait(display(viewer.scene))
