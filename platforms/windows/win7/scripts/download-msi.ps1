# Download one MSI. Compatible with Windows 7 PowerShell 2.0.
# Sources:
#   SpeechPlatformRuntime(x86).msi  -> Microsoft Download Center (still live)
#   MSSpeech_TTS_*.msi              -> Microsoft Download Center (deleted; fallback to manual)
$dest = $env:DL_DEST
$name = $env:DL_NAME
if (-not $dest -or -not $name) {
  Write-Host "missing DL_DEST or DL_NAME"
  exit 1
}

# Enable strong crypto for TLS 1.2 (works on PS 2.0 / .NET 3.5)
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
  } catch {}
try {
  [Net.ServicePointManager]::CheckCertificateRevocationList = $false
} catch {}
try {
  [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
} catch {}

if ($name -eq "SpeechPlatformRuntime(x86).msi") {
  $urls = @(
    "https://download.microsoft.com/download/A/6/4/A64012D6-D56F-4E58-85E3-531E56ABC0E6/x86_SpeechPlatformRuntime/SpeechPlatformRuntime.msi"
  )
} else {
  $urls = @(
    ("https://download.microsoft.com/download/4/0/D/40D6347A-AFA5-417D-A9BB-173D937BEED4/" + $name),
    ("https://web.archive.org/web/2023id_/https://download.microsoft.com/download/4/0/D/40D6347A-AFA5-417D-A9BB-173D937BEED4/" + $name)
  )
}

function Test-MsiFile([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  $item = Get-Item -LiteralPath $path
  if ($item.Length -lt 4096) { return $false }
  $fs = [IO.File]::OpenRead($path)
  try {
    $b = New-Object byte[] 8
    $n = $fs.Read($b, 0, 8)
    if ($n -lt 8) { return $false }
    return ($b[0] -eq 0xD0 -and $b[1] -eq 0xCF -and $b[2] -eq 0x11 -and $b[3] -eq 0xE0)
  } finally {
    $fs.Close()
  }
}

function Download-File([string]$Url, [string]$OutFile, [int]$MaxRetries = 5) {
  for ($i = 1; $i -le $MaxRetries; $i++) {
    try {
      if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
      $w = New-Object System.Net.WebClient
      $w.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36")
      $w.DownloadFile($Url, $OutFile)
      return $true
    } catch {
      Write-Host ("  attempt $i failed: " + $_.Exception.Message)
      if ($i -lt $MaxRetries) {
        Write-Host "  retrying in 5 seconds..."
        Start-Sleep -Seconds 5
      }
    }
  }
  return $false
}

$dir = Split-Path -Parent $dest
if (-not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

$partial = $dest + ".partial"
foreach ($u in $urls) {
  Write-Host ("  try: " + $u)
  if (Download-File $u $partial) {
    if (Test-MsiFile $partial) {
      if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
      Move-Item -LiteralPath $partial -Destination $dest
      Write-Host ("  saved: " + $dest)
      exit 0
    }
    Write-Host "  skip: response is not a valid MSI"
  }
}
if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
exit 1
