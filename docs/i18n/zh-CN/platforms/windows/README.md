# Windows TTS 修复

## 范围

本目录存放 Windows 平台的 TTS 修复脚本、资源和说明。

## 版本策略

- `win7/`：Windows 7 专用实现（基于 Microsoft Speech Platform）。
- `win10/`：Windows 10 实现（基于 DISM `Language.TextToSpeech` 能力）。
- `win11/`：Windows 11 实现，流程与 `win10/` 相同，独立成目录以便后续适配平台差异。

## 当前状态

| 目录 | 状态 |
|---|---|
| [win7](win7/README.md) | 已实现 `tts-repair.bat` |
| [win10](win10/README.md) | 已实现 `tts-repair.bat` |
| [win11](win11/README.md) | 已实现 `tts-repair.bat` |

## 常见问题域

- Microsoft Speech Platform Runtime / 语音包缺失或残留（Win7）。
- `Language.TextToSpeech` 能力 / 声音缺失（Win10/11），常见于离线机或 WSUS 管控、无法从 Windows Update 获取的机器。
- SAPI 与 Speech Platform 语音映射不一致。
- 编码、区域设置导致发音异常。
- 需要管理员权限才能安装 MSI / DISM 能力。

## 技术细节（Win7 实现）

- **静默安装 MSI** — `/quiet /norestart`
- **按实际文件判断**，而非卸载注册表残留
- **需要管理员权限** 安装 MSI
- **日志**写入 `platforms/windows/win7/logs/`