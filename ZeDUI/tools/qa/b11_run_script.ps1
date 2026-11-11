# QA (Nov 11 2026): runs one of the gallery's own runner scripts (menus, mod panes) as b11_run.ps1 does: b11_run_script.ps1 -Script x.ps1 -Name menus
param([Parameter(Mandatory)][string]$Script, [Parameter(Mandatory)][string]$Name)
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
$env:ZEDQA_NOSTEAM = "1"
$out = Join-Path $Qa "gallery_b11_$Name.out"
(Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Set-Content (Join-Path $Qa "b11_run_$Name.start")
$p = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $Qa $Script)) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
$p.Id | Set-Content (Join-Path $Qa "b11_run_$Name.pid")
L "$Name started PID $($p.Id)"
$p.WaitForExit()
L "$Name exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
