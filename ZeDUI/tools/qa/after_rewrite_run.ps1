# QA (Nov 9 2026): after the history rewrite and the move to $env:USERPROFILE paths: the release check at 4K, then
# b11_start_run.ps1 (the main-menu runner and the Deck runner, both through the moved paths). Start-Process + WaitForExit.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "after_rewrite_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$out = Join-Path $Qa "after_rewrite_release.out"
$p = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check.ps1", "-Report", "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-09_after_rewrite_release.md" -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
$p.WaitForExit()
L "release check exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
$p = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\b11_start_run.ps1" -NoNewWindow -PassThru
$p.WaitForExit()
L "b11_start_run exit $($p.ExitCode): $((Get-Content (Join-Path $Qa 'b11_start_run.log') -ErrorAction SilentlyContinue) -join ' || ')"
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
