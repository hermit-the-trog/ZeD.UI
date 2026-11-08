#Requires -Version 7.0
# ZeDUI/tools/qa/batch_stage_true.ps1  (Nov 6 2026, QA): 0.3.0-beta6 staged, then the release check on a true copy of the stage: a separate game folder (-cachedir) holding the staged
# mods, the bridge, the test save and the options, so neither the repo's 42/ nor the real Zomboid folder is touched. The run prints the version and folder the game loaded.
# Stops at the check: the upload is the director's.
$Qa = $PSScriptRoot
$Root = "$env:USERPROFILE\Zomboid\mods\ZeD-UI"
$Z = "$env:USERPROFILE\Zomboid"
$Stg = "$env:USERPROFILE\ZomboidStaged"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\tickets_20261105.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
Set-Location $Root
$o = & pwsh -NoProfile -File "$Root\ZeDUI\tools\release\stage_workshop.ps1" -Version 0.3.0-beta6 -Description "ZeDUI/workshop/tester_description_0.3.0-beta6.bbcode" -ChangeNote "ZeDUI/workshop/tester_changenote_0.3.0-beta6.txt" 2>&1
$o | Select-Object -Last 14 | Set-Content "$Root\ZeDUI\qa\stage_beta6.txt"
$From = "$Z\Workshop\ZeD-UI\Contents\mods"
if (-not (Select-String -Path "$From\ZeD-UI\42\mod.info" -Pattern '^modversion=0\.3\.0-beta6' -Quiet)) { Note "stage failed, no check"; exit 1 }
Note "staged 0.3.0-beta6"
if (Test-Path $Stg) { Remove-Item $Stg -Recurse -Force }
foreach ($d in "mods", "Lua", "Saves\Sandbox", "Screenshots") { New-Item -ItemType Directory -Force "$Stg\$d" | Out-Null }
Copy-Item "$From\*" "$Stg\mods\" -Recurse
Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" "$Stg\mods\ZeD-UI\42\media\lua\client\ZeD\" -Force
Copy-Item "$Z\Saves\Sandbox\ZeD-QA" "$Stg\Saves\Sandbox\ZeD-QA" -Recurse
Copy-Item "$Z\options.ini" "$Stg\options.ini"
foreach ($f in "latestSave.ini", "version.txt") { if (Test-Path "$Z\$f") { Copy-Item "$Z\$f" "$Stg\$f" } }
Copy-Item "$Z\Lua\ModOptions.ini" "$Stg\Lua\ModOptions.ini"
Copy-Item "$Z\mods\reset-mods-*.txt" "$Stg\mods\" -ErrorAction SilentlyContinue   # (a marker: without it the game clears the mod list on its first start in a folder)
Set-Content "$Stg\mods\default.txt" "VERSION = 1,`r`n`r`nmods`r`n{`r`n    mod = ZeD_UI,`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n" -NoNewline
Set-Content "$Stg\Lua\zedqa.lock" "free" -NoNewline
$env:ZEDQA_ZDIR = $Stg
$r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "release_check_staged.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-06_beta6_release_check_true.md" 2>&1
Remove-Item Env:\ZEDQA_ZDIR
Note "true staged check: $(($r | Select-Object -Last 2) -join ' | ')"
Copy-Item "$Stg\console.txt" "$Root\ZeDUI\qa\stage_true_console.txt" -Force -ErrorAction SilentlyContinue
Note "true check done"
