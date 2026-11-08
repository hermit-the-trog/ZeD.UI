#Requires -Version 7.0
# ZeDUI/tools/qa/batch_animals_clip.ps1  (Nov 6 2026, QA): the Animals tab's clip at 4K and at the Deck's size. The pen is built on the QA save, so the save and the options are put back after each run.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$env:USERPROFILE\Zomboid"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$env:USERPROFILE\ZedQaSaveKeep_20261106"
$Opt = "$Z\options.ini"
$KeepOpt = "$KeepSave.options.ini"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Shots = "$Z\Screenshots"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
Copy-Item $Opt $KeepOpt -Force
try {
    foreach ($r in @(@{ n = "acl_4k"; a = @{ Mode = "fullscreen4k" } }, @{ n = "acl_deck"; a = @{ Mode = "windowed"; Width = 1280; Height = 800 } })) {
        $a = $r.a
        & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\animals_clip.txt" -Report "$Rep\2026-11-06_animals_clip_$($r.n).md" @a
        Copy-Item "$Z\console.txt" "$Shots\$($r.n)_console.txt" -Force
        New-Item -ItemType Directory -Force "$Shots\$($r.n)" | Out-Null
        Get-ChildItem $Shots -Filter "zqa_acl_*.png" | Move-Item -Destination "$Shots\$($r.n)" -Force
        Remove-Item $Save -Recurse -Force
        Copy-Item $KeepSave $Save -Recurse
    }
}
finally {
    Copy-Item $KeepOpt $Opt -Force
    if (Test-Path $KeepSave) { Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue; Copy-Item $KeepSave $Save -Recurse }
    Remove-Item $KeepSave -Recurse -Force
    Remove-Item $KeepOpt -Force
}
Write-Output "done"
