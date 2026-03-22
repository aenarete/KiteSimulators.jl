@echo off
REM This script runs a batch simulation for the given kite project configuration.

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..

REM Check for help option
if "%1"=="--help" goto help
if "%1"=="-h" goto help

REM Check for list option
if "%1"=="--list" goto list

REM Run the batch pilot
call "%~dp0run_julia.bat" "examples/batch_pilot.jl" %*
goto end

:help
echo Usage: batch_pilot [OPTIONS] [PROJECT]
echo.
echo Run a batch simulation for the given kite project configuration.
echo.
echo Arguments:
echo   PROJECT        Name of the project config file (without .yml extension)
echo                  from the data/ directory (e.g. hydra20_426)
echo.
echo Options:
echo   --list         List all available project configurations
echo   --help, -h     Show this help message and exit
echo.
echo Examples:
echo   batch_pilot hydra20_426
echo   batch_pilot --list
goto end

:list
echo Available projects:
for /f "delims=" %%f in ('dir /b data\*.yml') do (
    echo %%~nf
)
goto end

:end
