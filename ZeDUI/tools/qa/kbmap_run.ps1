#Requires -Version 7.0
<#
    ZeDUI/tools/qa/kbmap_run.ps1  (Nov 19 2026, QA): the Keyboard map's checks (beta 21, ZeD_KeyboardMap.lua), with the
    director's real key file kept safe. keysB42.ini is the director's own; the map rewrites it, so this wrapper copies
    Zomboid/Lua/keysB42.ini aside first and puts it back byte for byte in a finally block, whatever happens (a file that
    was not there before is removed). Three launches through zedqa_run.ps1:
      1. kbmap_full.txt   rt_kbmap.lua: every in-game check (it puts every binding back itself, too)
      2. kbmap_set.txt    kbmap_set.lua: one binding (Toggle Music) set to a test key and left set; the game quits
      3. kbmap_check.txt  kbmap_check.lua: after the restart the game and keysB42.ini still hold it; then set back
    It refuses to start (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy, as the runner does.
    Exit 0 when all three runs are clean, 1 otherwise, 2 refused.
      pwsh -File ZeDUI/tools/qa/kbmap_run.ps1
      pwsh -File ZeDUI/tools/qa/kbmap_run.ps1 -Mode windowed -Width 1280 -Height 800
#>
param(
    [ValidateSet("windowed", "fullscreen4k")][string]$Mode = "fullscreen4k",
    [int]$Width = 1920,
    [int]$Height = 1080
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$zdir = $(if ($env:ZEDQA_ZDIR) { $env:ZEDQA_ZDIR } else { "$($env:USERPROFILE)\Zomboid" })
$lua = Join-Path $zdir "Lua"
$keys = Join-Path $lua "keysB42.ini"
$lock = Join-Path $lua "zedqa.lock"
$carry = Join-Path $lua "zedqa_kbmap_carry.txt"
$backup = Join-Path $lua "zedqa_keysB42_keep.ini"

# refuse to start: the shared game (the runner's own rule)
function Test-GameRunning {
    $out = ""
    try { $out = (& tasklist.exe /FI "IMAGENAME eq ProjectZomboid64.exe" /NH 2>$null) -join "`n" } catch { }
    if ($out -match 'ProjectZomboid64\.exe') { return $true }
    return [bool](Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)
}
$ls = $null
try { $ls = [string](Get-Content -LiteralPath $lock -Raw -ErrorAction Stop) } catch { }
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "kbmap_run: not starting: $lock says busy (another session holds the game)"; exit 2 }
if (Test-GameRunning) { Write-Output "kbmap_run: not starting: ProjectZomboid64.exe is running"; exit 2 }
if (Test-Path -LiteralPath $backup) { Write-Output "kbmap_run: not starting: $backup is still here from an earlier run; put it back as keysB42.ini by hand first"; exit 2 }

$had = Test-Path -LiteralPath $keys
$was = $null
if ($had) {
    $was = [IO.File]::ReadAllBytes($keys)
    Copy-Item -LiteralPath $keys -Destination $backup -Force   # (a copy on disk too, should this shell die mid-run)
}
$size = @()
if ($Mode -eq "windowed") { $size = @("-Width", $Width, "-Height", $Height) }
$tagSize = $(if ($Mode -eq "windowed") { "_${Width}x${Height}" } else { "_4k" })
$codes = @()
try {
    if (Test-Path -LiteralPath $carry) { Remove-Item -LiteralPath $carry -Force }
    & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "kbmap_full.txt") -Mode $Mode @size -Report "kbmap_full$tagSize"
    $codes += $LASTEXITCODE
    if ($LASTEXITCODE -eq 2) { throw "kbmap_run: the first run was refused; stopping" }
    # (the restart pair carries a key across two launches: zedqa_run.ps1 must not put keysB42.ini back between them;
    # this wrapper's own finally restores the director's bytes)
    $env:ZEDQA_KEEPKEYS = "1"
    & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "kbmap_set.txt") -Mode $Mode @size -Report "kbmap_set$tagSize"
    $codes += $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $carry)) { Write-Output "kbmap_run: the first launch wrote no carry file; not running the restart check"; $codes += 1; throw "kbmap_run: stopped before the restart check" }
    & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "kbmap_check.txt") -Mode $Mode @size -Report "kbmap_check$tagSize"
    $codes += $LASTEXITCODE
}
finally {
    Remove-Item Env:ZEDQA_KEEPKEYS -ErrorAction SilentlyContinue
    if ($had) {
        [IO.File]::WriteAllBytes($keys, $was)
        $now = [IO.File]::ReadAllBytes($keys)
        if ([System.Linq.Enumerable]::SequenceEqual([byte[]]$now, [byte[]]$was)) {
            Remove-Item -LiteralPath $backup -Force
            Write-Output "kbmap_run: keysB42.ini put back byte for byte ($($was.Length) bytes)"
        }
        else { Write-Output "kbmap_run: keysB42.ini did NOT come back byte for byte; the director's copy is kept at $backup"; $codes += 1 }
    }
    elseif (Test-Path -LiteralPath $keys) {
        Remove-Item -LiteralPath $keys -Force
        Write-Output "kbmap_run: there was no keysB42.ini before; the one the test wrote is removed"
    }
    if (Test-Path -LiteralPath $carry) { Remove-Item -LiteralPath $carry -Force }
}
$bad = @($codes | Where-Object { $_ -ne 0 })
if ($codes.Count -lt 3 -or $bad.Count -gt 0) { Write-Output "kbmap_run: not clean (exit codes: $($codes -join ', '))"; exit 1 }
Write-Output "kbmap_run: all three runs clean"
exit 0
