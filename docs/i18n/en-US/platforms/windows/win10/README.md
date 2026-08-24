# Windows 10 TTS Repair

## Purpose

Repair a missing Windows 10 text-to-speech (TTS) voice. Windows ships TTS voices as
`Language.TextToSpeech` capabilities (`Language.TextToSpeech~~~<locale>~0.0.1.0`); when a
voice is missing this script installs the capability fully offline:

1. Auto-detects the OS build (`CurrentBuildNumber`) and CPU architecture.
2. Resolves the matching cab from local `cache\`, or downloads it from
   [uupdump.net](https://uupdump.net) (files are served by Microsoft's official CDN and
   verified against the published SHA1).
3. Installs with `Add-WindowsCapability -Online -Source <cache> -LimitAccess`
   (`-LimitAccess` never touches Windows Update / WSUS).
4. Re-verifies the capability state and lists installed voice tokens.

## How to Run

Run `platforms/windows/win10/tts-repair.bat` **as Administrator**:

```bat
tts-repair.bat /help
tts-repair.bat /list
tts-repair.bat /menu
tts-repair.bat
tts-repair.bat zh-CN
tts-repair.bat /lang ja-JP
tts-repair.bat en-US /build 19045
```

- No arguments: repairs **zh-CN** (Microsoft Huihui).
- `/list`: shows supported locales; `[local]` = cab already cached, `[installed]` =
  capability present (needs admin to display).
- `/menu`: interactive picker.
- `/lang locale` or `locale`: repair that locale.
- `/build number`: override the auto-detected build used for the uupdump lookup.

## Notes

- Default locale catalog (49 locales) is embedded in the `.bat` as `rem @tts <locale>`
  lines; it matches the TextToSpeech packages published for Windows feature updates.
- On Windows 11 24H2+/25H2 syncs some smaller locales (e.g. `ms-MY`, `ta-IN`,
  `ca-ES`) moved to separate LanguageExperiencePack updates and may not resolve;
  use `/build` with an older build (e.g. `19045`) to fetch those cabs.
- Language FOD cabs are shared **within a servicing branch only** (e.g. any
  19041-19045 build can use a 19045-synced cab). A cab from another Windows
  generation (Win11 cab on Win10, etc.) makes `Add-WindowsCapability` fail with
  `0x800f081f`. The script handles this three ways: enablement builds without their
  own multilanguage sync fall back to the branch tip (19041-19044 → 19045,
  22621 → 22631); every cached cab records its target build in a `.meta` sidecar and
  is refreshed on mismatch; and if DISM still reports `0x800f081f` for a cached cab,
  it is discarded, re-downloaded for the detected build, and installed once more.
- Downloaded cabs are cached flat in `cache\`; delete a cached cab (and its `.meta`)
  if you suspect corruption (the SHA1 check would catch it first).
- Logs are written to `logs\tts-repair.log`.

## Directory Layout

```text
win10/
  tts-repair.bat            # entry point: args, menu, locale catalog
  scripts/
    repair-tts.ps1          # detect / download / install / verify
  cache/                    # downloaded capability cabs (gitignored)
  logs/                     # repair logs (gitignored)
```

## How "Installed" Is Determined

- Primary source: `Get-WindowsCapability -Online` state for
  `Language.TextToSpeech~~~<locale>~0.0.1.0` must be `Installed`.
- Informational: voice tokens under
  `HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens`,
  `...\Speech_OneCore\Voices\Tokens` (and WOW6432Node) matching the locale.
