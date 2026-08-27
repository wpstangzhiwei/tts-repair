@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title Win7 TTS Repair

set "SCRIPT_DIR=%~dp0"
set "RES_DIR=%SCRIPT_DIR%resources"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LANG_DIR=%RES_DIR%\Microsoft Speech Platform\Languages"
set "CLOSE_UNIFIER_VBS=%SCRIPT_DIR%scripts\auto-close-sapi-unifier.vbs"
set "DOWNLOAD_PS1=%SCRIPT_DIR%scripts\download-msi.ps1"
set "MSI_CODE_VBS=%SCRIPT_DIR%scripts\msi-productcode.vbs"
set "RUNTIME_MSI=%LANG_DIR%\SpeechPlatformRuntime(x86).msi"
set "UNIFIER_EXE=%RES_DIR%\SAPI_Unifier\SAPI_Unifier_requires_dot_NET_4.exe"
set "RUNTIME_PRODUCT={22CB8ED7-DF57-4864-BD04-F63B9CE4B494}"

set "SPEECH_DIR=%CommonProgramFiles%\Microsoft Shared\Speech"
set "SPEECH_DIR_X86=%CommonProgramFiles(x86)%\Microsoft Shared\Speech"

set "WANT_LOCALE="
set "WANT_VOICE="
set "WANT_KIND=tts"
set "DO_LIST=0"
set "DO_MENU=0"
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
if "!DO_MENU!"=="1" (
  call :pick_locale
  if errorlevel 1 exit /b 1
)

if "!DO_ALL!"=="0" if "!WANT_LOCALE!"=="" set "WANT_LOCALE=zh-CN"

echo ============================================================
echo Win7 TTS Repair - Check ^> Repair ^> Verify
echo ============================================================
echo Script Path: %SCRIPT_DIR%
echo Resource Path: %RES_DIR%
echo Help: tts-repair.bat /help    Menu: tts-repair.bat /menu
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
if /I "%~1"=="/menu" set "DO_MENU=1" & shift & goto :parse_args
if /I "%~1"=="-menu" set "DO_MENU=1" & shift & goto :parse_args
if /I "%~1"=="/all" set "DO_ALL=1" & set "WANT_KIND=all" & shift & goto :parse_args
if /I "%~1"=="-all" set "DO_ALL=1" & set "WANT_KIND=all" & shift & goto :parse_args
if /I "%~1"=="/lang" goto :parse_lang
if /I "%~1"=="-lang" goto :parse_lang
if /I "%~1"=="list" set "DO_LIST=1" & shift & goto :parse_args
if /I "%~1"=="menu" (
  if "!WANT_LOCALE!"=="" (
    set "DO_MENU=1"
    shift
    goto :parse_args
  )
)
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

:parse_lang
shift
if "%~1"=="" goto :usage
set "WANT_LOCALE=%~1"
shift
goto :parse_args

:usage
echo Usage:
echo   tts-repair.bat /help
echo   tts-repair.bat /list
echo   tts-repair.bat /menu
echo   tts-repair.bat
echo   tts-repair.bat /lang zh-CN
echo   tts-repair.bat zh-CN
echo   tts-repair.bat zh-CN HuiHui
echo   tts-repair.bat en-US
echo   tts-repair.bat en-US ZiraPro
echo   tts-repair.bat /all
echo.
echo Choose a language:
echo   /help            Show this help and the pack list
echo   /list            List locales and voices
echo   /menu            Interactive picker: number or locale
echo   /lang locale     Install TTS for that locale
echo   locale           Install all TTS voices for that locale
echo   locale Voice     Install one TTS voice
echo   /all             Install every pack in the catalog
echo.
echo Default without arguments: zh-CN HuiHui from the bundled local MSI.
echo Kind: tts
echo Other language MSIs: local Languages\ cache, then Langpacks\, then download.
call :list_packs
exit /b 1

:list_packs
echo Available packs. [local] = bundled, cached, or present in Langpacks.
echo [default] = shipped with this repo, no download required.
echo Other missing MSIs are downloaded into Languages\ and kept as cache.
echo.
echo TTS:
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "FN=%%~nL"
  if /I "!FN:~0,13!"=="MSSpeech_TTS_" (
    set "REST=!FN:MSSpeech_TTS_=!"
    set "MARK="
    if exist "%LANG_DIR%\%%L" set "MARK= [local]"
    if /I "%%L"=="MSSpeech_TTS_zh-CN_HuiHui.msi" set "MARK=!MARK! [default]"
    for /f "tokens=1* delims=_" %%A in ("!REST!") do echo   %%A  %%B!MARK!
  )
)
exit /b 0

