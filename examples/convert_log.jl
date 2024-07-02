using KiteSimulators

# the following values can be changed to match your interest
LOG_FILE_NAME = "output/sim_log" # without extension!
# end of user parameter section #

function fulldir(name)
    if occursin("~", name)
        return replace(dirname(name), "~" => homedir())
    else
        return joinpath(pwd(), dirname(name))
    end
end

log_file = load_log(basename(LOG_FILE_NAME), path=fulldir(LOG_FILE_NAME))
export_log(log_file)
# log_file.name="sim_log_uncompressed"
# save_log(log_file, false)
