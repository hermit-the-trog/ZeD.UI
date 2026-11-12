#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_wsp_run.ps1  (Nov 11 2026, QA): saved window positions. A 4K launch (wsp_4k.txt: the window menu script, then the places saved) and a Deck launch (wsp_deck.txt: those places
# brought back, then the window menu script). Zomboid/Lua/ZeD_window_places.txt is put back as it was at the end.
$ErrorActionPreference = "Stop"
$Qa = $PSScriptRoot
$f = "$($env:USERPROFILE)\Zomboid\Lua\ZeD_window_places.txt"
$had = Test-Path $f
$bytes = if ($had) { [System.IO.File]::ReadAllBytes($f) } else { $null }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "refused: the game is running"; exit 2 }
$env:ZEDQA_NOSTEAM = "1"
try {
    foreach ($r in @(@("4k", @("-Mode", "fullscreen4k", "-Manifest", "$Qa\wsp_4k.txt")), @("deck", @("-Mode", "windowed", "-Width", "1280", "-Height", "800", "-Manifest", "$Qa\wsp_deck.txt")))) {
        $out = Join-Path $Qa "wsp_run_$($r[0]).out"
        $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File", "$Qa\zedqa_run.ps1") + $r[1]) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
        $p.Id | Set-Content (Join-Path $Qa "wsp_run_$($r[0]).pid")
        $p.WaitForExit()
        Write-Output "run $($r[0]) exit $($p.ExitCode): $((Get-Content $out -Tail 1) -join ' ')"
    }
}
finally {
    if ($had) { [System.IO.File]::WriteAllBytes($f, $bytes) } elseif (Test-Path $f) { Remove-Item $f }
    Write-Output "ZeD_window_places.txt put back"
}
