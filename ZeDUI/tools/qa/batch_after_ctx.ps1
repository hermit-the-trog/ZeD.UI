#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after_ctx.ps1  (Nov 6 2026, QA): the context menu scripts and the outline, the auto-collapse and the real drag, all with the real-mouse helper on and no Steam.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Lua = "C:\Users\danie\Zomboid\Lua"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "14" -WindowStyle Hidden -PassThru
try {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\after_ctx.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_after_ctx4.md")) 2>&1
    Note "after ctx2 : $(($o | Select-Object -Last 1) -join ' ')"
}
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
}
