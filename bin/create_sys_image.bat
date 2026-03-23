@echo off
REM This script creates a julia system image with a name that
REM contains the Julia version, e.g. kps-image-1.11.so
REM It should be placed in the bin folder of the project.
REM It assumes that the following files exist:
REM test/create_sys_image.jl

REM Parse command-line arguments
setlocal enabledelayedexpansion
set _skip_dialog=false

if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="--yes" set _skip_dialog=true
if "%1"=="-y" set _skip_dialog=true

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..

REM Set environment variables
set MPLBACKEND=qt5agg
set NO_MTK=true
set JULIA_PKG_SERVER_REGISTRY_PREFERENCE=eager

REM Get Julia version
for /f "delims=" %%i in ('julia --version') do set version_string=%%i
for /f "tokens=3 delims= " %%a in ("%version_string%") do set version=%%a

set julia_major=%version:~0,3%
if "%julia_major%"=="1.1" (
    set julia_major=%version:~0,4%
)

if not exist output mkdir output

echo Installing package TestEnv in the global environment!
julia --startup-file=no -e "using Pkg; Pkg.add(\"TestEnv\")"

REM Setup PyCall
echo.
echo Setting up PyCall...
julia --startup-file=no --project -e "using Pkg; Pkg.activate(temp=true); Pkg.add(\"PyCall\"); Pkg.build(\"PyCall\")"

REM Backup existing system image
if exist "bin\kps-image-%julia_major%.so" (
    move "bin\kps-image-%julia_major%.so" "bin\kps-image-%julia_major%.so.bak"
)

REM Run batch simulation to generate logs
echo.
echo Running batch simulation...
call bin\batch_pilot hydra20_600

REM Precompile packages
echo.
echo Precompiling packages...
julia --startup-file=no --project -e "using Pkg; Pkg.precompile()"

REM Create system image
echo.
echo Creating system image...
set MPLBACKEND=agg
julia --startup-file=no --project -t 1 -e "include(\"./test/create_sys_image.jl\");"
if exist kps-image_tmp.so (
    move kps-image_tmp.so "bin\kps-image-%julia_major%.so"
) else (
    echo Error: Failed to create system image
    exit /b 1
)

REM Verify system image
echo.
echo Verifying system image...
julia --startup-file=no --project -J "bin\kps-image-%julia_major%.so" -e "using ControlPlots"
echo Successfully created system image!
goto end

:show_help
echo Usage: bin\create_sys_image [OPTIONS]
echo.
echo Options:
echo   -h, --help      Show this help message
echo   -y, --yes       Skip the Julia version dialog and use the default version
echo.
echo Examples:
echo   bin\create_sys_image      # Interactive mode
echo   bin\create_sys_image --yes # Use default Julia version without prompting
goto end

:end