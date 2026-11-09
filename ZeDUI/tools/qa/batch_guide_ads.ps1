#Requires -Version 7.0
# ZeDUI/tools/qa/batch_guide_ads.ps1  (Nov 7 2026, QA; punch list 98): guide_ads.txt at 4K 1.75x, at 1080p windowed,
# then in German at 4K (options.ini's language set for the run and put back). The QA save is put back after.
# -Only1080: the 1080p pass alone.
param([switch]$Only1080)
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$($env:USERPROFILE)\Zomboid"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$($env:USERPROFILE)\ZedQaSaveKeep_gad"
$Shots = "$Z\Screenshots"
$Out = "$($env:USERPROFILE)\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\gad"
$Reg = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
New-Item -ItemType Directory -Force $Out | Out-Null
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
$ini = "$Z\options.ini"
function Put-SaveBack {
    # (never while a game is open: it holds the save's files, and a half-deleted save would take the copy inside it)
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: the save is left alone, the copy stays at $KeepSave"; exit 1 }
    Remove-Item $Save -Recurse -Force
    if (Test-Path $Save) { Write-Output "the save could not be removed; the copy stays at $KeepSave"; exit 1 }
    Copy-Item $KeepSave $Save -Recurse
}
try {
    if (-not $Only1080) {
        & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\guide_ads.txt" -Report "$Reg\2026-11-07_guide_ads_4k.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1
        Copy-Item "$Shots\zqa_gad_*.png" $Out -Force; Copy-Item "$Z\console.txt" "$Out\console_4k.txt" -Force
        Put-SaveBack
    }
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\guide_ads.txt" -Report "$Reg\2026-11-07_guide_ads_1080.md" -Mode windowed -Width 1920 -Height 1080 2>&1 | Select-Object -Last 1
    Copy-Item "$Shots\zqa_gad_*.png" $Out -Force; Copy-Item "$Z\console.txt" "$Out\console_1080.txt" -Force
    if ($Only1080) { return }
    Put-SaveBack
    $text = Get-Content -Raw $ini
    $was = if ($text -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
    try {
        Set-Content -Path $ini -Value ($text -replace '(?m)^language=.*$', "language=DE") -NoNewline
        & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\guide_ads.txt" -Report "$Reg\2026-11-07_guide_ads_DE.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1
        Copy-Item "$Shots\zqa_gad_*.png" $Out -Force; Copy-Item "$Z\console.txt" "$Out\console_DE.txt" -Force
    }
    finally {
        $now = Get-Content -Raw $ini
        Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$was") -NoNewline
        Write-Output "language put back to $was"
    }
}
finally { Put-SaveBack; Remove-Item $KeepSave -Recurse -Force }
Write-Output "batch done"
