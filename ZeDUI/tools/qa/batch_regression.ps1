#Requires -Version 7.0
# ZeDUI/tools/qa/batch_regression.ps1  (Nov 6 2026, QA): the full regression with the pcall watch on. The report lands in ZeDUI/qa/regression/ under -Tag.
param([string]$Tag = "beta6_full")
$Qa = $PSScriptRoot
$Lua = "C:\Users\you\Zomboid\Lua"
Set-Content "$Lua\zedqa_pcallwatch.txt" "1" -NoNewline
try { & "$Qa\zedqa_run.ps1" -Manifest "$Qa\regression_b4.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_$Tag.md")) }
finally { Remove-Item "$Lua\zedqa_pcallwatch.txt" -ErrorAction SilentlyContinue }
