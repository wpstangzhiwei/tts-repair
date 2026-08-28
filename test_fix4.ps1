$t = [Net.SecurityProtocolType]
$f = $t.GetField('value__', 'NonPublic,Instance')
$sp = [Net.ServicePointManager]::SecurityProtocol
$v = $f.GetValue($sp)
Write-Host "Before: " $v
$f.SetValue($sp, ($v -bor 3072))
$v2 = $f.GetValue($sp)
Write-Host "After: " $v2

$w = New-Object System.Net.WebClient
$w.Headers.Add('User-Agent', 'Mozilla/5.0')
$url = 'https://download.microsoft.com/download/5/6/4/5641DA81-E6FA-4550-9F80-A1D862D9CFAA/dotNetFx40_Full_x86.exe'
$dest = 'C:\Users\KSO\AppData\Local\Temp\test_dotnet5.exe'
try {
    $w.DownloadFile($url, $dest)
    Write-Host "Download complete. Size: " (Get-Item $dest).Length
} catch {
    Write-Host "Error: " $_.Exception.Message
}