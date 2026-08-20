# Windows 7 TTS 修复

## 目的

修复 Windows 7 上缺失或不完整的 TTS 资源（Microsoft Speech Platform Runtime、中文 HuiHui 语音包、SAPI 映射）。

## 如何运行

1. 右键 `platforms/windows/win7/tts-repair.bat`，选择 **以管理员身份运行**。  
2. 脚本流程：检查 → 修复 → 复检。  
3. 安装日志写在 `platforms/windows/win7/logs/`。  

## 修复步骤

脚本按顺序处理：

1. 安装或修复 `resources/Microsoft Speech Platform/SpeechPlatformRuntime(x86).msi`  
2. 安装或修复 `resources/Microsoft Speech Platform/Languages/MSSpeech_TTS_zh-CN_HuiHui.msi`  
3. 若 SAPI 映射缺失，则运行 `resources/SAPI_Unifier/SAPI_Unifier_requires_dot_NET_4.exe`  

SAPI Unifier 是 GUI 程序，依赖 **.NET Framework 4**，**不依赖** `VC_redist.x86.exe`。映射在窗口弹出前已完成，脚本会自动关闭窗口，无需点击 Exit。

## 如何判断“已安装”

不以卸载列表残留为准，而以实际文件为准：

- **Speech Runtime**：存在 `Microsoft.Speech.dll` 或 `SR\v11.0\spsreng.dll`（`Common Files\Microsoft Shared\Speech` 或其 x86 路径）。  
- **HuiHui 语音包**：存在 `HuiHuiT.INI`（优先 `Tokens\TTS_MS_ZH-CN_HUIHUI_11.0\`）。  
- **SAPI 映射**：存在注册表  
  `HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0`  
  （含 Wow6432Node）。  

如果文件缺失但 MSI ProductCode 仍在卸载表中，脚本会走修复而不是跳过。

ProductCode：

- Runtime：`{22CB8ED7-DF57-4864-BD04-F63B9CE4B494}`  
- HuiHui：`{44B3785F-9F8B-46A9-AD46-21B7AC49D086}`  

## 资源目录

```text
win7/
  tts-repair.bat
  scripts/
    auto-close-sapi-unifier.vbs
  resources/
    Microsoft Speech Platform/
      SpeechPlatformRuntime(x86).msi
      Languages/MSSpeech_TTS_zh-CN_HuiHui.msi
    SAPI_Unifier/
      SAPI_Unifier_requires_dot_NET_4.exe
```

## 注意事项

- 必须使用管理员权限。  
- 静默安装 MSI；`1603` 时会再查 ProductCode，避免把残留安装当成成功后的唯一依据。  
- 不自动安装 VC++ 运行库。  
