#Requires -Version 7.0
# ZeDUI/tools/qa/batch_m1.ps1  (Nov 7 2026, QA): merge 1 of the next beta. Kills and firearm facts at 4K, the cards at 4K (Small and
# Large text) and at the Deck with Large text, then the guide ads at 1080p. -Only name,name: those runs alone. The save comes back after each run; never while the game is open.
param([string]$Only)
$OnlyList = @(if ($Only) { $Only -split "," | ForEach-Object { $_.Trim() } })
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$env:USERPROFILE\Zomboid"
$Shots = "$Z\Screenshots"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$env:USERPROFILE\ZedQaSaveKeep_m1"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Out = "$env:USERPROFILE\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\m1"
New-Item -ItemType Directory -Force $Out | Out-Null
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
function Put-SaveBack {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: the save is left alone, the copy stays at $KeepSave"; exit 1 }
    Remove-Item $Save -Recurse -Force
    if (Test-Path $Save) { Write-Output "the save could not be removed; the copy stays at $KeepSave"; exit 1 }
    Copy-Item $KeepSave $Save -Recurse
}
$runs = @(
    @{ n = "m1_kills_4k";  m = "merge1_quick.txt";   a = @{ Mode = "fullscreen4k" } },
    @{ n = "m1_cards_4k";  m = "m1_cards.txt";       a = @{ Mode = "fullscreen4k" } },
    @{ n = "m1_cards_4k_large"; m = "m1_cards_large.txt"; a = @{ Mode = "fullscreen4k" } },
    @{ n = "m1_cards_deck_large"; m = "m1_cards_large.txt"; a = @{ Mode = "windowed"; Width = 1280; Height = 800 } },
    @{ n = "guide_ads_1080"; m = "guide_ads.txt";    a = @{ Mode = "windowed"; Width = 1920; Height = 1080 } }
)
try {
    foreach ($r in $runs) {
        if ($OnlyList.Count -gt 0 -and ($OnlyList -notcontains $r.n)) { continue }
        $a = $r.a
        & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\$($r.m)" -Report "$Rep\2026-11-07_$($r.n).md" @a 2>&1 | Select-Object -Last 1
        New-Item -ItemType Directory -Force "$Out\$($r.n)" | Out-Null
        Get-ChildItem $Shots -Filter "zqa_*.png" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } | Move-Item -Destination "$Out\$($r.n)" -Force
        Copy-Item "$Z\console.txt" "$Out\$($r.n)\console.txt" -Force
        Put-SaveBack
    }
}
finally { Put-SaveBack; Remove-Item $KeepSave -Recurse -Force }
Write-Output "batch done"
