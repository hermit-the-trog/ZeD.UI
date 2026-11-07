#Requires -Version 7.0
# ZeDUI/tools/qa/batch_hf2.ps1  (Nov 6 2026, QA): 0.3.0-beta6a: the real-mouse card close on Crafting and Ranch, then the full regression with the pcall watch on, on the code that ships.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
& pwsh -NoProfile -File "$Qa\batch_card_real.ps1"
& pwsh -NoProfile -File "$Qa\batch_regression.ps1" -Tag "beta6a_full"
Write-Output "hf2 done"
