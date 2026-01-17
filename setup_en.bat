@echo off
setlocal enabledelayedexpansion
title Hytale Dedicated Server Manager

:: --- CONFIGURATION ---
set DOWNLOADER=hytale-downloader-windows-amd64.exe
set JAR_FILE=HytaleServer.jar
set WORLD_NAME=WORLD_NAME
set OWNER=PLAYER_NAME
set SERVER_DIR=%cd%
set BACKUP_DIR=%SERVER_DIR%\update_backups
set UNIVERSE_DIR=%SERVER_DIR%\universe

:MENU
cls
echo ===================================================
echo           HYTALE DEDICATED SERVER MANAGER
echo ===================================================
echo  0. INITIAL INSTALLATION (Download from scratch)
echo  1. CHECK FOR UPDATES (Local vs Cloud)
echo  2. UPDATE SERVER (Download + Auto-Install)
echo  3. REGENERATE SCHEMAS (Fixes config errors)
echo  4. MANUAL WORLD BACKUP (ZIP)
echo  5. START SERVER
echo  6. EXIT
echo ===================================================
set /p OPT="Select an option (0-6): "

if "%OPT%"=="0" goto INITIAL_INSTALL
if "%OPT%"=="1" goto VERSION
if "%OPT%"=="2" goto UPDATE
if "%OPT%"=="3" goto SCHEMA
if "%OPT%"=="4" goto WORLD_ZIP
if "%OPT%"=="5" goto START
if "%OPT%"=="6" exit
goto MENU

:INITIAL_INSTALL
echo.
echo [!] STARTING FIRST-TIME INSTALLATION...
goto UPDATE_PROCESS

:VERSION
echo.
echo [1/3] Checking Downloader version...
%DOWNLOADER% -check-update
echo.
echo [2/3] Getting local version...
if exist %JAR_FILE% (
    for /f "tokens=2" %%a in ('java -jar %JAR_FILE% --version ^| findstr "v2026"') do (
        set LOCAL_VER=%%a
        set LOCAL_VER=!LOCAL_VER:v=!
    )
) else (
    set LOCAL_VER=N/A
)
echo Local:  !LOCAL_VER!
echo [3/3] Getting Cloud version...
for /f "tokens=*" %%b in ('%DOWNLOADER% -print-version') do set REMOTE_VER=%%b
echo Remote: %REMOTE_VER%
echo.
if "!LOCAL_VER!"=="%REMOTE_VER%" (
    echo [OK] Server is already up to date.
) else (
    echo [!] UPDATE AVAILABLE.
    set /p COMP="Do you want to proceed? (Y/N): "
    if /i "!COMP!"=="Y" goto UPDATE
)
pause
goto MENU

:UPDATE
echo.
echo [1/6] Checking disk space...
:: Using PowerShell for language-independent disk space check (5GB minimum)
for /f %%a in ('powershell -Command "(Get-PSDrive -Name $env:SystemDrive.Substring(0,1)).Free"') do set BYTES_FREE=%%a
if !BYTES_FREE! LSS 5000000000 (
    echo [ERROR] Insufficient space. You need at least 5GB free.
    echo Detected space: !BYTES_FREE! bytes.
    pause
    goto MENU
)
echo [2/6] Creating config backup...
set CUR_DATE=%date:~-4%-%date:~3,2%-%date:~0,2%
set CUR_TIME=%time:~0,2%-%time:~3,2%
set CUR_TIME=%CUR_TIME: =0%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if exist "config.json" copy config.json "%BACKUP_DIR%\config_pre_update_%CUR_DATE%_%CUR_TIME%.json" >nul

:UPDATE_PROCESS
echo [3/6] Downloading Hytale package...
%DOWNLOADER%
for /f "tokens=*" %%b in ('%DOWNLOADER% -print-version') do set REMOTE_VER=%%b
set ZIP_DL=%REMOTE_VER%.zip

if not exist "%ZIP_DL%" (
    echo [ERROR] File %ZIP_DL% not found.
    pause
    goto MENU
)

echo [4/6] Extracting temporary files...
if exist "temp_upd" rd /s /q "temp_upd"
:: Using a more direct PowerShell method to avoid path errors
powershell -Command "Expand-Archive -Path '.\%ZIP_DL%' -DestinationPath '.\temp_upd' -Force"

if %errorlevel% neq 0 (
    echo [ERROR] Extraction failed. Possibly due to lack of space.
    pause
    goto MENU
)

echo [5/6] Installing Assets and Binaries...
if exist "temp_upd\Assets.zip" move /y "temp_upd\Assets.zip" ".\Assets.zip" >nul
if exist "temp_upd\Server" (
    xcopy "temp_upd\Server\*" ".\" /s /e /y >nul
)

echo [6/6] Cleaning up...
rd /s /q "temp_upd"
del /q "%ZIP_DL%"
echo [OK] Files installed successfully.
goto SCHEMA_AUTO

:SCHEMA
echo.
java -jar %JAR_FILE% --generate-schema
echo [OK] Schemas regenerated.
pause
goto MENU

:SCHEMA_AUTO
if exist %JAR_FILE% (
    echo [INFO] Generating compatibility schemas...
    java -jar %JAR_FILE% --generate-schema
    echo.
    echo ===================================================
    echo    PROCESS COMPLETED SUCCESSFULLY
    echo ===================================================
) else (
    echo [ERROR] HytaleServer.jar not found. Installation failed.
)
pause
goto MENU

:WORLD_ZIP
echo.
set CURRENT_DATE=%date:~-4%-%date:~3,2%-%date:~0,2%
set CURRENT_TIME=%time:~0,2%-%time:~3,2%
set CURRENT_TIME=%CURRENT_TIME: =0%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
set ZIP_FILE=%BACKUP_DIR%\Backup_%WORLD_NAME%_%CURRENT_DATE%_%CURRENT_TIME%.zip
powershell -Command "Compress-Archive -Path '%UNIVERSE_DIR%\*' -DestinationPath '%ZIP_FILE%' -Force"
pause
goto MENU

:START
echo.
java -Xms2G -Xmx4G --enable-native-access=ALL-UNNAMED -jar %JAR_FILE% --assets Assets.zip --universe "%UNIVERSE_DIR%" --owner-name "%OWNER%" --backup --backup-dir backup --backup-max-count 4 --backup-frequency 1440
pause
goto MENU
