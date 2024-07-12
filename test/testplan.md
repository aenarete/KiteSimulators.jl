## Test plan

Before triggering a new release, do the following:

### Do a clean install
```
cd test
./test_main_branch
```
After running this script their is a clean install in the folder `int_test`.

### Test the demo projects
Load each of the demo projects and click on RUN.
- hydra10_951 1375 Wh 4892 W 0.03% losses on Ryzen laptop
- hydra20_426                0.18% losses on Ryzen laptop
- hydra20_600
- hydra20_920

Verify:
- that the frame losses are OK (< 1% on Ryzen 7950X)
- that the harvested power matches the values above
- that the trajectories are within the acceptable range

Test saving and loading of a log file.

Test plotting:
```
# plot_timing(log)
# plot_power(log)
# plot_control(log)
# plot_control_II(log)
# plot_winch_control(log)
# plot_elev_az(log)
# plot_elev_az2(log)
# plot_elev_az3(log)
# plot_side_view(log)
# plot_side_view2(log)
# plot_side_view3(log)
# plot_front_view3(log)
# plot_aerodynamics(log)
```

### Test the examples
- compare_kps3_kps4.jl
- convert_log.jl
- depower_simple.jl
- joystick.jl
- logging.jl
- play_log.jl
- plot_log.jl
- reelout_2D.jl
- reelout_3D
- stats.jl
