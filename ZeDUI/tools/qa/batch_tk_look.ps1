#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tk_look.ps1  (Nov 6 2026, QA): the pop-ups, Find, where a card opens, every theme and accent on the cards (mp_tk_look.lua).
$Qa = $PSScriptRoot
$Shots = "C:\Users\you\Zomboid\Screenshots"
Copy-Item "$Qa\mp_ticket_cards.lua" "C:\Users\you\Zomboid\Lua\zedqa_tk_states.lua" -Force
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_look.txt:tk_look:1280:800"
New-Item -ItemType Directory -Force "$Shots\tk_look" | Out-Null; Get-ChildItem $Shots -Filter "mt?_*.png" | Move-Item -Destination "$Shots\tk_look" -Force
Remove-Item "C:\Users\you\Zomboid\Lua\zedqa_tk_states.lua" -ErrorAction SilentlyContinue
