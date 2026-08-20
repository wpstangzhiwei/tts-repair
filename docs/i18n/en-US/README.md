# TTS Repair Project

## Project Goal

Build a cross-platform text-to-speech (TTS) repair toolkit. All text documents are maintained in language-specific directories (at least Chinese and English).

## Current Progress

1. Windows first.  
2. **The Windows 7 repair script is available.** Default locale is zh-CN HuiHui. `tts-repair.bat` fetches language packs on demand from [tts-repair-win7-langpacks](https://github.com/wpstangzhiwei/tts-repair-win7-langpacks.git) and keeps a local cache.  
3. The Windows 10 / 11+ shared baseline directory exists; scripts are not implemented yet.  
4. Other platforms will follow later.  

## Directory Layout

```text
LICENSE
README.md
docs/i18n/
  zh-CN/
  en-US/
platforms/windows/
  README.md
  win7/
    tts-repair.bat
    resources/
  win10-plus/
    scripts/
    docs/
    samples/
```

## Quick Start (Windows 7)

1. Run `platforms/windows/win7/tts-repair.bat` as Administrator.  
2. The script checks, repairs, then verifies Microsoft Speech Platform Runtime, the HuiHui voice pack, and SAPI mapping.  
3. .NET Framework 4 is required (SAPI Unifier depends on it).  
4. Details: [Windows 7](platforms/windows/win7/README.md).  

## License

This project is licensed under [GPL-3.0-only](../../../LICENSE).  
If you use, reference, and distribute a derived work, you must publish the corresponding source code under GPLv3.

## Multilingual Rule

- Keep document bodies under `docs/i18n/<locale>/`.  
- `README.md` files in code directories are language entry pages with clickable links.  
