@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title Win11 TTS Repair

set "SCRIPT_DIR=%~dp0"
set "CACHE_DIR=%SCRIPT_DIR%cache"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "REPAIR_PS1=%SCRIPT_DIR%scripts\repair-tts.ps1"

set "WANT_LOCALE="
set "WANT_BUILD="
set "DO_LIST=0"
set "DO_MENU=0"
set "CAT="

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%" >nul 2>&1

call :build_catalog
call :parse_args %*
if errorlevel 1 exit /b 1
if "!DO_LIST!"=="1" (
  call :run_ps1 -List -Catalog "!CAT!"
  exit /b !ERRORLEVEL!
)
if "!DO_MENU!"=="1" (
  call :pick_locale
  if errorlevel 1 exit /b 1
)

if "!WANT_LOCALE!"=="" set "WANT_LOCALE=zh-CN"

echo ============================================================
echo Win11 TTS Repair - Check ^> Repair ^> Verify
echo ============================================================
echo Script Path: %SCRIPT_DIR%
echo Cache Path: %CACHE_DIR%
echo Help: tts-repair.bat /help    Menu: tts-repair.bat /menu
echo Target locale: !WANT_LOCALE!
if not "!WANT_BUILD!"=="" echo Target build override: !WANT_BUILD!
echo.

if not exist "%REPAIR_PS1%" (
  echo [ERROR] Missing script: "%REPAIR_PS1%"
  exit /b 1
)

call :run_ps1 -Locale "!WANT_LOCALE!" -CacheDir "%CACHE_DIR%" -LogDir "%LOG_DIR%" -BuildOverride "!WANT_BUILD!"
set "RC=!ERRORLEVEL!"

if "!RC!"=="0" (
  echo.
  echo [SUCCESS] Win11 TTS repair completed.
) else (
  echo.
  echo [FAILED] Win11 TTS repair did not complete. See messages above.
)
exit /b !RC!

:parse_args
if "%~1"=="" exit /b 0
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-?" goto :usage
if /I "%~1"=="/help" goto :usage
if /I "%~1"=="-help" goto :usage
if /I "%~1"=="/list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="-list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="/menu" set "DO_MENU=1" & shift & goto :parse_args
if /I "%~1"=="-menu" set "DO_MENU=1" & shift & goto :parse_args
if /I "%~1"=="/lang" goto :parse_lang
if /I "%~1"=="-lang" goto :parse_lang
if /I "%~1"=="/build" goto :parse_build
if /I "%~1"=="-build" goto :parse_build
if /I "%~1"=="list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="menu" (
  if "!WANT_LOCALE!"=="" (
    set "DO_MENU=1"
    shift
    goto :parse_args
  )
)
if "!WANT_LOCALE!"=="" (
  set "WANT_LOCALE=%~1"
  shift
  goto :parse_args
)
echo [ERROR] Unknown argument: %~1
goto :usage

:parse_lang
shift
if "%~1"=="" goto :usage
set "WANT_LOCALE=%~1"
shift
goto :parse_args

:parse_build
shift
if "%~1"=="" goto :usage
set "WANT_BUILD=%~1"
shift
goto :parse_args

:usage
echo Usage:
echo   tts-repair.bat /help
echo   tts-repair.bat /list
echo   tts-repair.bat /menu
echo   tts-repair.bat
echo   tts-repair.bat zh-CN
echo   tts-repair.bat /lang ja-JP
echo   tts-repair.bat en-US /build 19045
echo.
echo Repair a missing Windows TTS voice using DISM capabilities.
echo   Default without arguments: zh-CN
echo   /list            Show locales; marks cached cabs and installed voices
echo   /menu            Interactive picker
echo   /lang locale     Repair TTS for that locale
echo   /build number    Override auto-detected OS build used on uupdump lookup
echo.
echo Missing capability cabs are downloaded from uupdump.net into cache\
echo and installed offline via Add-WindowsCapability -LimitAccess.
echo Administrator permission is required for repair.
call :print_catalog
exit /b 1

:print_catalog
echo.
echo Supported TTS locales:
echo!CAT!
exit /b 0

:pick_locale
set "MENU_N=0"
echo.
echo ------------------------------------------------------------
echo Choose a language
echo ------------------------------------------------------------
echo.
for %%L in (!CAT!) do (
  set /a MENU_N+=1
  set "MENU_LOC_!MENU_N!=%%L"
  echo   !MENU_N!^) %%L
)
echo.
echo Enter a number, or a locale like zh-CN.
echo Empty = zh-CN [default].
set /p "MENU_IN=Select: "
if "!MENU_IN!"=="" (
  set "WANT_LOCALE=zh-CN"
  exit /b 0
)
if /I "!MENU_IN!"=="/help" goto :usage
if /I "!MENU_IN!"=="/list" goto :usage
echo(!MENU_IN!| findstr /r "^[1-9][0-9]*$" >nul
if not errorlevel 1 (
  call set "PICK_LOC=%%MENU_LOC_!MENU_IN!%%"
  if "!PICK_LOC!"=="" (
    echo [ERROR] Invalid menu number: !MENU_IN!
    exit /b 1
  )
  set "WANT_LOCALE=!PICK_LOC!"
  exit /b 0
)
set "WANT_LOCALE=!MENU_IN!"
exit /b 0

:run_ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%REPAIR_PS1%" %*
exit /b !ERRORLEVEL!

:build_catalog
for /f "tokens=3" %%L in ('findstr /b /c:"rem @tts " "%~f0"') do set "CAT=!CAT! %%L"
exit /b 0

rem Windows 10/11 TextToSpeech capability locales (uupdump LanguageFeatures packages)
rem @tts ar-EG
rem @tts ar-SA
rem @tts bg-BG
rem @tts ca-ES
rem @tts cs-CZ
rem @tts da-DK
rem @tts de-AT
rem @tts de-CH
rem @tts de-DE
rem @tts el-GR
rem @tts en-AU
rem @tts en-CA
rem @tts en-GB
rem @tts en-IN
rem @tts en-US
rem @tts es-ES
rem @tts es-MX
rem @tts fi-FI
rem @tts fr-CA
rem @tts fr-CH
rem @tts fr-FR
rem @tts he-IL
rem @tts hi-IN
rem @tts hr-HR
rem @tts hu-HU
rem @tts id-ID
rem @tts it-IT
rem @tts ja-JP
rem @tts ko-KR
rem @tts ms-MY
rem @tts nb-NO
rem @tts nl-BE
rem @tts nl-NL
rem @tts pl-PL
rem @tts pt-BR
rem @tts pt-PT
rem @tts ro-RO
rem @tts ru-RU
rem @tts sk-SK
rem @tts sl-SI
rem @tts sv-SE
rem @tts ta-IN
rem @tts th-TH
rem @tts tr-TR
rem @tts vi-VN
rem @tts zh-CN
rem @tts zh-HK
rem @tts zh-TW
