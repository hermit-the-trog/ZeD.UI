#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b8_console_typed.ps1 (Nov 8 2026, QA): the Lua console's typed line after Build's 5ac83525, ZeD alone, twice:
# 4K fullscreen and a 1280x800 window. Screenshots are copied to Temp\bel\console_<mode> after each run.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Rep = [System.IO.Path]::GetFullPath("$Qa\..\..\qa")
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running, stop"; exit 2 }
foreach ($r in @(@{ n = "4k"; a = @("-Mode", "fullscreen4k", "-Report", "$Rep\b8_console_4k.md") }, @{ n = "deck"; a = @("-Mode", "windowed", "-Width", "1280", "-Height", "800", "-Report", "$Rep\b8_console_deck.md") })) {
    "== $($r.n)"
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\b8_console_manifest.txt" @($r.a) 2>&1 | Select-Object -Last 16
    $sd = "$env:USERPROFILE\AppData\Local\Temp\bel\console_$($r.n)"; New-Item -ItemType Directory -Force $sd | Out-Null
    Copy-Item "$env:USERPROFILE\Zomboid\Screenshots\zqa_b8dc_*.png" $sd -Force -ErrorAction SilentlyContinue
}
