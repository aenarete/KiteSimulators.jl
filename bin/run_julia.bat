@echo off
REM This script launches julia and loads a version specific
REM system image from the folder bin if it exists.

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..

REM Set environment variables
set NO_AT_BRIDGE=1
set JULIA_PKG_SERVER_REGISTRY_PREFERENCE=eager
set MPLBACKEND=qt5agg
set NO_MTK=true

REM Get Julia version
for /f "delims=" %%i in ('julia --version') do set version_string=%%i
for /f "tokens=3 delims= " %%a in ("%version_string%") do set version=%%a

set julia_major=%version:~0,3%
if "%julia_major%"=="1.1" (
    set julia_major=%version:~0,4%
    set GCT=--gcthreads=1,0
) else (
    set GCT=
)

set PLOT_THREADS=-t 1

IF EXIST "bin/kps-image-%julia_major%.so" (
    echo Found system image!
    julia -J bin/kps-image-%julia_major%.so %PLOT_THREADS% %GCT% --project %*
) else (
    julia --project %PLOT_THREADS% %GCT% %*
)
