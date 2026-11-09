#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b8_mods.ps1  (Nov 7 2026, QA; beta 8 mod support): three runs through zedqa_mods_run.ps1 at 4K:
#   1. Wounds Overhaul, ZeD last      (b8_wo_mods.txt,    b8_wo_manifest.txt: prelude, b8sa step aside, b8wo Health tab)
#   2. Wounds Overhaul, ZeD first     (the same, -ZeDFirst)
#   3. the seven supported mods together, ZeD last (b8_seven_mods.txt, b8_seven_manifest.txt: prelude, b8hud, b8menu, cl, cbt)
# The mods come from SteamCMD's download (no subscription), copied into Zomboid\mods for the runs and removed after (only the folders
# this script copied). The QA save comes back after each run (zedqa_mods_run's own snapshot). Zomboid\Lua\ZeD_step_aside.txt (the step-aside
# record, which the hand-back rewrites) is saved first and put back at the end, or removed if there was none. Usage: pwsh -File batch_b8_mods.ps1 [-Runs wo,seven]
param([string]$Runs = "wo,seven")
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Mods = "$env:USERPROFILE\Zomboid\mods"
$Src = "C:\steamcmd\steamapps\workshop\content\108600"
$Rec = "$env:USERPROFILE\Zomboid\Lua\ZeD_step_aside.txt"
$Ids = "3775026731 3835479468 3834708364 3832759095 3830103302 3834856444 3834889317 3834902827" -split " "
$Out = [System.IO.Path]::GetFullPath("$Qa\..\..\qa")
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
$recBak = $null
if (Test-Path $Rec) { $recBak = [System.IO.File]::ReadAllBytes($Rec) }
$Copied = @()
try {
    foreach ($w in $Ids) {
        foreach ($d in Get-ChildItem "$Src\$w\mods" -Directory) {
            if (-not (Test-Path "$Mods\$($d.Name)")) { Copy-Item $d.FullName "$Mods\$($d.Name)" -Recurse; $Copied += "$Mods\$($d.Name)" }
        }
    }
    "copied $($Copied.Count) mod folders"
    $runList = @()
    foreach ($r in ($Runs -split ",")) {
        switch ($r.Trim()) {
            "wo"    { $runList += @{ tag = "wo_zedlast";  list = "b8_wo_mods.txt";    man = "b8_wo_manifest.txt";    first = $false }
                      $runList += @{ tag = "wo_zedfirst"; list = "b8_wo_mods.txt";    man = "b8_wo_manifest.txt";    first = $true } }
            "seven" { $runList += @{ tag = "seven_zedlast"; list = "b8_seven_mods.txt"; man = "b8_seven_manifest.txt"; first = $false } }
        }
    }
    foreach ($run in $runList) {
        $a = @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", "$Qa\$($run.list)", "-Mode", "fullscreen4k", "-Manifest", "$Qa\$($run.man)")
        if ($run.first) { $a += "-ZeDFirst" }
        "== $($run.tag)"
        & pwsh @a 2>&1 | Select-Object -Last 14
        Copy-Item "$env:USERPROFILE\Zomboid\console.txt" "$Out\b8_console_$($run.tag).txt" -Force -ErrorAction SilentlyContinue
        # the record the run left (the hand-back), kept beside the console for the report, then the saved one back
        if (Test-Path $Rec) { Copy-Item $Rec "$Out\b8_step_aside_$($run.tag).txt" -Force -ErrorAction SilentlyContinue }
        if ($recBak) { [System.IO.File]::WriteAllBytes($Rec, $recBak) } elseif (Test-Path $Rec) { Remove-Item $Rec -Force }
    }
} finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }
        "removed $($Copied.Count) mod folders"
        if ($recBak) { [System.IO.File]::WriteAllBytes($Rec, $recBak) } elseif (Test-Path $Rec) { Remove-Item $Rec -Force }
    } else { "the game is still running: the copied folders stay: $($Copied -join ', ')" }
}
