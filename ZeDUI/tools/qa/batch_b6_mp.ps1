#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6_stage.ps1  (Nov 6 2026, QA): the German cards with the console kept, and the multiplayer pictures, on the last code.
# Nothing is staged here.
$Qa = $PSScriptRoot
$Root = "C:\Users\you\Zomboid\mods\ZeD-UI"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\tickets_20261105.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Wk = "E:\Project Zomboid\steamapps\workshop\content\108600"
$Mods = "C:\Users\you\Zomboid\mods"
$Shots = "C:\Users\you\Zomboid\Screenshots"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
$Opt = "C:\Users\you\Zomboid\options.ini"
$KeepOpt = Join-Path $env:TEMP "options_lang_keep.ini"
Copy-Item $Opt $KeepOpt -Force
try {
    (Get-Content $Opt) -replace '^language=.*$', "language=DE" | Set-Content $Opt -Encoding ascii
    & "$Qa\batch_tickets.ps1" -Runs "mp_lang.txt:lang_DE:1280:800" | Out-Null
    Copy-Item "C:\Users\you\Zomboid\console.txt" "$Keep\console_de.txt" -Force
    New-Item -ItemType Directory -Force "$Shots\lang_DE" | Out-Null
    foreach ($p in "mtc_", "mac_", "zqa_id2_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\lang_DE" -Force }
}
finally { Copy-Item $KeepOpt $Opt -Force }
Note "german cards done"
& "$Qa\batch_tickets.ps1" -Runs "mp_gallery_b6.txt:mps_b6" | Out-Null
Note "mp surfaces done"
