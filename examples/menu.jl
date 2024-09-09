using REPL.TerminalMenus

function menu()
    options = ["include(\"autopilot.jl\")",
               "include(\"compare_kps3_kps4.jl\")",
               "quit"]
    active = true
    while active
        menu = RadioMenu(options, pagesize=8)
        choice = request("\nChoose function to execute or `q` to quit: ", menu)

        if choice != -1 && choice != length(options)
            eval(Meta.parse(options[choice]))
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

menu()