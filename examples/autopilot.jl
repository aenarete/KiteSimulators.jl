# activate the test environment if needed
using Pkg
if ! ("ControlPlots" ∈ keys(Pkg.project().dependencies))
    Pkg.activate(@__DIR__)
end
using Timers; tic()

if !@isdefined __PRECOMPILE__
    __PRECOMPILE__ = false
end

LOG_LIFT_DRAG::Bool = false
DRAG_CORR::Float64 = 0.93 

using KiteSimulators
using ControlPlots
using LinearAlgebra, Printf
import KiteSimulators.KiteViewers.GLMakie
import KiteSimulators.KiteViewers.GLMakie.GLFW
import KiteSimulators.KiteControllers.YAML

function read_project()
    config_file = joinpath(get_data_path(), "gui.yaml")
    if ! isfile(config_file)
        cp(config_file * ".default", config_file)
    end
    dict = YAML.load_file(config_file)
    dict["gui"]["project"]
end

PROJECT = read_project()
GLMakie.activate!(title = PROJECT)
OUTPUT_DIR::String = "output"
mkpath(OUTPUT_DIR)
@assert isdir(OUTPUT_DIR)
DEFAULT_LOG::String = joinpath(OUTPUT_DIR, "last_sim_log")

function test_observer(plot=true)
    log = load_log("uncorrected")
    ob = KiteObserver()
    observe!(ob, log)
    if plot
        plotxy(ob.fig8, ob.elevation, xlabel="fig8", ylabel="elevation")
    else
        ob
    end
end

mutable struct KiteApp
    set::Settings
    max_time::Float64
    next_max_time::Float64
    show_kite::Bool
    kcu::Union{KCU, Nothing} 
    kps4::Union{KPS4, Nothing}
    wcs::Union{WCSettings, Nothing}
    fcs::Union{FPCSettings, Nothing}
    fpps::Union{FPPSettings, Nothing}
    ssc::Union{SystemStateControl, Nothing}
    viewer::Union{Viewer3D, Nothing}
    logger::Union{Logger, Nothing}
    dt::Float64
    steps::Int64 # simulation steps for one simulation
    particles::Int64
    run::Int64
    parking::Bool
    initialized::Bool
end
app::KiteApp = KiteApp(deepcopy(load_settings(PROJECT)), 0, 0, true, nothing, nothing, nothing, 
                       nothing, nothing, nothing, nothing, nothing, 0, 0, 0, 0, false, false)
app.max_time      = app.set.sim_time
app.next_max_time = app.max_time

function init(app::KiteApp; init_viewer=false)
    app.max_time = app.next_max_time
    app.kcu   = KCU(app.set)
    project=(KiteUtils.PROJECT)
    app.kps4 = KPS4(app.kcu::KCU)
    KiteUtils.PROJECT = project
    app.wcs = WCSettings(true; dt=1/app.set.sample_freq)
    
    app.wcs.dt = 1/app.set.sample_freq
    app.dt = app.wcs.dt
    app.fcs = FPCSettings(true; dt=app.dt) 
    app.fcs.log_level = app.set.log_level
    app.fpps = FPPSettings(true)
    app.fpps.log_level = app.set.log_level
    u_d0 = 0.01 * se(project).depower_offset
    u_d = 0.01 * se(project).depowers[1]
    app.ssc = SystemStateControl(app.wcs, app.fcs, app.fpps; u_d0, u_d, v_wind=app.set.v_wind)
    if init_viewer
        app.viewer= Viewer3D(app.set, app.show_kite; menus=true)
        app.viewer.menu.options[]=["plot_main", "plot_power", "plot_control", "plot_control_II", "plot_winch_control", "plot_aerodynamics",
                                   "plot_elev_az", "plot_elev_az2", "plot_elev_az3", "plot_side_view", "plot_side_view2", "plot_side_view3", "plot_front_view3", "plot_timing", 
                                   "print_stats", "load logfile", "save logfile"]
        app.viewer.menu_rel_tol.options[]=["0.005","0.001","0.0005","0.0001","0.00005", "0.00001",
                                           "0.000005","0.000001"]
        app.viewer.menu_time_lapse.options[]=[ "1x","2x","3x","4x","6x","9x","12x","18x","24x"]
        app.viewer.menu_project.options[]=["Open...", "Save as...", "Edit..."]
    end
    if app.set.time_lapse==24.0
        app.viewer.menu_time_lapse.i_selected[] = 9
    elseif app.set.time_lapse==18.0
        app.viewer.menu_time_lapse.i_selected[] = 8
    elseif app.set.time_lapse==12.0
        app.viewer.menu_time_lapse.i_selected[] = 7    
    elseif app.set.time_lapse==9.0
        app.viewer.menu_time_lapse.i_selected[] = 6
    elseif app.set.time_lapse==6.0
        app.viewer.menu_time_lapse.i_selected[] = 5
    elseif app.set.time_lapse==4.0
        app.viewer.menu_time_lapse.i_selected[] = 4
    elseif app.set.time_lapse==3.0
        app.viewer.menu_time_lapse.i_selected[] = 3
    elseif app.set.time_lapse==2.0
        app.viewer.menu_time_lapse.i_selected[] = 2
    elseif app.set.time_lapse==1.0
        app.viewer.menu_time_lapse.i_selected[] = 1
    else
        println("Warning: Invalid setting for time_lapse in config file.")
    end
    app.viewer.t_sim.displayed_string[]=repr(Int64(round(app.set.sim_time)))
    app.steps = Int64(app.max_time/app.dt)
    app.particles = app.set.segments + 5
    app.logger = Logger(app.particles, app.steps)
    app.parking = false
    app.max_time      = app.set.sim_time
    app.next_max_time = app.max_time
    app.initialized = true
