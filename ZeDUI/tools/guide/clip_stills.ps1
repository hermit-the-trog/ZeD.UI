param([string]$Out = "$env:TEMP\zed_guide_stills")
# Pulls five frames from each of the game's survival guide clips (15, 35, 50, 65 and 85 percent through)
# with RAD Video Tools, for make_stills.py to pick the clearest. Run from PowerShell (the encoder hangs under Git Bash).
$src = "E:\Project Zomboid\steamapps\common\ProjectZomboid\media\videos\survival_guide"
$rad = "C:\RADVideoTools\radvideo64.exe"
New-Item -ItemType Directory -Force $Out | Out-Null
foreach ($f in Get-ChildItem $src -Filter *.bik) {
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    $frames = [BitConverter]::ToUInt32($b, 8)
    $picks = @(0.15, 0.35, 0.50, 0.65, 0.85) | ForEach-Object { [math]::Max(1, [math]::Round($frames * $_)) }
    $list = ($picks -join ";")
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $p = Start-Process -FilePath $rad -ArgumentList @("BinkConv", "`"$($f.FullName)`"", "`"$Out\$base`_.png`"", "/Include($list)", "/O", "/#") -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit(60000)) { $p.Kill(); "TIMEOUT $base" }
}
"done: " + (Get-ChildItem $Out -Filter *.png).Count + " frames"
