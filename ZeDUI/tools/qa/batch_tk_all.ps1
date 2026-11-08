#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_all.ps1  (Nov 5 2026, QA): the restart pass again, then the controller walk and every card state at each size, the pictures moved by size.
$Qa = $PSScriptRoot
$Shots = "$env:USERPROFILE\Zomboid\Screenshots"
& "$Qa\batch_tk_restart.ps1" -NoBig
function Move-Shots($to) { New-Item -ItemType Directory -Force "$Shots\$to" | Out-Null; Get-ChildItem $Shots -Filter "mt?_*.png" | Move-Item -Destination "$Shots\$to" -Force }
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad.txt:tk_pad:1280:800"; Move-Shots "tk_pad_deck"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards.txt:tk_cards_4k"; Move-Shots "tk_cards_4k"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards.txt:tk_cards_deck:1280:800"; Move-Shots "tk_cards_deck"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_large.txt:tk_cards_deck_large:1280:800"; Move-Shots "tk_cards_deck_large"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards.txt:tk_cards_720:1280:720"; Move-Shots "tk_cards_720"
& "$Qa\batch_tickets.ps1" -Runs "mp_ticket_cards_large.txt:tk_cards_720_large:1280:720"; Move-Shots "tk_cards_720_large"