end

# the following values can be changed to match your interest
DEFAULT_TOLERANCE = 3
# end of user parameter section #

init(app; init_viewer=true)
bring_viewer_to_front()

function simulate(integrator, stopped=true)
    start_time_ns = time_ns()
    sys_state = SysState(app.kps4::KPS4)
    sys_state.e_mech = 0
    sys_state.sys_state = Int16(app.ssc.fpp._state)
    e_mech = 0.0
    last_vel = [0.0, 0.0, 0.0]
    on_new_systate(app.ssc::SystemStateControl, sys_state)
    clear_viewer(app.viewer::Viewer3D)
    KiteViewers.update_system(app.viewer::Viewer3D, sys_state; scale = 0.04/1.1, kite_scale=app.set.kite_scale)
    KiteViewers.running[] = ! stopped
    app.viewer.stop = stopped
    if ! stopped
        set_status(app.viewer::Viewer3D, "ssParking")
    end
    i=1
    j=0; k=0
    GC.enable(true)
    GC.gc()
    mem_start=Sys.total_memory()/1e9 
    if Sys.total_memory()/1e9 > 24 && app.max_time < 1002
        GC.enable(false)
    end
    max_time = 0
    last_yaw = 0.0
    last_yaw_rate = 0.0
    while app.initialized
        local v_ro
        if app.viewer.stop
            sleep(app.dt)
        else
            if i == 1
                app.max_time = app.next_max_time
                app.steps = Int64(app.max_time/app.dt)
                app.particles = app.set.segments + 5
                app.logger = Logger(app.particles, app.steps)
                log!(app.logger::Logger, sys_state)
                integrator = init!(app.kps4::KPS4; delta=app.set.delta, stiffness_factor=app.set.stiffness_factor)
            end
            if mod(i, 100) == 0 && app.set.log_level > 0
                println("Free memory: $(round(Sys.free_memory()/1e9, digits=1)) GB") 
            end
            if i > 100
                dp = KiteControllers.get_depower(app.ssc::SystemStateControl)
                if dp < 0.22 dp = 0.22 end
                heading = calc_heading(app.kps4::KPS4; neg_azimuth=true, one_point=false)
                app.ssc.sys_state.heading = heading
                app.ssc.sys_state.azimuth = -calc_azimuth(app.kps4::KPS4)
                #  steering = calc_steering(app.ssc; heading)
                steering = -calc_steering(app.ssc::SystemStateControl)
                set_depower_steering((app.kps4::KPS4).kcu, dp, steering)
            end
            if i == 200 && ! app.parking
                on_autopilot(app.ssc::SystemStateControl)
            end
            # execute winch controller
            v_ro = calc_v_set(app.ssc::SystemStateControl)
            #
            t_sim = @elapsed KiteModels.next_step!(app.kps4::KPS4, integrator; set_speed=v_ro, dt=app.dt)
            sys_state.orient .= calc_orient_quat(app.kps4::KPS4)
            sys_state=SysState(app.kps4::KPS4)
            acc = ((app.kps4::KPS4).vel_kite - last_vel)/app.dt
            last_vel = deepcopy((app.kps4::KPS4).vel_kite)

            on_new_systate(app.ssc::SystemStateControl, sys_state)
            e_mech += (sys_state.winch_force[1] * sys_state.v_reelout[1])/3600*app.dt
            sys_state.e_mech = e_mech
            sys_state.sys_state = Int16(app.ssc.fpp._state)
            sys_state.cycle  = app.ssc.fpp.fpca.cycle
            sys_state.fig_8   = app.ssc.fpp.fpca.fig8
            sys_state.var_03 = get_state(app.ssc.wc) # 0=lower_force_control 1=square_root_control 2=upper_force_control
            sys_state.var_04 = app.ssc.wc.lfc.f_set # set force of lower force controller
            sys_state.var_05 = app.ssc.wc.lfc.v_set_out
            sys_state.var_06 = app.ssc.fpp.fpca.fpc.ndi_gain
            if isnothing(app.ssc.fpp.fpca.fpc.psi_dot_set)
                sys_state.var_07 = app.ssc.fpp.fpca.fpc.chi_set
                sys_state.var_10 = NaN
                sys_state.var_09 = NaN
            else
                sys_state.var_07 = NaN
                sys_state.var_09 = app.ssc.fpp.fpca.fpc.psi_dot_set
                sys_state.var_10 = app.ssc.fpp.fpca.fpc.est_psi_dot
            end
            
            sys_state.var_11 = app.ssc.fpp.fpca.fpc.est_chi_dot
            sys_state.var_12 = app.ssc.fpp.fpca.fpc.c2
            sys_state.acc = norm(acc)
            if abs((sys_state.yaw - last_yaw) / app.dt ) < 20.0
                sys_state.var_15 = (sys_state.yaw - last_yaw) / app.dt # yaw rate
            else
                sys_state.var_15 = last_yaw_rate
            end
            last_yaw = sys_state.yaw
            last_yaw_rate = sys_state.var_15
            sys_state.var_16 = app.kps4.side_slip
            
            sys_state.var_08 = norm(app.kps4.lift_force)/norm(app.kps4.drag_force)
            if i > 10
                sys_state.t_sim = t_sim*1000
            end
            log!(app.logger::Logger, sys_state)
            if mod(app.set.time_lapse, 3) == 0
                ratio = 3
            elseif mod(app.set.time_lapse, 2) == 0
                ratio = 2
            else
                ratio = 1
            end
            if app.set.time_lapse == 12
                ratio = 4
            end
            app.viewer.mod_text = 3*ratio
            if mod(i, Int64(app.set.time_lapse)/ratio) == 0 
                KiteViewers.update_system(app.viewer::Viewer3D, sys_state; scale = 0.04/1.1, kite_scale=app.set.kite_scale)
                set_status(app.viewer::Viewer3D, String(Symbol(app.ssc.state)))
                # re-enable garbage collector when we are short of memory
                if Sys.free_memory()/1e9 < 4.0
                    GC.enable(true)
                end
                wait_until(start_time_ns + 1e9*app.dt/ratio, always_sleep=true) 
                mtime = 0
                if i > 10/app.dt 
                    # if we missed the deadline by more than 1 ms
                    mtime = time_ns() - start_time_ns
                    if mtime > app.dt*1e9/ratio + 1e6
                        print(".")
                        j += 1
                    end
                    k +=1
                end
                if mtime > max_time
                    max_time = mtime
                end            
                start_time_ns = time_ns()
            end
            i += 1
        end
        if ! isopen(app.viewer.fig.scene) break end
        if KiteViewers.status[] == "Stopped" && i > 10 
            if app.set.log_level > 0
                @timev KiteModels.next_step!(app.kps4::KPS4, integrator; set_speed=v_ro, dt=app.dt)
            else
                KiteModels.next_step!(app.kps4::KPS4, integrator; set_speed=v_ro, dt=app.dt)
            end
            break 
        end
        if i*app.dt > app.max_time break end
    end
    mem_used=mem_start-Sys.free_memory()/1e9 
    if app.set.log_level > 0
        println("\nMaximal memory usage: $(round(mem_used, digits=1)) GB")
    end
    if i > 10/app.dt
        misses = j/k * 100
        println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    end
    return div(i, Int64(app.set.time_lapse))
