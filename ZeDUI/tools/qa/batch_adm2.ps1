#Requires -Version 7.0
# ZeDUI/tools/qa/batch_adm2.ps1  (Nov 6 2026, QA): mp_adm2.lua's three phases: a short ban left to lift on an empty server (E8), then the admin table across a restart.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Cache = "C:\Users\danie\Zomboid\zedqa_mp"; $Lua = "C:\Users\danie\Zomboid\Lua"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force; Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force; Copy-Item "$Lua\ModOptions.ini" "$Keep\ModOptions.ini" -Force
function Phase($n) {
    Set-Content "$Lua\zedqa_tk_phase.txt" "$n" -NoNewline
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_adm2.txt" -Mp -Mode windowed -Width 1280 -Height 800 -Report "$Rep\2026-11-05_adm2_$n.md" 2>&1
    Note "adm2 phase $n : $(($o | Select-Object -Last 1) -join ' ')"
}
function Up { & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" | ForEach-Object { Note $_ } }
function Down { & "$Qa\mp_server.ps1" -Stop | ForEach-Object { Note $_ } }
try {
    Up
    Phase 1
    Note "the server empty, waiting 80 s"
    Start-Sleep 80
    Copy-Item "$Cache\server-stdout.txt" "$Keep\server_e8.txt" -Force
    Phase 2
    Down
    Up
    Phase 3
    $z = Get-ChildItem "$Cache\Logs" -Filter "*_ZeD.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    foreach ($f in $z) { Copy-Item $f.FullName "$Keep\" -Force }
}
finally {
    Down
    Start-Sleep 3
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force; Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force; Copy-Item "$Keep\ModOptions.ini" "$Lua\ModOptions.ini" -Force
    Get-ChildItem "$Cache\Saves\Multiplayer" -Recurse -Filter "global_mod_data*" -ErrorAction SilentlyContinue | ForEach-Object { Move-Item $_.FullName "$Keep\" -Force }
    Remove-Item "$Lua\zedqa_tk_phase.txt" -ErrorAction SilentlyContinue
    Note "closed"
}
