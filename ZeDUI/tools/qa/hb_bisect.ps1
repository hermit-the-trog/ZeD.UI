#Requires -Version 7.0
# ZeDUI/tools/qa/hb_bisect.ps1  (Nov 5 2026, QA; punch list 54): runs Hair and beard's check once per mod set and says
# for each whether the callFrame error came. Sets are given as comma lists of mod ids, one argument each. One line per
# set in ZeDUI/qa/hb_bisect_20261105.txt.
param([Parameter(Mandatory)][string[]]$Sets)
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath((Join-Path $Qa "..\..\qa\hb_bisect_20261105.txt"))
foreach ($s in $Sets) {
    $tmp = Join-Path $env:TEMP "hb_set_mods.txt"
    ($s -split ",") | Set-Content $tmp -Encoding utf8NoBOM
    $before = Get-Date
    & pwsh -NoProfile -File (Join-Path $Qa "zedqa_mods_run.ps1") -ModList $tmp -Mode windowed -Manifest (Join-Path $Qa "hb_set.txt") 2>&1 | Out-Null
    $rep = Get-ChildItem (Join-Path $Qa "..\..\qa\regression") -Filter "*_mods_windowed.md" | Where-Object { $_.LastWriteTime -ge $before } | Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $rep) { "$s | NO REPORT" | Add-Content $Out; continue }
    $txt = Get-Content $rep.FullName -Raw
    $cf = ([regex]::Matches($txt, "callFrame")).Count
    $fails = ([regex]::Matches($txt, "ZEDQA hbt FAIL[^\r\n]*") | ForEach-Object { $_.Value }) -join " ; "
    "$s | callFrame $cf | $($rep.Name) | $fails" | Add-Content $Out
}
