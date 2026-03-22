# batch_plot.jl
# Command-line plotting tool for kite simulation logs.
# No GUI — select a plot from a text menu.
# Usage: julia batch_plot.jl [path/to/project.yml]

using Pkg
if ! ("ControlPlots" ∈ keys(Pkg.project().dependencies))
    Pkg.activate(@__DIR__)
end

if !@isdefined __PRECOMPILE__
    __PRECOMPILE__ = false
end

using ControlPlots, KiteSimulators, KiteSimulators.LaTeXStrings, Statistics, KiteSimulators.KiteUtils.YAML
using REPL.TerminalMenus

include("yaml_utils.jl")

# Paths
const GUI_YAML   = joinpath(@__DIR__, "..", "data", "gui.yaml")
const BATCH_OUTPUT_DIR = joinpath(@__DIR__, "..", "output")

# ---------------------------------------------------------------------------
# Project management helpers
# ---------------------------------------------------------------------------
"""Return sorted list of project names that have a batch-*.arrow file."""
function discover_projects()
    files = filter(f -> startswith(f, "batch-") && endswith(f, ".arrow"),
                   readdir(BATCH_OUTPUT_DIR))
    sort([replace(replace(f, r"^batch-" => ""), r"\.arrow$" => "") for f in files])
end

"""Read currently selected project name (without .yml) from gui.yaml."""
function read_project_name()
    cfg = YAML.load_file(GUI_YAML)
    project = get(get(cfg, "gui", Dict()), "project", "hydra20_600.yml")
    replace(project, r"\.yml$" => "")
end

"""Persist selected project name to gui.yaml."""
function write_project_name(project::String)
    content = read(GUI_YAML, String)
    # Replace the value after "project:" up to the first whitespace/newline/comment
    new_content = replace(content, r"(project:\s+)\S+" => SubstitutionString("\\1" * project * ".yml"))
    write(GUI_YAML, new_content)
end

"""Return the full path to the batch arrow file for a given project name."""
function project_arrow(project::String)
    joinpath(BATCH_OUTPUT_DIR, "batch-" * project * ".arrow")
end

# Mutable reference to the active log file (updated when project is changed)
function _resolve_plot_file(arg::String)
    # Full path given
    dirname(arg) != "" && return arg
    # Already looks like a complete arrow filename
    endswith(arg, ".arrow") && return joinpath(BATCH_OUTPUT_DIR, arg)
    # Try treating as a project name: batch-<arg>.arrow
    candidate = joinpath(BATCH_OUTPUT_DIR, "batch-" * arg * ".arrow")
    isfile(candidate) && return candidate
    # Fall back to using the arg as a bare filename in output/
    joinpath(BATCH_OUTPUT_DIR, arg)
end

const PLOT_FILE = Ref{String}(
    if isempty(ARGS)
        project_arrow(read_project_name())
    else
        let resolved = _resolve_plot_file(ARGS[1])
            # Persist the selected project to gui.yaml so the menu reflects it
            project_name = replace(replace(basename(resolved), r"\.arrow$" => ""), r"^batch-" => "")
            write_project_name(project_name)
            resolved
        end
    end
)

# ---------------------------------------------------------------------------
# Helper accessors (same as in plots.jl)
# ---------------------------------------------------------------------------
function l_tether(sl)
    hcat(sl.l_tether...)[1,:]
end

function force(sl)
    hcat(sl.winch_force...)[1,:]
end

function v_reelout(sl)
    hcat(sl.v_reelout...)[1,:]
end

# Derive dt from the log instead of from an app object
function log_dt(sl)
    length(sl.time) > 1 ? sl.time[2] - sl.time[1] : 0.05
end

# ---------------------------------------------------------------------------
# Load helper
# ---------------------------------------------------------------------------
function load_plot_log()
    load_log(basename(PLOT_FILE[]); path=dirname(PLOT_FILE[]))
end

