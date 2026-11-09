#Requires -Version 7.0
# ZeDUI/tools/qa/batch_pool.ps1  (Nov 5 2026, QA): the game alone (ZeD off, the shim for the bridge): control, the bad call, the bad call
# with the pool's check on. Log: ZeDUI/qa/pool_repro_20261105.txt. Then the Farm and Ranch retake.
$Qa = $PSScriptRoot
$Log = [IO.Path]::GetFullPath("$Qa\..\..\qa\pool_repro_20261105.txt")
Set-Content "$env:TEMP\shim_only.txt" "ZeDQAShim" -Encoding utf8NoBOM
foreach ($m in "control", "poison", "check") {
    Set-Content "$($env:USERPROFILE)\Zomboid\Lua\zedqa_pool_mode.txt" $m
    "== $m" | Add-Content $Log
    & pwsh -NoProfile -File "$Qa\zedqa_off_run.ps1" -ModList "$env:TEMP\shim_only.txt" -Script "$Qa\zedqa_pool_repro.lua" -Tag pol -TimeoutSec 45 2>&1 | Add-Content $Log
}
Remove-Item "$($env:USERPROFILE)\Zomboid\Lua\zedqa_pool_mode.txt" -ErrorAction SilentlyContinue
& pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\gallery_farm_ranch.txt" 2>&1 | Select-Object -Last 3
