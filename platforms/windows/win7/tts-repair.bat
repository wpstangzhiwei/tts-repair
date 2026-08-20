@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title Win7 TTS Repair

set "SCRIPT_DIR=%~dp0"
set "RES_DIR=%SCRIPT_DIR%resources"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LANG_DIR=%RES_DIR%\Microsoft Speech Platform\Languages"
set "LANGPACKS_DIR=%RES_DIR%\Microsoft Speech Platform\langpacks"
set "LANGPACKS_URL=https://github.com/wpstangzhiwei/tts-repair-win7-langpacks/raw/main"
set "CLOSE_UNIFIER_VBS=%SCRIPT_DIR%scripts\auto-close-sapi-unifier.vbs"
set "MSI_CODE_VBS=%SCRIPT_DIR%scripts\msi-productcode.vbs"
set "RUNTIME_MSI=%RES_DIR%\Microsoft Speech Platform\SpeechPlatformRuntime(x86).msi"
set "UNIFIER_EXE=%RES_DIR%\SAPI_Unifier\SAPI_Unifier_requires_dot_NET_4.exe"
set "RUNTIME_PRODUCT={22CB8ED7-DF57-4864-BD04-F63B9CE4B494}"

set "SPEECH_DIR=%CommonProgramFiles%\Microsoft Shared\Speech"
set "SPEECH_DIR_X86=%CommonProgramFiles(x86)%\Microsoft Shared\Speech"

set "WANT_LOCALE="
set "WANT_VOICE="
set "WANT_KIND=tts"
set "DO_LIST=0"
set "DO_ALL=0"
set "NEED_UNIFIER=0"
set "SEL_N=0"
set "VERIFY_FAIL=0"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

call :parse_args %*
if errorlevel 1 exit /b 1
if "!DO_LIST!"=="1" (
  call :list_packs
  exit /b 0
)

if "!DO_ALL!"=="0" if "!WANT_LOCALE!"=="" set "WANT_LOCALE=zh-CN"

echo ============================================================
echo Win7 TTS Repair - Check ^> Repair ^> Verify
echo ============================================================
echo Script Path: %SCRIPT_DIR%
echo Resource Path: %RES_DIR%
if "!DO_ALL!"=="1" (
  echo Target: ALL language packs
) else (
  echo Target locale: !WANT_LOCALE!
  if not "!WANT_VOICE!"=="" echo Target voice: !WANT_VOICE!
  echo Target kind: !WANT_KIND!
)
echo.

call :require_admin || goto :fail
call :check_resources || goto :fail
call :select_packs || goto :fail

echo [1/3] Initial Check...
call :detect_runtime
call :print_item "Speech Runtime" "!RUNTIME_OK!" "!RUNTIME_PRODUCT_OK!"
call :print_selected_state

echo.
echo [2/3] Repair...
call :ensure_msi "%RUNTIME_MSI%" "Microsoft Speech Platform Runtime x86" "runtime" "%RUNTIME_PRODUCT%" "!RUNTIME_OK!" || goto :fail

for /L %%I in (1,1,!SEL_N!) do (
  call :ensure_cached "!SEL_FILE_%%I!" || goto :fail
  set "SEL_MSI_%%I=!CACHE_PATH!"
  call :read_product_code "!SEL_MSI_%%I!" "SEL_CODE_%%I"
  call :ensure_msi "!SEL_MSI_%%I!" "!SEL_NAME_%%I!" "!SEL_TAG_%%I!" "!SEL_CODE_%%I!" "!SEL_OK_%%I!" || goto :fail
)

if "!NEED_UNIFIER!"=="1" (
  set "ANY_SAPI_MISSING=0"
  for /L %%I in (1,1,!SEL_N!) do (
    if /I "!SEL_KIND_%%I!"=="tts" if not "!SEL_SAPI_%%I!"=="1" set "ANY_SAPI_MISSING=1"
  )
  if "!ANY_SAPI_MISSING!"=="1" (
    call :run_unifier "%UNIFIER_EXE%" || goto :fail
  ) else (
    echo - SAPI Unifier mapping already present for selected TTS. Skip.
  )
) else (
  echo - SR-only repair. SAPI Unifier skipped.
)

