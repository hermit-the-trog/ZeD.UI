#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b7.ps1  (Nov 7 2026, QA): Build's 44df3931 at 4K. The odometers (dash_odo_a.txt, then a relaunch on
# the same save for dash_odo_b.txt), the house ad in EN, DE, FR and TH (options.ini's language set per run and put back),
# then every dash design's bulb check (dash_bulbs.txt). The save comes back after each part; never while the game is open.
param([string]$Only)
$OnlyList = @(if ($Only) { $Only -split "," | ForEach-Object { $_.Trim() } })
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$($env:USERPROFILE)\Zomboid"
$Shots = "$Z\Screenshots"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$($env:USERPROFILE)\ZedQaSaveKeep_b7"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Out = "$($env:USERPROFILE)\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\b7"
$ini = "$Z\options.ini"
New-Item -ItemType Directory -Force $Out | Out-Null
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
function Put-SaveBack {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: the save is left alone, the copy stays at $KeepSave"; exit 1 }
    Remove-Item $Save -Recurse -Force
    if (Test-Path $Save) { Write-Output "the save could not be removed; the copy stays at $KeepSave"; exit 1 }
    Copy-Item $KeepSave $Save -Recurse
}
function Run($name, $manifest) {
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\$manifest" -Report "$Rep\2026-11-07_$name.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1
    New-Item -ItemType Directory -Force "$Out\$name" | Out-Null
    Get-ChildItem $Shots -Filter "zqa_*.png" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-40) } | Move-Item -Destination "$Out\$name" -Force
    Copy-Item "$Z\console.txt" "$Out\$name\console.txt" -Force
}
function Want($n) { return ($OnlyList.Count -eq 0 -or $OnlyList -contains $n) }
try {
    if (Want "odo") {
        Remove-Item "$Z\Lua\zedqa_odo_persist.txt" -ErrorAction SilentlyContinue
        Run "b7_dash_odo" "dash_odo_a.txt"
        Run "b7_dash_odo_reload" "dash_odo_b.txt"
        Put-SaveBack
    }
    if (Want "house") {
        $text = Get-Content -Raw $ini
        $was = if ($text -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
        try {
            foreach ($l in @("EN", "DE", "FR", "TH")) {
                $now = Get-Content -Raw $ini
                Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$l") -NoNewline
                Run "b7_house_ad_$l" "house_ad.txt"
                Put-SaveBack
            }
        }
        finally {
            $now = Get-Content -Raw $ini
            Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$was") -NoNewline
            Write-Output "language put back to $was"
        }
    }
    if (Want "bulbs") {
        Run "b7_dash_bulbs" "dash_bulbs.txt"
        Put-SaveBack
    }
}
finally { Put-SaveBack; Remove-Item $KeepSave -Recurse -Force }
Write-Output "batch done"
