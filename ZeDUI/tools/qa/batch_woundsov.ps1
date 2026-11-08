#Requires -Version 7.0
# ZeDUI/tools/qa/batch_woundsov.ps1  (Nov 7 2026, QA): Wounds Overhaul with ZeD, ZeD last then ZeD first. The mod comes from
# SteamCMD's download (no subscription), copied into Zomboid\mods for the run and removed after.
$Qa = $PSScriptRoot; $Mods = "C:\Users\danie\Zomboid\mods"; $Src = "C:\steamcmd\steamapps\workshop\content\108600\3775026731\mods\WoundsOverhaul"
$env:ZEDQA_NOSTEAM = "1"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
$copied = $false
if (-not (Test-Path "$Mods\WoundsOverhaul")) { Copy-Item $Src "$Mods\WoundsOverhaul" -Recurse; $copied = $true }
try {
    foreach ($first in $false, $true) {
        $tag = $(if ($first) { "zedfirst" } else { "zedlast" })
        $args2 = @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", "$Qa\woundsov_mods.txt", "-Mode", "fullscreen4k", "-Manifest", "$Qa\woundsov_manifest.txt")
        if ($first) { $args2 += "-ZeDFirst" }
        "== $tag"; & pwsh @args2 2>&1 | Select-Object -Last 12
        Copy-Item "C:\Users\danie\Zomboid\console.txt" "$Qa\..\..\qa\woundsov_console_$tag.txt" -Force -ErrorAction SilentlyContinue
    }
} finally { if ($copied) { Remove-Item "$Mods\WoundsOverhaul" -Recurse -Force } }
