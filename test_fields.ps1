$t = [Net.SecurityProtocolType]
$t.GetFields('NonPublic,Instance,Public,Static') | ForEach-Object { Write-Host $_.Name }