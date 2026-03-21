function l_tether(sl)
    hcat(sl.l_tether...)[1,:]
end

function resolved_log_file(name)
    log_path = joinpath(fulldir(name), basename(name))
    if isfile(log_path)
        return log_path
    elseif !endswith(log_path, ".arrow") && isfile(log_path * ".arrow")
        return log_path * ".arrow"
    else
        return nothing
    end
end

function log_file_exists()
    log_path = resolved_log_file(KiteViewers.plot_file[])
    log_path !== nothing && return true
    println("Log file not found: $(joinpath(fulldir(KiteViewers.plot_file[]), basename(KiteViewers.plot_file[])))")
    return false
end

function force(sl)
    hcat(sl.winch_force...)[1,:]
end

function v_reelout(sl)
    hcat(sl.v_reelout...)[1,:]
end


function plot_timing()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))

    sl  = log.syslog
    time_limit = app.dt/app.set.time_lapse
    t_sim = collect(sl.t_sim)
    tl = fill(time_limit * 1000, length(t_sim))
    display(ControlPlots.plotx(sl.time, [t_sim, tl], 100*sl.steering, 100*sl.depower;
                               ylabels=["t_sim [ms]", "steering [%]","depower [%]"],
                               labels=[["t_sim", "time_limit"], "", ""],
                               fig="timing"))
    println("Time limit:                $(time_limit*1000) ms")
    println("Mean    time per timestep: $(mean(sl.t_sim)) ms")
    println("Maximum time per timestep: $(maximum(sl.t_sim[10:end])) ms")
    index = Int64(round(12/app.dt))
    println("Maximum for t>12s        : $(maximum(sl.t_sim[index:end])) ms")
    nothing
end

function plot_timing2()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))

    sl  = log.syslog
    time_limit = app.dt/app.set.time_lapse
    t_sim = collect(sl.t_sim)
    tl = fill(time_limit * 1000, length(t_sim))
    display(ControlPlots.plot(sl.time, [t_sim, tl], ylabel="t_sim [ms]", labels=["t_sim","time_limit"], fig="timing2"))
    nothing
end

function plot_main(log=nothing)
    if log === nothing
        log_file_exists() || return
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotx(log.syslog.time, log.z, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), l_tether(sl), force(sl), 
    v_reelout(sl), sl.cycle;
        ylabels=["height [m]", "elevation [°]", "azimuth [°]", "length [m]", "force [N]", "v_ro [m/s]", "cycle [-]"],
        yzoom=0.9, fig="main"))
     nothing
end

function plot_power()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    energy = similar(v_reelout(sl))
    en = 0.0
    v_ro = v_reelout(sl)
    f_ = force(sl)
    for i in eachindex(energy)
        en +=  f_[i] * v_ro[i] * app.dt
        energy[i] = en
    end
    display(plotx(log.syslog.time, force(sl), v_reelout(sl), force(sl) .* v_reelout(sl), energy./3600, sl.acc;
            ylabels=["force [N]", L"v_\mathrm{ro}~[m/s]", L"P_\mathrm{m}~[W]", "Energy [Wh]", "acc [m/s^2]"],
            fig="power"))
    nothing
end

function plot_control()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), rad2deg.(wrap2pi.(sl.heading)), force(sl), 100*sl.depower, 100*sl.steering, sl.sys_state, sl.cycle, sl.fig_8;
            ylabels=["elevation [°]", "azimuth [°]", "heading [°]", "force [N]", "depower [%]", "steering [%]", "fpp_state", "cycle", "fig8"],
            fig="control", ysize=10, yzoom=0.7))
    sleep(0.05)
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), -rad2deg.(wrap2pi.(sl.heading)), 100*sl.depower, 100*sl.steering, rad2deg.(sl.var_07), sl.var_06, sl.sys_state, sl.cycle;
            ylabels=["elevation [°]", "azimuth [°]", "psi [°]", "depower [%]", "steering [%]", "chi_set", "ndi_gain", "fpp_state", "cycle"],
            fig="fpc", ysize=10, yzoom=0.7))
    nothing
end

