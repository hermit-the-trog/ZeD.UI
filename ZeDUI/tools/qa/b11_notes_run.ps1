# QA (Nov 11 2026): zedqa_b11_notes.lua (punch list 155, 156, 157, 160, 162) at 4K, then on the Deck (1280x800).
# Start-Process to a file + WaitForExit; lines to b11_notes_run.log.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_notes_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$m = Join-Path $Qa "b11n_manifest.txt"
Set-Content $m @("zedqa_prelude.lua | pre | timeout=120", "zedqa_b11_notes.lua | b11n | timeout=600")
foreach ($run in @(@{ t = "4k"; a = @("-Mode", "fullscreen4k") }, @{ t = "deck"; a = @("-Mode", "windowed", "-Width", "1280", "-Height", "800") })) {
    $out = Join-Path $Qa "b11n_$($run.t).out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File", "$Qa\zedqa_run.ps1", "-Manifest", $m, "-Report", "b11n_$($run.t)") + $run.a) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    L "$($run.t) exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
}
$r = & "$Qa\pzrestorewin.ps1" 2>&1 | Out-String
L "restore: $($r.Trim())"
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
