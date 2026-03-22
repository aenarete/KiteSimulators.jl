# batch_pilot.jl
# Runs a full kite simulation without GUI or plots.
# Reads settings.yaml (and associated yaml config files) and saves the result to
# output/batch-<timestamp>.arrow
# This can be used for batch simulations, e.g. for parameter tuning or sensitivity
# analysis. You can specify a custom settings file as a command-line argument, or
# set the PROJECT environment variable to point to a specific yaml file in the data/ directory. By default, it runs a predefined set of projects.
#
# Example usage:
#   julia --project=examples examples/batch_pilot.jl
#   ./bin/batch_pilot --help

using Pkg
using Timers

using KiteSimulators, Statistics
using Dates, LinearAlgebra, Printf

DEFAULT_PROJECTS = ["hydra20_600.yml", "hydra20_426.yml", "hydra20_920.yml", "hydra10_951.yml"]
PROJECTS = isempty(ARGS) ? DEFAULT_PROJECTS : [
    (endswith(lowercase(project), ".yml") || endswith(lowercase(project), ".yaml")) ? project : "$(project).yml"
    for project in ARGS
]

SAVELOG = true
TIMESTAMPS = false

function env_float(name::String, default::Float64)
    value = get(ENV, name, "")
    parsed = tryparse(Float64, value)
    return isnothing(parsed) ? default : parsed
end

include("stats.jl")

@enum SimError begin
    NoError
    TooLow
    TooHigh
    VelocityTooHigh
    VelocityTooLow
end

struct SimulationError
    code::SimError
    message::String
end

SimulationError() = SimulationError(NoError, "")

const tolerance  =   1.1 # allow 10% tolerance for velocity limits, to avoid false positives due to numerical issues
const min_height =  40.0 # minimum height for simulation to be considered valid
const max_height = 600.0 # maximum height for simulation to be considered valid

function read_project(index::Int = 1)
    return PROJECTS[index]  
end

# ensure KiteUtils uses this project's data/ directory, regardless of cwd
set_data_path(joinpath(dirname(@__DIR__), "data"))

mutable struct KiteApp
    set::Settings
    max_time::Float64
    kcu::Union{KCU, Nothing}
    kps4::Union{KPS4, Nothing}
    wcs::Union{WCSettings, Nothing}
    fcs::Union{FPCSettings, Nothing}
    fpps::Union{FPPSettings, Nothing}
    ssc::Union{SystemStateControl, Nothing}
    logger::Union{Logger, Nothing}
    dt::Float64
    steps::Int64
    particles::Int64
    initialized::Bool
end



function init(app::KiteApp)
    app.kcu  = KCU(app.set)
    project  = KiteUtils.PROJECT
    app.kps4 = KPS4(app.kcu::KCU)
    KiteUtils.PROJECT = project

    app.wcs     = WCSettings(true; dt = 1/app.set.sample_freq)
    app.wcs.dt  = 1/app.set.sample_freq
    app.dt      = app.wcs.dt
    app.fcs     = FPCSettings(true; dt = app.dt)
    app.fcs.log_level = app.set.log_level
    app.fpps    = FPPSettings(true)
    app.fpps.log_level = app.set.log_level

    u_d0 = 0.01 * app.set.depower_offset
    u_d  = 0.01 * app.set.depowers[1]
    app.ssc = SystemStateControl(app.wcs, app.fcs, app.fpps;
                                 u_d0, u_d, v_wind = app.set.v_wind)

    app.steps     = Int64(app.max_time / app.dt)
    app.particles = app.set.segments + 5
    app.logger    = Logger(app.particles, app.steps)
    app.initialized = true
end

