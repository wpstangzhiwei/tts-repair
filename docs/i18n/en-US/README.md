# TTS Repair Project

## Project Goal

Build a cross-platform text-to-speech (TTS) repair toolkit with multilingual text processing support for all text assets.

## Current Priority

1. Windows platform first.  
2. Add and validate repair workflow for Windows TTS engines.  
3. Extend the same architecture to other platforms later.  

## Directory Layout

```text
platforms/
  windows/
    README.md
    win10-plus/
      README.md
```

## Multilingual Rule

- Every text file should include multilingual content (at least Chinese and English).  
- New docs should be maintained in language-separated directories.  

## Next Step

Define Windows-specific issue categories and repair scripts in `platforms/windows/win10-plus` (shared for both Windows 10 and Windows 11+).
