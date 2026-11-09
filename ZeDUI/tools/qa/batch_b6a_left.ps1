#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6a_left.ps1  (Nov 7 2026, QA): zedqa_b6a_left.lua at 4K, then at the Deck's size, with the real-mouse helper beside it. The save comes back after each run.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$($env:USERPROFILE)\Zomboid"
$Lua = "$Z\Lua"
$Shots = "$Z\Screenshots"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$($env:USERPROFILE)\ZedQaSaveKeep_b6l"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
try {
    foreach ($r in @(@{ n = "4k"; a = @{ Mode = "fullscreen4k" } }, @{ n = "deck"; a = @{ Mode = "windowed"; Width = 1280; Height = 800 } })) {
        Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
        $h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "6" -WindowStyle Hidden -PassThru
        $a = $r.a
        try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\b6a_left.txt" -Report "$Rep\2026-11-07_b6a_left_$($r.n).md" @a 2>&1 | Select-Object -Last 1 }
        finally {
            Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
            for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
            Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Force "$Shots\b6l_$($r.n)" | Out-Null
        Get-ChildItem $Shots -Filter "zqa_b6l_*.png" | Move-Item -Destination "$Shots\b6l_$($r.n)" -Force
        Remove-Item $Save -Recurse -Force; Copy-Item $KeepSave $Save -Recurse
    }
}
finally {
    if (Test-Path $KeepSave) { Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue; Copy-Item $KeepSave $Save -Recurse; Remove-Item $KeepSave -Recurse -Force }
}
