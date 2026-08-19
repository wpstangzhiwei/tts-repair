# Windows 10+ Baseline

## Purpose

This directory is the shared TTS repair baseline for Windows 10 and Windows 11+. It currently contains the folder skeleton only; repair scripts are not implemented yet.

## Rule

- Implement once in `win10-plus`, and validate on both Win10 and Win11+.  
- Split to `win11` only when a proven Win11-only issue cannot be handled by shared logic.  

## Current Layout

```text
win10-plus/
  scripts/      # intended home for tts-repair.bat; currently empty
  docs/
  samples/
```

For Windows 7, use [win7](../win7/README.md). Do not fold Win7 logic into this directory.  
