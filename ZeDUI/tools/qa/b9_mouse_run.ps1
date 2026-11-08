# QA b9: run a manifest with the real-mouse helper beside it (stopped by its PID at the end)
param([string]$Manifest, [string]$Report, [string]$Mode = "fullscreen4k", [int]$Width = 1920, [int]$Height = 1080)
$env:ZEDQA_NOSTEAM = "1"
$Qa = $PSScriptRoot
Remove-Item "$env:USERPROFILE\Zomboid\Lua\zedqa_click_stop.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "25" -WindowStyle Hidden -PassThru -RedirectStandardOutput "$Qa\b9_mouse_out.txt" -RedirectStandardError "$Qa\b9_mouse_err.txt"
try { pwsh -File "$Qa\zedqa_run.ps1" -Mode $Mode -Width $Width -Height $Height -Manifest $Manifest -Report $Report }
finally { if ($h -and -not $h.HasExited) { Stop-Process -Id $h.Id -Force } }
