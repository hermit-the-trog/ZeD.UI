#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_cards.ps1  (Nov 6 2026, QA): every ticket card state at each size, the windows pinned, the pictures moved by size.
$Qa = $PSScriptRoot
$Shots = "$env:USERPROFILE\Zomboid\Screenshots"
function Move-Shots($to) { New-Item -ItemType Directory -Force "$Shots\$to" | Out-Null; Get-ChildItem $Shots -Filter "mt?_*.png" | Move-Item -Destination "$Shots\$to" -Force }
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_pin.txt:tk_cards_4k"; Move-Shots "tk_cards_4k"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_pin.txt:tk_cards_deck:1280:800"; Move-Shots "tk_cards_deck"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_large.txt:tk_cards_deck_large:1280:800"; Move-Shots "tk_cards_deck_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_pin.txt:tk_cards_720:1280:720"; Move-Shots "tk_cards_720"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_large.txt:tk_cards_720_large:1280:720"; Move-Shots "tk_cards_720_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad_large.txt:tk_pad_720_large:1280:720"; Move-Shots "tk_pad_720_large"