# ---------------------------------------------------------------------------
# Plot functions (adapted from plots.jl — no KiteViewers references)
# ---------------------------------------------------------------------------
function plot_main()
    log = load_plot_log()
    sl  = log.syslog
    display(plotx(sl.time, log.z, rad2deg.(sl.elevation), rad2deg.(sl.azimuth),
                  l_tether(sl), force(sl), v_reelout(sl), sl.cycle;
            ylabels=["height [m]", "elevation [°]", "azimuth [°]", "length [m]",
                     "force [N]", "v_ro [m/s]", "cycle [-]"],
            yzoom=0.9, fig="main"))
    nothing
end

function plot_power()
    log = load_plot_log()
    sl  = log.syslog
    display(plotx(sl.time, force(sl), v_reelout(sl), force(sl) .* v_reelout(sl), sl.e_mech, sl.acc;
            ylabels=["force [N]", L"v_\mathrm{ro}~[m/s]", L"P_\mathrm{m}~[W]", "Energy [Wh]", "acc [m/s^2]"],
            fig="power"))
    nothing
end

function plot_control()
    log = load_plot_log()
    sl  = log.syslog
    display(plotx(sl.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth),
                  rad2deg.(wrap2pi.(sl.heading)), force(sl),
                  100*sl.depower, 100*sl.steering, sl.sys_state, sl.cycle, sl.fig_8;
            ylabels=["elevation [°]", "azimuth [°]", "heading [°]", "force [N]",
                     "depower [%]", "steering [%]", "fpp_state", "cycle", "fig8"],
            fig="control", ysize=10, yzoom=0.7))
    sleep(0.05)
    display(plotx(sl.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth),
                  -rad2deg.(wrap2pi.(sl.heading)), 100*sl.depower, 100*sl.steering,
                  rad2deg.(sl.var_07), sl.var_06, sl.sys_state, sl.cycle;
            ylabels=["elevation [°]", "azimuth [°]", "psi [°]", "depower [%]",
                     "steering [%]", "chi_set", "ndi_gain", "fpp_state", "cycle"],
            fig="fpc", ysize=10, yzoom=0.7))
    nothing
end

function plot_control_II()
    log = load_plot_log()
    sl  = log.syslog
    display(plotx(sl.time, rad2deg.(sl.azimuth), -rad2deg.(wrap2pi.(sl.heading)),
                  100*sl.steering, sl.var_12, rad2deg.(sl.course .- pi),
                  rad2deg.(sl.var_09), rad2deg.(sl.var_10), sl.var_06, sl.sys_state;
            ylabels=["azimuth [°]", "psi [°]", "steering [%]", "c2", "chi",
                     "psi_dot_set", "psi_dot", "ndi_gain", "fpp_state"],
            fig="fpc", ysize=10, yzoom=0.7))
    nothing
end

function plot_winch_control()
    log = load_plot_log()
    sl  = log.syslog
    display(plotx(sl.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth),
                  force(sl), sl.var_04, v_reelout(sl),
                  100*sl.depower, 100*sl.steering, sl.var_03;
            ylabels=["elevation [°]", "azimuth [°]", "force [N]", "set_force",
                     "v_reelout [m/s]", "depower [%]", "steering [%]", "wc_state"],
            fig="winch_control", ysize=10))
    display(plot(sl.time, [v_reelout(sl), sl.var_05];
            labels=["v_reelout", "pid2_v_set_out"],
            ylabel="v_reelout [m/s]",
            xlabel="time [s]",
            fig="winch", ysize=10))
    nothing
end

