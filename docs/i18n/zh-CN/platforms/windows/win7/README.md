# Windows 7 TTS 修复

## 目的

修复 Windows 7 上缺失或不完整的 TTS 资源（Microsoft Speech Platform Runtime、指定语言包、SAPI 映射）。

## 如何运行

以管理员身份运行 `platforms/windows/win7/tts-repair.bat`：

```bat
tts-repair.bat /help
tts-repair.bat /list
tts-repair.bat /menu
tts-repair.bat
tts-repair.bat /lang zh-CN
tts-repair.bat zh-CN
tts-repair.bat zh-CN HuiHui
tts-repair.bat en-US
tts-repair.bat en-US ZiraPro
tts-repair.bat ja-JP sr
tts-repair.bat ja-JP all
tts-repair.bat /all
```

- `/help`：显示参数说明，并列出可选语言 / 语音。  
- `/list`：只列出可用 TTS / SR；`[local]` 表示磁盘上已有 MSI，`[default]` 是随仓库附带的默认包。  
- `/menu`：交互选择语言（输入编号，或 `locale [语音] [tts|sr|all]`）。  
- 无参数：默认安装 `zh-CN` TTS（HuiHui）。该 MSI 首次运行时从 Microsoft 下载并缓存在 `Languages/`。  
- `/lang locale` 或 `locale`：安装该语言全部 TTS 语音（如 `en-US` 会装 Helen 和 ZiraPro）。  
- `locale 语音名`：只装指定 TTS 语音。  
- `locale sr`：只装该语言识别包。  
- `locale all`：TTS + SR。  
- `/all`：安装清单中全部语言包。  

默认的 `MSSpeech_TTS_zh-CN_HuiHui.msi` 首次运行时从 Microsoft 下载。其他语言 MSI 也从 Microsoft 下载。脚本按 本地缓存 `Languages/` → 从 Microsoft 下载到 `Languages/` 的顺序解析，下载后缓存在本地。

安装日志写在 `platforms/windows/win7/logs/`。

## 修复步骤

脚本按顺序处理：

1. 安装或修复 `resources/Microsoft Speech Platform/SpeechPlatformRuntime(x86).msi`（从 Microsoft 下载）  
2. 解析所选语言包：本地 `Languages/` 缓存 → 从 Microsoft 下载到 `Languages/`  
3. 安装或修复所选 `MSSpeech_*.msi`  
4. 若所选 TTS 的 SAPI 映射缺失，则运行 `resources/SAPI_Unifier/SAPI_Unifier_requires_dot_NET_4.exe`  

SAPI Unifier 是 GUI 程序，依赖 **.NET Framework 4**，**不依赖** `VC_redist.x86.exe`。映射在窗口弹出前已完成，脚本会自动关闭窗口，无需点击 Exit。

## 如何判断“已安装”

不以卸载列表残留为准，而以实际文件为准：

- **Speech Runtime**：存在 `Microsoft.Speech.dll` 或 `SR\v11.0\spsreng.dll`（`Common Files\Microsoft Shared\Speech` 或其 x86 路径）。  
- **TTS 语言包**：存在 Speech Server 语音 token，例如 `TTS_MS_zh-CN_HuiHui_11.0`，或 `Tokens\<token>\` 目录。  
- **SR 语言包**：存在 `Recognizers\Tokens\SR_MS_<locale>_TELE_11.0`。  
- **SAPI 映射**（仅 TTS）：`HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\<token>`。  

如果文件缺失但 MSI ProductCode 仍在卸载表中，脚本会走修复而不是跳过。ProductCode 从各 MSI 现场读取。  

## 资源目录

```text
win7/
  tts-repair.bat
  scripts/
    auto-close-sapi-unifier.vbs
    msi-productcode.vbs
    download-msi.ps1
  resources/
    Microsoft Speech Platform/
      Languages/
        MSSpeech_TTS_zh-CN_HuiHui.msi   # 下载缓存
        # 其他 MSI：下载缓存
    SAPI_Unifier/
      SAPI_Unifier_requires_dot_NET_4.exe
```

## 第三方组件

本项目包含 SAPI Unifier（GPL-3.0），由 Mahmood Taghavi 开发。
源码：https://github.com/Mahmood-Taghavi/SAPI_Unifier