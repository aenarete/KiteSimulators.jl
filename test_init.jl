using KiteSimulators
using KiteControllers

set = load_settings("hydra20_600")
app = KiteApp(set, 0, 0, false, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, 0.0, 0, 0, 0, false, false)
kcu = KCU(app.set)
kps4 = KPS4(kcu)
integrator = init!(kps4; delta=app.set.delta, stiffness_factor=app.set.stiffness_factor)
println("Initialization successful!")
