@echo off
REM This script creates a julia system image with a name that
REM contains the Julia version, e.g. kps-image-1.7.so
REM It should be placed in the bin folder of the project.
REM It assumes that the following files exist:
REM test/update_packages.jl
REM test/create_sys_image.jl

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..
for /f "delims=" %%i in ('julia --version') do set version_string=%%i
for /f "tokens=3 delims= " %%a in ("%version_string%") do set version=%%a

set julia_major=%version:~0,4%
set image=kps-image-%julia_major%.so

IF EXIST "bin\%image%" (
  move bin\kps-image-%julia_major%.so bin\kps-image-%julia_major%.so.bak
)

echo Updating packages...
if EXIST "Manifest.toml" (
    REM move Manifest.toml Manifest.toml.bak
)

REM julia --project -e "include(\"./test/update_packages.jl\");"
julia --project -e "using Pkg; Pkg.activate(temp=true); Pkg.add(\"PyCall\"); Pkg.build(\"PyCall\")"
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
move kps-image_tmp.so bin\kps-image-%julia_major%.so
julia --project -e "using Pkg; Pkg.precompile()"