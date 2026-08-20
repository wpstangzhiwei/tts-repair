# Windows 7 TTS Repair

## Purpose

Repair missing or incomplete TTS resources on Windows 7: Microsoft Speech Platform Runtime, the Chinese HuiHui voice pack, and SAPI mapping.

## How to Run

1. Right-click `platforms/windows/win7/tts-repair.bat` and choose **Run as administrator**.  
2. Flow: check → repair → verify.  
3. Installer logs are written to `platforms/windows/win7/logs/`.  

## Repair Steps

The script handles these in order:

1. Install or repair `resources/Microsoft Speech Platform/SpeechPlatformRuntime(x86).msi`  
2. Install or repair `resources/Microsoft Speech Platform/Languages/MSSpeech_TTS_zh-CN_HuiHui.msi`  
3. If SAPI mapping is missing, run `resources/SAPI_Unifier/SAPI_Unifier_requires_dot_NET_4.exe`  

SAPI Unifier is a GUI app. It requires **.NET Framework 4** and does **not** require `VC_redist.x86.exe`. Mapping finishes before the window appears; the script closes the window automatically, so you do not need to click Exit.

## How Installation Is Detected

Detection uses payload files, not leftover Uninstall entries:

- **Speech Runtime**: `Microsoft.Speech.dll` or `SR\v11.0\spsreng.dll` under `Common Files\Microsoft Shared\Speech` (or the x86 equivalent).  
- **HuiHui voice pack**: `HuiHuiT.INI` (preferred path `Tokens\TTS_MS_ZH-CN_HUIHUI_11.0\`).  
- **SAPI mapping**: registry key  
  `HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0`  
  (including Wow6432Node).  

If files are missing but the MSI ProductCode is still registered, the script repairs instead of skipping.

ProductCodes:

- Runtime: `{22CB8ED7-DF57-4864-BD04-F63B9CE4B494}`  
- HuiHui: `{44B3785F-9F8B-46A9-AD46-21B7AC49D086}`  

## Resource Layout

```text
win7/
  tts-repair.bat
  resources/
    Microsoft Speech Platform/
      SpeechPlatformRuntime(x86).msi
      Languages/MSSpeech_TTS_zh-CN_HuiHui.msi
    SAPI_Unifier/
      SAPI_Unifier_requires_dot_NET_4.exe
```

## Notes

- Administrator rights are required.  
- MSI installs run silently. On `1603`, ProductCode is checked again so leftover registration is not treated as a complete install by itself.  
- The script does not install the VC++ redistributable.  
