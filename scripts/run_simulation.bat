@echo off
REM =========================================================================
REM run_simulation.bat
REM Runs Vivado simulation from the command line
REM Usage: scripts\run_simulation.bat
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
    echo Please set VIVADO_PATH in this script or add Vivado to PATH
    exit /b 1
)

echo Found Vivado: %VIVADO_EXE%
echo.

REM Create project
echo Creating project...
"%VIVADO_EXE%" -mode batch -source "%PROJECT_DIR%\create_project.tcl"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Project creation failed
    exit /b 1
)

REM Run simulation
echo Running simulation...
"%VIVADO_EXE%" -mode batch -source "%PROJECT_DIR%\run_sim.tcl"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Simulation failed
    exit /b 1
)

echo.
echo Simulation complete. Check output above for PASS/FAIL results.
