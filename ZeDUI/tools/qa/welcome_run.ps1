#Requires -Version 7.0
<#
    ZeDUI/tools/qa/welcome_run.ps1  (Nov 19 2026, QA): the first-launch setup's checks (beta 21, ZeD_MainMenuWelcome.lua;
    zedqa_menu_welcome.lua, tag mwel), with the director's own files kept safe. The window and its checks write four of
    the director's files in Zomboid/Lua: ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt and ZeD_setup_seen.txt. This
    wrapper reads each one's bytes first (and notes which were not there), and in a finally block, whatever happens,
    writes each back byte for byte and deletes any that was not there before. Copies also wait on disk in
    Lua/zedqa_welcome_keep/ should this shell die mid-run; that folder is removed once all four are back.
    Two main menu launches through zedqa_menu_mods_run.ps1 (ZeD only), the same script each time:
      absent   no ZeD_setup_seen.txt at launch: the desk must open the welcome by itself (the first-run rule's yes)
      present  ZeD_setup_seen.txt there at launch: it must not (the rule's no)
    The files are put back between the two launches too. It refuses to start (exit 2) while ProjectZomboid64.exe runs
    or Zomboid/Lua/zedqa.lock says busy (the runner takes the lock itself). Exit 0 when every launch says VERDICT PASS,
    1 otherwise, 2 refused.
      pwsh -NoProfile -File ZeDUI/tools/qa/welcome_run.ps1
      pwsh -NoProfile -File ZeDUI/tools/qa/welcome_run.ps1 -Launches absent
#>
param(
    [ValidateSet("both", "absent", "present")][string]$Launches = "both",
    [int]$TimeoutSec = 300
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = Join-Path "$($env:USERPROFILE)\Zomboid" "Lua"
$lock = Join-Path $lua "zedqa.lock"
$keepDir = Join-Path $lua "zedqa_welcome_keep"
$names = @("ModOptions.ini", "ZeD_setup.txt", "ZeD_tutorial.txt", "ZeD_setup_seen.txt")
$seenFile = Join-Path $lua "ZeD_setup_seen.txt"

function Test-GameRunning {
    $out = ""
    try { $out = (& tasklist.exe /FI "IMAGENAME eq ProjectZomboid64.exe" /NH 2>$null) -join "`n" } catch { }
    if ($out -match 'ProjectZomboid64\.exe') { return $true }
    return [bool](Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)
}
$ls = $null
try { $ls = [string](Get-Content -LiteralPath $lock -Raw -ErrorAction Stop) } catch { }
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "welcome_run: not starting: $lock says busy (another session holds the game)"; exit 2 }
if (Test-GameRunning) { Write-Output "welcome_run: not starting: ProjectZomboid64.exe is running"; exit 2 }
if (Test-Path -LiteralPath $keepDir) { Write-Output "welcome_run: not starting: $keepDir is still here from an earlier run; put its files back in Zomboid/Lua by hand first"; exit 2 }

# ---- the director's four files, as found
$was = @{}
New-Item -ItemType Directory -Path $keepDir | Out-Null
foreach ($n in $names) {
    $p = Join-Path $lua $n
    if (Test-Path -LiteralPath $p) {
        $was[$n] = [IO.File]::ReadAllBytes($p)
        Copy-Item -LiteralPath $p -Destination (Join-Path $keepDir $n) -Force
        Write-Output "welcome_run: kept $n ($($was[$n].Length) bytes)"
    }
    else { $was[$n] = $null; Write-Output "welcome_run: $n is not there (it will be deleted after)" }
}

# every file back byte for byte; one that was not there deleted. True when all four match.
function Restore-Files {
    $good = $true
    foreach ($n in $names) {
        $p = Join-Path $lua $n
        $b = $was[$n]
        try {
            if ($null -ne $b) {
                [IO.File]::WriteAllBytes($p, $b)
                $now = [IO.File]::ReadAllBytes($p)
                if (-not [System.Linq.Enumerable]::SequenceEqual([byte[]]$now, [byte[]]$b)) { $good = $false; Write-Output "welcome_run: $n did NOT come back byte for byte" }
            }
            elseif (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
        }
        catch { $good = $false; Write-Output "welcome_run: $n could not be put back: $($_.Exception.Message)" }
    }
    return $good
}

$plan = $(if ($Launches -eq "both") { @("absent", "present") } else { @($Launches) })
$results = @()
try {
    foreach ($mode in $plan) {
        if (Test-GameRunning) { throw "welcome_run: the game is still running from the launch before; stopping" }
        [void](Restore-Files)
        if ($mode -eq "absent") { if (Test-Path -LiteralPath $seenFile) { Remove-Item -LiteralPath $seenFile -Force } }
        elseif ($null -eq $was["ZeD_setup_seen.txt"] -or $was["ZeD_setup_seen.txt"].Length -eq 0) { [IO.File]::WriteAllText($seenFile, "1") }
        Write-Output "welcome_run: launch '$mode' (ZeD_setup_seen.txt $(if (Test-Path -LiteralPath $seenFile) { 'there' } else { 'absent' }) at launch)"
        $out = @(& pwsh -NoProfile -File (Join-Path $here "zedqa_menu_mods_run.ps1") -ModList (Join-Path $here "zed_only_mods.txt") `
                -Script (Join-Path $here "zedqa_menu_welcome.lua") -Tag mwel -TimeoutSec $TimeoutSec 2>&1)
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Output "  [$mode] $_" }
        if ($code -eq 2) { $results += "${mode}: refused"; throw "welcome_run: the runner refused to start; stopping" }
        $verdict = @($out | Where-Object { "$_" -match 'ZEDQA mwel VERDICT (PASS|FAIL)' } | Select-Object -Last 1)
        $results += "${mode}: $(if ($verdict.Count) { ("$($verdict[0])" -replace '^.*ZEDQA mwel ', '') } else { 'no verdict' })"
    }
}
finally {
    if (Test-GameRunning) { Write-Output "welcome_run: the game is still running; the files are put back now and may be rewritten when it quits (copies in $keepDir)" }
    if (Restore-Files) {
        Remove-Item -LiteralPath $keepDir -Recurse -Force
        Write-Output "welcome_run: ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt and ZeD_setup_seen.txt put back byte for byte (absent ones deleted)"
    }
    else { Write-Output "welcome_run: NOT every file came back; the director's copies are kept in $keepDir"; $results += "restore: failed" }
}
$results | ForEach-Object { Write-Output "welcome_run: $_" }
$bad = @($results | Where-Object { $_ -notmatch ': VERDICT PASS' })
if ($results.Count -lt $plan.Count -or $bad.Count -gt 0) { Write-Output "welcome_run: not clean"; exit 1 }
Write-Output "welcome_run: clean"
exit 0
