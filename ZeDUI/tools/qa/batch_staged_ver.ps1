#Requires -Version 7.0
# ZeDUI/tools/qa/batch_staged_ver.ps1  (Nov 6 2026, QA): proves which copy of ZeD a staged run loads. The bridge goes into the staged copy for the run and comes out after.
$Qa = $PSScriptRoot
$Root = [IO.Path]::GetFullPath("$Qa/../../..")
$env:ZEDQA_NOSTEAM = "1"
$dest = "C:/Users/danie/Zomboid/Workshop/ZeD-UI/Contents/mods/ZeD-UI/42/media/lua/client/ZeD"
Copy-Item "$Root/42/media/lua/client/ZeD/QABridge.lua" $dest -Force
try { & pwsh -NoProfile -File "$Qa/zedqa_run.ps1" -Manifest "$Qa/staged_ver.txt" -Report "$Root/ZeDUI/qa/regression/2026-11-06_staged_ver.md" -StagedCopy 2>&1 | Select-Object -Last 1 }
finally { Remove-Item "$dest/QABridge.lua" -Force -ErrorAction SilentlyContinue }
