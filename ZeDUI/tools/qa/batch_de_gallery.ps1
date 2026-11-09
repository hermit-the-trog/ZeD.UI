#Requires -Version 7.0
# ZeDUI/tools/qa/batch_de_gallery.ps1  (Nov 6 2026, QA): the German cards (the first language's join met a dead character), then the gallery retake.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Opt = "$($env:USERPROFILE)\Zomboid\options.ini"
$Keep = Join-Path $env:TEMP "options_lang_keep.ini"
$Shots = "$($env:USERPROFILE)\Zomboid\Screenshots"
Copy-Item $Opt $Keep -Force
try {
    (Get-Content $Opt) -replace '^language=.*$', "language=DE" | Set-Content $Opt -Encoding ascii
    & "$Qa\batch_tickets.ps1" -Runs "mp_lang.txt:lang_DE:1280:800" | Out-Null
    foreach ($p in "mtc_", "mac_", "zqa_id2_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\lang_DE" -Force }
}
finally { Copy-Item $Keep $Opt -Force }
& "$Qa\batch_gallery.ps1"