echo.
echo [3/3] Verify...
call :detect_runtime
call :print_item "Speech Runtime" "!RUNTIME_OK!" "!RUNTIME_PRODUCT_OK!"
if not "!RUNTIME_OK!"=="1" set "VERIFY_FAIL=1"
call :print_selected_state
for /L %%I in (1,1,!SEL_N!) do (
  if not "!SEL_OK_%%I!"=="1" set "VERIFY_FAIL=1"
  if /I "!SEL_KIND_%%I!"=="tts" if not "!SEL_SAPI_%%I!"=="1" set "VERIFY_FAIL=1"
)

if "!VERIFY_FAIL!"=="0" (
  echo.
  echo [SUCCESS] Win7 TTS repair completed.
  echo You can now test TTS output in your target application.
  exit /b 0
)

echo.
echo [ERROR] Repair finished but verification failed.
echo Please review the logs above and run this script again as Administrator.
exit /b 1

:parse_args
if "%~1"=="" exit /b 0
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-?" goto :usage
if /I "%~1"=="/help" goto :usage
if /I "%~1"=="-help" goto :usage
if /I "%~1"=="/list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="-list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="/all" set "DO_ALL=1" & set "WANT_KIND=all" & shift & goto :parse_args
if /I "%~1"=="-all" set "DO_ALL=1" & set "WANT_KIND=all" & shift & goto :parse_args
if /I "%~1"=="list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="all" (
  if "!WANT_LOCALE!"=="" (
    set "DO_ALL=1"
  ) else (
    set "WANT_KIND=all"
  )
  shift
  goto :parse_args
)
if /I "%~1"=="tts" set "WANT_KIND=tts" & shift & goto :parse_args
if /I "%~1"=="sr" set "WANT_KIND=sr" & shift & goto :parse_args
if "!WANT_LOCALE!"=="" (
  set "WANT_LOCALE=%~1"
  shift
  goto :parse_args
)
if "!WANT_VOICE!"=="" (
  set "WANT_VOICE=%~1"
  shift
  goto :parse_args
)
echo [ERROR] Unknown argument: %~1
goto :usage

:usage
echo Usage:
echo   tts-repair.bat
echo   tts-repair.bat /list
echo   tts-repair.bat /all
echo   tts-repair.bat zh-CN
echo   tts-repair.bat zh-CN HuiHui
echo   tts-repair.bat en-US
echo   tts-repair.bat en-US ZiraPro
echo   tts-repair.bat ja-JP sr
echo   tts-repair.bat ja-JP all
echo.
echo Default without arguments: zh-CN TTS.
echo Kind: tts  sr  all
echo Language MSIs are downloaded from the langpacks repo and cached in Languages\.
call :list_packs
exit /b 1

:list_packs
echo Available packs. [local] = cached or present in langpacks.
echo Missing MSIs are downloaded from the langpacks repo into Languages\ and kept as cache.
echo.
echo TTS:
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "FN=%%~nL"
  if /I "!FN:~0,13!"=="MSSpeech_TTS_" (
    set "REST=!FN:MSSpeech_TTS_=!"
    set "MARK="
    if exist "%LANG_DIR%\%%L" set "MARK= [local]"
    if not defined MARK if exist "%LANGPACKS_DIR%\%%L" set "MARK= [local]"
    for /f "tokens=1* delims=_" %%A in ("!REST!") do echo   %%A  %%B!MARK!
  )
)
echo.
echo SR:
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "FN=%%~nL"
  if /I "!FN:~0,12!"=="MSSpeech_SR_" (
    set "REST=!FN:MSSpeech_SR_=!"
    set "MARK="
    if exist "%LANG_DIR%\%%L" set "MARK= [local]"
    if not defined MARK if exist "%LANGPACKS_DIR%\%%L" set "MARK= [local]"
    for /f "tokens=1* delims=_" %%A in ("!REST!") do echo   %%A  %%B!MARK!
  )
)
exit /b 0

:select_packs
if not exist "%LANG_DIR%" mkdir "%LANG_DIR%" >nul 2>&1
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "ITEM=%%L"
  if /I not "!WANT_KIND!"=="sr" if /I "!ITEM:~0,13!"=="MSSpeech_TTS_" call :maybe_add_tts "%%L"
  if /I not "!WANT_KIND!"=="tts" if /I "!ITEM:~0,12!"=="MSSpeech_SR_" call :maybe_add_sr "%%L"
)
if "!SEL_N!"=="0" (
  echo [ERROR] No matching language pack found.
  echo Use /list to see available locales and voices.
  exit /b 1
)
echo [OK] Selected !SEL_N! language pack(s).
exit /b 0

