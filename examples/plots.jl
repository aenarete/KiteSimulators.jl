function fulldir(name)
    if occursin("~", name)
        return replace(dirname(name), "~" => homedir())
    else
        return joinpath(pwd(), dirname(name))
    end
end

function plot_timing(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end

    sl  = log.syslog
    display(ControlPlots.plotx(sl.time, sl.t_sim, 100*sl.steering, 100*sl.depower;
                               ylabels=["t_sim [ms]", "steering [%]","depower [%]"],
                               fig="timing"))
    println("Mean    time per timestep: $(mean(sl.t_sim)) ms")
    println("Maximum time per timestep: $(maximum(sl.t_sim[10:end])) ms")
    index = Int64(round(12/app.dt))
    println("Maximum for t>12s        : $(maximum(sl.t_sim[index:end])) ms")
    nothing
end

function plot_main(log=nothing) 
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotx(log.syslog.time, log.z, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), sl.l_tether, sl.force, 
                  sl.v_reelout, sl.var_01;
        ylabels=["height [m]", "elevation [°]", "azimuth [°]", "length [m]", "force [N]", "v_ro [m/s]", "cycle [-]"],
        fig="main"))
     nothing
end

function plot_power(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    energy = similar(sl.v_reelout)
    en=0.0
    for i in eachindex(energy)
        en +=  sl.force[i]*sl.v_reelout[i]*app.dt
        energy[i] = en
    end
    display(plotx(log.syslog.time, sl.force, sl.v_reelout, sl.force.*sl.v_reelout, energy./3600;
            ylabels=["force [N]", L"v_\mathrm{ro}~[m/s]", L"P_\mathrm{m}~[W]", "Energy [Wh]"],
            fig="power"))
    nothing
end

function plot_control(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), rad2deg.(sl.heading), sl.force, 100*sl.depower, 100*sl.steering, sl.sys_state, sl.var_01, sl.var_02;
            ylabels=["elevation [°]", "azimuth [°]", "heading [°]", "force [N]", "depower [%]", "steering [%]", "fpp_state", "cycle", "fig8"],
            fig="control", ysize=10))
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), -rad2deg.(wrap2pi.(sl.heading)), 100*sl.depower, 100*sl.steering, rad2deg.(sl.var_07), sl.var_06, sl.sys_state, sl.var_01;
            ylabels=["elevation [°]", "azimuth [°]", "psi [°]", "depower [%]", "steering [%]", "chi_set", "ndi_gain", "fpp_state", "cycle"],
            fig="fpc", ysize=10))
    nothing
end

function plot_control_II(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.azimuth), -rad2deg.(wrap2pi.(sl.heading)), 100*sl.steering, sl.var_12, rad2deg.(sl.course.-pi), rad2deg.(sl.var_09), rad2deg.(sl.var_10), sl.var_06, sl.sys_state;
            ylabels=["azimuth [°]", "psi [°]", "steering [%]", "c2", "chi", "psi_dot_set", "psi_dot", "ndi_gain", "fpp_state"],
            fig="fpc", ysize=10))
    nothing
end

function plot_winch_control(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotx(log.syslog.time, rad2deg.(sl.elevation), rad2deg.(sl.azimuth), sl.force, sl.var_04, sl.v_reelout, 100*sl.depower, 100*sl.steering, sl.var_03;
            ylabels=["elevation [°]", "azimuth [°]", "force [N]", "set_force", "v_reelout [m/s]", "depower [%]", "steering [%]", "wc_state"],
            fig="winch_control", ysize=10))
    display(plot(log.syslog.time, [sl.v_reelout, sl.var_05];
            labels=["v_reelout", "pid2_v_set_out"],
            ylabel="v_reelout [n/s]",
            xlabel="time [s]",
            fig="winch", ysize=10))            
    nothing
end

function plot_elev_az(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    display(plotxy(rad2deg.(sl.azimuth), rad2deg.(sl.elevation);
            ylabel="elevation [°]",
            xlabel="azimuth [°]",
            fig="elev_az"))
    nothing
end

function plot_elev_az2(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    index=1
    for i in 1:length(sl.var_01)
        if sl.var_01[i] == 2
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

function plot_elev_az3(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl  = log.syslog
    index=1
    for i in 1:length(sl.var_01)
        if sl.var_01[i] == 3
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

function plot_side_view(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    display(plotxy(log.x, log.z;
    ylabel="pos_x [m]",
    xlabel="height [m]",
    fig="side_view"))
    nothing
end

function plot_side_view2(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.var_01)
        if sl.var_01[i] == 2
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

function plot_side_view3(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.var_01)
        if sl.var_01[i] == 3
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

function plot_front_view3(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    index = 1
    sl    = log.syslog
    for i in 1:length(sl.var_01)
        if sl.var_01[i] == 3
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

function plot_aerodynamics(log=nothing)
    if isnothing(log)
        log = load_log(basename(KiteViewers.plot_file[]); path=fulldir(KiteViewers.plot_file[]))
    end
    sl    = log.syslog

    display(plotxy(sl.time, sl.var_08;
    ylabel="LoD [-]",
    fig="aerodynamics"))
    nothing
end
