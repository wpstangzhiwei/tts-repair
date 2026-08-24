# Windows TTS Repair

## Scope

This directory holds Windows TTS repair scripts, resources, and notes.

## Version Strategy

- `win7/`: Windows 7 specific implementation (Microsoft Speech Platform based).
- `win10/`: Windows 10 implementation (DISM `Language.TextToSpeech` capability based).
- `win11/`: Windows 11 implementation; same flow as `win10/`, kept as a separate directory
  for platform-specific adjustments.

## Current Status

| Directory | Status |
|---|---|
| [win7](win7/README.md) | `tts-repair.bat` implemented |
| [win10](win10/README.md) | `tts-repair.bat` implemented |
| [win11](win11/README.md) | `tts-repair.bat` implemented |

## Typical Problem Areas

- Missing or leftover Microsoft Speech Platform Runtime / voice packs (Win7).
- Missing `Language.TextToSpeech` capabilities / voices (Win10/11), e.g. on offline or
  WSUS-managed machines where Windows Update cannot deliver them.
- SAPI mapping out of sync with Speech Platform voices.
- Encoding and locale pronunciation issues.
- Administrator rights required to install MSI packages / DISM capabilities.

## Technical Notes (Win7 Implementation)

- **Silent MSI installs** — `/quiet /norestart`
- **Detection by payload files**, not Uninstall registry leftovers
- **Admin required** for MSI installation
- **Logs** written to `platforms/windows/win7/logs/`