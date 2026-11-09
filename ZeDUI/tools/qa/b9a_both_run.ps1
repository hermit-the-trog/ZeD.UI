# QA (Nov 8 2026): the 9a true staged check (fix scripts only, no pnw: it pins the windows the scripts stage) at 4K, then on the Deck (1280x800); lines to b9a_both_run.log as they happen
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b9a_both_run.log"
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
& pwsh -NoProfile -File "$Qa\batch_stage_true_b9a.ps1" -Tag 4k 2>&1 | ForEach-Object { "$(Get-Date -Format 'HH:mm:ss') 4k $_" | Add-Content $Log }
& pwsh -NoProfile -File "$Qa\batch_stage_true_b9a.ps1" -Tag deck -Width 1280 -Height 800 2>&1 | ForEach-Object { "$(Get-Date -Format 'HH:mm:ss') deck $_" | Add-Content $Log }
& pwsh -NoProfile -File "$Qa\pzrestorewin.ps1" 2>&1 | ForEach-Object { "$(Get-Date -Format 'HH:mm:ss') $_" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
