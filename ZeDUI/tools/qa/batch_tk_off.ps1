#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_off.ps1  (Nov 6 2026, QA): step 10: the fallback, forced on a server with ZeD's server part, then for real on one without it.
$Qa = $PSScriptRoot
$Shots = "C:\Users\danie\Zomboid\Screenshots"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_off.txt:tk_off_forced:1280:800"
$Cache = "C:\Users\danie\Zomboid\zedqa_mp"; $Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"; $Lua = "C:\Users\danie\Zomboid\Lua"
Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force; Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force; Copy-Item "$Lua\ModOptions.ini" "$Keep\ModOptions.ini" -Force
Set-Content "$Lua\zedqa_tk_real.txt" "1" -NoNewline
try {
    & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -NoServerPart | ForEach-Object { Note $_ }
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_tk_off.txt" -Mp -Mode windowed -Width 1280 -Height 800 -Report "$Rep\2026-11-05_tk_off_real.md" 2>&1
    Note "tk_off_real : $(($o | Select-Object -Last 1) -join ' ')"
}
finally {
    & "$Qa\mp_server.ps1" -Stop | ForEach-Object { Note $_ }
    Remove-Item "$Lua\zedqa_tk_real.txt" -ErrorAction SilentlyContinue
    Start-Sleep 3
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force; Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force; Copy-Item "$Keep\ModOptions.ini" "$Lua\ModOptions.ini" -Force
}
New-Item -ItemType Directory -Force "$Shots\tk_off" | Out-Null; Get-ChildItem $Shots -Filter "mtf_*.png" | Move-Item -Destination "$Shots\tk_off" -Force
