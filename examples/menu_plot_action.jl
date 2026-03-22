using PyPlot

function configure_matplotlib_backend()
    if !Sys.isapple()
        return nothing
    end
    for backend in ("qtagg", "QtAgg", "macosx")
        try
            PyPlot.matplotlib.use(backend, force = true)
            return backend
        catch
        end
    end
    return nothing
end

configure_matplotlib_backend()

using KiteSimulators
using ControlPlots
using Printf
import KiteSimulators.KiteViewers.GLMakie

Base.@kwdef mutable struct PlotMenuSettings
    time_lapse::Float64
end

Base.@kwdef mutable struct PlotMenuApp
    dt::Float64
    set::PlotMenuSettings
end

function bring_process_to_front()
    if !Sys.isapple()
        return nothing
    end
    pid = getpid()
    script = "tell application \"System Events\" to set frontmost of first process whose unix id is $pid to true"
    try
        run(`osascript -e $script`; wait = false)
    catch
    end
    nothing
end

const ACTION = ARGS[1]
const LOG_FILE = ARGS[2]
const LOG_LIFT_DRAG = lowercase(get(ENV, "KITE_LOG_LIFT_DRAG", "false")) == "true"

global app = PlotMenuApp(dt=parse(Float64, ARGS[3]), set=PlotMenuSettings(time_lapse=parse(Float64, ARGS[4])))
KiteViewers.plot_file[] = LOG_FILE

include("plots.jl")
include("stats.jl")

function print_stats_menu()
    log_file_exists() || return
    lg = load_log(basename(KiteViewers.plot_file[]); path=dirname(KiteViewers.plot_file[]))
    sl = lg.syslog
    elev_ro = deepcopy(sl.elevation)
    az_ro = deepcopy(sl.azimuth)
    for i in eachindex(sl.sys_state)
        if !(sl.sys_state[i] in (5, 6, 7, 8))
            elev_ro[i] = 0
            az_ro[i] = 0
        end
    end
    av_power = 0.0
    peak_power = 0.0
    n = 0
    last_full_cycle = maximum(sl.cycle) - 1
    force_ = force(sl)
    v_reelout_ = v_reelout(sl)
    for i in eachindex(force_)
        if sl.cycle[i] in 2:last_full_cycle
            av_power += force_[i] * v_reelout_[i]
            n += 1
        end
        if abs(force_[i] * v_reelout_[i]) > peak_power
            peak_power = abs(force_[i] * v_reelout_[i])
        end
    end
    av_power /= n
    stats = Stats(sl[end].e_mech, av_power, peak_power, minimum(force_[Int64(round(5 / app.dt)):end]), maximum(force_),
                  minimum(lg.z), maximum(lg.z), minimum(rad2deg.(sl.elevation)), maximum(rad2deg.(elev_ro)),
                  minimum(rad2deg.(az_ro)), maximum(rad2deg.(az_ro)), last_full_cycle)
    show_stats(stats)
end

function wait_for_stats_figure(fig)
    fig === nothing && return nothing
    sleep(0.1)
    bring_process_to_front()
    while isopen(fig.scene)
        sleep(0.1)
    end
    nothing
end

if ACTION == "plot_timing"
    plot_timing()
elseif ACTION == "plot_power"
    plot_power()
elseif ACTION == "plot_control"
    plot_control()
elseif ACTION == "plot_control_II"
    plot_control_II()
elseif ACTION == "plot_winch_control"
    plot_winch_control()
elseif ACTION == "plot_aerodynamics"
    plot_aerodynamics(LOG_LIFT_DRAG)
elseif ACTION == "plot_elev_az"
    plot_elev_az()
elseif ACTION == "plot_elev_az2"
    plot_elev_az2()
elseif ACTION == "plot_elev_az3"
    plot_elev_az3()
elseif ACTION == "plot_main"
    plot_main()
elseif ACTION == "plot_side_view"
    plot_side_view()
elseif ACTION == "plot_side_view2"
    plot_side_view2()
elseif ACTION == "plot_side_view3"
    plot_side_view3()
elseif ACTION == "plot_front_view3"
    plot_front_view3()
elseif ACTION == "print_stats"
    wait_for_stats_figure(print_stats_menu())
else
    error("Unsupported menu action: $ACTION")
end

if startswith(ACTION, "plot_")
    sleep(0.1)
    bring_process_to_front()
    ControlPlots.plt.show(block = true)
end