function plot_aerodynamics(plot_lift_drag=false)
    log = load_plot_log()
    sl  = log.syslog
    if plot_lift_drag
        display(plotx(sl.time, sl.var_08, rad2deg.(sl.AoA), sl.CL2, sl.CD2;
                      ylabels=["LoD [-]", L"AoA~[°]", "CL [-]", "CD [-]"],
                      fig="aerodynamics"))
        display(plotxy(rad2deg.(sl.AoA[2:end]), sl.CL2[2:end];
                      xlabel="AoA [°]", ylabel="CL [-]",
                      fig="CL as function of AoA"))
        display(plotxy(rad2deg.(sl.AoA[2:end]), sl.CD2[2:end];
                      xlabel="AoA [°]", ylabel="CD [-]",
                      fig="CD_tot as function of AoA"))
    else
        display(plotx(sl.time, sl.var_08, rad2deg.(sl.AoA), 100*sl.steering,
                      sl.var_15, rad2deg.(sl.var_16);
                    ylabels=["LoD [-]", L"AoA~[°]", "steering [%]",
                             "yaw_rate [°/s]", L"side\_slip~[°]"],
                    fig="aerodynamics"))
    end
    nothing
end

function plot_elev_az()
    log = load_plot_log()
    sl  = log.syslog
    display(plotxy(rad2deg.(sl.azimuth), rad2deg.(sl.elevation);
            ylabel="elevation [°]", xlabel="azimuth [°]", fig="elev_az"))
    nothing
end

function plot_elev_az2()
    log = load_plot_log()
    sl  = log.syslog
    index = 1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 2; index = i; break; end
    end
    display(plotxy(rad2deg.(sl.azimuth)[index:end], rad2deg.(sl.elevation)[index:end];
            ylabel="elevation [°]", xlabel="azimuth [°]", fig="elev_az"))
    nothing
end

function plot_elev_az3()
    log = load_plot_log()
    sl  = log.syslog
    index = 1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3; index = i; break; end
    end
    display(plotxy(rad2deg.(sl.azimuth)[index:end], rad2deg.(sl.elevation)[index:end];
            ylabel="elevation [°]", xlabel="azimuth [°]", fig="elev_az"))
    nothing
end

function plot_side_view()
    log = load_plot_log()
    display(plotxy(log.x, log.z;
            ylabel="pos_x [m]", xlabel="height [m]", fig="side_view"))
    nothing
end

function plot_side_view2()
    log = load_plot_log()
    sl  = log.syslog
    index = 1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 2; index = i; break; end
    end
    display(plotxy(log.x[index:end], log.z[index:end];
            ylabel="pos_x [m]", xlabel="height [m]", fig="side_view"))
    nothing
end

function plot_side_view3()
    log = load_plot_log()
    sl  = log.syslog
    index = 1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3; index = i; break; end
    end
    display(plotxy(log.x[index:end], log.z[index:end];
            ylabel="pos_x [m]", xlabel="height [m]", fig="side_view"))
    nothing
end

function plot_front_view3()
    log = load_plot_log()
    sl  = log.syslog
    index = 1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3; index = i; break; end
    end
    display(plotxy(log.y[index:end], log.z[index:end];
            xlabel="pos_y [m]", ylabel="height [m]", fig="front_view"))
    nothing
end

# ---------------------------------------------------------------------------
# Project selection sub-menu
# ---------------------------------------------------------------------------
function select_project_menu()
    projects = discover_projects()
    if isempty(projects)
        println("No batch-*.arrow files found in $BATCH_OUTPUT_DIR")
        return
    end
    current = read_project_name()
    println("\nCurrent project: $current")
    opts = vcat(projects, ["cancel"])
    menu = RadioMenu(opts, pagesize=8)
    choice = request("\nSelect project: ", menu)
    if choice == -1 || choice == length(opts)
        println("Project selection cancelled.")
        return
    end
    selected = projects[choice]
    write_project_name(selected)
    PLOT_FILE[] = project_arrow(selected)
    println("Project set to: $selected")
    println("Log file: $(PLOT_FILE[])")
    nothing
end

# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------
function highlight_yaml(content::String)
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    CYAN   = "\033[36m"
    YELLOW = "\033[33m"
    GREEN  = "\033[32m"
    MAGENTA = "\033[35m"

    buf = IOBuffer()
    for line in split(content, '\n')
        # Section header: "key:" with nothing after colon
        m = match(r"^(\s*)([\w]+)(\s*:\s*)$", line)
        if m !== nothing
            indent, key, colon = m.captures
            print(buf, indent * BOLD * CYAN * key * RESET * colon * "\n")
            continue
        end
        # Key: value  # optional inline comment
        m = match(r"^(\s*)([\w]+)(\s*:\s*)(\"[^\"]*\"|-?[0-9][0-9.]*|[^#\n]*?)(\s*)(#[^\n]*)?\n?$", line)
        if m !== nothing
            indent, key, colon, value, space, comment = m.captures
            value   = something(value,   "")
            space   = something(space,   "")
            comment = something(comment, "")
            # choose value color: string → yellow, number → magenta, empty → default
            val_color = occursin(r"^\s*\"", value) ? YELLOW :
                        occursin(r"^\s*-?[0-9]", value) ? MAGENTA : RESET
            colored = indent * CYAN * key * RESET * colon *
                      val_color * value * RESET * space *
                      (isempty(comment) ? "" : GREEN * comment * RESET)
            print(buf, colored * "\n")
            continue
        end
        print(buf, line * "\n")
    end
    String(take!(buf))
end

function print_statistics()
    project = read_project_name()
    stats_file = joinpath(BATCH_OUTPUT_DIR, "batch-" * project * "_stats.yaml")
    if !isfile(stats_file)
        println("No stats file found: $stats_file")
        return
    end
    println("\033[2J\033[H")  # clear terminal
    print(highlight_yaml(read(stats_file, String)))
    nothing
end

# ---------------------------------------------------------------------------
# Interactive menu (REPL.TerminalMenus RadioMenu)
# ---------------------------------------------------------------------------
const MENU_ITEMS = [
    ("select project",     select_project_menu),
    ("statistics",         print_statistics),
    ("plot_main",          plot_main),
    ("plot_power",         plot_power),
    ("plot_control",       plot_control),
    ("plot_control_II",    plot_control_II),
    ("plot_winch_control", plot_winch_control),
    ("plot_aerodynamics",  () -> plot_aerodynamics(false)),
    ("plot_elev_az",       plot_elev_az),
    ("plot_elev_az2",      plot_elev_az2),
    ("plot_elev_az3",      plot_elev_az3),
    ("plot_side_view",     plot_side_view),
    ("plot_side_view2",    plot_side_view2),
    ("plot_side_view3",    plot_side_view3),
    ("plot_front_view3",   plot_front_view3)
]

const OPTIONS = [item[1] for item in MENU_ITEMS]
push!(OPTIONS, "quit")

function run_menu()
    println("\nLog file: $(PLOT_FILE[])")
    active = true
    while active
        menu   = RadioMenu(OPTIONS, pagesize=8)
        # Derive active project name from the current log file
        log_base = replace(basename(PLOT_FILE[]), r"\.arrow$" => "")
        active_project = replace(log_base, r"^batch-" => "")
        choice = request("\nActive project: \e[1m$active_project\e[0m  Select new project or choose plot to display or `q` to quit: ", menu)
        if choice != -1 && choice != length(OPTIONS)
            name, fn = MENU_ITEMS[choice]
            println("Running $name …")
            try
                fn()
            catch e
                println("Error in $name: $e")
            end
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

function run_command(cmd::String)
    idx = findfirst(item -> item[1] == cmd, MENU_ITEMS)
    if isnothing(idx)
        println("Unknown command: $cmd")
        println("Available commands: ", join([item[1] for item in MENU_ITEMS], ", "))
        return
    end
    name, fn = MENU_ITEMS[idx]
    println("Running $name …")
    fn()
    println("Close the plot window to exit.")
    ControlPlots.plt.show(block=true)
end

if !__PRECOMPILE__
    if length(ARGS) >= 2
        run_command(ARGS[2])
    else
        run_menu()
    end
end
