#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b9a.ps1  (Nov 8 2026, hotfix 0.3.0-beta9a): the hotfix's nine scripts (b9a.txt) and the dual pin
# script with the real-mouse helper beside them, as batch_drag.ps1 does. Run it at 4K, then at the Deck; the scripts
# read the screen size, they never set it. Check Lua\zedqa.lock first; never while the game is already running.
param([string]$Report = "")
$Qa = $PSScriptRoot
$Lua = "C:\Users\you\Zomboid\Lua"
if (-not $Report) { $Report = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression\$(Get-Date -Format yyyy-MM-dd_HHmm)_b9a.md") }
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "30" -WindowStyle Hidden -PassThru
try { & "$Qa\zedqa_run.ps1" -Manifest "$Qa\b9a.txt" -Report $Report }
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
}
