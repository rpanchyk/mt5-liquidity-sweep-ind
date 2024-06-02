@echo off
setlocal

@REM The script copies files from MetaTrader

@REM Read options file having format:
@REM DATA_DIR=C:\Users\[USER]\AppData\Roaming\MetaQuotes\Terminal\[TERMINAL_ID]
@REM To see the actual path go to main menu "File -> Open Data Folder" in MetaTrader.
set OPTIONS_FILE=copy_options.txt
if not exist %OPTIONS_FILE% echo Error: %OPTIONS_FILE% file not found && pause && exit 1
for /f "delims== tokens=1,2" %%G in (%OPTIONS_FILE%) do set %%G=%%H

@REM Settings
::set INCLUDE_DIR=MQL5\Include
::set EXPERTS_DIR=MQL5\Experts
set INDICATORS_DIR=MQL5\Indicators

@REM Clean local dirs
::if exist "%INCLUDE_DIR%" rmdir /s /q "%INCLUDE_DIR%"
::if exist "%EXPERTS_DIR%" rmdir /s /q "%EXPERTS_DIR%"
if exist "%INDICATORS_DIR%" rmdir /s /q "%INDICATORS_DIR%"

@REM Create local dirs
::if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%"
::if not exist "%EXPERTS_DIR%" mkdir "%EXPERTS_DIR%"
if not exist "%INDICATORS_DIR%" mkdir "%INDICATORS_DIR%"

@REM Copy files to local dirs
::xcopy /s /i /f /v /y "%DATA_DIR%\%INCLUDE_DIR%" "%INCLUDE_DIR%"
::copy /y "%DATA_DIR%\%EXPERTS_DIR%\My_EA.mq5" "%EXPERTS_DIR%"
copy /y "%DATA_DIR%\%INDICATORS_DIR%\LiquiditySweep.mq5" "%INDICATORS_DIR%"

echo Successfully copied.
timeout /t 5
