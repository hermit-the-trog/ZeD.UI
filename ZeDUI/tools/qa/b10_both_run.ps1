# QA (Nov 9 2026): the beta 10 true staged check from its own -cachedir (%USERPROFILE%\ZomboidStaged) at 4K, then on
# the Deck (1280x800), with the reruns Build asked for (b10_stage.txt; no pnw: it pins the windows the scripts stage).
# Each run goes through Start-Process with its output to a file and WaitForExit (never piped: the game it starts would
# hold the pipe open). Lines go to b10_both_run.log as they happen.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b10_both_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
function Run([string]$tag, [string[]]$argv) {
    $out = Join-Path $Qa "b10_both_$tag.out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File") + $argv) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    L "$tag exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
}
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
Run "4k" @("$Qa\batch_stage_true_b10.ps1", "-Tag", "4k")
Run "deck" @("$Qa\batch_stage_true_b10.ps1", "-Tag", "deck", "-Width", "1280", "-Height", "800")
Run "restore" @("$Qa\pzrestorewin.ps1")
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
