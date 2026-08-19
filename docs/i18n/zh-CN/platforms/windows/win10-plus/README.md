# Windows 10+ 基线

## 目的

本目录是 Windows 10 与 Windows 11+ 共用的 TTS 修复基线。当前仅有目录骨架，修复脚本尚未实现。

## 规则

- 在 `win10-plus` 中实现一次，并在 Win10 与 Win11+ 双端验证。  
- 仅当确认 Win11 专属问题无法通过共享逻辑处理时，才拆分 `win11`。  

## 当前结构

```text
win10-plus/
  scripts/      # 计划放置 tts-repair.bat，目前为空
  docs/
  samples/
```

Windows 7 请使用 [win7](../win7/README.md)，不要把 Win7 逻辑并入本目录。  
