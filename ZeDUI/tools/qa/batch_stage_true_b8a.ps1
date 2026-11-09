#Requires -Version 7.0
# ZeDUI/tools/qa/batch_stage_true_b8a.ps1  (Nov 8 2026, QA): the release check on a true copy of Build's 0.3.0-beta8a stage (Build staged
# it; nothing is staged here): a separate game folder (-cachedir) holding the staged mods, the bridge, the test save and the options, so
# neither the staged Contents, the repo's 42/ nor the real Zomboid folder is touched. The run prints the version and folder the game
# loaded. Stops at the check: the upload is the director's.
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$Z = "$($env:USERPROFILE)\Zomboid"
$Stg = "$($env:USERPROFILE)\ZomboidStaged"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\stage_true_b8a.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
Set-Location $Root
$From = "$Z\Workshop\ZeD-UI\Contents\mods"
if (-not (Select-String -Path "$From\ZeD-UI\42\mod.info" -Pattern '^modversion=0\.3\.0-beta8a' -Quiet)) { Note "the stage is not 0.3.0-beta8a, no check"; exit 1 }
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') the true staged check of 0.3.0-beta8a" | Set-Content $Out
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
$r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "b8a_stage.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-08_beta8a_release_check_true.md" 2>&1
Remove-Item Env:\ZEDQA_ZDIR
Note "true staged check: $(($r | Select-Object -Last 3) -join ' | ')"
Copy-Item "$Stg\console.txt" "$Root\ZeDUI\qa\stage_true_b8a_console.txt" -Force -ErrorAction SilentlyContinue
Note "true check done"