function simulate(app::KiteApp)
    on_parking(app.ssc::SystemStateControl)
    integrator = KiteModels.init!(app.kps4::KPS4; delta = app.set.delta, stiffness_factor = app.set.stiffness_factor)

    sys_state = SysState(app.kps4::KPS4)
    sys_state.e_mech   = 0
    sys_state.sys_state = Int16(app.ssc.fpp._state)

    e_mech        = 0.0
    last_vel      = [0.0, 0.0, 0.0]
    last_yaw      = 0.0
    last_yaw_rate = 0.0

    on_new_systate(app.ssc::SystemStateControl, sys_state)
    log!(app.logger::Logger, sys_state)

    println("Simulating $(app.max_time) s  (dt = $(app.dt) s, $(app.steps) steps) ...")

    error = SimulationError()
    i = 1
    while i * app.dt <= app.max_time
        local v_ro

        # switch from parking to autopilot at step 200
        if i == 200
            on_autopilot(app.ssc::SystemStateControl)
        end

        if i > 100
            dp = KiteControllers.get_depower(app.ssc::SystemStateControl)
            if dp < 0.22; dp = 0.22; end
            heading = calc_heading(app.kps4::KPS4; neg_azimuth = true, one_point = false)
            app.ssc.sys_state.heading = heading
            app.ssc.sys_state.azimuth = -calc_azimuth(app.kps4::KPS4)
            steering = -calc_steering(app.ssc::SystemStateControl)
            set_depower_steering((app.kps4::KPS4).kcu, dp, steering)
        end

        v_ro = calc_v_set(app.ssc::SystemStateControl)
        KiteModels.next_step!(app.kps4::KPS4, integrator; set_speed = v_ro, dt = app.dt)

        sys_state  = SysState(app.kps4::KPS4)
        acc        = ((app.kps4::KPS4).vel_kite - last_vel) / app.dt
        last_vel   = deepcopy((app.kps4::KPS4).vel_kite)

        on_new_systate(app.ssc::SystemStateControl, sys_state)

        e_mech += (sys_state.winch_force[1] * sys_state.v_reelout[1]) / 3600 * app.dt
        sys_state.e_mech    = e_mech
        sys_state.sys_state = Int16(app.ssc.fpp._state)
        sys_state.cycle     = app.ssc.fpp.fpca.cycle
        sys_state.fig_8     = app.ssc.fpp.fpca.fig8
        sys_state.var_03    = get_state(app.ssc.wc)
        sys_state.var_04    = app.ssc.wc.lfc.f_set
        sys_state.var_05    = app.ssc.wc.lfc.v_set_out
        sys_state.var_06    = app.ssc.fpp.fpca.fpc.ndi_gain

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
        sys_state.acc    = norm(acc)

        if abs((sys_state.yaw - last_yaw) / app.dt) < 20.0
            sys_state.var_15 = (sys_state.yaw - last_yaw) / app.dt
        else
            sys_state.var_15 = last_yaw_rate
        end
        last_yaw      = sys_state.yaw
        last_yaw_rate = sys_state.var_15
        sys_state.var_16 = (app.kps4::KPS4).side_slip
        sys_state.var_08 = norm((app.kps4::KPS4).lift_force) / norm((app.kps4::KPS4).drag_force)

        log!(app.logger::Logger, sys_state)

        if sys_state.Z[end] < min_height
            error = SimulationError(TooLow, "Height $(round(sys_state.Z[end], digits = 2)) m is below minimum $(min_height) m")
            break
        end

        if sys_state.Z[end] > max_height
            error = SimulationError(TooHigh, "Height $(round(sys_state.Z[end], digits = 2)) m exceeds maximum $(max_height) m")
            break
        end

        if sys_state.v_reelout[1] > tolerance * app.set.v_ro_max
            error = SimulationError(VelocityTooHigh, "Reel-out speed $(round(sys_state.v_reelout[1], digits = 3)) m/s exceeds limit $(round(tolerance * app.set.v_ro_max, digits = 3)) m/s")
            break
        end

        if sys_state.v_reelout[1] < tolerance * app.set.v_ro_min
            error = SimulationError(VelocityTooLow, "Reel-out speed $(round(sys_state.v_reelout[1], digits = 3)) m/s is below limit $(round(tolerance * app.set.v_ro_min, digits = 3)) m/s")
            break
        end

        if mod(i, Int64(round(200.0/app.dt))) == 0
            @printf("  t = %6.1f s  height = %6.1f m\n", i * app.dt, sys_state.Z[end])
        end

        i += 1
    end
    return i - 1, error
end

function calc_stats(logger::Logger)
    lg = extract_log(logger)
    sl  = lg.syslog
    dt = 1.0
    if length(sl.time) > 1
        deltas = diff(sl.time)
        first_positive = findfirst(d -> d > 0, deltas)
        if !isnothing(first_positive)
            dt_candidate = Float64(deltas[first_positive])
            if isfinite(dt_candidate) && dt_candidate > 0
                dt = dt_candidate
            end
        end
    end
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
    force_ = getindex.(sl.winch_force, 1)
    v_reelout_ = getindex.(sl.v_reelout, 1)
    for i in eachindex(force_)
        if sl.cycle[i] in 2:last_full_cycle
            av_power += force_[i] * v_reelout_[i]
            n+=1
        end
        if abs(force_[i] * v_reelout_[i]) > peak_power
            peak_power = abs(force_[i] * v_reelout_[i])
        end
    end
    if n > 0
        av_power /= n
    else
        av_power = mean(force_ .* v_reelout_)
    end
    start_idx = clamp(Int64(round(5 / dt)), 1, length(force_))
    cycles = last_full_cycle - 1
    return Stats(sl[end].e_mech, av_power, peak_power, minimum(force_[start_idx:end]), maximum(force_), 
                 minimum(lg.z), maximum(lg.z), minimum(rad2deg.(sl.elevation)), maximum(rad2deg.(elev_ro)),
                 minimum(rad2deg.(az_ro)), maximum(rad2deg.(az_ro)), cycles)
