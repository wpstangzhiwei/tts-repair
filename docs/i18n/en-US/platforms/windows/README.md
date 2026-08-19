# Windows TTS Repair

## Scope

This directory holds Windows TTS repair scripts, resources, and notes.

## Version Strategy

- `win7/`: Windows 7 specific implementation (repair script is available).  
- `win10-plus/`: shared baseline for Windows 10 and Windows 11+. Do not add `win11/` unless a confirmed Win11-only difference appears.  

## Current Status

| Directory | Status |
|---|---|
| [win7](win7/README.md) | `tts-repair.bat` implemented |
| [win10-plus](win10-plus/README.md) | skeleton only; scripts pending |

## Typical Problem Areas

- Missing or leftover Microsoft Speech Platform Runtime / voice packs.  
- SAPI mapping out of sync with Speech Platform voices.  
- Encoding and locale pronunciation issues.  
- Administrator rights required to install MSI packages.  

## Multilingual Requirement

Keep document bodies under `docs/i18n/<locale>/platforms/windows/`. README files in code directories are language entry pages only.  
