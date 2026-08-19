# Windows TTS Repair / Windows TTS 修复

## Scope / 范围

This directory contains Windows-first repair standards, troubleshooting notes, and implementation scripts for TTS issues.

本目录用于存放 Windows 优先的 TTS 问题修复规范、排障说明和实现脚本。

Windows 11 should follow the same implementation as Windows 10 unless a platform-specific issue is found.

在未发现平台特有问题前，Windows 11 与 Windows 10 走同一套实现。

## Version Strategy / 版本策略

- `win10-plus` is the baseline directory for both Windows 10 and Windows 11+.
- Add a dedicated `win11` directory only when there is a confirmed Win11-only behavior difference.

- `win10-plus` 作为 Windows 10 与 Windows 11+ 的统一基线目录。
- 仅在确认存在 Win11 专属行为差异时，才新增独立的 `win11` 目录。

## Typical Problem Areas / 常见问题域

- Voice installation and availability mismatch.
- Encoding and locale-related text pronunciation errors.
- API invocation differences across engines.
- Runtime permission and dependency issues.

- 语音包安装与可用性不一致。
- 编码与区域设置导致的文本发音异常。
- 不同引擎之间的 API 调用差异。
- 运行时权限与依赖问题。

## Suggested Subfolders / 建议子目录

You can create these as implementation grows:

随着实现推进可逐步创建以下子目录：

- `win10-plus/`: shared implementation for Windows 10 and 11+ / Windows 10 与 11+ 共用实现
- `scripts/`: automation and repair scripts / 自动化与修复脚本
- `docs/`: troubleshooting cases / 故障案例文档
- `samples/`: reproducible input/output samples / 可复现输入输出样例

## Multilingual Requirement / 多语言要求

All text documents under this directory should keep bilingual content (Chinese + English) for consistency.

本目录下所有文本文档建议保持中英文双语，确保协作一致性。
