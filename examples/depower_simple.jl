using KiteSimulators

set = deepcopy(load_settings("system.yaml"))

set.abs_tol=0.0006
set.rel_tol=0.00001

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS::Int64 = Int64(round(TIME/dt))
# end of user parameter section #

kcu::KCU = KCU(set)
kps4::KPS4 = KPS4(kcu)

viewer::Viewer3D = Viewer3D(true)

function simulate(integrator, steps)
    start_time_ns = time_ns()
    KiteViewers.clear_viewer(viewer)
    for i in 1:steps
        if i == 300
            set_depower_steering(kps4.kcu, 0.30, 0.0)
        elseif i == 640
            set_depower_steering(kps4.kcu, 0.35, 0.0)    
        end
        KiteModels.next_step!(kps4, integrator; set_speed=0, dt=dt)
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system(viewer, SysState(kps4); scale = 0.08, kite_scale=3.0)
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            start_time_ns = time_ns()
        end
    end
end

integrator = KiteModels.init_sim!(kps4; delta=0.0, stiffness_factor=1)
simulate(integrator, STEPS)

stop(viewer)