:pick_locale
set "MENU_N=0"
echo.
echo ------------------------------------------------------------
echo Choose a language
echo ------------------------------------------------------------
echo.
echo TTS packs:
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "FN=%%~nL"
  if /I "!FN:~0,13!"=="MSSpeech_TTS_" (
    set "REST=!FN:MSSpeech_TTS_=!"
    set /a MENU_N+=1
    set "MARK="
    if exist "%LANG_DIR%\%%L" set "MARK= [local]"
    if /I "%%L"=="MSSpeech_TTS_zh-CN_HuiHui.msi" set "MARK=!MARK! [default]"
    for /f "tokens=1* delims=_" %%A in ("!REST!") do (
      echo   !MENU_N!^) %%A  %%B!MARK!
      set "MENU_LOC_!MENU_N!=%%A"
      set "MENU_VOICE_!MENU_N!=%%B"
    )
  )
)
echo.
echo Enter a number, or: locale [voice] [tts^|all]
echo Empty = zh-CN HuiHui [default, bundled].
set /p "MENU_IN=Select: "
if "!MENU_IN!"=="" (
  set "WANT_LOCALE=zh-CN"
  set "WANT_VOICE=HuiHui"
  set "WANT_KIND=tts"
  exit /b 0
)
if /I "!MENU_IN!"=="/help" goto :usage
if /I "!MENU_IN!"=="/list" goto :usage
echo(!MENU_IN!| findstr /r "^[1-9][0-9]*$" >nul
if not errorlevel 1 (
  call set "PICK_LOC=%%MENU_LOC_!MENU_IN!%%"
  call set "PICK_VOICE=%%MENU_VOICE_!MENU_IN!%%"
  if "!PICK_LOC!"=="" (
    echo [ERROR] Invalid menu number: !MENU_IN!
    exit /b 1
  )
  set "WANT_LOCALE=!PICK_LOC!"
  set "WANT_VOICE=!PICK_VOICE!"
  set "WANT_KIND=tts"
  exit /b 0
)
set "P1="
set "P2="
set "P3="
for /f "tokens=1,2,3" %%A in ("!MENU_IN!") do (
  set "P1=%%A"
  set "P2=%%B"
  set "P3=%%C"
)
if /I "!P1!"=="all" (
  set "DO_ALL=1"
  set "WANT_KIND=all"
  exit /b 0
)
set "WANT_LOCALE=!P1!"
if /I "!P2!"=="tts" (
  set "WANT_KIND=tts"
  set "P2="
)
if /I "!P2!"=="all" (
  set "WANT_KIND=all"
  set "P2="
)
if not "!P2!"=="" set "WANT_VOICE=!P2!"
if /I "!P3!"=="tts" set "WANT_KIND=tts"
if /I "!P3!"=="all" set "WANT_KIND=all"
exit /b 0

:select_packs
if not exist "%LANG_DIR%" mkdir "%LANG_DIR%" >nul 2>&1
for /f "tokens=3" %%L in ('findstr /b /c:"rem @pack " "%~f0"') do (
  set "ITEM=%%L"
  if /I "!ITEM:~0,13!"=="MSSpeech_TTS_" call :maybe_add_tts "%%L"
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

:ensure_cached
set "CACHE_NAME=%~1"
set "CACHE_PATH="
call :local_msi "%CACHE_NAME%"
if defined CACHE_PATH (
  echo - local: %CACHE_NAME%
  exit /b 0
)
echo [DOWNLOAD] %CACHE_NAME%
if not exist "%LANG_DIR%" mkdir "%LANG_DIR%" >nul 2>&1
set "DL_DEST=%LANG_DIR%\%CACHE_NAME%"
set "DL_NAME=%CACHE_NAME%"
if exist "%DOWNLOAD_PS1%" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%"
) else (
  echo [ERROR] Missing downloader: "%DOWNLOAD_PS1%"
)
if not exist "%DL_DEST%" (
  echo.
  echo [ERROR] Automatic download failed: "%CACHE_NAME%"
  echo.
  echo Please download the file manually in a browser, then run this script again.
  echo.
  if "%CACHE_NAME%"=="SpeechPlatformRuntime(x86).msi" (
    echo   Download URL:
    echo     https://download.microsoft.com/download/A/6/4/A64012D6-D56F-4E58-85E3-531E56ABC0E6/x86_SpeechPlatformRuntime/SpeechPlatformRuntime.msi
  ) else (
    echo   The language packs are archived at:
    echo     https://legacyupdate.net/download-center/download/27224/microsoft-speech-platform-runtime-languages-version-11
    echo.
    echo   Find "%CACHE_NAME%" in the list and download it.
  )
  echo.
  echo   Save it as this exact file name:
  echo      %CACHE_NAME%
  echo.
  echo   Put it in this folder:
  echo      %LANG_DIR%
  echo.
  if exist "%LANG_DIR%" start "" explorer "%LANG_DIR%"
  echo The target folder has been opened. Copy the MSI there, then rerun tts-repair.bat.
  echo.
  pause
  exit /b 1
)
set "CACHE_PATH=%DL_DEST%"
exit /b 0

:local_msi
set "CACHE_PATH="
if exist "%LANG_DIR%\%~1" (
  for %%I in ("%LANG_DIR%\%~1") do if not "%%~zI"=="0" set "CACHE_PATH=%LANG_DIR%\%~1"
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

:print_selected_state
for /L %%I in (1,1,!SEL_N!) do (
  call :detect_one %%I
  call :print_item "!SEL_NAME_%%I!" "!SEL_OK_%%I!" "!SEL_PRODUCT_OK_%%I!"
  call :print_item "SAPI mapping !SEL_TOKEN_%%I!" "!SEL_SAPI_%%I!" ""
)
exit /b 0

:detect_one
set "I=%~1"
call :detect_tts_token "!SEL_TOKEN_%I%!" "SEL_OK_%I%" "SEL_SAPI_%I%" "SEL_PRODUCT_OK_%I%" "!SEL_CODE_%I%!"
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

if not exist "%MSI_PATH%" (
  echo [DOWNLOAD] %MSI_NAME%
  set "DL_DEST=%MSI_PATH%"
  set "DL_NAME=%~nx1"
  if exist "%DOWNLOAD_PS1%" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%"
  ) else (
    echo [ERROR] Missing downloader: "%DOWNLOAD_PS1%"
    exit /b 1
  )
  if not exist "%MSI_PATH%" (
    echo [ERROR] Download failed: %MSI_NAME%
    echo Please download manually and place in: "%LANG_DIR%"
    exit /b 1
  )
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
rem https://legacyupdate.net/download-center/download/27224/microsoft-speech-platform-runtime-languages-version-11
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
