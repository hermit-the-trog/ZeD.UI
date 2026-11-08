#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b7_final.ps1  (Nov 7 2026, QA): the next beta's last merges (c8bfd10b) at 4K: the book (b7f_book.txt), the
# release check, kill counts and the ACC key (b7f_kd.txt), the contents at Large text in DE and FR (b7f_lang.txt; options.ini's
# language set per run and put back). The save comes back after each part; never while the game is open.
param([string]$Only)
$OnlyList = @(if ($Only) { $Only -split "," | ForEach-Object { $_.Trim() } })
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$env:USERPROFILE\Zomboid"
$Shots = "$Z\Screenshots"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$env:USERPROFILE\ZedQaSaveKeep_b7f"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Out = "$env:USERPROFILE\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\b7f"
$ini = "$Z\options.ini"
New-Item -ItemType Directory -Force $Out | Out-Null
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
function Put-SaveBack {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: the save is left alone, the copy stays at $KeepSave"; exit 1 }
    Remove-Item $Save -Recurse -Force
    if (Test-Path $Save) { Write-Output "the save could not be removed; the copy stays at $KeepSave"; exit 1 }
    Copy-Item $KeepSave $Save -Recurse
}
function Run($name, $manifest) {
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\$manifest" -Report "$Rep\2026-11-07_$name.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1
    New-Item -ItemType Directory -Force "$Out\$name" | Out-Null
    Get-ChildItem $Shots -Filter "zqa_*.png" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-40) } | Move-Item -Destination "$Out\$name" -Force
    Copy-Item "$Z\console.txt" "$Out\$name\console.txt" -Force
}
function Want($n) { return ($OnlyList.Count -eq 0 -or $OnlyList -contains $n) }
$MO = "$Z\Lua\ModOptions.ini"; $MOKeep = "$KeepSave.modoptions.ini"; Copy-Item $MO $MOKeep -Force
try {
    if ($OnlyList.Count -eq 0) { $OnlyList = @("book", "kd", "lang") }
    if (Want "book") { Run "b7f_book" "b7f_book.txt"; Put-SaveBack; Copy-Item $MOKeep $MO -Force }
    if (Want "kd") { Run "b7f_kd" "b7f_kd.txt"; Put-SaveBack; Copy-Item $MOKeep $MO -Force }
    if (Want "keys") { Run "b7f_keys" "b7f_keys.txt"; Put-SaveBack; Copy-Item $MOKeep $MO -Force }
    if (Want "lang") {
        $text = Get-Content -Raw $ini
        $was = if ($text -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
        try {
            foreach ($l in @("DE", "FR")) {
                $now = Get-Content -Raw $ini
                Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$l") -NoNewline
                Run "b7f_lang_$l" "b7f_lang.txt"
                Put-SaveBack; Copy-Item $MOKeep $MO -Force
            }
        } finally {
            $now = Get-Content -Raw $ini
            Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$was") -NoNewline
        }
    }
} finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        Put-SaveBack
        Copy-Item $MOKeep $MO -Force
        Remove-Item $KeepSave -Recurse -Force; Remove-Item $MOKeep -Force
    } else { Write-Output "the game is still running: the save copy stays at $KeepSave" }
}
Write-Output "batch done"
