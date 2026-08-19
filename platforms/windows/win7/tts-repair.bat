@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title Win7 TTS Repair

set "SCRIPT_DIR=%~dp0"
set "RES_DIR=%SCRIPT_DIR%resources"
set "RUNTIME_MSI=%RES_DIR%\Microsoft Speech Platform\SpeechPlatformRuntime(x86).msi"
set "LANG_MSI=%RES_DIR%\Microsoft Speech Platform\Languages\MSSpeech_TTS_zh-CN_HuiHui.msi"
set "UNIFIER_EXE=%RES_DIR%\SAPI_Unifier\SAPI_Unifier_requires_dot_NET_4.exe"

echo ============================================================
echo Win7 TTS Repair - Check ^> Repair ^> Verify
echo ============================================================
echo Script Path: %SCRIPT_DIR%
echo Resource Path: %RES_DIR%
echo.

call :require_admin || goto :fail
call :check_resources || goto :fail

echo [1/3] Initial Check...
call :detect_state
call :print_state

echo.
echo [2/3] Repair...
if "%RUNTIME_OK%"=="1" (
  echo - Runtime already installed. Skip.
) else (
  call :install_msi "%RUNTIME_MSI%" "Microsoft Speech Platform Runtime x86" || goto :fail
)

if "%LANG_OK%"=="1" (
  echo - zh-CN HuiHui language pack already installed. Skip.
) else (
  call :install_msi "%LANG_MSI%" "MSSpeech_TTS_zh-CN_HuiHui" || goto :fail
)

if "%SAPI_OK%"=="1" (
  echo - SAPI Unifier result already present. Skip.
) else (
  call :run_unifier "%UNIFIER_EXE%" || goto :fail
)

echo.
echo [3/3] Verify...
call :detect_state
call :print_state

if "%RUNTIME_OK%"=="1" if "%LANG_OK%"=="1" if "%SAPI_OK%"=="1" (
  echo.
  echo [SUCCESS] Win7 TTS repair completed.
  echo You can now test TTS output in your target application.
  exit /b 0
)

echo.
echo [ERROR] Repair finished but verification failed.
echo Please review the logs above and run this script again as Administrator.
exit /b 1

:require_admin
net session >nul 2>&1
if "%ERRORLEVEL%"=="0" (
  echo [OK] Running with Administrator permission.
  exit /b 0
)
echo [ERROR] Administrator permission is required.
echo Please right-click this script and choose "Run as administrator".
exit /b 1

:check_resources
if not exist "%RES_DIR%" (
  echo [ERROR] Resource directory not found: "%RES_DIR%"
  exit /b 1
)
if not exist "%RUNTIME_MSI%" (
  echo [ERROR] Missing file: "%RUNTIME_MSI%"
  exit /b 1
)
if not exist "%LANG_MSI%" (
  echo [ERROR] Missing file: "%LANG_MSI%"
  exit /b 1
)
if not exist "%UNIFIER_EXE%" (
  echo [ERROR] Missing file: "%UNIFIER_EXE%"
  exit /b 1
)
echo [OK] Required resource files are present.
exit /b 0

:detect_state
set "RUNTIME_OK=0"
set "LANG_OK=0"
set "SAPI_OK=0"

rem Runtime check
reg query "HKLM\SOFTWARE\Microsoft\SpeechServer\v11.0" >nul 2>&1 && set "RUNTIME_OK=1"
if "%RUNTIME_OK%"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\SpeechServer\v11.0" >nul 2>&1 && set "RUNTIME_OK=1"

rem Language pack check (HuiHui token under SpeechServer)
reg query "HKLM\SOFTWARE\Microsoft\SpeechServer\v11.0\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "LANG_OK=1"
if "%LANG_OK%"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\SpeechServer\v11.0\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "LANG_OK=1"

rem SAPI mapping check (expected after running SAPI Unifier)
reg query "HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "SAPI_OK=1"
if "%SAPI_OK%"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "SAPI_OK=1"
exit /b 0

:print_state
call :print_item "Speech Runtime" "%RUNTIME_OK%"
call :print_item "zh-CN HuiHui Language Pack" "%LANG_OK%"
call :print_item "SAPI Unifier Mapping" "%SAPI_OK%"
exit /b 0

:print_item
if "%~2"=="1" (
  echo - %~1: OK
) else (
  echo - %~1: MISSING
)
exit /b 0

:install_msi
echo [INSTALL] %~2
msiexec /i "%~1" /qn /norestart
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo [ERROR] Failed to install: %~2. Exit code: %RC% & exit /b 1
echo [OK] Installed: %~2
exit /b 0

:run_unifier
echo [RUN] SAPI Unifier
echo Launching: "%~1"
start "" /wait "%~1"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo [ERROR] SAPI Unifier failed. Exit code: %RC% & exit /b 1
echo [OK] SAPI Unifier finished.
exit /b 0

:fail
echo.
echo [FAILED] Win7 TTS repair did not complete.
exit /b 1
