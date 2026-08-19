# TTS Repair / TTS 修复项目

## Project Goal / 项目目标

Build a cross-platform text-to-speech (TTS) repair toolkit with multilingual text processing support for all text assets.

构建一个跨平台的文本转语音（TTS）修复工具集，并确保所有文本资产都具备多语言处理能力。

## Current Priority / 当前优先级

1. Windows platform first.
2. Add and validate repair workflow for Windows TTS engines.
3. Extend the same architecture to other platforms later.

1. 优先处理 Windows 平台。
2. 为 Windows TTS 引擎建立并验证修复流程。
3. 后续将同一架构扩展到其他平台。

## Directory Layout / 目录结构

```text
platforms/
  windows/
    README.md
    win10-plus/
      README.md
```

## Multilingual Rule / 多语言规则

- Every text file should include multilingual content (at least Chinese and English).
- New docs should keep paired sections in both languages.

- 所有文本文件都应包含多语言内容（至少中文与英文）。
- 新文档应保持中英文配对章节。

## Next Step / 下一步

Define Windows-specific issue categories and repair scripts in `platforms/windows/win10-plus` (shared for both Windows 10 and Windows 11+).

在 `platforms/windows/win10-plus` 中定义 Windows 专属问题分类与修复脚本（Windows 10 与 Windows 11+ 共用）。
