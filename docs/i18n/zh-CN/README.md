# TTS 修复项目

## 项目目标

构建一个跨平台的文本转语音（TTS）修复工具集，并确保所有文本资产都具备多语言处理能力。

## 当前优先级

1. 优先处理 Windows 平台。  
2. 为 Windows TTS 引擎建立并验证修复流程。  
3. 后续将同一架构扩展到其他平台。  

## 目录结构

```text
platforms/
  windows/
    README.md
    win10-plus/
      README.md
```

## 多语言规则

- 所有文本文件都应包含多语言内容（至少中文与英文）。  
- 新文档应保持按语言分目录维护。  

## 下一步

在 `platforms/windows/win10-plus` 中定义 Windows 专属问题分类与修复脚本（Windows 10 与 Windows 11+ 共用）。
