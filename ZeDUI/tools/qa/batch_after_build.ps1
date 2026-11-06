#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after_build.ps1  (Nov 6 2026, QA): the restart checks, then the cards.
$Qa = $PSScriptRoot
& "$Qa\batch_adm2.ps1"
& "$Qa\batch_adm_cards.ps1"
