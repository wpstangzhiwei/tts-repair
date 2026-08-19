# Windows 10+ Baseline / Windows 10+ 基线

## Purpose / 目的

This directory is the shared baseline for both Windows 10 and Windows 11+ TTS repair logic.

本目录是 Windows 10 与 Windows 11+ 共用的 TTS 修复基线实现目录。

## Rule / 规则

- Implement once in `win10-plus`, validate on both Win10 and Win11+.
- Split to `win11` only when a proven Win11-only issue cannot be handled by shared logic.

- 在 `win10-plus` 中实现一次，并在 Win10 与 Win11+ 双端验证。
- 仅当确认 Win11 专属问题无法通过共享逻辑处理时，才拆分 `win11`。

## Recommended Layout / 建议结构

```text
win10-plus/
  scripts/
  docs/
  samples/
```
