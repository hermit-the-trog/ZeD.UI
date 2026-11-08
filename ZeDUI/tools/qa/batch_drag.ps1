#Requires -Version 7.0
# ZeDUI/tools/qa/batch_drag.ps1  (Nov 6 2026, QA): zedqa_drag_real.lua with the real-mouse helper beside it.
$Qa = $PSScriptRoot
$Lua = "$env:USERPROFILE\Zomboid\Lua"
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "6" -WindowStyle Hidden -PassThru
try { & "$Qa\zedqa_run.ps1" -Manifest "$Qa\drag_real.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_drag_real.md")) }
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
}
