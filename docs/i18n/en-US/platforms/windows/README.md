# Windows TTS Repair

## Scope

This directory contains Windows-first repair standards, troubleshooting notes, and implementation scripts for TTS issues.

Windows 11 should follow the same implementation as Windows 10 unless a platform-specific issue is found.

## Version Strategy

- `win10-plus` is the baseline directory for both Windows 10 and Windows 11+.  
- Add a dedicated `win11` directory only when there is a confirmed Win11-only behavior difference.  

## Typical Problem Areas

- Voice installation and availability mismatch.  
- Encoding and locale-related text pronunciation errors.  
- API invocation differences across engines.  
- Runtime permission and dependency issues.  

## Suggested Subfolders

- `win10-plus/`: shared implementation for Windows 10 and 11+  
- `scripts/`: automation and repair scripts  
- `docs/`: troubleshooting cases  
- `samples/`: reproducible input/output samples  

## Multilingual Requirement

All text documents under this directory should keep at least Chinese and English versions in language-specific folders.
