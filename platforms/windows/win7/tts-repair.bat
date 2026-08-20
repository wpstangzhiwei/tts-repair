@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title Win7 TTS Repair

set "SCRIPT_DIR=%~dp0"
set "RES_DIR=%SCRIPT_DIR%resources"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "RUNTIME_MSI=%RES_DIR%\Microsoft Speech Platform\SpeechPlatformRuntime(x86).msi"
set "LANG_MSI=%RES_DIR%\Microsoft Speech Platform\Languages\MSSpeech_TTS_zh-CN_HuiHui.msi"
set "UNIFIER_EXE=%RES_DIR%\SAPI_Unifier\SAPI_Unifier_requires_dot_NET_4.exe"

rem ProductCode taken from the bundled MSI Property table.
set "RUNTIME_PRODUCT={22CB8ED7-DF57-4864-BD04-F63B9CE4B494}"
set "LANG_PRODUCT={44B3785F-9F8B-46A9-AD46-21B7AC49D086}"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

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
call :ensure_msi "%RUNTIME_MSI%" "Microsoft Speech Platform Runtime x86" "runtime" "%RUNTIME_PRODUCT%" "!RUNTIME_OK!" || goto :fail
call :ensure_msi "%LANG_MSI%" "MSSpeech_TTS_zh-CN_HuiHui" "lang" "%LANG_PRODUCT%" "!LANG_OK!" || goto :fail

if "!SAPI_OK!"=="1" (
  echo - SAPI Unifier result already present. Skip.
) else (
  call :run_unifier "%UNIFIER_EXE%" || goto :fail
)

echo.
echo [3/3] Verify...
call :detect_state
call :print_state

if "!RUNTIME_OK!"=="1" if "!LANG_OK!"=="1" if "!SAPI_OK!"=="1" (
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
set "RUNTIME_PRODUCT_OK=0"
set "LANG_OK=0"
set "LANG_PRODUCT_OK=0"
set "SAPI_OK=0"
set "SPEECH_DIR=%CommonProgramFiles%\Microsoft Shared\Speech"
set "SPEECH_DIR_X86=%CommonProgramFiles(x86)%\Microsoft Shared\Speech"

call :query_product "%RUNTIME_PRODUCT%" RUNTIME_PRODUCT_OK
call :query_product "%LANG_PRODUCT%" LANG_PRODUCT_OK

rem Functional check uses payload files, not leftover ProductCode / empty registry keys.
if exist "%SPEECH_DIR%\Microsoft.Speech.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR%\SR\v11.0\spsreng.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR_X86%\Microsoft.Speech.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR_X86%\SR\v11.0\spsreng.dll" set "RUNTIME_OK=1"

if exist "%SPEECH_DIR%\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0\HuiHuiT.INI" set "LANG_OK=1"
if "!LANG_OK!"=="0" if exist "%SPEECH_DIR_X86%\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0\HuiHuiT.INI" set "LANG_OK=1"
if "!LANG_OK!"=="0" if exist "%SPEECH_DIR%\HuiHuiT.INI" set "LANG_OK=1"
if "!LANG_OK!"=="0" if exist "%SPEECH_DIR_X86%\HuiHuiT.INI" set "LANG_OK=1"

reg query "HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "SAPI_OK=1"
if "!SAPI_OK!"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0" >nul 2>&1 && set "SAPI_OK=1"
exit /b 0

:print_state
call :print_item "Speech Runtime" "!RUNTIME_OK!" "!RUNTIME_PRODUCT_OK!"
call :print_item "zh-CN HuiHui Language Pack" "!LANG_OK!" "!LANG_PRODUCT_OK!"
call :print_item "SAPI Unifier Mapping" "!SAPI_OK!" ""
exit /b 0

:print_item
if "%~2"=="1" (
  echo - %~1: OK
) else (
  echo - %~1: MISSING
)
if "%~3"=="1" if not "%~2"=="1" echo   Leftover MSI registration found. Will repair or reinstall.
if "%~3"=="1" if "%~2"=="1" echo   MSI product already registered.
exit /b 0

:ensure_msi
set "MSI_PATH=%~1"
set "MSI_NAME=%~2"
set "MSI_TAG=%~3"
set "MSI_CODE=%~4"
set "MSI_FUNC=%~5"
call :query_product "%MSI_CODE%" MSI_PRODUCT

if "%MSI_FUNC%"=="1" (
  echo - %MSI_NAME% already installed. Skip.
  exit /b 0
)

if "%MSI_PRODUCT%"=="1" (
  echo [REPAIR] %MSI_NAME% is registered but incomplete. Repairing instead of reinstalling.
  call :run_msiexec "%MSI_PATH%" "%MSI_NAME%" "%MSI_TAG%-repair.log" "REINSTALL=ALL REINSTALLMODE=vomus"
  exit /b !ERRORLEVEL!
)

echo [INSTALL] %MSI_NAME%
call :run_msiexec "%MSI_PATH%" "%MSI_NAME%" "%MSI_TAG%-install.log" ""
exit /b !ERRORLEVEL!

:run_msiexec
set "MSI_LOG=%LOG_DIR%\%~3"
echo Log: "%MSI_LOG%"
msiexec /i "%~1" %~4 /qn /norestart /L*v "%MSI_LOG%"
set "RC=%ERRORLEVEL%"
if "%RC%"=="0" echo [OK] %~2 & exit /b 0
if "%RC%"=="3010" echo [WARN] %~2 finished. Reboot required. & set "REBOOT_REQUIRED=1" & exit /b 0
if "%RC%"=="1638" echo [OK] %~2 already installed. & exit /b 0
if not "%RC%"=="1603" echo [ERROR] Failed: %~2. Exit code: %RC% & echo [ERROR] MSI log: "%MSI_LOG%" & exit /b 1

echo [WARN] Installer returned 1603 for %~2. Checking ProductCode...
call :query_product "%MSI_CODE%" MSI_PRODUCT
if "%MSI_PRODUCT%"=="1" echo [OK] %~2 is already registered. Skip reinstall. & exit /b 0
echo [ERROR] Failed: %~2. Exit code: 1603
echo [ERROR] MSI log: "%MSI_LOG%"
exit /b 1

:run_unifier
echo [RUN] SAPI Unifier
echo Launching: "%~1"
echo The Unifier window will be closed automatically after mapping finishes.
start "" wscript //nologo "%SCRIPT_DIR%auto-close-sapi-unifier.vbs"
start "" /wait "%~1"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" if not "%RC%"=="1" echo [WARN] SAPI Unifier exit code: %RC%
echo [OK] SAPI Unifier finished.
exit /b 0

:query_product
set "%~2=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%~1" >nul 2>&1
if "%ERRORLEVEL%"=="0" set "%~2=1" & exit /b 0
reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\%~1" >nul 2>&1
if "%ERRORLEVEL%"=="0" set "%~2=1"
exit /b 0

:fail
echo.
echo [FAILED] Win7 TTS repair did not complete.
if defined REBOOT_REQUIRED echo [INFO] A reboot may be required before retrying.
exit /b 1
