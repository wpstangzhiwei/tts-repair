# TTS 修复项目

## 项目目标

构建一个跨平台的文本转语音（TTS）修复工具集。所有文本文档按语言分目录维护（至少中文、英文）。

## 当前进度

1. 优先 Windows。  
2. **Windows 7 修复脚本已可用。** 默认装 zh-CN HuiHui；语言包由 `tts-repair.bat` 从 [tts-repair-win7-langpacks](https://github.com/wpstangzhiwei/tts-repair-win7-langpacks.git) 按需下载并缓存在本地。  
3. Windows 10 / 11+ 共用基线目录已建好，脚本尚未实现。  
4. 其他平台后续扩展。  

## 目录结构

```text
LICENSE
README.md
docs/i18n/
  zh-CN/
  en-US/
platforms/windows/
  README.md
  win7/
    tts-repair.bat
    resources/
  win10-plus/
    scripts/
    docs/
    samples/
```

## 快速使用（Windows 7）

1. 以管理员身份运行 `platforms/windows/win7/tts-repair.bat`。  
2. 脚本会检查 → 修复 → 复检 Microsoft Speech Platform Runtime、HuiHui 语音包、SAPI 映射。  
3. 需要已安装 .NET Framework 4（SAPI Unifier 依赖它）。  
4. 详细说明见 [Windows 7](platforms/windows/win7/README.md)。  

## 许可证

本项目采用 [GPL-3.0-only](../../../LICENSE)。  
使用、引用并发布衍生作品时，必须按 GPLv3 公开对应源代码。

## 多语言规则

- 正文文档放在 `docs/i18n/<locale>/`。  
- 代码目录中的 `README.md` 只作为语言入口，使用可点击链接跳转。  
