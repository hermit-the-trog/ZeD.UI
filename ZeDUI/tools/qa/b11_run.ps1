# QA (Nov 11 2026): one beta 11 gallery run: b11_run.ps1 -Name t1a. Start-Process to a file + WaitForExit (never piped);
# the runner's PID goes to b11_run_<name>.pid so a stall_watch can follow it. Lines to b11_run.log.
param([Parameter(Mandatory)][string]$Name)
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
$env:ZEDQA_NOSTEAM = "1"
$out = Join-Path $Qa "gallery_b11_$Name.out"
(Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Set-Content (Join-Path $Qa "b11_run_$Name.start")
$p = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", "$Qa\zedqa_run.ps1", "-Manifest", (Join-Path $Qa "gallery_b11_$Name.txt"), "-Report", "gallery_b11_$Name", "-Mode", "fullscreen4k") -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
$p.Id | Set-Content (Join-Path $Qa "b11_run_$Name.pid")
L "$Name started PID $($p.Id)"
$p.WaitForExit()
L "$Name exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
