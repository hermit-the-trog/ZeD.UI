#Requires -Version 7.0
# ZeDUI/tools/qa/batch_minsidebar.ps1: Minimal Sidebar (3642084851) from SteamCMD's download (no subscription), copied into
# Zomboid\mods for the run and removed after (only the folders this script copied). One run in game at 4K, ZeD last:
# minsidebar_manifest.txt (zedqa_minsidebar.lua, tag msb)  -> qa/minsidebar_game.txt, console lines in qa/minsidebar_console.txt
# $env:ZEDQA_NOSTEAM = "1".
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Mods = "C:\Users\you\Zomboid\mods"
$Src = "C:\steamcmd\steamapps\workshop\content\108600\3642084851"
$Con = "C:\Users\you\Zomboid\console.txt"
$Out = [System.IO.Path]::GetFullPath("$Qa\..\..\qa")
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
$Copied = @()
try {
    foreach ($d in Get-ChildItem "$Src\mods" -Directory) {
        if (-not (Test-Path "$Mods\$($d.Name)")) { Copy-Item $d.FullName "$Mods\$($d.Name)" -Recurse; $Copied += "$Mods\$($d.Name)" }
    }
    "copied $($Copied.Count) mod folders"
    & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\minsidebar_mods.txt" -Mode fullscreen4k -Manifest "$Qa\minsidebar_manifest.txt" 2>&1 | Tee-Object "$Out\minsidebar_game.txt" | Select-Object -Last 40
    $pat = 'ZEDQA (msb|pre|pnw)|ModSupport: Minimal|ERROR|Exception|attempted index|Minimal|belt'
    Get-Content $Con -ErrorAction SilentlyContinue | ForEach-Object { $_ -replace "`0", "" } | Where-Object { $_ -match $pat } | Select-Object -First 400 | Set-Content "$Out\minsidebar_console.txt"
} finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }
        "removed $($Copied.Count) mod folders"
    } else { "the game is still running: the copied folders stay: $($Copied -join ', ')" }
}
