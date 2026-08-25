# TTS Repair

Cross-platform text-to-speech (TTS) repair toolkit. Documentation in [English](docs/i18n/en-US/README.md) | [简体中文](docs/i18n/zh-CN/README.md).

[GPL-3.0-only](LICENSE)

## Status

| Platform | Implementation |
|---|---|
| **Windows 7** | `platforms/windows/win7/tts-repair.bat` — complete |
| **Windows 10** | `platforms/windows/win10/tts-repair.bat` — complete |
| **Windows 11** | `platforms/windows/win11/tts-repair.bat` — complete |
| Linux / macOS | Planned |

## Quick Start (Windows 7)

```bat
# Run as Administrator
platforms\windows\win7\tts-repair.bat
```

- Default: installs **zh-CN HuiHui** TTS (MSI bundled, no download)
- Use `/help`, `/menu`, or `locale [voice]` to select other languages
- Missing packs auto-download from [tts-repair-win7-langpacks](https://github.com/wpstangzhiwei/tts-repair-win7-langpacks.git) and cache locally

## What the Win7 Script Repairs

1. **Microsoft Speech Platform Runtime** (`SpeechPlatformRuntime(x86).msi`)
2. **Language packs** (TTS and/or SR) — resolves from local cache → submodule → download
3. **SAPI mapping** — runs `SAPI_Unifier_requires_dot_NET_4.exe` (requires .NET Framework 4, **not** VC++ redist)

## Quick Start (Windows 10 / 11)

```bat
# Run as Administrator
platforms\windows\win10\tts-repair.bat
platforms\windows\win11\tts-repair.bat
```

- Default: repairs the **zh-CN** TTS voice (`Language.TextToSpeech~~~zh-CN~0.0.1.0`)
- Use `/help`, `/menu`, or `locale` to select another language (49 locales supported)
- Checks the DISM capability state first; missing voices are repaired fully offline:
  the matching cab is fetched from local `cache\` or auto-downloaded from
  [uupdump.net](https://uupdump.net) for the detected OS build (SHA1 verified), then
  installed via `Add-WindowsCapability -LimitAccess`
- Details: [Windows 10](docs/i18n/en-US/platforms/windows/win10/README.md) /
  [Windows 11](docs/i18n/en-US/platforms/windows/win11/README.md)

## Technical Details

- **Silent MSI installs** (Win7) — `/quiet /norestart`
- **Detection by payload files**, not Uninstall registry leftovers
- **Admin required** for MSI installation / DISM capability install
- **Architecture support**: amd64 (64-bit), x86 (32-bit), arm64 (ARM64)
- **Logs**: Win7 → `platforms/windows/win7/logs/`; Win10/11 → `logs\` per platform dir

## Directory Layout

```
tts-repair/
├── LICENSE
├── README.md
├── docs/i18n/
│   ├── en-US/
│   └── zh-CN/
└── platforms/windows/
    ├── win7/
    │   ├── tts-repair.bat
    │   ├── scripts/
    │   └── resources/
    ├── win10/
    │   ├── tts-repair.bat
    │   └── scripts/
    └── win11/
        ├── tts-repair.bat
        └── scripts/
```
