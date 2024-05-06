using KiteSimulators

# the following values can be changed to match your interest
dt::Float64 = 0.05
ALPHA_ZERO = 8.8 
STEPS::Int64 = round(600/dt*0.05)
PLOT = true
FRONT_VIEW = false
ZOOM = true
PRINT = false
STATISTIC = false
# end of user parameter section #

set = deepcopy(se())
set.version = 2

kcu::KCU  = KCU(set)
kps4::KPS4 = KPS4(kcu)
kps3::KPS3 = KPS3(kcu)

if PLOT
    using ControlPlots
end

function simulate(s, integrator, steps, plot=false; fig="")
    start = integrator.p.iter
    for i in 1:steps
        if PRINT
            lift, drag = KiteModels.lift_drag(s)
            @printf "%.2f: " round(integrator.t, digits=2)
            println("lift, drag  [N]: $(round(lift, digits=2)), $(round(drag, digits=2))")
        end

        KiteModels.next_step!(s, integrator, dt=dt)
        
        if plot
            reltime = i*dt-dt
            if mod(i, 5) == 1
                plot2d(s.pos, reltime; zoom=ZOOM, front=FRONT_VIEW, fig)          
            end
        end
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init_sim!(kps3, stiffness_factor=0.04, prn=STATISTIC)
av_steps = simulate(kps3, integrator, STEPS, true; fig="kps3")

lift, drag = KiteModels.lift_drag(kps3)
println("KPS3")
println("lift, drag  [N]: $(round(lift, digits=2)), $(round(drag, digits=2))")
println("winch_force [N]: $(round(winch_force(kps3), digits=2))")
println("Average number of callbacks per time step: $av_steps")

kps4.set.alpha_zero = ALPHA_ZERO
integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04, prn=STATISTIC)
av_steps = simulate(kps4, integrator, STEPS, true; fig="kps4")

lift, drag = KiteModels.lift_drag(kps4)
println("KPS4")
println("lift, drag  [N]: $(round(lift, digits=2)), $(round(drag, digits=2))")
println("winch_force [N]: $(round(winch_force(kps4), digits=2))")
println("Average number of callbacks per time step: $av_steps")
