@echo off
REM =========================================================================
REM run_synthesis.bat
REM Runs Vivado synthesis and generates reports
REM Usage: scripts\run_synthesis.bat
REM =========================================================================

set VIVADO_PATH=C:\AMDDesignTools\2026.1\Vivado
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..\vivado

REM Find Vivado
set VIVADO_EXE=
for /d %%d in ("%VIVADO_PATH%\20*") do (
    if exist "%%d\bin\vivado.bat" (
        set VIVADO_EXE=%%d\bin\vivado.bat
    )
)

if "%VIVADO_EXE%"=="" (
    echo ERROR: Vivado not found at %VIVADO_PATH%
    exit /b 1
)

echo Running synthesis...
"%VIVADO_EXE%" -mode batch -source "%PROJECT_DIR%\run_synth.tcl"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Synthesis failed
    exit /b 1
)

echo.
echo Synthesis complete. Check vivado\reports\ for utilization and timing.
