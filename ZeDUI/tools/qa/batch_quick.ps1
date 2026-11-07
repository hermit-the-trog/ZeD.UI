#Requires -Version 7.0
# ZeDUI/tools/qa/batch_quick.ps1  (Nov 7 2026, QA): one manifest at 4K with the QA save put back after. -Manifest name.txt -Tag report name.
param([string]$Manifest, [string]$Tag)
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "C:\Users\you\Zomboid"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "C:\Users\you\ZedQaSaveKeep_quick"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\$Manifest" -Report "$Z\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-07_$Tag.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1 }
finally {
    # (never while a game is open: it holds the save's files, and a half-deleted save would take the copy inside it)
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: the save is left alone, the copy stays at $KeepSave"; exit 1 }
    Remove-Item $Save -Recurse -Force
    if (Test-Path $Save) { Write-Output "the save could not be removed; the copy stays at $KeepSave"; exit 1 }
    Copy-Item $KeepSave $Save -Recurse; Remove-Item $KeepSave -Recurse -Force
}
