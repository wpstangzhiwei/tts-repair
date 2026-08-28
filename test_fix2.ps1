$protocol = [Net.ServicePointManager]::SecurityProtocol
Write-Host "Before: " $protocol.value__
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject($protocol.GetType(), ($protocol.value__ -bor 3072))
$protocol2 = [Net.ServicePointManager]::SecurityProtocol
Write-Host "After: " $protocol2.value__

$w = New-Object System.Net.WebClient
$w.Headers.Add('User-Agent', 'Mozilla/5.0')
$url = 'https://download.microsoft.com/download/5/6/4/5641DA81-E6FA-4550-9F80-A1D862D9CFAA/dotNetFx40_Full_x86.exe'
$dest = 'C:\Users\KSO\AppData\Local\Temp\test_dotnet3.exe'
try {
    $w.DownloadFile($url, $dest)
    Write-Host "Download complete. Size: " (Get-Item $dest).Length
} catch {
    Write-Host "Error: " $_.Exception.Message
}