function plot_control_II()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.azimuth), -rad2deg.(wrap2pi.(sl.heading)), 100*sl.steering, sl.var_12, rad2deg.(sl.course.-pi), rad2deg.(sl.var_09), rad2deg.(sl.var_10), sl.var_06, sl.sys_state;
            ylabels=["azimuth [°]", "psi [°]", "steering [%]", "c2", "chi", "psi_dot_set", "psi_dot", "ndi_gain", "fpp_state"],
            fig="fpc", ysize=10, yzoom=0.7))
    nothing
end

function plot_winch_control()
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), force(sl), sl.var_04, v_reelout(sl), 100*sl.depower, 100*sl.steering, sl.var_03;
            ylabels=["elevation [°]", "azimuth [°]", "force [N]", "set_force", "v_reelout [m/s]", "depower [%]", "steering [%]", "wc_state"],
            fig="winch_control", ysize=10))
    display(plot(log.syslog.time, [v_reelout(sl), sl.var_05];
            labels=["v_reelout", "pid2_v_set_out"],
            ylabel="v_reelout [n/s]",
            xlabel="time [s]",
            fig="winch", ysize=10))            
    nothing
end

function plot_elev_az()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    display(plotxy(rad2deg.(sl.azimuth), rad2deg.(sl.elevation);
            ylabel="elevation [°]",
            xlabel="azimuth [°]",
            fig="elev_az"))
    nothing
end

function plot_elev_az2()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    index=1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 2
            index=i
            break
        end
    end
    display(plotxy(rad2deg.(sl.azimuth)[index:end], rad2deg.(sl.elevation)[index:end];
            ylabel="elevation [°]",
            xlabel="azimuth [°]",
            fig="elev_az"))
    nothing
end

function plot_elev_az3()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl  = log.syslog
    index=1
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3
            index=i
            break
        end
    end
    display(plotxy(rad2deg.(sl.azimuth)[index:end], rad2deg.(sl.elevation)[index:end];
            ylabel="elevation [°]",
            xlabel="azimuth [°]",
            fig="elev_az"))
    nothing
end

function plot_side_view()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    display(plotxy(log.x, log.z;
    ylabel="pos_x [m]",
    xlabel="height [m]",
    fig="side_view"))
    nothing
end

function plot_side_view2()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 2
            index=i
            break
        end
    end
    display(plotxy(log.x[index:end], log.z[index:end];
    ylabel="pos_x [m]",
    xlabel="height [m]",
    fig="side_view"))
    nothing
end

function plot_side_view3()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3
            index=i
            break
        end
    end
    display(plotxy(log.x[index:end], log.z[index:end];
    ylabel="pos_x [m]",
    xlabel="height [m]",
    fig="side_view"))
    nothing
end

function plot_front_view3()
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.cycle)
        if sl.cycle[i] == 3
            index=i
            break
        end
    end
    display(plotxy(log.y[index:end], log.z[index:end];
    xlabel="pos_y [m]",
    ylabel="height [m]",
    fig="front_view"))
    nothing
end

function plot_aerodynamics(plot_lift_drag = false)
    log_file_exists() || return
    log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    sl    = log.syslog

    if plot_lift_drag
        display(plotx(sl.time, sl.var_08, rad2deg.(sl.AoA), sl.CL2, sl.CD2; 
                      ylabels=["LoD [-]", L"AoA~[°]", "CL [-]",  "CD [-]"],
                      fig="aerodynamics"))
        display(plotxy(rad2deg.(sl.AoA[2:end]), sl.CL2[2:end]; 
                      xlabel="AoA [°]",
                      ylabel="CL [-]",
                      fig="CL as function of AoA"))
        display(plotxy(rad2deg.(sl.AoA[2:end]), sl.CD2[2:end]; 
                      xlabel="AoA [°]",
                      ylabel="CD [-]",
                      fig="CD_tot as function of AoA"))

    else
        display(plotx(sl.time, sl.var_08, rad2deg.(sl.AoA), 100*sl.steering, sl.var_15, rad2deg.(sl.var_16); 
                    ylabels=["LoD [-]", L"AoA~[°]", "steering [%]", "yaw_rate [°/s]", L"side\_slip~[°]"],
                    fig="aerodynamics"))
    end
    nothing
end
