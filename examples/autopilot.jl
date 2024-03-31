# activate the test environment if needed
using Pkg
if ! ("ControlPlots" ∈ keys(Pkg.project().dependencies))
    using TestEnv; TestEnv.activate()
end
using Timers; tic()

using KiteControllers, KiteViewers, KiteModels, StatsBase, ControlPlots, NativeFileDialog, LaTeXStrings
using Printf
import KiteViewers.GLMakie

set = deepcopy(se())

# the following values can be changed to match your interest
MAX_TIME::Float64 = 460
TIME_LAPSE_RATIO  = 4
SHOW_KITE         = true
set.segments = 6
# end of user parameter section #

kcu::KCU   = KCU(set)
kps4::KPS4 = KPS4(kcu)

wcs = WCSettings(); update(wcs); wcs.dt = 1/set.sample_freq
fcs::FPCSettings = FPCSettings(); fcs.dt = wcs.dt
fpps::FPPSettings = FPPSettings()
ssc::SystemStateControl = SystemStateControl(wcs, fcs, fpps)
dt::Float64 = wcs.dt
initialized = true

function init_globals()
    global kcu, kps4, wcs, fcs, fpps, ssc, initialized
    if ! initialized
        kcu   = KCU(set)
        kps4 = KPS4(kcu)
        wcs = WCSettings(); update(wcs); wcs.dt = 1/set.sample_freq
        fcs = FPCSettings(); fcs.dt = wcs.dt
        fpps = FPPSettings()
        ssc = SystemStateControl(wcs, fcs, fpps)
    end
    initialized = false
    KiteViewers.plot_file[]="last_sim_log"
end

viewer::Viewer3D = Viewer3D(set, SHOW_KITE; menus=true)
viewer.menu.options[]=["plot_main", "plot_power", "plot_control", "plot_elev_az", "plot_side_view", "plot_timing", "print_stats", "load logfile", "save logfile"]
viewer.menu_rel_tol.options[]=["0.0005","0.0001","0.00005", "0.00001","0.000005","0.000001"]
viewer.menu_rel_tol.i_selected[]=1
PARKING::Bool = false

steps = 0
STEPS::Int64 = Int64(MAX_TIME/dt)
if ! @isdefined T;        const T = zeros(STEPS); end
if ! @isdefined DELTA_T;  const DELTA_T = zeros(STEPS); end
if ! @isdefined STEERING; const STEERING = zeros(STEPS); end
if ! @isdefined DEPOWER_; const DEPOWER_ = zeros(STEPS); end
LAST_I::Int64=0
PARTICLES::Int64 = set.segments + 5
logger::Logger = Logger(PARTICLES, STEPS) 

function simulate(integrator, stopped=true)
    global LAST_I, logger
    start_time_ns = time_ns()
    clear_viewer(viewer)
    KiteViewers.running[] = ! stopped
    viewer.stop = stopped
    if ! stopped
        set_status(viewer, "ssParking")
    end
    i=1
    j=0; k=0
    GC.enable(true)
    GC.gc()
    if Sys.total_memory()/1e9 > 24 && MAX_TIME < 500
        GC.enable(false)
    end
    max_time = 0
    t_gc_tot = 0
    sys_state = SysState(kps4)
    sys_state.e_mech = 0
    sys_state.sys_state = Int16(ssc.fpp._state)
    e_mech = 0.0
    on_new_systate(ssc, sys_state)
    logger = Logger(PARTICLES, STEPS) 
    KiteViewers.update_system(viewer, sys_state; scale = 0.04/1.1, kite_scale=6.6)
    log!(logger, sys_state)
    while true
        if viewer.stop
            sleep(dt)
        else
            if i == 1
                integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
            end
            if i > 100
                dp = KiteControllers.get_depower(ssc)
                if dp < 0.22 dp = 0.22 end
                steering = calc_steering(ssc)
                set_depower_steering(kps4.kcu, dp, steering)
            end
            if i == 200 && ! PARKING
                on_autopilot(ssc)
            end
            # execute winch controller
            v_ro = calc_v_set(ssc)
            #
            t_sim = @elapsed KiteModels.next_step!(kps4, integrator, v_ro=v_ro, dt=dt)
            sys_state = SysState(kps4)
            if i <= length(T)
                T[i] = dt * i
                if i > 10/dt
                    sys_state.t_sim  = t_sim * 1000
                    STEERING[i] = sys_state.steering
                    DEPOWER_[i] = sys_state.depower
                    LAST_I=i
                end
            end
            on_new_systate(ssc, sys_state)
            e_mech += (sys_state.force * sys_state.v_reelout)/3600*dt
            sys_state.e_mech = e_mech
            sys_state.sys_state = Int16(ssc.fpp._state)
            log!(logger, sys_state)
            if mod(i, TIME_LAPSE_RATIO) == 0 
                KiteViewers.update_system(viewer, sys_state; scale = 0.04/1.1, kite_scale=6.6)
                set_status(viewer, String(Symbol(ssc.state)))
                # turn garbage collection back on if we are short of memory
                if Sys.free_memory()/1e9 < 2.0
                    GC.enable(true)
                end
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
            i += 1
        end
        if ! isopen(viewer.fig.scene) break end
        if KiteViewers.status[] == "Stopped" && i > 10 break end
        if i*dt > MAX_TIME break end
    end
    if i > 10/dt
        misses = j/k * 100
        println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    end
    return div(i, TIME_LAPSE_RATIO)
