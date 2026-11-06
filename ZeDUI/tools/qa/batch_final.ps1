#Requires -Version 7.0
# ZeDUI/tools/qa/batch_final.ps1  (Nov 6 2026, QA): the last stretch before beta 6's upload, one after the other: the German cards again, the mods panes with the three mods they name
# copied in (with no Steam the Workshop folder isn't read), then the last full regression. Everything copied comes back out, and the director's options.ini goes back.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Opt = "C:\Users\you\Zomboid\options.ini"
$Keep = Join-Path $env:TEMP "options_lang_keep.ini"
$Shots = "C:\Users\you\Zomboid\Screenshots"
Note "final start"
Copy-Item $Opt $Keep -Force
try {
    (Get-Content $Opt) -replace '^language=.*$', "language=DE" | Set-Content $Opt -Encoding ascii
    & "$Qa\batch_tickets.ps1" -Runs "mp_lang.txt:lang_DE:1280:800" | Out-Null
    New-Item -ItemType Directory -Force "$Shots\lang_DE" | Out-Null
    foreach ($p in "mtc_", "mac_", "zqa_id2_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\lang_DE" -Force }
}
finally { Copy-Item $Keep $Opt -Force }
Note "german cards done"
$Wk = "E:\Project Zomboid\steamapps\workshop\content\108600"
$Mods = "C:\Users\you\Zomboid\mods"
$Copied = @()
foreach ($d in "3480990544\mods\Constown", "3616176188\mods\GaelGunStore", "3494108029\mods\SmartRadialMenu") {
    $to = Join-Path $Mods (Split-Path $d -Leaf)
    if (-not (Test-Path $to)) { Copy-Item "$Wk\$d" $to -Recurse; $Copied += $to }
}
try {
    $o = & "$Qa\zedqa_mods_panes_run.ps1" 2>&1
    Note "gallery panes : $(($o | Select-Object -Last 1) -join ' ')"
}
finally { foreach ($c in $Copied) { Remove-Item $c -Recurse -Force } }
Note "the copied mods taken out"
& "$Qa\batch_regression.ps1" -Tag "beta6_last" | Out-Null
Note "last regression done"