end

function play(stopped=false)
    while isopen(app.viewer.fig.scene)
        if ! app.initialized
            init(app)
        end
        KiteViewers.plot_file[]=DEFAULT_LOG
        on_parking(app.ssc::SystemStateControl)
        integrator = init!(app.kps4::KPS4; delta=app.set.delta, stiffness_factor=app.set.stiffness_factor)
        if !isnothing(app.viewer)
            _ss = SysState(app.kps4::KPS4)
            _ss.sys_state = Int16(app.ssc.fpp._state)
            KiteViewers.update_system(app.viewer::Viewer3D, _ss; scale = 0.04/1.1, kite_scale=app.set.kite_scale)
        end
        if app.run == 0; toc(); end
        app.run += 1
        simulate(integrator, stopped)
        app.initialized = false
        stopped = ! app.viewer.sw.active[]
        if !isnothing(app.logger) && (app.logger::Logger).index > 100
            KiteViewers.plot_file[]=DEFAULT_LOG
            if app.set.log_level > 0
                println("Saving log... $((app.logger::Logger).index)")
            end
            save_log(app.logger::Logger, basename(DEFAULT_LOG); path=dirname(DEFAULT_LOG))
        end
        if (@isdefined __PRECOMPILE__) && __PRECOMPILE__
            break
        end
    end
    GC.enable(true)