:maybe_add_tts
set "FN=%~n1"
set "REST=!FN:MSSpeech_TTS_=!"
for /f "tokens=1* delims=_" %%A in ("!REST!") do (
  set "LOC=%%A"
  set "VOICE=%%B"
)
if "!DO_ALL!"=="0" if /I not "!LOC!"=="!WANT_LOCALE!" exit /b 0
if not "!WANT_VOICE!"=="" if /I not "!VOICE!"=="!WANT_VOICE!" exit /b 0
set /a SEL_N+=1
set "TOK=TTS_MS_!LOC!_!VOICE!_11.0"
set "SEL_FILE_!SEL_N!=%~nx1"
set "SEL_KIND_!SEL_N!=tts"
set "SEL_NAME_!SEL_N!=!FN!"
set "SEL_TAG_!SEL_N!=tts-!LOC!-!VOICE!"
set "SEL_TOKEN_!SEL_N!=!TOK!"
set "NEED_UNIFIER=1"
call :detect_tts_token "!TOK!" "SEL_OK_!SEL_N!" "SEL_SAPI_!SEL_N!" "SEL_PRODUCT_OK_!SEL_N!" ""
exit /b 0

:maybe_add_sr
set "FN=%~n1"
set "REST=!FN:MSSpeech_SR_=!"
for /f "tokens=1* delims=_" %%A in ("!REST!") do (
  set "LOC=%%A"
  set "VOICE=%%B"
)
if "!DO_ALL!"=="0" if /I not "!LOC!"=="!WANT_LOCALE!" exit /b 0
set /a SEL_N+=1
set "TOK=SR_MS_!LOC!_!VOICE!_11.0"
set "SEL_FILE_!SEL_N!=%~nx1"
set "SEL_KIND_!SEL_N!=sr"
set "SEL_NAME_!SEL_N!=!FN!"
set "SEL_TAG_!SEL_N!=sr-!LOC!-!VOICE!"
set "SEL_TOKEN_!SEL_N!=!TOK!"
set "SEL_SAPI_!SEL_N!=1"
call :detect_sr_token "!TOK!" "SEL_OK_!SEL_N!" "SEL_PRODUCT_OK_!SEL_N!" ""
exit /b 0

:ensure_cached
set "CACHE_NAME=%~1"
set "CACHE_PATH="
call :local_msi "%CACHE_NAME%"
if defined CACHE_PATH (
  echo - local: %CACHE_NAME%
  exit /b 0
)
echo [DOWNLOAD] %CACHE_NAME%
echo   %LANGPACKS_URL%/%CACHE_NAME%
if not exist "%LANG_DIR%" mkdir "%LANG_DIR%" >nul 2>&1
set "DL_DEST=%LANG_DIR%\%CACHE_NAME%"
set "DL_URL=%LANGPACKS_URL%/%CACHE_NAME%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) } catch {} ; $d = $env:DL_DEST; $u = $env:DL_URL; $t = $d + '.partial'; $w = New-Object System.Net.WebClient; $w.Headers.Add('User-Agent','tts-repair'); if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }; $w.DownloadFile($u, $t); if (-not (Test-Path -LiteralPath $t) -or ((Get-Item -LiteralPath $t).Length -le 0)) { throw 'empty download' }; if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Force }; Move-Item -LiteralPath $t -Destination $d }"
if not exist "%DL_DEST%" (
  echo [ERROR] Missing language MSI: "%CACHE_NAME%"
  echo [ERROR] Download from langpacks repo failed.
  echo [ERROR] %LANGPACKS_URL%/%CACHE_NAME%
  exit /b 1
)
set "CACHE_PATH=%DL_DEST%"
exit /b 0

:local_msi
set "CACHE_PATH="
if exist "%LANG_DIR%\%~1" (
  for %%I in ("%LANG_DIR%\%~1") do if not "%%~zI"=="0" set "CACHE_PATH=%LANG_DIR%\%~1"
)
if defined CACHE_PATH exit /b 0
if exist "%LANGPACKS_DIR%\%~1" (
  for %%I in ("%LANGPACKS_DIR%\%~1") do if not "%%~zI"=="0" set "CACHE_PATH=%LANGPACKS_DIR%\%~1"
)
exit /b 0

:read_product_code
set "%~2="
if not exist "%MSI_CODE_VBS%" exit /b 0
for /f "usebackq delims=" %%C in (`cscript //nologo "%MSI_CODE_VBS%" "%~1"`) do set "%~2=%%C"
exit /b 0

