using Timers; tic()
using KiteSimulators

# change this to KPS3 or KPS4
const Model = KPS4

kcu::KCU = KCU(se())
if ! @isdefined kps4;   const kps4 = Model(kcu); end
if ! @isdefined js;
    const js = open_joystick();
    const jsaxes = JSState(); 
    const jsbuttons = JSButtonState()
    async_read!(js, jsaxes, jsbuttons)
end
wcs = WCSettings(); update(wcs); wcs.dt = 1/se().sample_freq
fcs::FPCSettings = FPCSettings(); fcs.dt = wcs.dt
fpps::FPPSettings = FPPSettings()
ssc::SystemStateControl = SystemStateControl(wcs, fcs, fpps)
dt::Float64 = wcs.dt

# the following values can be changed to match your interest
MAX_TIME::Float64=3600
TIME_LAPSE_RATIO = 1
SHOW_KITE = true
# end of user parameter section #

viewer::Viewer3D = Viewer3D(SHOW_KITE, "WinchON")

steps = 0

function simulate(integrator)
    start_time_ns = time_ns()
    clear_viewer(viewer)
    i=1; j=0; k=0
    GC.gc()
    max_time = 0
    t_gc_tot = 0
    sys_state = SysState(kps4)
    on_new_systate(ssc, sys_state)
    while true
        if i > 100
            manual_depower = -jsaxes.y*0.4
            depower = manual_depower + KiteControllers.get_depower(ssc)
            if depower < 0.22; depower = 0.22; end
            steering = calc_steering(ssc, jsaxes.x)
            set_depower_steering(kps4.kcu, depower, steering)
            # set_depower_steering(kps4.kcu, depower, jsaxes.x)
            # v_ro = jsaxes.u * 8.0 
        end  
        # execute winch controller
        v_ro = calc_v_set(ssc)
        t_sim = @elapsed KiteModels.next_step!(kps4, integrator, v_ro=v_ro, dt=dt)
        if t_sim < 0.3*dt
            t_gc_tot += @elapsed GC.gc(false)
        end
        sys_state = SysState(kps4)
        on_new_systate(ssc, sys_state)
        if mod(i, TIME_LAPSE_RATIO) == 0
            KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3)
            set_status(viewer, String(Symbol(ssc.state)))
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
            start_time_ns = time_ns()
            t_gc_tot = 0
        end
        if viewer.stop break end
        if i*dt > MAX_TIME break end
        i += 1
    end
    misses = j/k * 100
    println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    return div(i, TIME_LAPSE_RATIO)
end

function play()
    global steps
    integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
    toc()
    try
        steps = simulate(integrator)
    catch e
        if isa(e, AssertionError)
            println("AssertionError! Halting simulation.")
        else
            println("Exception! Halting simulation.")
        end
    end
    GC.enable(true)
end

function async_play()
    if viewer.stop
        @async begin
            play()
            stop(viewer)
        end
    end
end

function parking()
    on_parking(ssc)
end

function autopilot()
    on_winchcontrol(ssc)
end

on(viewer.btn_PLAY.clicks) do c; async_play(); end
on(viewer.btn_STOP.clicks) do c; stop(viewer); on_stop(ssc) end
on(viewer.btn_PARKING.clicks) do c; parking(); end
on(viewer.btn_AUTO.clicks) do c; autopilot(); end

on(jsbuttons.btn1) do val; if val async_play() end; end
on(jsbuttons.btn2) do val; if val stop(viewer) end; end
on(jsbuttons.btn3) do val; if val autopilot() end; end
on(jsbuttons.btn4) do val; if val on_reelin(ssc) end; end
on(jsbuttons.btn5) do val; if val on_parking(ssc) end; end

play()
stop(viewer)
