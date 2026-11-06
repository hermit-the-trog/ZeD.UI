#Requires -Version 7.0
# ZeDUI/tools/qa/batch_pre_reg.ps1  (Nov 6 2026, QA): the admin table across a restart, then the ticket pad walk, before the full regression.
$Qa = $PSScriptRoot
& "$Qa\batch_adm2.ps1" -From2
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad.txt:tk_pad3:1280:800"
