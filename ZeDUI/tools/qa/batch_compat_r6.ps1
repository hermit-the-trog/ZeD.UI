#Requires -Version 7.0
# ZeDUI/tools/qa/batch_compat_r6.ps1  (Nov 7 2026, QA): compatibility round 6, new popular B42 mods since Oct 29 (the survey in
# ZeDUI/workshop/compat_round6_candidates.md). The mods come from SteamCMD's workshop_download_item (no subscription on the director's
# account) at C:\steamcmd\steamapps\workshop\content\108600; with -nosteam the game reads only Zomboid\mods, so each mod folder is
# copied in for the run and removed after. Two sets (compat_r6a_mods.txt, compat_r6b_mods.txt), each through zedqa_mods_run.ps1 at
# 4K with compat_r5.txt's suite. The QA save comes back after each run (zedqa_mods_run's own snapshot).
param([string]$Sets = "a,b", [string]$Manifest = "compat_r5.txt")
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Mods = "$($env:USERPROFILE)\Zomboid\mods"
$Src = "C:\steamcmd\steamapps\workshop\content\108600"
$Ids = "3830045886 3789836701 3832114824 3508537032 3816406671 3763913359 3829853258 3833987918 3832759095 3830103302 3829124374 3830007154 3829468590 3001154607 3835479468 3834570592 3834902827 3834856444 3834889317 3834708364 3833717583" -split " "
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
$Copied = @()
try {
    foreach ($w in $Ids) {
        foreach ($d in Get-ChildItem "$Src\$w\mods" -Directory) {
            if (-not (Test-Path "$Mods\$($d.Name)")) { Copy-Item $d.FullName "$Mods\$($d.Name)" -Recurse; $Copied += "$Mods\$($d.Name)" }
        }
    }
    Write-Output "copied $($Copied.Count) mod folders"
    foreach ($set in ($Sets -split ",")) {
        $r = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\compat_r6${set}_mods.txt" -Mode fullscreen4k -Manifest "$Qa\$Manifest" 2>&1
        Write-Output "set ${set}: $(($r | Select-Object -Last 2) -join ' | ')"
    }
} finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }
        Write-Output "removed $($Copied.Count) mod folders"
    } else { Write-Output "the game is still running: the copied folders stay: $($Copied -join ', ')" }
}
