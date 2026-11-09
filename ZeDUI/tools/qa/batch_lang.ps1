#Requires -Version 7.0
# ZeDUI/tools/qa/batch_lang.ps1  (Nov 6 2026, QA): the ticket, Admin and Identity cards in German (the long words) and Russian (the wide ones), at the Deck's size. The director's
# options.ini goes back after; the pictures are moved by language.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Opt = "$($env:USERPROFILE)\Zomboid\options.ini"
$Keep = Join-Path $env:TEMP "options_lang_keep.ini"
$Shots = "$($env:USERPROFILE)\Zomboid\Screenshots"
Copy-Item $Opt $Keep -Force
try {
    foreach ($lang in "DE", "RU") {
        (Get-Content $Opt) -replace '^language=.*$', "language=$lang" | Set-Content $Opt -Encoding ascii
        & "$Qa\batch_tickets.ps1" -Runs "mp_lang.txt:lang_${lang}:1280:800" | Out-Null
        New-Item -ItemType Directory -Force "$Shots\lang_$lang" | Out-Null
        foreach ($p in "mtc_", "mac_", "zqa_id2_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\lang_$lang" -Force }
        Copy-Item $Keep $Opt -Force
    }
}
finally { Copy-Item $Keep $Opt -Force }
& "$Qa\batch_after_ctx.ps1"
