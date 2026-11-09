#Requires -Version 7.0
# ZeDUI/tools/qa/batch_adm_cards.ps1  (Nov 6 2026, QA): every admin, claims, log, community and extras card at each size, the windows pinned, the pictures moved by size; then
# the ticket pad walk again for Build's landing fix.
$Qa = $PSScriptRoot
$Shots = "$($env:USERPROFILE)\Zomboid\Screenshots"
function Move-Shots($to) { New-Item -ItemType Directory -Force "$Shots\$to" | Out-Null; foreach ($p in "mac_", "mcc_", "mlc_", "mcm_", "mxc_", "mtp_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\$to" -Force } }
$Set = "PlayerSafehouse=true;AdminSafehouse=true;War=true"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_large.txt:adm_cards_deck_large:1280:800" -Set $Set; Move-Shots "adm_cards_deck_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_large.txt:adm_cards_720_large:1280:720" -Set $Set; Move-Shots "adm_cards_720_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_pin.txt:adm_cards_4k" -Set $Set; Move-Shots "adm_cards_4k"
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad.txt:tk_pad3:1280:800" -Set $Set; Move-Shots "tk_pad3"
