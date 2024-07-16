## Test plan

Tested: v0.3.12

Before triggering a new release, do the following:

### Do a clean install
```
cd test
./test_main_branch
```
After running this script there is a clean install in the folder `int_test`.

### Test the demo projects
Load each of the demo projects and click on RUN.
- hydra10_951 1375 Wh  4892 W 0.03% losses on Ryzen laptop
- hydra20_426 1579 Wh  5524 W 0.02% losses on Ryzen laptop
- hydra20_600 3446 Wh 12507 W 0.02% losses on Ryzen laptop
- hydra20_920 3005 Wh 10794 W 0.04% losses on Ryzen laptop

Verify:
- that the frame losses are OK (< 1% on Ryzen 7950X) PASSED
- that the harvested power matches the values above  PASSED
- that the trajectories are within the acceptable range

Test saving and loading of a log file.
- save the log file under a new name - PASSED

Test plotting using `hydra20_600` project and GUI:
```
# plot_main(log) OK
# plot_power(log) OK
# plot_control(log) OK (two plots)
# plot_control_II(log) OK
# plot_winch_control(log) OK (two plots)
# plot_elev_az(log) OK
# plot_elev_az2(log) OK
# plot_elev_az3(log) OK
# plot_side_view(log) OK
# plot_side_view2(log) OK
# plot_side_view3(log) OK
# plot_front_view3(log) OK
# plot_timing(log) OK
# plot_aerodynamics(log) OK
```

### Test the examples
- autopilot.jl - run one full example - OK
- compare_kps3_kps4.jl OK
- convert_log.jl OK
- depower_simple.jl OK
- joystick.jl
- play_log.jl OK
- plot_log.jl OK
- reelout_2D.jl OK
- reelout_3D.jl OK
