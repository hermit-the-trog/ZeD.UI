#Requires -Version 7.0
# ZeDUI/tools/qa/batch_repair.ps1  (Nov 6 2026, QA): the once-only Vanilla Access repair across two launches, windowed. The director's ModOptions.ini and the mark file come back after.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$env:ZEDQA_KEEP_ADDITIONS = "1"
$Lua = "C:\Users\danie\Zomboid\Lua"
$MO = "$Lua\ModOptions.ini"
$Mark = "$Lua\ZeD_presetRepair.txt"
$Keep = Join-Path $env:TEMP "zedqa_repair_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item $MO "$Keep\ModOptions.ini" -Force
if (Test-Path $Mark) { Copy-Item $Mark "$Keep\mark.txt" -Force }
$Rep = "C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression"
try {
    $ids = "ammoBox", "readMarks", "readNext", "dimRead", "dashLamps", "moodleNotices", "messagesCatch", "messagesToast", "putBack", "sandboxInGame", "loadouts", "haloBubble"
    $vals = @{ additionsPreset = 4; restock = 3; devicesStyle = 2; watchStyle = 2; dashStyle = 2; guideStyle = 2; modsStyle = 2; identityStyle = 1 }
    foreach ($i in $ids) { $vals[$i] = 2 }
    $l = Get-Content $MO | Where-Object { $_ -ne "" -and -not ($_ -match '\|ZeD_UI\|([^|]+)\|' -and $vals.ContainsKey($Matches[1])) }
    foreach ($k in $vals.Keys) { $l += "combobox|ZeD_UI|$k|$($vals[$k])" }
    Set-Content $MO $l
    Remove-Item $Mark -ErrorAction SilentlyContinue
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\repair_check.txt" -Report "$Rep\2026-11-06_hotfix_repair_1.md" -Mode windowed -Width 1280 -Height 800 2>&1 | Select-Object -Last 1
    # (the runner put back the file it found: the player's pick has to survive to the second launch, so the pick is written the same way)
    $l = (Get-Content $MO) | ForEach-Object { if ($_ -match '\|ZeD_UI\|identityStyle\|') { "combobox|ZeD_UI|identityStyle|1" } elseif ($_ -match '\|ZeD_UI\|additionsPreset\|') { "combobox|ZeD_UI|additionsPreset|4" } else { $_ } }
    Set-Content $MO $l
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\repair_check.txt" -Report "$Rep\2026-11-06_hotfix_repair_2.md" -Mode windowed -Width 1366 -Height 768 2>&1 | Select-Object -Last 1
}
finally {
    Copy-Item "$Keep\ModOptions.ini" $MO -Force
    Remove-Item $Mark -ErrorAction SilentlyContinue
    if (Test-Path "$Keep\mark.txt") { Copy-Item "$Keep\mark.txt" $Mark -Force }
}
