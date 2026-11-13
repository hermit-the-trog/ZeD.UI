#Requires -Version 7.0
# ZeDUI/tools/qa/batch_summercar.ps1  (Nov 12 2026, Build, punch list 177): Maskarad's Summer Car's engine window beside
# ZeD's Vehicle tab (zedqa_summercar.lua). Three runs: ZeD last and ZeD first at fullscreen 4K, then ZeD last windowed
# 1280 x 800 (the Deck size). The mod comes from SteamCMD's download (no subscription), copied into Zomboid\mods for
# the runs and removed after (only if this script copied it). The real-mouse helper runs alongside, so never while the
# director uses the machine. The ZeD-off control is QA's zedqa_msc_run.ps1 -Run 2 (the mod's normal look).
$Qa = $PSScriptRoot; $Mods = "$($env:USERPROFILE)\Zomboid\mods"; $Lua = "$($env:USERPROFILE)\Zomboid\Lua"
$Src = "C:\steamcmd\steamapps\workshop\content\108600\3790160840\mods\MaskaradsSummerCar"
$env:ZEDQA_NOSTEAM = "1"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
if (Test-Path "$Lua\zedqa.lock") { "the QA lock is held, stop"; exit 2 }
if (-not (Test-Path $Src)) { "Summer Car's copy is not at $Src (SteamCMD: workshop_download_item 108600 3790160840)"; exit 2 }
$copied = $false
if (-not (Test-Path "$Mods\MaskaradsSummerCar")) { Copy-Item $Src "$Mods\MaskaradsSummerCar" -Recurse; $copied = $true }
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "45" -WindowStyle Hidden -PassThru
try {
    $runs = @(
        @{ tag = "zedlast_4k"; args = @("-Mode", "fullscreen4k") },
        @{ tag = "zedfirst_4k"; args = @("-Mode", "fullscreen4k", "-ZeDFirst") },
        @{ tag = "zedlast_deck"; args = @("-Mode", "windowed", "-Width", "1280", "-Height", "800") }
    )
    foreach ($r in $runs) {
        $a = @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", "$Qa\summercar_mods.txt", "-Manifest", "$Qa\summercar_manifest.txt") + $r.args
        "== $($r.tag)"; & pwsh @a 2>&1 | Select-Object -Last 12
        Copy-Item "$($env:USERPROFILE)\Zomboid\console.txt" "$Qa\..\..\qa\summercar_console_$($r.tag).txt" -Force -ErrorAction SilentlyContinue
    }
} finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    if (-not $h.HasExited) { Stop-Process -Id $h.Id -Force }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
    if ($copied) { Remove-Item "$Mods\MaskaradsSummerCar" -Recurse -Force }
}
