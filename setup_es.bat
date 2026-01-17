@echo off
setlocal enabledelayedexpansion
title Administrador de Servidor Dedidado de Hytale

:: --- CONFIGURACIÓN ---
set DOWNLOADER=hytale-downloader-windows-amd64.exe
set JAR_FILE=HytaleServer.jar
set WORLD_NAME=NOMBRE_MUNDO
set OWNER=NOMBRE_JUGADOR
set SERVER_DIR=%cd%
set BACKUP_DIR=%SERVER_DIR%\backups_actualizacion
set UNIVERSE_DIR=%SERVER_DIR%\universe

:MENU
cls
echo ===================================================
echo           ADMINISTRADOR DE SERVIDOR HYTALE
echo ===================================================
echo  0. INSTALACION INICIAL (Descarga desde cero)
echo  1. COMPROBAR ACTUALIZACIONES (Local vs Nube)
echo  2. ACTUALIZAR SERVIDOR (Descarga + Auto-Install)
echo  3. REGENERAR ESQUEMAS (Arregla errores de config)
echo  4. BACKUP MANUAL DEL MUNDO (ZIP)
echo  5. INICIAR SERVIDOR
echo  6. SALIR
echo ===================================================
set /p OPT="Selecciona una opcion (0-6): "

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
echo [!] INICIANDO INSTALACION POR PRIMERA VEZ...
goto UPDATE_PROCESS

:VERSION
echo.
echo [1/3] Verificando version del Descargador...
%DOWNLOADER% -check-update
echo.
echo [2/3] Obteniendo version local...
if exist %JAR_FILE% (
    for /f "tokens=2" %%a in ('java -jar %JAR_FILE% --version ^| findstr "v2026"') do (
        set LOCAL_VER=%%a
        set LOCAL_VER=!LOCAL_VER:v=!
    )
) else (
    set LOCAL_VER=N/A
)
echo Local:  !LOCAL_VER!
echo [3/3] Obteniendo version en la Nube...
for /f "tokens=*" %%b in ('%DOWNLOADER% -print-version') do set REMOTE_VER=%%b
echo Remota: %REMOTE_VER%
echo.
if "!LOCAL_VER!"=="%REMOTE_VER%" (
    echo [OK] El servidor ya esta al dia.
) else (
    echo [!] ACTUALIZACION DISPONIBLE.
    set /p COMP="Deseas proceder? (S/N): "
    if /i "!COMP!"=="S" goto UPDATE
)
pause
goto MENU

:UPDATE
echo.
echo [1/6] Verificando espacio en disco...
:: Usando PowerShell para verificacion de espacio independiente del idioma (minimo 5GB)
for /f %%a in ('powershell -Command "(Get-PSDrive -Name $env:SystemDrive.Substring(0,1)).Free"') do set BYTES_FREE=%%a
if !BYTES_FREE! LSS 5000000000 (
    echo [ERROR] Espacio insuficiente. Necesitas al menos 5GB libres.
    echo Espacio detectado: !BYTES_FREE! bytes.
    pause
    goto MENU
)
echo [2/6] Creando backup de config...
set CUR_DATE=%date:~-4%-%date:~3,2%-%date:~0,2%
set CUR_TIME=%time:~0,2%-%time:~3,2%
set CUR_TIME=%CUR_TIME: =0%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if exist "config.json" copy config.json "%BACKUP_DIR%\config_pre_update_%CUR_DATE%_%CUR_TIME%.json" >nul

:UPDATE_PROCESS
echo [3/6] Descargando paquete de Hytale...
%DOWNLOADER%
for /f "tokens=*" %%b in ('%DOWNLOADER% -print-version') do set REMOTE_VER=%%b
set ZIP_DL=%REMOTE_VER%.zip

if not exist "%ZIP_DL%" (
    echo [ERROR] El archivo %ZIP_DL% no se encuentra.
    pause
    goto MENU
)

echo [4/6] Extrayendo archivos temporales...
if exist "temp_upd" rd /s /q "temp_upd"
:: Usamos un metodo mas directo de PowerShell para evitar errores de ruta
powershell -Command "Expand-Archive -Path '.\%ZIP_DL%' -DestinationPath '.\temp_upd' -Force"

if %errorlevel% neq 0 (
    echo [ERROR] La extraccion fallo. Posiblemente por falta de espacio.
    pause
    goto MENU
)

echo [5/6] Instalando Assets y Binarios...
if exist "temp_upd\Assets.zip" move /y "temp_upd\Assets.zip" ".\Assets.zip" >nul
if exist "temp_upd\Server" (
    xcopy "temp_upd\Server\*" ".\" /s /e /y >nul
)

echo [6/6] Limpiando...
rd /s /q "temp_upd"
del /q "%ZIP_DL%"
echo [OK] Archivos instalados correctamente.
goto SCHEMA_AUTO

:SCHEMA
echo.
java -jar %JAR_FILE% --generate-schema
echo [OK] Esquemas regenerados.
pause
goto MENU

:SCHEMA_AUTO
if exist %JAR_FILE% (
    echo [INFO] Generando esquemas de compatibilidad...
    java -jar %JAR_FILE% --generate-schema
    echo.
    echo ===================================================
    echo    PROCESO FINALIZADO CON EXITO
    echo ===================================================
) else (
    echo [ERROR] No se encontro HytaleServer.jar. La instalacion fallo.
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