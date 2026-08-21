# TTS Repair

Cross-platform text-to-speech (TTS) repair toolkit. Documentation in [English](docs/i18n/en-US/README.md) | [简体中文](docs/i18n/zh-CN/README.md).

[GPL-3.0-only](LICENSE)

## Status

| Platform | Implementation |
|---|---|
| **Windows 7** | `platforms/windows/win7/tts-repair.bat` — complete |
| Windows 10 / 11+ | `platforms/windows/win10-plus/` — skeleton only |
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

## Technical Details

- **Silent MSI installs** — `/quiet /norestart`
- **Detection by payload files**, not Uninstall registry leftovers
- **Admin required** for MSI installation
- **Logs** written to `platforms/windows/win7/logs/`

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
    └── win10-plus/
        └── scripts/
```