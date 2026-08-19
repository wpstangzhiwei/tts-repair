# Windows 10+ 基线

## 目的

本目录是 Windows 10 与 Windows 11+ 共用的 TTS 修复基线实现目录。

## 规则

- 在 `win10-plus` 中实现一次，并在 Win10 与 Win11+ 双端验证。  
- 仅当确认 Win11 专属问题无法通过共享逻辑处理时，才拆分 `win11`。  

## 建议结构

```text
win10-plus/
  scripts/
  docs/
  samples/
```
