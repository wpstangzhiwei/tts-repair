# Windows 7 TTS Repair

## Purpose

Repair missing or incomplete TTS resources on Windows 7: Microsoft Speech Platform Runtime, selected language packs, and SAPI mapping.

## How to Run

Run `platforms/windows/win7/tts-repair.bat` as Administrator:

```bat
tts-repair.bat /help
tts-repair.bat /list
tts-repair.bat /menu
tts-repair.bat
tts-repair.bat /lang zh-CN
tts-repair.bat zh-CN
tts-repair.bat zh-CN HuiHui
tts-repair.bat en-US
tts-repair.bat en-US ZiraPro
tts-repair.bat ja-JP sr
tts-repair.bat ja-JP all
tts-repair.bat /all
```

- `/help`: show parameters and the available locale/voice list.  
- `/list`: list TTS / SR packs; `[local]` means the MSI is already on disk; `[default]` is the bundled pack.  
- `/menu`: interactive picker (enter a number, or `locale [voice] [tts|sr|all]`).  
- No arguments: install `zh-CN` TTS (HuiHui). The MSI is auto-downloaded from Microsoft on first run and cached under `Languages/`.  
- `/lang locale` or `locale`: install all TTS voices for that locale (for example `en-US` installs Helen and ZiraPro).  
- `locale VoiceName`: install one TTS voice.  
- `locale sr`: install the recognizer pack only.  
- `locale all`: TTS + SR.  
- `/all`: install every pack in the catalog.  

`MSSpeech_TTS_zh-CN_HuiHui.msi` is downloaded from Microsoft on first run. Other language MSIs are also downloaded from Microsoft. The script resolves them in this order: local `Languages/` cache → download from Microsoft into `Languages/`. All downloaded MSIs are cached locally.

Installer logs are written to `platforms/windows/win7/logs/`.

## Repair Steps

The script handles these in order:

1. Install or repair `resources/Microsoft Speech Platform/SpeechPlatformRuntime(x86).msi` (downloaded from Microsoft)  
2. Resolve the selected language MSI: local `Languages/` cache → download from Microsoft into `Languages/`  
3. Install or repair the selected `MSSpeech_*.msi`  
4. If SAPI mapping is missing for a selected TTS voice, run `resources/SAPI_Unifier/SAPI_Unifier_requires_dot_NET_4.exe`  

SAPI Unifier is a GUI app. It requires **.NET Framework 4** and does **not** require `VC_redist.x86.exe`. Mapping finishes before the window appears; the script closes the window automatically, so you do not need to click Exit.

## How Installation Is Detected

Detection uses payload files, not leftover Uninstall entries:

- **Speech Runtime**: `Microsoft.Speech.dll` or `SR\v11.0\spsreng.dll` under `Common Files\Microsoft Shared\Speech` (or the x86 equivalent).  
- **TTS language pack**: Speech Server voice token, for example `TTS_MS_zh-CN_HuiHui_11.0`, or the `Tokens\<token>\` folder.  
- **SR language pack**: `Recognizers\Tokens\SR_MS_<locale>_TELE_11.0`.  
- **SAPI mapping** (TTS only): `HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\<token>`.  

If files are missing but the MSI ProductCode is still registered, the script repairs instead of skipping. ProductCodes are read from each MSI at runtime.

## Resource Layout

```text
win7/
  tts-repair.bat
  scripts/
    auto-close-sapi-unifier.vbs
    msi-productcode.vbs
    download-msi.ps1
  resources/
    Microsoft Speech Platform/
      Languages/
        MSSpeech_TTS_zh-CN_HuiHui.msi   # downloaded cache
        # other MSIs: download cache
    SAPI_Unifier/
      SAPI_Unifier_requires_dot_NET_4.exe
```

## Third-Party Components

This project includes SAPI Unifier (GPL-3.0), developed by Mahmood Taghavi.
Source: https://github.com/Mahmood-Taghavi/SAPI_Unifier
