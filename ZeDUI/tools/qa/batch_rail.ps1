#Requires -Version 7.0
# ZeDUI/tools/qa/batch_rail.ps1  (Nov 6 2026, QA): the Admin tab's rail and footer at 4K and at the Deck's size, the pictures kept by size. The staged copy steps aside and comes back.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Shots = "C:/Users/you/Zomboid/Screenshots"
$C = "C:/Users/you/Zomboid/Workshop/ZeD-UI/Contents"
$Aside = "C:/Users/you/Zomboid/Workshop_ZeD-UI_Contents_aside"
if (Test-Path $C) { Move-Item $C $Aside }
try {
    foreach ($r in @(@("rail_4k", ""), @("rail_deck", ":1280:800"))) {
        & "$Qa/batch_tickets.ps1" -Runs "mp_admin_rail.txt:$($r[0])$($r[1])" | Out-Null
        New-Item -ItemType Directory -Force "$Shots/$($r[0])" | Out-Null
        Get-ChildItem $Shots -Filter "zqa_arl_*.png" | Move-Item -Destination "$Shots/$($r[0])" -Force
    }
}
finally { if (Test-Path $Aside) { Move-Item $Aside $C } }
