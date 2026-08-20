# Download one language MSI. Compatible with Windows 7 PowerShell 2.0.
$dest = $env:DL_DEST
$name = $env:DL_NAME
if (-not $dest -or -not $name) {
  Write-Host "missing DL_DEST or DL_NAME"
  exit 1
}

try {
  [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
} catch {}
try {
  [Net.ServicePointManager]::CheckCertificateRevocationList = $false
} catch {}
try {
  [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
} catch {}

$urls = @(
  ("https://raw.githubusercontent.com/wpstangzhiwei/tts-repair-win7-langpacks/main/" + $name),
  ("https://media.githubusercontent.com/media/wpstangzhiwei/tts-repair-win7-langpacks/main/" + $name),
  ("https://cdn.jsdelivr.net/gh/wpstangzhiwei/tts-repair-win7-langpacks@main/" + $name),
  ("https://github.com/wpstangzhiwei/tts-repair-win7-langpacks/raw/main/" + $name)
)

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

$dir = Split-Path -Parent $dest
if (-not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

$partial = $dest + ".partial"
foreach ($u in $urls) {
  Write-Host ("  try: " + $u)
  try {
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
    $w = New-Object System.Net.WebClient
    $w.Headers.Add("User-Agent", "tts-repair")
    $w.DownloadFile($u, $partial)
    if (Test-MsiFile $partial) {
      if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
      Move-Item -LiteralPath $partial -Destination $dest
      Write-Host ("  saved: " + $dest)
      exit 0
    }
    Write-Host "  skip: response is not a valid MSI"
  } catch {
    Write-Host ("  fail: " + $_.Exception.Message)
  }
}
if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
exit 1
