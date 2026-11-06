#Requires -Version 7.0
# ZeDUI/tools/qa/batch_final.ps1  (Nov 5 2026, QA): after batch_verify: Hair and beard with the bridge's pcall watch on, Hands-On + ZeD
# and then Hands-On + the shim with ZeD off; the Ranch page's controller check; the server's second pass.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
$Pcw = [IO.Path]::GetFullPath("$Qa\..\..\qa\pcallwatch_20261105.txt")
$Flag = "C:\Users\danie\Zomboid\Lua\zedqa_pcallwatch.txt"
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
Set-Content $Flag "on"
try {
    & "$Qa\hb_bisect.ps1" -Sets @("HandsOnInteractionsIso")
    "== Hands-On + ZeD_UI" | Add-Content $Pcw
    Select-String -Path "C:\Users\danie\Zomboid\console.txt" -Pattern "pcw " -SimpleMatch | ForEach-Object { $_.Line } | Add-Content $Pcw
    Set-Content "$env:TEMP\hands_only.txt" @("ZeDQAShim", "HandsOnInteractionsIso") -Encoding utf8NoBOM
    $o = & pwsh -NoProfile -File "$Qa\zedqa_off_run.ps1" -ModList "$env:TEMP\hands_only.txt" -Script "$Qa\zedqa_hands_off.lua" -Tag hof -TimeoutSec 60 2>&1
    $o | Set-Content ([IO.Path]::GetFullPath("$Qa\..\..\qa\hands_off_20261105.log"))
    "== Hands-On + shim, ZeD off" | Add-Content $Pcw
    Select-String -Path "C:\Users\danie\Zomboid\console.txt" -Pattern "pcw " -SimpleMatch | ForEach-Object { $_.Line } | Add-Content $Pcw
    Note "pcall watch done: $(@(Get-Content $Pcw).Count) lines"
}
finally { Remove-Item $Flag -ErrorAction SilentlyContinue }
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\ranch_pad.txt" 2>&1
Note "ranch pad: $(($o | Select-Object -Last 2) -join ' | ')"
& "$Qa\batch_mp.ps1"
