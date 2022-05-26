#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd ..

julia_version=$(julia --version | awk '{print($3)}')
julia_major=${julia_version:0:3} 

echo "Lauching KiteViewer..."
if test -f "bin/kps-image-${julia_major}.so"; then
    julia --startup-file=no  -t auto -J bin/kps-image-${julia_major}.so --optimize=1 --project -e "include(\"./examples/joystick.jl\");"
else
    julia --startup-file=no -t auto --optimize=2 --project -e "include(\"./examples/joystick.jl\");"
fi
