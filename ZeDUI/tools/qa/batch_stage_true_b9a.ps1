#Requires -Version 7.0
# ZeDUI/tools/qa/batch_stage_true_b9a.ps1  (Nov 8 2026, QA): the true staged check of 0.3.0-beta9a (Build's hotfix stage) from its own -cachedir; -Tag 4k or deck, -Width/-Height for the Deck window.
# it; nothing is staged here): a separate game folder (-cachedir) holding the staged mods, the bridge, the test save and the options, so
# neither the staged Contents, the repo's 42/ nor the real Zomboid folder is touched. The run prints the version and folder the game
# loaded. Stops at the check: the upload is the director's.
param([string]$Tag = "4k", [int]$Width = 0, [int]$Height = 0)
$Qa = $PSScriptRoot
$Root = "C:\Users\danie\Zomboid\mods\ZeD-UI"
$Z = "C:\Users\danie\Zomboid"
$Stg = "C:\Users\danie\ZomboidStaged"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\stage_true_b9a_$Tag.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
Set-Location $Root
$From = "$Z\Workshop\ZeD-UI\Contents\mods"
if (-not (Select-String -Path "$From\ZeD-UI\42\mod.info" -Pattern '^modversion=0.3.0-beta9a' -Quiet)) { Note "the stage is not 0.3.0-beta9, no check"; exit 1 }
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') the true staged check of 0.3.0-beta9a" | Set-Content $Out
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
$r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "b9a_stage.txt" -Width $Width -Height $Height -Report "$Root\ZeDUI\qa\regression\2026-11-08_beta9a_check_true_$Tag.md" 2>&1
Remove-Item Env:\ZEDQA_ZDIR
Note "true staged check: $(($r | Select-Object -Last 3) -join ' | ')"
Copy-Item "$Stg\console.txt" "$Root\ZeDUI\qa\stage_true_b9a_console_$Tag.txt" -Force -ErrorAction SilentlyContinue
Note "true check done"

