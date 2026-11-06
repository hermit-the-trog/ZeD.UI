#Requires -Version 7.0
# ZeDUI/tools/qa/gallery_b6_collect.ps1  (Nov 6 2026, QA): every picture the spreads use that was retaken since -Since goes to Screenshots/gallery_t14, the folder the spreads read.
# -Skip is a pattern of names to leave. Prints what's fresh and what stays older, by first word. Touches neither the game nor the lock.
param([Parameter(Mandatory)][datetime]$Since, [string]$Skip = '^$')
$Spreads = [IO.Path]::GetFullPath("$PSScriptRoot\..\..\workshop\gallery\spreads")
$Scr = "C:\Users\danie\Zomboid\Screenshots"; $To = "$Scr\gallery_t14"
$names = New-Object 'System.Collections.Generic.HashSet[string]'
Get-ChildItem "$Spreads\*.json" | ForEach-Object { foreach ($m in [regex]::Matches((Get-Content $_.FullName -Raw), '"src"\s*:\s*"([^"]+)"')) { [void]$names.Add((Split-Path $m.Groups[1].Value -Leaf)) } }
$copied = 0; $old = @{}; $none = @()
foreach ($n in $names) {
    $f = Join-Path $Scr $n
    if ((Test-Path $f) -and (Get-Item $f).LastWriteTime -ge $Since -and $n -notmatch $Skip) { Copy-Item $f (Join-Path $To $n) -Force; $copied++ }
    elseif (Test-Path (Join-Path $To $n)) { $p = ($n -replace '^(zqa_[a-z0-9]+|[a-z0-9]+).*$', '$1'); $old[$p] = [int]$old[$p] + 1 }
    else { $none += $n }
}
"copied $copied of $($names.Count)"
"older: " + (($old.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "$($_.Key) $($_.Value)" }) -join ", ")
if ($none) { "MISSING: " + ($none -join ", ") }
