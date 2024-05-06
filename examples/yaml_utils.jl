# modify a variable in a yaml file

# read as text
function readfile(filename)
    open(filename) do file
        readlines(file)
    end
end

function writefile(lines, filename)
    open(filename, "w") do file
        for line in lines
            write(file, line, '\n')
        end
    end
end

function change_value(lines, varname, value::Union{Integer, Float64})
    change_value(lines, varname, repr(value))
end

function change_value(lines, varname, value::String)
    res = String[]
    for line in lines
        if startswith(lstrip(line), varname)
            start = (findfirst(varname, line)).stop+1
            stop  = findfirst('#', line)-1
            new_line = ""
            leading = true
            j = 1
            for (i, chr) in pairs(line)
                if i < start || i > stop
                    new_line *= chr
                elseif line[i] == ' ' && leading
                    new_line *= ' '
                elseif j <= length(value)
                    new_line *= value[j]
                    j += 1
                    leading = false
                elseif i <= stop
                    new_line *= ' '
                end
            end
            push!(res, new_line)
        else
            push!(res, line)
        end
    end
    res
end
