Option Explicit
' Auto-close SAPI Unifier after it finishes unifying.
' The actual registry work runs in the form constructor, before the window is shown.
Dim sh, i, closed
Set sh = CreateObject("WScript.Shell")

Function ActivateUnifier()
  ActivateUnifier = sh.AppActivate("SAPI Unifier")
  If Not ActivateUnifier Then ActivateUnifier = sh.AppActivate("SAPI_Unifier")
End Function

For i = 1 To 150
  If ActivateUnifier() Then Exit For
  WScript.Sleep 200
Next

If Not ActivateUnifier() Then
  WScript.Quit 0
End If

WScript.Sleep 500
ActivateUnifier
WScript.Sleep 100
sh.SendKeys "%{F4}"

WScript.Sleep 1500
If ActivateUnifier() Then
  sh.Run "taskkill /IM SAPI_Unifier_requires_dot_NET_4.exe /F", 0, True
End If

WScript.Quit 0
