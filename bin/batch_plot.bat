@echo off
REM This script plots the results of a batch simulation from an Arrow log file.

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..

REM Check for help option
if "%1"=="--help" goto help
if "%1"=="-h" goto help

REM Check for list-commands option
if "%1"=="--list-commands" goto list_commands

REM Check for list option
if "%1"=="--list" goto list

REM Run the batch plot
call "%~dp0run_julia.bat" "examples/batch_plot.jl" %*
goto end

:help
echo Usage: batch_plot [OPTIONS] [PROJECT [COMMAND]]
echo.
echo Plot the results of a batch simulation from an Arrow log file.
echo.
echo Arguments:
echo   PROJECT        Project name (e.g. hydra20_426) or full log filename
echo                  (e.g. batch-hydra20_426) from the output/ directory.
echo                  If omitted, the last selected project is used.
echo   COMMAND        Plot command to run directly without showing the menu
echo                  (e.g. plot_main, plot_power, plot_control, plot_elev_az)
echo.
echo Options:
echo   --list              List all available projects in output/
echo   --list-commands     List all available plot commands
echo   --help, -h          Show this help message and exit
echo.
echo Examples:
echo   batch_plot hydra20_426
echo   batch_plot hydra20_426 plot_main
echo   batch_plot hydra20_426 plot_elev_az
echo   batch_plot --list
echo   batch_plot --list-commands
goto end

:list_commands
echo Available plot commands:
echo   statistics
echo   plot_main
echo   plot_power
echo   plot_control
echo   plot_control_II
echo   plot_winch_control
echo   plot_aerodynamics
echo   plot_elev_az
echo   plot_elev_az2
echo   plot_elev_az3
echo   plot_side_view
echo   plot_side_view2
echo   plot_side_view3
echo   plot_front_view3
goto end

:list
echo Available projects:
for /f "delims=" %%f in ('dir /b output\batch-*.arrow') do (
    set filename=%%f
    REM Remove "batch-" prefix and ".arrow" suffix
    set project=!filename:batch-=!
    set project=!project:.arrow=!
    echo !project!
)
goto end

:end
