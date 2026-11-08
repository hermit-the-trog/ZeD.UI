#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6_stage.ps1  (Nov 6 2026, QA): 0.3.0-beta6 staged and the release check on the staged copy. Stops at the check: the upload is the director's.
$Qa = $PSScriptRoot
$Root = "$env:USERPROFILE\Zomboid\mods\ZeD-UI"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\tickets_20261105.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Wk = "E:\Project Zomboid\steamapps\workshop\content\108600"
$Mods = "$env:USERPROFILE\Zomboid\mods"
$Shots = "$env:USERPROFILE\Zomboid\Screenshots"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
$W = "$Root\ZeDUI\workshop"
$o = & pwsh -NoProfile -File "$Root\ZeDUI\tools\release\stage_workshop.ps1" -Version 0.3.0-beta6 -Description "ZeDUI/workshop/tester_description_0.3.0-beta6.bbcode" -ChangeNote "ZeDUI/workshop/tester_changenote_0.3.0-beta6.txt" 2>&1
$o | Select-Object -Last 14 | Set-Content "$Root\ZeDUI\qa\stage_beta6.txt"; if (-not (Test-Path "$env:USERPROFILE\Zomboid\Workshop\ZeD-UI\Contents\mods\ZeD-UI\42\mod.info")) { Note "stage failed, no check"; exit 1 }
Note "staged: $(($o | Select-Object -Last 1) -join ' ')"
$dest = "$env:USERPROFILE\Zomboid\Workshop\ZeD-UI\Contents\mods\ZeD-UI\42\media\lua\client\ZeD"
Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" $dest -Force
try {
    $r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Staged -Manifest "release_check_pinned.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-06_beta6_release_check_staged.md" 2>&1
    Note "release check: $(($r | Select-Object -Last 2) -join ' | ')"
}
finally { Remove-Item (Join-Path $dest "QABridge.lua") -Force -ErrorAction SilentlyContinue }
Note "stage done, bridge out"
