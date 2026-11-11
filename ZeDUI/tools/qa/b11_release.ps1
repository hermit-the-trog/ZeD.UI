#Requires -Version 7.0
# ZeDUI/tools/qa/b11_release.ps1  (Nov 11 2026, QA): the beta 11 release pass on the dev mod, every stage in a row.
# Before the run the game's Font Size is set to 3 in options.ini (the director's is put back at the end) so the run
# proves zedqa_run.ps1's pin: 2 (19px) while the game runs, the line before the run put back after.
# Each stage: Start-Process to a file + WaitForExit (never piped). Lines to b11_release.log; stall_watch.ps1 beside it.
$here = $PSScriptRoot
$log = Join-Path $here "b11_release.log"
$opt = "$($env:USERPROFILE)\Zomboid\options.ini"
$lock = "$($env:USERPROFILE)\Zomboid\Lua\zedqa.lock"
function Say([string]$s) { "{0}  {1}" -f (Get-Date -Format "HH:mm:ss"), $s | Add-Content -LiteralPath $log }
function FontLine { ((Select-String -Path $opt -Pattern '^fontSize=' | Select-Object -First 1).Line) }
function Wait-Free {
    while ($true) {
        $busy = (Test-Path $lock) -and ((Get-Content $lock -Raw).Trim() -ne "free")
        if (-not $busy -and -not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Seconds 20
    }
}
function Stage([string]$name, [string[]]$argv) {
    Wait-Free
    $out = Join-Path $here ("b11r_" + ($name -replace '\W', '_') + ".out")
    Say "START $name (fontSize before: $(FontLine))"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile") + $argv) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $seen = @()
    while (-not $p.HasExited) {   # sample the font line while the game runs: the pin must read fontSize=2
        if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { $seen += (FontLine) }
        Start-Sleep -Seconds 15
    }
    $tail = (Get-Content $out -ErrorAction SilentlyContinue | Where-Object { $_ -match "pass,|FAIL|TIMEOUT|refus|error" } | Select-Object -Last 8) -join " || "
    Say "END $name (exit $($p.ExitCode)); fontSize while running: $((@($seen | Select-Object -Unique)) -join ', '); after: $(FontLine) $tail"
}
Set-Content -LiteralPath $log -Value "b11 release pass, started $(Get-Date)"
$env:ZEDQA_NOSTEAM = "1"
$directorFont = FontLine
Say "director's font line: $directorFont"
(Get-Content $opt) -replace '^fontSize=.*', 'fontSize=3' | Set-Content $opt
$m = Join-Path $here "b11_notes_manifest.txt"
Set-Content $m @("zedqa_prelude.lua | pre | timeout=120", "zedqa_bubbles.lua | bub | timeout=300", "zedqa_halo_notes.lua | timeout=300", "zedqa_reader.lua | rd | timeout=180", "zedqa_notebook.lua | nb | timeout=180", "zedqa_guide_bubble.lua | gbub | timeout=240")
try {
    Stage "1 release check" @("-File", "$here\release_check.ps1", "-Report", "b11r_release")
    Stage "2 regression" @("-File", "$here\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", "$here\regression.txt", "-Report", "b11r_regression")
    Stage "3 notes 4k" @("-File", "$here\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", $m, "-Report", "b11r_notes_4k")
    Stage "4 notes deck" @("-File", "$here\zedqa_run.ps1", "-Mode", "windowed", "-Width", "1280", "-Height", "800", "-Manifest", $m, "-Report", "b11r_notes_deck")
} finally {
    Wait-Free
    $r = & "$here\pzrestorewin.ps1" 2>&1 | Out-String
    Say "restore: $($r.Trim())"
    Say "fontSize at the end (expect fontSize=3): $(FontLine)"
    (Get-Content $opt) -replace '^fontSize=.*', $directorFont | Set-Content $opt
    Say "director's font line put back: $(FontLine)"
    Say "ALL DONE"
}
