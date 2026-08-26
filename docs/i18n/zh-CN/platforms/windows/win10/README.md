# Windows 10 TTS 修复

## 目的

修复 Windows 10 上缺失的 TTS 声音。此脚本同样适用于 Windows 11。Windows 的 TTS 语音以
`Language.TextToSpeech` 能力（capability，如 `Language.TextToSpeech~~~zh-CN~0.0.1.0`）
形式发布；脚本将其完整离线补齐：

1. 自动探测系统版本号（`CurrentBuildNumber`）与 CPU 架构（amd64、x86、arm64）。
2. 解析对应 cab：优先本地 `cache\`，缺失时从 [uupdump.net](https://uupdump.net)
   下载（文件实际来自微软官方 CDN，并按公布的 SHA1 校验）。
3. 用 `Add-WindowsCapability -Online -Source <cache> -LimitAccess` 离线安装
   （`-LimitAccess` 保证完全不访问 Windows Update / WSUS）。若能力源解析失败
   （常见于早期 Win10 1904x、无完整 FOD 仓库布局时），自动改用
   `Add-WindowsPackage` 直接安装 cab 包体。
4. 复检能力状态，并列出已注册的语音 token。

## 如何运行

以管理员身份运行 `platforms/windows/win10/tts-repair.bat`：

```bat
tts-repair.bat /help
tts-repair.bat /list
tts-repair.bat /menu
tts-repair.bat
tts-repair.bat zh-CN
tts-repair.bat /lang ja-JP
tts-repair.bat en-US /build 19045
```

- 无参数：默认修复 **zh-CN**（Microsoft Huihui）。
- `/list`：列出支持的语言；`[local]` = cab 已缓存，`[installed]` = 已安装（需管理员）。
- `/menu`：交互选择语言。
- `/lang locale` 或 `locale`：修复指定语言。
- `/build number`：覆盖自动探测的系统版本号（用于 uupdump 查找）。

## 说明

- 默认语言清单（49 个 locale）内嵌在 `.bat` 的 `rem @tts <locale>` 行中，
  与 Windows 功能更新的 TextToSpeech 包一致。
- Windows 11 24H2+/25H2 的同步中部分小语种（如 `ms-MY`、`ta-IN`、`ca-ES`）
  移到了独立的 LanguageExperiencePack 更新，可能查不到；此时可用 `/build`
  指定旧版本号（如 `19045`）获取。
- 语言 FOD cab 仅在**同一服务分支内**通用（例如 19041-19045 任意版本都可用
  19045 同步的 cab）。跨代使用（如把 Win11 的 cab 装到 Win10）会让
  `Add-WindowsCapability` 报 `0x800f081f`。脚本对此有三层处理：无独立多语言
  同步的启用包 build 自动回退到分支顶端（19041-19044 → 19045，22621 → 22631）；
  每个 cab 下载后在 `.meta` 旁车文件中记录目标 build，不匹配即自动刷新；
  若 DISM 仍对缓存 cab 报 `0x800f081f`，则丢弃缓存、按当前 build 重下并重试一次。
- cab 平铺缓存在 `cache\`；若怀疑损坏可删除 cab 及其 `.meta` 后重跑
  （SHA1 校验会先行拦截）。
- 日志写入 `logs\tts-repair.log`。

## 目录结构

```text
win10/
  tts-repair.bat            # 入口：参数解析、菜单、语言清单
  scripts/
    repair-tts.ps1          # 探测 / 下载 / 安装 / 复检
  cache/                    # 下载的能力 cab（gitignore）
  logs/                     # 修复日志（gitignore）
```

## 如何判断"已安装"

- 主要依据：`Get-WindowsCapability -Online` 中
  `Language.TextToSpeech~~~<locale>~0.0.1.0` 的状态为 `Installed`。
- 辅助信息：`HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens`、
  `...\Speech_OneCore\Voices\Tokens`（含 WOW6432Node）下匹配该语言的语音 token。