end

function extract_log(logger::Logger)
    nl = length(logger)
    for fn in fieldnames(typeof(logger))
        f = getfield(logger, fn)
        f isa Vector && resize!(f, nl)
    end
    KiteUtils.sys_log(logger)
end

# ── run ────────────────────────────────────────────────────────────────────────
let
    tic()
    results = Tuple{String, SimulationError}[]
    av_powers = Float64[]
    for project in PROJECTS
        wall_start_ns = time_ns()
        println("Running project $project ...")
        app = KiteApp(deepcopy(load_settings(project)), 0.0,
                    nothing, nothing, nothing, nothing, nothing, nothing, nothing,
                    0.0, 0, 0, false)
        app.max_time = app.set.sim_time
        @printf("\nInit parameters: delta=%.6f, stiffness_factor=%.3f\n", app.set.delta, app.set.stiffness_factor)

        init(app)
        if TIMESTAMPS
            timestamp   = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
            output_name = "batch-$(first(splitext(project)))-$timestamp"
        else
            timestamp   = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
            output_name = "batch-$(first(splitext(project)))"
        end
        output_path = joinpath(dirname(@__DIR__), "output")

        steps, error = simulate(app)
        sim_time = steps * app.dt
        wall_time_sim = (time_ns() - wall_start_ns) / 1e9
        push!(results, (project, error))
        if error.code != NoError
            println("\nSimulation error ($(error.code)): $(error.message)")
        else
            @printf("\nSimulation completed successfully (project = %s, sim_time = %.2f s, wall_time = %.2f s)\n",
                    project, sim_time, wall_time_sim)
        end
        if SAVELOG
            println("\nSaving log to output/$(output_name).arrow  ($(app.logger.index) entries) ...")
            save_log(app.logger::Logger, output_name; path = output_path)
        end
        wall_time = (time_ns() - wall_start_ns) / 1e9
        stats = calc_stats(app.logger)
        fmt(x) = @sprintf("%10.2f", x)
        v_wind_200 = app.set.v_wind * calc_wind_factor(app.kps4.am, 200.0)
        stats_yaml = """
            meta:
              project: "$(project)"
              timestamp: "$(timestamp)"
              duration:      $(fmt(steps * app.dt))  # simulated duration [s]
              wall_time:     $(fmt(wall_time))  # elapsed wall-clock time for setup/sim/save [s]
              v_wind_200:    $(fmt(v_wind_200))  # wind speed at 200m height [m/s]
            error:
              code: "$(error.code)"
              message: "$(error.message)"
            stats:
              cycles:        $(@sprintf("%7d   ", stats.cycles))  # number of full reel-out/reel-in cycles
              e_mech:        $(fmt(stats.e_mech))  # total mechanical energy [Wh]
              av_power:      $(fmt(stats.av_power))  # average reel-out power [W]
              peak_power:    $(fmt(stats.peak_power))  # peak reel-out power [W]
              min_force:     $(fmt(stats.min_force))  # minimum tether force [N]
              max_force:     $(fmt(stats.max_force))  # maximum tether force [N]
              min_height:    $(fmt(stats.min_height))  # minimum kite height [m]
              max_height:    $(fmt(stats.max_height))  # maximum kite height [m]
              min_elevation: $(fmt(stats.min_elevation))  # minimum elevation angle [deg]
              max_elev_ro:   $(fmt(stats.max_elev_ro))  # maximum elevation angle during reel-out [deg]
              min_az_ro:     $(fmt(stats.min_az_ro))  # minimum azimuth angle during reel-out [deg]
              max_az_ro:     $(fmt(stats.max_az_ro))  # maximum azimuth angle during reel-out [deg]
            """
        write(joinpath(output_path, "$(output_name)_stats.yaml"), stats_yaml)
        push!(av_powers, stats.av_power)
        @printf("Average power: %.1f W\n", stats.av_power)
        toc()
    end

    println()
    @info("Results summary:")
    println(rpad("Project", 18), " | ", rpad("error.code", 14), " | ", rpad("av_power [W]", 12), " | error.message")
    println(repeat("-", 18), "-+-", repeat("-", 14), "-+-", repeat("-", 12), "-+-", repeat("-", 42))
    for i in eachindex(results)
        project, error = results[i]
        @printf("%s | %s | %12.1f | %s\n", rpad(project, 18), rpad(string(error.code), 14), av_powers[i], error.message)
    end
    println()
    @info "You can find the results in the output folder."
    display(filter(endswith(".yaml"), readdir("output", join=true)))
end

nothing
