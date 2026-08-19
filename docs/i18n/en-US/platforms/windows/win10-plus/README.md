# Windows 10+ Baseline

## Purpose

This directory is the shared baseline for both Windows 10 and Windows 11+ TTS repair logic.

## Rule

- Implement once in `win10-plus`, validate on both Win10 and Win11+.  
- Split to `win11` only when a proven Win11-only issue cannot be handled by shared logic.  

## Recommended Layout

```text
win10-plus/
  scripts/
  docs/
  samples/
```
