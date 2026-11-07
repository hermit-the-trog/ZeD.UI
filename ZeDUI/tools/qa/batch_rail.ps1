#Requires -Version 7.0
# ZeDUI/tools/qa/batch_rail.ps1  (Nov 6 2026, QA): the Admin tab's rail and footer at the Deck's size and at 4K. The staged copy steps aside and comes back.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$C = "C:/Users/danie/Zomboid/Workshop/ZeD-UI/Contents"
$Aside = "C:/Users/danie/Zomboid/Workshop_ZeD-UI_Contents_aside"
if (Test-Path $C) { Move-Item $C $Aside }
try { & "$Qa/batch_tickets.ps1" -Runs "mp_admin_rail.txt:rail" | Out-Null }
finally { if (Test-Path $Aside) { Move-Item $Aside $C } }
