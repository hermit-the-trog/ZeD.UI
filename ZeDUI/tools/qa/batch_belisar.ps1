#Requires -Version 7.0
# ZeDUI/tools/qa/batch_belisar.ps1  (Nov 8 2026, QA; Belisar's report): Stay With Me (3800989007), NeatUI Equipment (3790656296, with
# NeatUI Framework 3508537032) and Minimal Sidebar (3642084851), from SteamCMD's download (no subscription), copied into Zomboid\mods for
# the runs and removed after (only the folders this script copied). Runs (pwsh -File batch_belisar.ps1 [-Runs menu,game,base]):
#   menu  main menu, the three + ZeD last: zedqa_belisar_menu.lua (the companion design screen)  -> qa/belisar_menu.txt
#   game  in game at 4K, ZeD last: belisar_manifest.txt                                          -> qa/belisar_game.txt
#   base  in game at 4K, ZeD off (ZeDQAShim's bridge): belisar_manifest_nozed.txt                -> qa/belisar_base.txt
# $env:ZEDQA_NOSTEAM = "1". Zomboid\Lua\ZeD_step_aside.txt is saved first and put back after each run.
param([string]$Runs = "menu,game,base")
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Mods = "$env:USERPROFILE\Zomboid\mods"
$Src = "C:\steamcmd\steamapps\workshop\content\108600"
$Rec = "$env:USERPROFILE\Zomboid\Lua\ZeD_step_aside.txt"
$Con = "$env:USERPROFILE\Zomboid\console.txt"
$Ids = "3800989007 3790656296 3508537032 3642084851" -split " "
$Out = [System.IO.Path]::GetFullPath("$Qa\..\..\qa")
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
$recBak = $null
if (Test-Path $Rec) { $recBak = [System.IO.File]::ReadAllBytes($Rec) }
function Keep($tag) {
    $sd = "$env:USERPROFILE\AppData\Local\Temp\bel\$tag"; New-Item -ItemType Directory -Force $sd | Out-Null
    Copy-Item "$env:USERPROFILE\Zomboid\Screenshots\zqa_bel*.png" $sd -Force -ErrorAction SilentlyContinue
    # the lines that matter from the console, for the report
    $pat = 'ZEDQA (bel|belm|pre|pnw)|Step aside|ERROR|Exception|Bridge|NEQ|NeatUI|Minimal|attempted index|nil'
    Get-Content $Con -ErrorAction SilentlyContinue | ForEach-Object { $_ -replace "`0", "" } | Where-Object { $_ -match $pat } | Select-Object -First 400 | Set-Content "$Out\belisar_console_$tag.txt"
    if (Test-Path $Rec) { Copy-Item $Rec "$Out\belisar_step_aside_$tag.txt" -Force -ErrorAction SilentlyContinue }
    if ($recBak) { [System.IO.File]::WriteAllBytes($Rec, $recBak) } elseif (Test-Path $Rec) { Remove-Item $Rec -Force }
}
$Copied = @()
try {
    foreach ($w in $Ids) {
        foreach ($d in Get-ChildItem "$Src\$w\mods" -Directory) {
            if (-not (Test-Path "$Mods\$($d.Name)")) { Copy-Item $d.FullName "$Mods\$($d.Name)" -Recurse; $Copied += "$Mods\$($d.Name)" }
        }
    }
    "copied $($Copied.Count) mod folders"
    foreach ($r in ($Runs -split ",")) {
        switch ($r.Trim()) {
            "menu" {
                "== menu"
                & pwsh -NoProfile -File "$Qa\zedqa_menu_mods_run.ps1" -ModList "$Qa\belisar_mods.txt" -Script "$Qa\zedqa_belisar_menu.lua" -Tag belm -TimeoutSec 240 2>&1 | Tee-Object "$Out\belisar_menu.txt" | Select-Object -Last 40
                Keep "menu"
            }
            "game" {
                "== game"
                & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\belisar_mods.txt" -Mode fullscreen4k -Manifest "$Qa\belisar_manifest.txt" 2>&1 | Tee-Object "$Out\belisar_game.txt" | Select-Object -Last 30
                Keep "game"
            }
            "base" {
                "== base"
                & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\belisar_mods_nozed.txt" -NoZeD -Mode fullscreen4k -Manifest "$Qa\belisar_manifest_nozed.txt" 2>&1 | Tee-Object "$Out\belisar_base.txt" | Select-Object -Last 30
                Keep "base"
            }
        }
    }
} finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }
        "removed $($Copied.Count) mod folders"
        if ($recBak) { [System.IO.File]::WriteAllBytes($Rec, $recBak) } elseif (Test-Path $Rec) { Remove-Item $Rec -Force }
    } else { "the game is still running: the copied folders stay: $($Copied -join ', ')" }
}
