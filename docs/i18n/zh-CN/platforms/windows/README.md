# Windows TTS 修复

## 范围

本目录存放 Windows 平台的 TTS 修复脚本、资源和说明。

## 版本策略

- `win7/`：Windows 7 专用实现（当前已提供修复脚本）。  
- `win10-plus/`：Windows 10 与 Windows 11+ 共用基线。未发现 Win11 专属差异前，不单独建 `win11/`。  

## 当前状态

| 目录 | 状态 |
|---|---|
| [win7](win7/README.md) | 已实现 `tts-repair.bat` |
| [win10-plus](win10-plus/README.md) | 目录骨架已建，脚本待实现 |

## 常见问题域

- Microsoft Speech Platform Runtime / 语音包缺失或残留。  
- SAPI 与 Speech Platform 语音映射不一致。  
- 编码、区域设置导致发音异常。  
- 需要管理员权限才能安装 MSI。  

## 多语言要求

文本文档放在 `docs/i18n/<locale>/platforms/windows/`，代码目录中的 README 仅作语言入口。  
