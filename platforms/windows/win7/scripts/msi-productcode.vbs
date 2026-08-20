Option Explicit
' Print MSI ProductCode to stdout.
Dim installer, database, view, rec
If WScript.Arguments.Count < 1 Then
  WScript.Quit 1
End If
Set installer = CreateObject("WindowsInstaller.Installer")
Set database = installer.OpenDatabase(WScript.Arguments(0), 0)
Set view = database.OpenView("SELECT `Value` FROM `Property` WHERE `Property`='ProductCode'")
view.Execute
Set rec = view.Fetch
If rec Is Nothing Then
  WScript.Quit 1
End If
WScript.Echo rec.StringData(1)
