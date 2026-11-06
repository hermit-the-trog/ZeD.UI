#Requires -Version 7.0
# ZeDUI/tools/qa/batch_adm_cards.ps1  (Nov 6 2026, QA): every Admin tab and claims card at each size, the windows pinned, the pictures moved by size.
$Qa = $PSScriptRoot
$Shots = "C:\Users\you\Zomboid\Screenshots"
function Move-Shots($to) { New-Item -ItemType Directory -Force "$Shots\$to" | Out-Null; Get-ChildItem $Shots -Filter "m[ac]c_*.png" | Move-Item -Destination "$Shots\$to" -Force }
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_pin.txt:adm_cards_4k"; Move-Shots "adm_cards_4k"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_pin.txt:adm_cards_deck:1280:800"; Move-Shots "adm_cards_deck"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_large.txt:adm_cards_deck_large:1280:800"; Move-Shots "adm_cards_deck_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_pin.txt:adm_cards_720:1280:720"; Move-Shots "adm_cards_720"
& "$Qa\batch_tickets.ps1" -Runs "mp_adm_cards_large.txt:adm_cards_720_large:1280:720"; Move-Shots "adm_cards_720_large"
