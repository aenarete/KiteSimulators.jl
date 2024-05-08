struct Stats
    e_mech::Float64
    av_power::Float64
    peak_power::Float64
    min_force::Float64
    max_force::Float64
    min_height::Float64
    max_height::Float64
    min_elevation::Float64
    max_elev_ro::Float64
    min_az_ro::Float64
    max_az_ro::Float64
end

function show_stats(stats::Stats)
    HEIGHT=380
    UPPER_BORDER=20
    fig = GLMakie.Figure(size = (400, HEIGHT))
    if Sys.islinux()
        # sudo apt install ttf-bitstream-vera 
        lin_font="/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
        if isfile(lin_font)
            font=lin_font
        else
            font="/usr/share/fonts/truetype/freefont/FreeMono.ttf"
        end
    else
        font="Courier New"
    end
    function print(lbl::String, value::String; line, font=font)
        GLMakie.text!(fig.scene, 20, HEIGHT-UPPER_BORDER-line*32; text=lbl, fontsize = 24, space=:pixel)
        GLMakie.text!(fig.scene, 250, HEIGHT-UPPER_BORDER-line*32; text=value, fontsize = 24, font, space=:pixel)
        line +=1    
    end
    line = print("energy:       ", @sprintf("%5.0f Wh", stats.e_mech); line = 1)
    line = print("average power:", @sprintf("%5.0f  W", stats.av_power); line)
    line = print("peak power:", @sprintf("%5.0f  W", stats.peak_power); line)
    line = print("min force:    ", @sprintf("%5.0f  N", stats.min_force); line)
    line = print("max force:    ", @sprintf("%5.0f  N", stats.max_force); line)
    line = print("min height:   ", @sprintf("%5.0f  m", stats.min_height); line)
    line = print("max height:   ", @sprintf("%5.0f  m", stats.max_height); line)
    line = print("min elevation:", @sprintf("%5.1f  °", stats.min_elevation); line)
    line = print("max elev_ro:  ", @sprintf("%5.1f  °", stats.max_elev_ro); line)
    line = print("min az_ro:    ", @sprintf("%5.1f  °", stats.min_az_ro); line)
    line = print("max az_ro:    ", @sprintf("%5.1f  °", stats.max_az_ro); line)

    display(GLMakie.Screen(), fig)
    nothing
end