end

function parking()
    app.parking     = true
    app.viewer.stop = false
    on_parking(app.ssc::SystemStateControl)
end

function autopilot()
    app.parking     = false
    app.viewer.stop = false
    on_autopilot(app.ssc::SystemStateControl)
end

function stop_(; clear_display=true)
    if app.set.log_level > 0
        println("Stopping...")
    end
    on_stop(app.ssc::SystemStateControl)
    clear!(app.kps4::KPS4)
    if clear_display && ! isnothing(app.viewer)
        clear_viewer(app.viewer::Viewer3D)
    end
end

stop_(; clear_display=false)
on(app.viewer.btn_PARKING.clicks) do _; parking(); end
on(app.viewer.btn_AUTO.clicks) do _; autopilot(); end
on(app.viewer.btn_STOP.clicks) do _; stop_(); end
on(app.viewer.btn_PLAY.clicks) do _;
    if ! app.viewer.stop
        app.parking = false
    end
end
on(app.viewer.menu_time_lapse.selection) do _;
    val=app.viewer.menu_time_lapse.selection[][begin:end-1]
    app.set.time_lapse=parse(Int64, val)
end

# GTK3 (used by NativeFileDialog on Linux) prints warnings directly to fd 2;
# redirect at the OS level to suppress them during file dialogs.
function without_gtk_warnings(f)
    if !Sys.islinux()
        return f()
    end
    old_fd = ccall(:dup, Cint, (Cint,), 2)
    null_fd = ccall(:open, Cint, (Cstring, Cint), "/dev/null", 1)
    ccall(:dup2, Cint, (Cint, Cint), null_fd, 2)
    ccall(:close, Cint, (Cint,), null_fd)
    try
        return f()
    finally
        ccall(:dup2, Cint, (Cint, Cint), old_fd, 2)
        ccall(:close, Cint, (Cint,), old_fd)
    end
end

function select_log()
    @async begin 
        filename = without_gtk_warnings() do
            pick_file("output"; filterlist="arrow")
        end
        if filename != ""
            short_filename = replace(filename, homedir() => "~")
            KiteViewers.plot_file[] = short_filename
        end
    end
end

