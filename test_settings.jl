using KiteSimulators
println("Loading settings...")
set = load_settings("hydra20_600")
println("Settings loaded. Checking delta and stiffness_factor...")
println("delta: $(set.delta)")
println("stiffness_factor: $(set.stiffness_factor)")
println("Done!")
