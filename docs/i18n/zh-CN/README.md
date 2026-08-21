# TTS 修复项目

## 项目目标

构建一个跨平台的文本转语音（TTS）修复工具集。所有文本文档按语言分目录维护在 `docs/i18n/<locale>/`。

## 当前进度

1. **优先 Windows**
2. **Windows 7 修复脚本已可用** — `platforms/windows/win7/tts-repair.bat`  
   默认装 zh-CN HuiHui（MSI 随仓库附带，无需下载）。其他语言可用 `/help`、`/menu` 或 `locale` 参数选择；缺失的语言包才从 [tts-repair-win7-langpacks](https://github.com/wpstangzhiwei/tts-repair-win7-langpacks.git) 按需下载并缓存。
3. **Windows 10 / 11+** 共用基线目录已建好，脚本尚未实现。
4. 其他平台后续扩展。

## 目录结构

```text
LICENSE
README.md
docs/i18n/
  zh-CN/
  en-US/
platforms/windows/
  win7/
    tts-repair.bat
    scripts/
    resources/
  win10-plus/
    scripts/
```

## 快速使用（Windows 7）

1. 以管理员身份运行 `platforms/windows/win7/tts-repair.bat`。
2. 脚本会检查 → 修复 → 复检 Microsoft Speech Platform Runtime、所选语音包、SAPI 映射。
3. 需要已安装 **.NET Framework 4**（SAPI Unifier 依赖它）。
4. 详细说明见 [Windows 7](docs/i18n/zh-CN/platforms/windows/win7/README.md)。

## 许可证

采用 [GPL-3.0-only](../LICENSE)。  
使用、引用并发布衍生作品时，必须按 GPLv3 公开对应源代码。

## 多语言规则

- 正文文档放在 `docs/i18n/<locale>/`。
- 代码目录不再放 README，直接链接到 `docs/i18n/`。