end

function play(stopped=false)
    global steps, kcu, kps4, wcs, fcs, fpps, ssc
    while isopen(viewer.fig.scene)
        init_globals()
        on_parking(ssc)
        integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04)
        toc()
        steps = simulate(integrator, stopped)
        stopped = ! viewer.sw.active[]
        if logger.index > 100
            KiteViewers.plot_file[]="last_sim_log"
            println("Saving log... $(logger.index)")
            save_log(logger, "last_sim_log")
        end
        if @isdefined __PRECOMPILE__
            break
        end
    end
    GC.enable(true)
end

function parking()
    global PARKING
    PARKING = true
    viewer.stop=false
    on_parking(ssc)
end

function autopilot()
    global PARKING
    PARKING = false
    viewer.stop=false
    on_autopilot(ssc)
end

function stop_()
    println("Stopping...")
    on_stop(ssc)
    clear!(kps4)
    clear_viewer(viewer)
end

stop_()
on(viewer.btn_PARKING.clicks) do c; parking(); end
on(viewer.btn_AUTO.clicks) do c; autopilot(); end
on(viewer.btn_STOP.clicks) do c; stop_(); end
on(viewer.btn_PLAY.clicks) do c;
    global PARKING
    if ! viewer.stop
        PARKING = false
    end
end

function select_log()
    @async begin 
        filename = fetch(Threads.@spawn pick_file("data"; filterlist="arrow"))
        if filename != ""
            short_filename = replace(filename, homedir() => "~")
            KiteViewers.plot_file[] = short_filename
        end
    end
end

function save_log_as()
    @async begin 
        filename = fetch(Threads.@spawn save_file("data"; filterlist="arrow"))
        if filename != ""
            source = replace(KiteViewers.plot_file[], "~" => homedir())
            if ! isfile(source)
                source = joinpath(pwd(), "data", KiteViewers.plot_file[]) * ".arrow"
            end
            dest  = filename
            println("Copying: ", source, " => ", dest)
            cp(source, dest; force=true)
            KiteViewers.set_status(viewer, "Saved log as:")
            KiteViewers.plot_file[] = replace(filename, homedir() => "~")
        end
    end
end

include("logging.jl")
include("plots.jl")
include("stats.jl")

function print_stats()
    log = load_log(basename(KiteViewers.plot_file[]))
    sl  = log.syslog
    elev_ro = deepcopy(sl.elevation)
    az_ro = deepcopy(sl.azimuth)
    for i in eachindex(sl.sys_state)
        if ! (sl.sys_state[i] in (5,6,7,8))
            elev_ro[i] = 0
            az_ro[i] = 0
        end
    end
    stats = Stats(sl[end].e_mech, minimum(sl.force[Int64(round(5/dt)):end]), maximum(sl.force), 
                  minimum(log.z), maximum(log.z), minimum(rad2deg.(sl.elevation)), maximum(rad2deg.(elev_ro)),
                  minimum(rad2deg.(az_ro)), maximum(rad2deg.(az_ro)))
    show_stats(stats)
end

function do_menu(c)
    if c == "save logfile"
        save_log_as()
    elseif c == "load logfile"
        select_log()
    elseif c == "plot_timing"
        plot_timing()
    elseif c == "plot_power"
        plot_power()
    elseif c == "plot_control"
        plot_control()
    elseif c == "plot_elev_az"
        plot_elev_az()
    elseif c == "plot_main"
        plot_main()
    elseif c == "plot_side_view"
        plot_side_view()
    elseif c == "print_stats"
        print_stats()
    end
end

on(viewer.btn_OK.clicks) do c
    do_menu(viewer.menu.selection[])
end

on(viewer.menu.selection) do c
    do_menu(c)
end

on(viewer.menu_rel_tol.selection) do c
    rel_tol = parse(Float64, c)
    factor = rel_tol/0.001
    set.rel_tol = rel_tol
    set.abs_tol = factor * 0.0006 
    println(rel_tol)
end

if @isdefined __PRECOMPILE__
    MAX_TIME = 30
    play(false)
else
    viewer.menu_rel_tol.i_selected[]=2
    viewer.menu_rel_tol.i_selected[]=1
    play(true)
end
stop_()
KiteViewers.GLMakie.closeall()

GC.enable(true)
nothing

# GC disabled, Ryzen 7950X, 4x realtime, GMRES
# abs_tol: 0.0006, rel_tol: 0.001
# Missed the deadline for 0.04 %. Max time: 160.4 ms
#     Mean    time per timestep: 3.1066040097826084 ms
#     Maximum time per timestep: 11.13074 ms
#     Maximum for t>12s        : 11.13074 ms

# GC disabled, Ryzen 7950X, 4x realtime, GMRES
# abs_tol: 0.0003, rel_tol: 0.0005
# Missed the deadline for 0.04 %. Max time: 172.1 ms
#     Mean    time per timestep: 3.5648891855434783 ms
#     Maximum time per timestep: 14.024168999999999 ms
#     Maximum for t>12s        : 14.024168999999999 ms
