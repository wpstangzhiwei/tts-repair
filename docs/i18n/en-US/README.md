# TTS Repair Project

## Project Goal

Build a cross-platform text-to-speech (TTS) repair toolkit. All text documents are maintained in language-specific directories under `docs/i18n/<locale>/`.

## Current Progress

1. **Windows first**
2. **Windows 7 repair script is available** — `platforms/windows/win7/tts-repair.bat`  
   Default locale: zh-CN HuiHui (MSI bundled, no download). Use `/help`, `/menu`, or `locale` argument to pick another language. Missing packs are fetched on demand from [tts-repair-win7-langpacks](https://github.com/wpstangzhiwei/tts-repair-win7-langpacks.git) and cached locally.
3. **Windows 10 / 11 repair scripts are available** — `platforms/windows/win10/tts-repair.bat`, `platforms/windows/win11/tts-repair.bat`  
   Default locale: zh-CN. Detects the OS build automatically, downloads the matching
   TextToSpeech capability cab from uupdump.net when not cached, installs it offline via
   `Add-WindowsCapability -LimitAccess`, and verifies the voice afterwards.
4. Other platforms will follow later.

## Directory Layout

```text
LICENSE
README.md
docs/i18n/
  zh-CN/
  en-US/
platforms/windows/
  win7/
    tts-repair.bat
    scripts/
    resources/
  win10/
    tts-repair.bat
    scripts/
  win11/
    tts-repair.bat
    scripts/
```

## Quick Start (Windows 7)

1. Run `platforms/windows/win7/tts-repair.bat` **as Administrator**.
2. The script checks → repairs → verifies: Microsoft Speech Platform Runtime, the selected voice pack(s), and SAPI mapping.
3. Requires **.NET Framework 4** (SAPI Unifier depends on it).
4. Details: [Windows 7](docs/i18n/en-US/platforms/windows/win7/README.md).

## Quick Start (Windows 10 / 11)

1. Run the matching `tts-repair.bat` **as Administrator**.
2. Default repairs the zh-CN TTS voice; use `/help`, `/menu`, or pass a locale to choose another.
3. Details: [Windows 10](docs/i18n/en-US/platforms/windows/win10/README.md) /
   [Windows 11](docs/i18n/en-US/platforms/windows/win11/README.md).

## License

[GPL-3.0-only](../LICENSE). If you use, reference, and distribute a derived work, you must publish the corresponding source code under GPLv3.

## Multilingual Rule

- Document bodies live under `docs/i18n/<locale>/`.
- Code directories contain no README — link directly to `docs/i18n/`.