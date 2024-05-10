@echo off
REM This script launches julia and loads a version specific
REM system image from the folder bin if it exists.
REM The name of the system image must be similar to
REM kps-image-1.10.so
REM It launches julia with two threads.

REM determine basename of current directory
for /F "delims=" %%i in ("%cd%") do set basename=%%~ni

if %basename%==bin cd ..
for /f "delims=" %%i in ('julia --version') do set version_string=%%i
for /f "tokens=3 delims= " %%a in ("%version_string%") do set version=%%a

set julia_major=%version:~0,4%
set image=kps-image-%julia_major%.so

set EDITOR="code"

IF EXIST "bin/%image%" (
    echo Found system image!
    julia -J  bin/kps-image-%julia_major%.so -t 2 --project
) else julia --project
