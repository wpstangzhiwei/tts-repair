# Windows 7 TTS Repair

## Purpose

Repair missing or incomplete TTS resources on Windows 7: Microsoft Speech Platform Runtime, selected language packs, and SAPI mapping.

## How to Run

Run `platforms/windows/win7/tts-repair.bat` as Administrator, with an optional language:

```bat
tts-repair.bat
tts-repair.bat /list
tts-repair.bat /all
tts-repair.bat zh-CN
tts-repair.bat zh-CN HuiHui
tts-repair.bat en-US
tts-repair.bat en-US ZiraPro
tts-repair.bat ja-JP sr
tts-repair.bat ja-JP all
```

- No arguments: install `zh-CN` TTS.  
- `/list`: list TTS / SR packs in `Languages`.  
- `locale`: install all TTS voices for that locale (for example `en-US` installs Helen and ZiraPro).  
- `locale VoiceName`: install one TTS voice.  
- `locale sr`: install the recognizer pack only.  
- `locale all`: TTS + SR.  
- `/all`: install every pack in the folder.  

Installer logs are written to `platforms/windows/win7/logs/`.

## Repair Steps

The script handles these in order:

1. Install or repair `resources/Microsoft Speech Platform/SpeechPlatformRuntime(x86).msi`  
2. Install or repair the selected `resources/Microsoft Speech Platform/Languages/MSSpeech_*.msi` files  
3. If SAPI mapping is missing for a selected TTS voice, run `resources/SAPI_Unifier/SAPI_Unifier_requires_dot_NET_4.exe`  

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
  resources/
    Microsoft Speech Platform/
      SpeechPlatformRuntime(x86).msi
      Languages/MSSpeech_TTS_*.msi
      Languages/MSSpeech_SR_*.msi
    SAPI_Unifier/
      SAPI_Unifier_requires_dot_NET_4.exe
```

## Notes

- Administrator rights are required.  
- MSI installs run silently. On `1603`, ProductCode is checked again so leftover registration is not treated as a complete install by itself.  
- The script does not install the VC++ redistributable.  