:detect_runtime
set "RUNTIME_OK=0"
set "RUNTIME_PRODUCT_OK=0"
call :query_product "%RUNTIME_PRODUCT%" RUNTIME_PRODUCT_OK
if exist "%SPEECH_DIR%\Microsoft.Speech.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR%\SR\v11.0\spsreng.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR_X86%\Microsoft.Speech.dll" set "RUNTIME_OK=1"
if "!RUNTIME_OK!"=="0" if exist "%SPEECH_DIR_X86%\SR\v11.0\spsreng.dll" set "RUNTIME_OK=1"
exit /b 0

:detect_tts_token
set "TOKEN=%~1"
set "OKVAR=%~2"
set "SAPIVAR=%~3"
set "PRODVAR=%~4"
set "CODE=%~5"
set "%OKVAR%=0"
set "%SAPIVAR%=0"
set "%PRODVAR%=0"
call :query_product "%CODE%" %PRODVAR%
reg query "HKLM\SOFTWARE\Microsoft\Speech Server\v11.0\Voices\Tokens\%TOKEN%" >nul 2>&1 && set "%OKVAR%=1"
if "!%OKVAR%!"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Speech Server\v11.0\Voices\Tokens\%TOKEN%" >nul 2>&1 && set "%OKVAR%=1"
if "!%OKVAR%!"=="0" if exist "%SPEECH_DIR%\Tokens\%TOKEN%\" set "%OKVAR%=1"
if "!%OKVAR%!"=="0" if exist "%SPEECH_DIR_X86%\Tokens\%TOKEN%\" set "%OKVAR%=1"
reg query "HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\%TOKEN%" >nul 2>&1 && set "%SAPIVAR%=1"
if "!%SAPIVAR%!"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Speech\Voices\Tokens\%TOKEN%" >nul 2>&1 && set "%SAPIVAR%=1"
if "!%SAPIVAR%!"=="0" reg query "HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\%TOKEN%" /reg:32 >nul 2>&1 && set "%SAPIVAR%=1"
if "!%SAPIVAR%!"=="0" reg query "HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\%TOKEN%" /reg:64 >nul 2>&1 && set "%SAPIVAR%=1"
exit /b 0

:detect_sr_token
set "TOKEN=%~1"
set "OKVAR=%~2"
set "PRODVAR=%~3"
set "CODE=%~4"
set "%OKVAR%=0"
set "%PRODVAR%=0"
call :query_product "%CODE%" %PRODVAR%
reg query "HKLM\SOFTWARE\Microsoft\Speech Server\v11.0\Recognizers\Tokens\%TOKEN%" >nul 2>&1 && set "%OKVAR%=1"
if "!%OKVAR%!"=="0" reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Speech Server\v11.0\Recognizers\Tokens\%TOKEN%" >nul 2>&1 && set "%OKVAR%=1"
exit /b 0

:print_selected_state
for /L %%I in (1,1,!SEL_N!) do (
  call :detect_one %%I
  if /I "!SEL_KIND_%%I!"=="tts" (
    call :print_item "!SEL_NAME_%%I!" "!SEL_OK_%%I!" "!SEL_PRODUCT_OK_%%I!"
    call :print_item "SAPI mapping !SEL_TOKEN_%%I!" "!SEL_SAPI_%%I!" ""
  ) else (
    call :print_item "!SEL_NAME_%%I!" "!SEL_OK_%%I!" "!SEL_PRODUCT_OK_%%I!"
  )
)
exit /b 0

:detect_one
set "I=%~1"
if /I "!SEL_KIND_%I%!"=="tts" (
  call :detect_tts_token "!SEL_TOKEN_%I%!" "SEL_OK_%I%" "SEL_SAPI_%I%" "SEL_PRODUCT_OK_%I%" "!SEL_CODE_%I%!"
) else (
  call :detect_sr_token "!SEL_TOKEN_%I%!" "SEL_OK_%I%" "SEL_PRODUCT_OK_%I%" "!SEL_CODE_%I%!"
  set "SEL_SAPI_%I%=1"
)
exit /b 0

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
if not exist "%UNIFIER_EXE%" (
  echo [ERROR] Missing file: "%UNIFIER_EXE%"
  exit /b 1
)
if not exist "%LANG_DIR%" mkdir "%LANG_DIR%" >nul 2>&1
echo [OK] Required resource files are present.
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
start "" wscript //nologo "%CLOSE_UNIFIER_VBS%"
start "" /wait "%~1"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" if not "%RC%"=="1" echo [WARN] SAPI Unifier exit code: %RC%
echo [OK] SAPI Unifier finished.
exit /b 0

