[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$w = New-Object System.Net.WebClient
$w.Headers.Add('User-Agent', 'Mozilla/5.0')
$url = 'https://download.microsoft.com/download/5/6/4/5641DA81-E6FA-4550-9F80-A1D862D9CFAA/dotNetFx40_Full_x86.exe'
$dest = 'C:\Users\KSO\AppData\Local\Temp\test_dotnet_final.exe'
try {
    $w.DownloadFile($url, $dest)
    Write-Host "Download complete. Size: " (Get-Item $dest).Length
} catch {
    Write-Host "Error: " $_.Exception.Message
}