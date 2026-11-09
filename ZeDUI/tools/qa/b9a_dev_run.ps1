# QA (Nov 8 2026): Build's batch_b9a.ps1 on the dev mod (main carries the same 9a fixes), the staged 9a held aside for the run
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b9a_dev_run.log"
$Ws = "C:\Users\danie\Zomboid\Workshop\ZeD-UI"
$env:ZEDQA_NOSTEAM = "1"
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
if (Test-Path "$Ws\Contents") { Rename-Item "$Ws\Contents" "Contents.hold"; "held aside" | Add-Content $Log }
try { & pwsh -NoProfile -File "$Qa\batch_b9a.ps1" -Report "C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-08_b9a_dev.md" 2>&1 | ForEach-Object { "$(Get-Date -Format 'HH:mm:ss') $_" | Add-Content $Log } }
finally {
    if (Test-Path "$Ws\Contents.hold") { Rename-Item "$Ws\Contents.hold" "Contents"; "put back" | Add-Content $Log }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
