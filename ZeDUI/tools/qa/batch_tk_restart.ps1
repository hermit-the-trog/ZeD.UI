#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_restart.ps1  (Nov 5 2026, QA): Part D steps 2, 4, 7 and 11 (mp_tk_b.lua, five phases with the server stopped, started or emptied between),
# then E14 (mp_tk_big.lua). Windowed at the Deck's size, so nothing here is about layout. The server's database and settings go back after, and the save's
# ticket table is moved aside. Results land in ZeDUI/qa/tickets_20261105.txt; the end state of the database is kept in $Keep for reading.
param([switch]$NoBig)
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Cache = "C:\Users\you\Zomboid\zedqa_mp"
$Lua = "C:\Users\you\Zomboid\Lua"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
Copy-Item "$Lua\ModOptions.ini" "$Keep\ModOptions.ini" -Force
Remove-Item "$Lua\zedqa_tk_ids.txt" -ErrorAction SilentlyContinue
function ServerUp { & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" | ForEach-Object { Note $_ } }
function ServerDown { & "$Qa\mp_server.ps1" -Stop | ForEach-Object { Note $_ } }
function Phase($n) {
    Set-Content "$Lua\zedqa_tk_phase.txt" "$n" -NoNewline
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_tk_b.txt" -Mp -Mode windowed -Width 1280 -Height 800 -Report "$Rep\2026-11-05_tk_b$n.md" 2>&1
    Note "phase $n : $(($o | Select-Object -Last 1) -join ' ')"
    Copy-Item "C:\Users\you\Zomboid\console.txt" "$Keep\console_phase$n.txt" -Force
    $z = Get-ChildItem "$Cache\Logs" -Filter "*_ZeD.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($z) { Copy-Item $z.FullName "$Keep\zed_log_phase$n.txt" -Force }
}
try {
    ServerUp
    Phase 1
    ServerDown
    ServerUp
    Phase 2
    Phase 3
    ServerDown
    ServerUp
    Phase 4
    ServerDown
    Start-Sleep 4                                      # (the killed server's hold on the file takes a moment to go)
    Remove-Item "$Cache\db\zedqa.db" -Force -ErrorAction Stop
    Note "zedqa.db removed"
    ServerUp
    Phase 5
    Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa_after_phase5.db" -Force
    if (-not $NoBig) {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_tk_big.txt" -Mp -Mode windowed -Width 1280 -Height 800 -Report "$Rep\2026-11-05_tk_big.md" 2>&1
    Note "big list : $(($o | Select-Object -Last 1) -join ' ')"
    Copy-Item "C:\Users\you\Zomboid\console.txt" "$Keep\console_big.txt" -Force
    Copy-Item "$Cache\server-stdout.txt" "$Keep\server_big.txt" -Force
    }
}
finally {
    ServerDown
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Copy-Item "$Keep\ModOptions.ini" "$Lua\ModOptions.ini" -Force
    Get-ChildItem "$Cache\Saves\Multiplayer" -Recurse -Filter "global_mod_data*" -ErrorAction SilentlyContinue | ForEach-Object { Move-Item $_.FullName "$Keep\" -Force }
    Remove-Item "$Lua\zedqa_tk_phase.txt", "$Lua\zedqa_tk_ids.txt" -ErrorAction SilentlyContinue
    Note "closed"
}
