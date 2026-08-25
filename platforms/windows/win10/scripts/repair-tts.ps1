# Repair a missing Windows TTS voice (Language.TextToSpeech capability).
# Flow: check -> resolve (local cache, then uupdump cab) -> install offline -> verify.
# Compatible with Windows 10 / 11 Windows PowerShell 5.1.

param(
  [string]$Locale = "zh-CN",
  [switch]$List,
  [string]$Catalog = "",
  [string]$CacheDir = "",
  [string]$LogDir = "",
  [string]$BuildOverride = "",
  [switch]$NoInstall,
  [string]$ApiBase = "https://api.uupdump.net"
)

$ErrorActionPreference = "Stop"

try {
  [Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

$script:LogPath = ""
if ($LogDir) {
  if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
  }
  $script:LogPath = Join-Path $LogDir "tts-repair.log"
}
if (-not $CacheDir) {
  $CacheDir = Join-Path $PSScriptRoot "..\cache"
}
if (-not (Test-Path -LiteralPath $CacheDir)) {
  New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

# Language FODs are shared inside a servicing branch. Older enablement builds have no
# multilanguage sync of their own on uupdump, so fall back to the branch tip that does.
$script:FallbackBuilds = @{
  "19041" = "19045"   # Win10 2004 -> 22H2
  "19042" = "19045"   # Win10 20H2 -> 22H2
  "19043" = "19045"   # Win10 21H1 -> 22H2
  "19044" = "19045"   # Win10 21H2 -> 22H2
  "22621" = "22631"   # Win11 22H2 -> 23H2
}

function Write-Log([string]$Message) {
  Write-Host $Message
  if ($script:LogPath) {
    try {
      Add-Content -LiteralPath $script:LogPath -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message) -Encoding UTF8
    } catch {}
  }
}

function Test-Administrator {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($id)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-OsInfo {
  $cv = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
  $arch = $env:PROCESSOR_ARCHITEW6432
  if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
  if ($arch -match "ARM64") { $arch = "arm64" }
  elseif ($arch -match "x86") { $arch = "x86" }
  else { $arch = "amd64" }
  return [pscustomobject]@{
    Build = [string]$cv.CurrentBuildNumber
    Ubr   = [string]$cv.UBR
    Arch  = $arch
  }
}

# zh-cn -> zh-CN ; sr-latn-rs -> sr-Latn-RS
function ConvertTo-CapabilityLocale([string]$Value) {
  $parts = $Value.ToLowerInvariant() -split "-"
  $out = $parts[0]
  if ($parts.Count -ge 2) {
    if ($parts[1].Length -eq 4) {
      $out += "-" + $parts[1].Substring(0, 1).ToUpperInvariant() + $parts[1].Substring(1).ToLowerInvariant()
    } else {
      $out += "-" + $parts[1].ToUpperInvariant()
    }
  }
  if ($parts.Count -ge 3) {
    $out += "-" + $parts[2].ToUpperInvariant()
  }
  return $out
}

function Get-TtsCapabilityStates {
  $map = @{}
  try {
    $caps = Get-WindowsCapability -Online -ErrorAction Stop |
      Where-Object { $_.Name -like "Language.TextToSpeech~~~*" }
    foreach ($cap in $caps) {
      $tok = $cap.Name -split "~"
      if ($tok.Count -ge 4) { $map[$tok[3]] = [string]$cap.State }
    }
  } catch {
    Write-Log "[ERROR] Get-WindowsCapability failed: $($_.Exception.Message)"
    throw
  }
  return $map
}

function Format-State([string]$State) {
  if ($State -eq "Installed") { return "OK" }
  return "MISSING"
}

function Find-UupUpdateId([string]$Build, [string]$Arch, [string]$LangLower) {
  $candidates = @($Build)
  if ($script:FallbackBuilds.ContainsKey($Build)) { $candidates += $script:FallbackBuilds[$Build] }

  foreach ($b in $candidates) {
    $pick = Find-UupUpdateIdForBuild -Build $b -Arch $Arch -LangLower $LangLower
    if ($pick) { return $pick }
  }
  throw "no uupdump update for build $Build ($Arch) provides language '$LangLower'; try /build <number>"
}

function Find-UupUpdateIdForBuild([string]$Build, [string]$Arch, [string]$LangLower) {
  $url = "$ApiBase/listid.php?search=$Build&sortByDate=1"
  Write-Log "- Query uupdump known builds: build $Build / $Arch"
  $resp = Invoke-RestMethod -Uri $url -TimeoutSec 120
  $entries = @($resp.response.builds.PSObject.Properties.Value | Where-Object { $_.arch -eq $Arch })
  if ($entries.Count -eq 0) { return $null }

  # Full multilanguage syncs rank above cumulative/CPC/en-us-only updates;
  # ties are broken by creation date (newest first).
  $scored = @(foreach ($e in $entries) {
    $pref = 0
    if ($e.title -match ", version \d+H\d") { $pref += 2 }
    if ($e.title -match "^Feature update to Windows") { $pref += 1 }
    [pscustomobject]@{ E = $e; Pref = $pref }
  })
  $ordered = @($scored | Sort-Object @{ Expression = "Pref"; Descending = $true },
      @{ Expression = { $_.E.created }; Descending = $true })

  $probed = 0
  foreach ($item in $ordered) {
    if ($probed -ge 5) { break }
    $probed++
    $e = $item.E
    try {
      $langs = (Invoke-RestMethod -Uri "$ApiBase/listlangs.php?id=$($e.uuid)" -TimeoutSec 120).response.langList
    } catch { continue }
    if (@($langs) -contains $LangLower) {
      return [pscustomobject]@{ Id = $e.uuid; Title = $e.title; Build = $e.build }
    }
  }
  return $null
}

function Resolve-TtsCab([string]$UpdateId, [string]$LangLower, [string]$Arch) {
  $url = "$ApiBase/get.php?id=$UpdateId&lang=$LangLower"
  Write-Log "- Query file list for language '$LangLower'"
  $resp = Invoke-RestMethod -Uri $url -TimeoutSec 300

  $files = $resp.response.files
  if (-not $files) { throw "uupdump returned no files (update $($resp.response.updateName))" }

  $exact = "Microsoft-Windows-LanguageFeatures-TextToSpeech-$LangLower-Package-$Arch.cab"
  if ($files.PSObject.Properties.Name -contains $exact) {
    $f = $files.$exact
    return [pscustomobject]@{ Name = $exact; Sha1 = $f.sha1; Size = [int64]$f.size; Url = $f.url }
  }

  $pattern = "TextToSpeech-$LangLower-Package-$Arch\.cab$"
  $key = $files.PSObject.Properties.Name |
    Where-Object { $_ -notmatch "_[0-9a-f]{8}\.cab$" -and $_ -match $pattern } |
    Select-Object -First 1
  if (-not $key) {
    $key = $files.PSObject.Properties.Name |
      Where-Object { $_ -match $pattern } | Select-Object -First 1
  }
  if (-not $key) { throw "no TextToSpeech cab for '$LangLower' / $Arch in this update" }

  $f = $files.$key
  return [pscustomobject]@{ Name = $key; Sha1 = $f.sha1; Size = [int64]$f.size; Url = $f.url }
}

function Save-Cab([object]$Cab, [string]$Dest) {
  $partial = "$Dest.partial"
  if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
  $curl = Join-Path $env:SystemRoot "System32\curl.exe"

  if (Test-Path -LiteralPath $curl) {
    Write-Log "- Download via curl.exe: $($Cab.Name)"
    & $curl -L --fail --retry 3 --silent --show-error -o $partial $Cab.Url
    if ($LASTEXITCODE -ne 0) { throw "curl.exe exit code $LASTEXITCODE" }
  } else {
    Write-Log "- Download via Invoke-WebRequest: $($Cab.Name)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Cab.Url -OutFile $partial -UseBasicParsing -TimeoutSec 3600
  }

  $hash = (Get-FileHash -LiteralPath $partial -Algorithm SHA1).Hash.ToLowerInvariant()
  if ($hash -ne $Cab.Sha1.ToLowerInvariant()) {
    Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
    throw "SHA1 mismatch for $($Cab.Name) (expected $($Cab.Sha1), got $hash)"
  }
  Move-Item -LiteralPath $partial -Destination $Dest -Force
  Write-Log ("  saved: {0} ({1:N1} MB)" -f $Dest, ($Cab.Size / 1MB))
}

# DISM's Add-WindowsCapability -Source scans the directory for cabs using the
# CBS public-key naming convention (~31bf3856ad364e35~<arch>~~).  uupdump delivers
# plain-named cabs; create a public-key-named copy so DISM can resolve it.
$script:WinPubKey = "31bf3856ad364e35"

function Get-PublicKeyPath([string]$PlainPath) {
  $dir  = Split-Path $PlainPath -Parent
  $name = Split-Path $PlainPath -Leaf
  if ($name -match '^(.+)-Package-([^-]+)\.cab$') {
    return Join-Path $dir ("{0}-Package~{1}~{2}~~.cab" -f $Matches[1], $script:WinPubKey, $Matches[2])
  }
  return $null
}

function Ensure-PublicKeyCopy([string]$PlainPath) {
  $pubKeyPath = Get-PublicKeyPath -PlainPath $PlainPath
  if ($pubKeyPath -and -not (Test-Path -LiteralPath $pubKeyPath)) {
    Write-Log "- creating CBS public-key copy for DISM compatibility"
    Copy-Item -LiteralPath $PlainPath -Destination $pubKeyPath -Force
  }
}

function Ensure-Cab([string]$LocLower, [object]$OsInfo, [string]$CacheDir) {
  $cabName = "Microsoft-Windows-LanguageFeatures-TextToSpeech-$LocLower-Package-$($OsInfo.Arch).cab"
  $cached = Join-Path $CacheDir $cabName

  if ((Test-Path -LiteralPath $cached) -and (Get-Item -LiteralPath $cached).Length -gt 0) {
    Write-Log "- local cache: $cabName"
    Ensure-PublicKeyCopy -PlainPath $cached
    return [pscustomobject]@{ Ok = $true; Path = $cached; Name = $cabName }
  }

  try {
    $upd = Find-UupUpdateId -Build $OsInfo.Build -Arch $OsInfo.Arch -LangLower $LocLower
    Write-Log ("- update: {0} (id {1})" -f $upd.Title, $upd.Id)
    $cab = Resolve-TtsCab -UpdateId $upd.Id -LangLower $LocLower -Arch $OsInfo.Arch
    Save-Cab -Cab $cab -Dest $cached
    Ensure-PublicKeyCopy -PlainPath $cached
    return [pscustomobject]@{ Ok = $true; Path = $cached; Name = $cabName }
  } catch {
    return [pscustomobject]@{ Ok = $false; Error = $_.Exception.Message }
  }
}

function Install-TtsCapability([string]$CapabilityName, [string]$CabPath, [string]$SourceDir) {
  Write-Log "[INSTALL] $CapabilityName"

  # Main path: capability-aware install (handles staging and dependencies).
  $hr = ""
  try {
    $result = Add-WindowsCapability -Online -Name $CapabilityName -Source $SourceDir -LimitAccess -ErrorAction Stop
    if ($result.RestartNeeded) {
      Write-Log "[WARN] Restart required to finish the installation."
    }
    Write-Log "[OK] Capability installed: $CapabilityName"
    return [pscustomobject]@{ Ok = $true; HResult = "" }
  } catch {
    if ($_.Exception.Message -match "0x[0-9a-fA-F]{7,8}") { $hr = $Matches[0].ToLowerInvariant() }
    Write-Log "[ERROR] Add-WindowsCapability failed ($($hr)): $($_.Exception.Message)"
    return [pscustomobject]@{ Ok = $false; HResult = $hr }
  }
}

function Get-VoiceTokens([string]$Locale) {
  $needle = $Locale.Replace("-", "")
  $tokens = @()
  foreach ($root in @(
    "HKLM:\SOFTWARE\Microsoft\Speech\Voices\Tokens",
    "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Speech\Voices\Tokens"
  )) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    foreach ($name in (Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
      if (($name.PSChildName -replace "-", "").ToLowerInvariant().Contains($needle.ToLowerInvariant())) {
        $tokens += $name.PSChildName
      }
    }
  }
  return @($tokens | Sort-Object -Unique)
}

# ---------------------------------------------------------------- main ----

$os = Get-OsInfo
Write-Log "============================================================"
if ($List) { Write-Log "Win10/11 TTS Repair - List" }
else { Write-Log "Win10/11 TTS Repair - Check > Repair > Verify" }
Write-Log "============================================================"
Write-Log "OS: build $($os.Build).$($os.Ubr) / $($os.Arch)"
Write-Log "Target locale: $Locale"

$isAdmin = Test-Administrator

$states = $null
if ($isAdmin) {
  try { $states = Get-TtsCapabilityStates } catch { exit 1 }
}

if ($List) {
  if (-not $Catalog) { exit 0 }
  Write-Log ""
  Write-Log "Available TTS locales ([local] cached cab, [installed] capability present):"
  foreach ($loc in ($Catalog -split "\s+" | Where-Object { $_ })) {
    $marks = ""
    if ($states -and $states[$loc] -eq "Installed") { $marks += " [installed]" }
    $cabName = "Microsoft-Windows-LanguageFeatures-TextToSpeech-$($loc.ToLowerInvariant())-Package-$($os.Arch).cab"
    if ($CacheDir -and (Test-Path -LiteralPath (Join-Path $CacheDir $cabName))) { $marks += " [local]" }
    Write-Log ("  {0}{1}" -f $loc, $marks)
  }
  if (-not $states) {
    Write-Log ""
    Write-Log "[INFO] Administrator rights are needed to show installed states."
  }
  exit 0
}

if (-not $isAdmin -and -not $NoInstall) {
  Write-Log "[ERROR] Administrator permission is required."
  Write-Log 'Please right-click this script and choose "Run as administrator".'
  exit 1
}

if ($BuildOverride) { $os.Build = $BuildOverride }

$targets = @($Locale | ForEach-Object { ConvertTo-CapabilityLocale $_.Trim() } | Where-Object { $_ })

if ($NoInstall) {
  Write-Log ""
  Write-Log "[DOWNLOAD ONLY] Fetching cabs into cache (no install):"
  $failed = 0
  foreach ($loc in $targets) {
    $langLower = $loc.ToLowerInvariant()
    $res = Ensure-Cab -LocLower $langLower -OsInfo $os -CacheDir $CacheDir
    if (-not $res.Ok) {
      Write-Log "[ERROR] Could not fetch cab from uupdump: $($res.Error)"
      Write-Log "        Check network access to $ApiBase, or use /build <number> to pick another build."
      $failed++
    }
  }
  if ($failed -eq 0) { exit 0 }
  exit 1
}

Write-Log ""
Write-Log "[1/3] Initial Check..."
foreach ($loc in $targets) {
  $state = $states[$loc]
  if (-not $state) { $state = "NotPresent" }
  Write-Log ("- TTS capability {0}: {1}" -f $loc, (Format-State $state))
  foreach ($tok in (Get-VoiceTokens $loc)) {
    Write-Log ("  voice token: {0}" -f $tok)
  }
}

Write-Log ""
Write-Log "[2/3] Repair..."
$failed = 0
foreach ($loc in $targets) {
  $capName = "Language.TextToSpeech~~~$loc~0.0.1.0"
  if ($states[$loc] -eq "Installed") {
    Write-Log "- $loc already installed. Skip."
    continue
  }

  $langLower = $loc.ToLowerInvariant()
  $res = Ensure-Cab -LocLower $langLower -OsInfo $os -CacheDir $CacheDir
  if (-not $res.Ok) {
    Write-Log "[ERROR] Could not fetch cab from uupdump: $($res.Error)"
    Write-Log "        Check network access to $ApiBase, or use /build <number> to pick another build."
    $failed++
    continue
  }

  $install = Install-TtsCapability -CapabilityName $capName -CabPath $res.Path -SourceDir $CacheDir
  if (-not $install.Ok) {
    $failed++
  }
}

Write-Log ""
Write-Log "[3/3] Verify..."
$verifyFail = 0
try { $states = Get-TtsCapabilityStates } catch { exit 1 }
foreach ($loc in $targets) {
  $state = $states[$loc]
  if (-not $state) { $state = "NotPresent" }
  Write-Log ("- TTS capability {0}: {1}" -f $loc, (Format-State $state))
  if ($state -ne "Installed") { $verifyFail++ }
  $tokens = @(Get-VoiceTokens $loc)
  foreach ($tok in $tokens) {
    Write-Log ("  voice token: {0}" -f $tok)
  }
  if ($state -eq "Installed" -and $tokens.Count -eq 0) {
    Write-Log "  [WARN] capability installed but no matching voice token yet; sign out/in or reboot may be needed."
  }
}

if ($verifyFail -eq 0 -and $failed -eq 0) {
  Write-Log ""
  Write-Log "[SUCCESS] Win10/11 TTS repair completed."
  exit 0
}

Write-Log ""
Write-Log "[ERROR] Repair finished but verification failed."
Write-Log "Review the [DOWNLOAD]/[INSTALL] errors above, fix the cause, then rerun this script."
exit 1

