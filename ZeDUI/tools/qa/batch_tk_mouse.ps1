#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_mouse.ps1  (Nov 6 2026, QA): mp_tk_mouse.lua with the real-mouse helper running beside it.
$Qa = $PSScriptRoot
$Shots = "$env:USERPROFILE\Zomboid\Screenshots"
$Lua = "$env:USERPROFILE\Zomboid\Lua"
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "8" -WindowStyle Hidden -PassThru
try { & "$Qa\batch_tickets.ps1" -Runs "mp_tk_mouse.txt:tk_mouse:1280:800" }
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force "$Shots\tk_mouse" | Out-Null; Get-ChildItem $Shots -Filter "mtm_*.png" | Move-Item -Destination "$Shots\tk_mouse" -Force
