Write-Host "Tls12 value: " [Net.SecurityProtocolType]::Tls12
Write-Host "Before: " [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Write-Host "After: " [Net.ServicePointManager]::SecurityProtocol

$w = New-Object System.Net.WebClient
$w.Headers.Add('User-Agent', 'Mozilla/5.0')
$url = 'https://download.microsoft.com/download/5/6/4/5641DA81-E6FA-4550-9F80-A1D862D9CFAA/dotNetFx40_Full_x86.exe'
$dest = 'C:\Users\KSO\AppData\Local\Temp\test_dotnet6.exe'
try {
    $w.DownloadFile($url, $dest)
    Write-Host "Download complete. Size: " (Get-Item $dest).Length
} catch {
    Write-Host "Error: " $_.Exception.Message
}