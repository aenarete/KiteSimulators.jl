__PRECOMPILE__ = true
let
    include("../examples/batch_plot.jl")

    for (name, fn) in MENU_ITEMS
        name == "select project" && continue
        println("Precompiling $name ...")
        try
            fn()
            sleep(1)
            GC.gc()
        catch e
            println("  Skipped $name: $e")
        end
    end

end

@info "Precompile script precompile_batch_plot.jl has completed execution."