function save_log_as()
    @async begin 
        filename = without_gtk_warnings() do
            save_file("output"; filterlist="arrow")
        end
        if filename != ""
            source = replace(KiteViewers.plot_file[], "~" => homedir()) * ".arrow"
            if ! isfile(source)
                source = joinpath(pwd(), "output", KiteViewers.plot_file[]) * ".arrow"
            end
            dest  = filename
            if app.set.log_level > 0
                println("Copying: ", source, " => ", dest)
            end
            cp(source, dest; force=true)
            KiteViewers.set_status(app.viewer, "Saved log as:")
            KiteViewers.plot_file[] = replace(filename, homedir() => "~")
        end
    end
end

include("plots.jl")
include("stats.jl")
include("yaml_utils.jl")

function show_stats(stats::Stats)
    HEIGHT = 380
    UPPER_BORDER = 20
    fig  = GLMakie.Figure(size = (400, HEIGHT))
    font = if Sys.islinux()
        # sudo apt install ttf-bitstream-vera
        lin_font = "/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
        isfile(lin_font) ? lin_font : "/usr/share/fonts/truetype/freefont/FreeMono.ttf"
    else
        "Courier New"
    end
    function print(lbl::String, value::String; line, font=font)
        GLMakie.text!(fig.scene, 20, HEIGHT-UPPER_BORDER-line*32; text=lbl, fontsize = 24, space=:pixel)
        GLMakie.text!(fig.scene, 250, HEIGHT-UPPER_BORDER-line*32; text=value, fontsize = 24, font, space=:pixel)
        line +=1    
    end
    line = print("energy:       ", @sprintf("%5.0f Wh", stats.e_mech); line = 1)
    line = print("average power:", @sprintf("%5.0f  W", stats.av_power); line)
    line = print("peak power:", @sprintf("%5.0f  W", stats.peak_power); line)
    line = print("min force:    ", @sprintf("%5.0f  N", stats.min_force); line)
    line = print("max force:    ", @sprintf("%5.0f  N", stats.max_force); line)
    line = print("min height:   ", @sprintf("%5.0f  m", stats.min_height); line)
    line = print("max height:   ", @sprintf("%5.0f  m", stats.max_height); line)
    line = print("min elevation:", @sprintf("%5.1f  °", stats.min_elevation); line)
    line = print("max elev_ro:  ", @sprintf("%5.1f  °", stats.max_elev_ro); line)
    line = print("min az_ro:    ", @sprintf("%5.1f  °", stats.min_az_ro); line)
    line = print("max az_ro:    ", @sprintf("%5.1f  °", stats.max_az_ro); line)
    line = print("cycles:       ", @sprintf("%5d   ", stats.cycles); line)

    display(GLMakie.Screen(), fig)
    nothing
end

function print_stats()
    log_file_exists() || return
    lg = load_log(basename(KiteViewers.plot_file[]); path=dirname(KiteViewers.plot_file[]))
    sl  = lg.syslog
    elev_ro = deepcopy(sl.elevation)
    az_ro = deepcopy(sl.azimuth)
    for i in eachindex(sl.sys_state)
        if ! (sl.sys_state[i] in (5,6,7,8))
            elev_ro[i] = 0
            az_ro[i] = 0
        end
    end
    av_power = 0.0
    peak_power = 0.0
    n = 0
    last_full_cycle = maximum(sl.cycle)-1
    force_ = force(sl)
    v_reelout_ = v_reelout(sl)
    for i in eachindex(force_)
        if sl.cycle[i] in 2:last_full_cycle
            av_power += force_[i] * v_reelout_[i]
            n+=1
        end
        if abs(force_[i] * v_reelout_[i]) > peak_power
            peak_power = abs(force_[i] * v_reelout_[i])
        end
    end
    av_power /= n
    stats = Stats(sl[end].e_mech, av_power, peak_power, minimum(force_[Int64(round(5/app.dt)):end]), maximum(force_), 
                  minimum(lg.z), maximum(lg.z), minimum(rad2deg.(sl.elevation)), maximum(rad2deg.(elev_ro)),
                  minimum(rad2deg.(az_ro)), maximum(rad2deg.(az_ro)), last_full_cycle)
    show_stats(stats)
end

