@echo off
REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..
for /f "delims=" %%i in ('julia --version') do set version_string=%%i
for /f "tokens=3 delims= " %%a in ("%version_string%") do set version=%%a

set julia_major=%version:~0,4%
set image=kps-image-%julia_major%.dll

echo Lauching KiteViewer...
IF EXIST "bin/%image%" (
    julia --startup-file=no  -t auto -J bin/kps-image-%julia_major%.dll --optimize=1 --project -e "include(\"./examples/joystick.jl\");"
) else julia --startup-file=no -t auto --optimize=2 --project -e "include(\"./examples/joystick.jl\");"
