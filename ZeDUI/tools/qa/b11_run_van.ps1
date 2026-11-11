# QA (Nov 11 2026): the vanilla gallery run (ZeD off), as b11_run.ps1: PID to b11_run_van.pid, lines to b11_run.log.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
$env:ZEDQA_NOSTEAM = "1"
$out = Join-Path $Qa "gallery_b11_van.out"
$p = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", "$Qa\gallery_b11_van_mods.txt", "-NoZeD", "-Mode", "fullscreen4k", "-Manifest", "$Qa\gallery_b11_van.txt") -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
$p.Id | Set-Content (Join-Path $Qa "b11_run_van.pid")
L "van started PID $($p.Id)"
$p.WaitForExit()
L "van exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