:query_product
set "%~2=0"
if "%~1"=="" exit /b 0
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

rem Microsoft Speech Platform Runtime Languages 11
rem https://github.com/wpstangzhiwei/tts-repair-win7-langpacks
rem @pack MSSpeech_SR_ca-ES_TELE.msi
rem @pack MSSpeech_SR_da-DK_TELE.msi
rem @pack MSSpeech_SR_de-DE_TELE.msi
rem @pack MSSpeech_SR_en-AU_TELE.msi
rem @pack MSSpeech_SR_en-CA_TELE.msi
rem @pack MSSpeech_SR_en-GB_TELE.msi
rem @pack MSSpeech_SR_en-IN_TELE.msi
rem @pack MSSpeech_SR_en-US_TELE.msi
rem @pack MSSpeech_SR_es-ES_TELE.msi
rem @pack MSSpeech_SR_es-MX_TELE.msi
rem @pack MSSpeech_SR_fi-FI_TELE.msi
rem @pack MSSpeech_SR_fr-CA_TELE.msi
rem @pack MSSpeech_SR_fr-FR_TELE.msi
rem @pack MSSpeech_SR_it-IT_TELE.msi
rem @pack MSSpeech_SR_ja-JP_TELE.msi
rem @pack MSSpeech_SR_ko-KR_TELE.msi
rem @pack MSSpeech_SR_nb-NO_TELE.msi
rem @pack MSSpeech_SR_nl-NL_TELE.msi
rem @pack MSSpeech_SR_pl-PL_TELE.msi
rem @pack MSSpeech_SR_pt-BR_TELE.msi
rem @pack MSSpeech_SR_pt-PT_TELE.msi
rem @pack MSSpeech_SR_ru-RU_TELE.msi
rem @pack MSSpeech_SR_sv-SE_TELE.msi
rem @pack MSSpeech_SR_zh-CN_TELE.msi
rem @pack MSSpeech_SR_zh-HK_TELE.msi
rem @pack MSSpeech_SR_zh-TW_TELE.msi
rem @pack MSSpeech_TTS_ca-ES_Herena.msi
rem @pack MSSpeech_TTS_da-DK_Helle.msi
rem @pack MSSpeech_TTS_de-DE_Hedda.msi
rem @pack MSSpeech_TTS_en-AU_Hayley.msi
rem @pack MSSpeech_TTS_en-CA_Heather.msi
rem @pack MSSpeech_TTS_en-GB_Hazel.msi
rem @pack MSSpeech_TTS_en-IN_Heera.msi
rem @pack MSSpeech_TTS_en-US_Helen.msi
rem @pack MSSpeech_TTS_en-US_ZiraPro.msi
rem @pack MSSpeech_TTS_es-ES_Helena.msi
rem @pack MSSpeech_TTS_es-MX_Hilda.msi
rem @pack MSSpeech_TTS_fi-FI_Heidi.msi
rem @pack MSSpeech_TTS_fr-CA_Harmonie.msi
rem @pack MSSpeech_TTS_fr-FR_Hortense.msi
rem @pack MSSpeech_TTS_it-IT_Lucia.msi
rem @pack MSSpeech_TTS_ja-JP_Haruka.msi
rem @pack MSSpeech_TTS_ko-KR_Heami.msi
rem @pack MSSpeech_TTS_nb-NO_Hulda.msi
rem @pack MSSpeech_TTS_nl-NL_Hanna.msi
rem @pack MSSpeech_TTS_pl-PL_Paulina.msi
rem @pack MSSpeech_TTS_pt-BR_Heloisa.msi
rem @pack MSSpeech_TTS_pt-PT_Helia.msi
rem @pack MSSpeech_TTS_pt-PT_Helia16k.msi
rem @pack MSSpeech_TTS_ru-RU_Elena.msi
rem @pack MSSpeech_TTS_sv-SE_Hedvig.msi
rem @pack MSSpeech_TTS_zh-CN_HuiHui.msi
rem @pack MSSpeech_TTS_zh-HK_HunYee.msi
rem @pack MSSpeech_TTS_zh-TW_HanHan.msi
