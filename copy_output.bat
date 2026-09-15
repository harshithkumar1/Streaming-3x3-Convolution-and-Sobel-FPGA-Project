@echo off
REM copy_output.bat - Copies Vivado output to MATLAB folder
REM Run this after Vivado simulation completes

echo ==========================================
echo  Copying Vivado output to MATLAB folder
echo ==========================================

set SOURCE=Stage2\vivado\stage2_sobel_edge\stage2_sobel_edge.sim\sim_1\behav\xsim\vivado_edge_output.hex
set DEST=Stage2\matlab\vivado_edge_output.hex

if exist "%SOURCE%" (
    copy "%SOURCE%" "%DEST%" /Y
    echo Copied successfully!
    echo Source: %SOURCE%
    echo Dest:   %DEST%
) else (
    echo ERROR: Source file not found!
    echo Looked in: %SOURCE%
)

echo.
pause
