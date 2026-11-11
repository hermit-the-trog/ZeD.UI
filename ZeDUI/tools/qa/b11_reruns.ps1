# QA (Nov 11 2026): beta 11 reruns after Build's script fixes: at 4K b11n, sg, wi, tw, hln; at the Deck b11n, hln.
# Start-Process to a file + WaitForExit; lines to b11_reruns.log.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_reruns.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
function Line($script) { (Select-String (Join-Path $Qa "regression.txt") -Pattern "^$([regex]::Escape($script))").Line }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$pre = "zedqa_prelude.lua | pre | timeout=120"
$b11n = "zedqa_b11_notes.lua | b11n | timeout=600"
$hln = "zedqa_halo_notes.lua | timeout=300"
Set-Content (Join-Path $Qa "b11_reruns_4k.txt") @($pre, $b11n, (Line "zedqa_sort_groups.lua"), (Line "zedqa_wheel_icons.lua"), (Line "zedqa_twoway.lua"), $hln)
Set-Content (Join-Path $Qa "b11_reruns_deck.txt") @($pre, $b11n, $hln)
foreach ($run in @(@{ t = "4k"; a = @("-Mode", "fullscreen4k") }, @{ t = "deck"; a = @("-Mode", "windowed", "-Width", "1280", "-Height", "800") })) {
    $out = Join-Path $Qa "b11_reruns_$($run.t).out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File", "$Qa\zedqa_run.ps1", "-Manifest", (Join-Path $Qa "b11_reruns_$($run.t).txt"), "-Report", "b11_reruns_$($run.t)") + $run.a) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    L "$($run.t) exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
}
$r = & "$Qa\pzrestorewin.ps1" 2>&1 | Out-String
L "restore: $($r.Trim())"
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