function do_menu(c)
    if isnothing(app.viewer) || !isopen(app.viewer.fig.scene)
        return nothing
    end
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
    elseif c == "plot_control_II"
        plot_control_II()
    elseif c == "plot_winch_control"
        plot_winch_control()
    elseif c == "plot_aerodynamics"
        plot_aerodynamics(LOG_LIFT_DRAG)
    elseif c == "plot_elev_az"
        plot_elev_az()
    elseif c == "plot_elev_az2"
        plot_elev_az2()
    elseif c == "plot_elev_az3"
        plot_elev_az3()
    elseif c == "plot_main"
        plot_main()
    elseif c == "plot_side_view"
        plot_side_view()
    elseif c == "plot_side_view2"
        plot_side_view2()
    elseif c == "plot_side_view3"
        plot_side_view3()
    elseif c == "plot_front_view3"
        plot_front_view3()        
    elseif c == "print_stats"
        print_stats()
    end
end

on(app.viewer.btn_OK.clicks) do _
    do_menu(app.viewer.menu.selection[])
end

on(app.viewer.menu.selection) do c
    do_menu(c)
end

on(app.viewer.menu_rel_tol.selection) do c
    rel_tol = parse(Float64, c)
    factor = rel_tol/0.001
    app.set.rel_tol = rel_tol
    app.set.abs_tol = factor * 0.0006 
end

on(app.viewer.menu_project.i_selected) do _
    global PROJECT, app
    sel = app.viewer.menu_project.selection[]
    if sel == "Open..."
        @async begin 
            filename = without_gtk_warnings() do
                pick_file("data"; filterlist="yml")
            end
            if filename != ""
                PROJECT = basename(filename)
                GLFW.SetWindowTitle(app.viewer.screen.glscreen, PROJECT)
                lines = readfile(joinpath(KiteControllers.KiteUtils.get_data_path(), "gui.yaml"))
                lines = change_value(lines, "project:", PROJECT)
                writefile(lines, joinpath(KiteControllers.KiteUtils.get_data_path(), "gui.yaml"))
                sleep(0.1)
                app.set = deepcopy(load_settings(PROJECT))
                app.max_time      = app.set.sim_time
                app.next_max_time = app.max_time
                app.initialized = false
            end
        end
    end
end

on(app.viewer.t_sim.stored_string) do c
    val = (parse(Int64, c))
    if val == 0
        val = repr(Int64(round(app.set.sim_time)))
        app.viewer.t_sim.displayed_string[]=repr(Int64(round(val)))
    end
    app.next_max_time=val
    app.set.sim_time=val
end

if __PRECOMPILE__
    app.max_time = 30
    app.next_max_time = 30
    play(false)
else
    app.viewer.menu_rel_tol.i_selected[]=2
    app.viewer.menu_rel_tol.i_selected[]=DEFAULT_TOLERANCE
    play(true)
end
if @isdefined __PRECOMPILE__ 
    do_menu(app.viewer.menu.selection[])
    sleep(0.1)   
end
stop_()
if !__PRECOMPILE__
    KiteViewers.GLMakie.closeall()   
end

GC.enable(true)
nothing

# GC disabled, Ryzen 7950X, 4x realtime, GMRES
# abs_tol: 0.0003, rel_tol: 0.0005
# Missed the deadline for 0.04 %. Max time: 172.1 ms
#     Mean    time per timestep: 3.5468899328260868 ms
#     Maximum time per timestep: 13.760848 ms
#     Maximum for t>12s        : 13.760848 ms
# Maximal memory usage: 27.0 GB

# GC disabled, Ryzen 7950X, 4x realtime, DFBDF solver
# abs_tol: 0.0003, rel_tol: 0.0005
# Missed the deadline for 0.0 %. Max time: 25.0 ms
#     Mean    time per timestep: 0.7769367125 ms
#     Maximum time per timestep: 8.064576 ms
#     Maximum for t>12s        : 7.994796 ms
# Maximal memory usage: 11.4 GB

# GC disabled, Ryzen 7950X, 4x realtime, DImplicitEuler solver
# abs_tol: 0.0003, rel_tol: 0.0005
# Missed the deadline for 0.02 %. Max time: 80.2 ms
#     Mean    time per timestep: 0.9781242155434784 ms
#     Maximum time per timestep: 17.54421 ms
#     Maximum for t>12s        : 16.454081 ms
# Maximal memory usage: 12.7 GB

