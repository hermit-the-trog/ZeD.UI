#Requires -Version 7.0
# ZeDUI/tools/qa/batch_gallery3.ps1  (Nov 6 2026, QA): the gallery pictures the morning's retake didn't cover, on the last code: Farm and Ranch, the Simple pages, the multiplayer surfaces.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
foreach ($m in "gallery_farm_ranch", "gallery_beta") {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\$m.txt" -Report "$Rep\2026-11-06_b6_$m.md" 2>&1
    Note "$m : $(($o | Select-Object -Last 1) -join ' ')"
}
& "$Qa\batch_tickets.ps1" -Runs "mp_gallery_b6.txt:mps_b6" | Out-Null
Note "mp surfaces done"
