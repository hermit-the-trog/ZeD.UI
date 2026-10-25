#Requires -Version 7.0
<#
.SYNOPSIS
    Does a save made with ZeD-UI load with ZeD switched off, and come back whole
    when ZeD is switched on again? (Oct 24 2026, before a public test.)

.DESCRIPTION
    Three launches of the game in a 1920x1080 window, zedqa_offsave.lua in each:
      before  zedqa_run.ps1 on the ZeD-QA save: the character wears ZeD's Timez
              watch, carries one and has one in a bag; the run's quit saves it.
              That save is copied to Saves/Sandbox/ZeD-QA-off, and ZeD-QA is put
              back from a copy taken first (ZeD-QA keeps no trace of the test).
      off     ZeD-QA-off with ZeD_UI swapped for ZeDQA_Probe (probe_mod/, a
              stand-in for the QA bridge) in the save's mod list and the main
              menu's (mods/default.txt); quit to the menu saves it without ZeD.
      on      ZeD_UI back in the save's list, default.txt as it was.
    The results go in ZeDUI/qa/offsave/<yyyy-MM-dd_HHmm>/: the three
    zedqa_off_<phase>.txt inventories, a console.txt per launch and the before
    run's report (screenshots stay in Zomboid/Screenshots, zqa_off_*.png). The
    save copies (ZeD-QA before the test, the ZeD-QA-off save after it) go to
    the temp folder, not the project.
    ZeD's UI scale is Auto for the off and on launches, as zedqa_run.ps1 sets
    it for a 1080p window (the director's 1.75x does not fit the pair side by
    side in a 1920x1080 window).
    Put back in every case (finally): mods/default.txt, latestSave.ini,
    Lua/ModOptions.ini, the probe mod folder removed, ZeD-QA-off removed from
    Saves, the lock "free".
    Refuses to start when the lock is busy, the game runs or latestSave.ini
    is not ZeD-QA.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
$Utf8NoBom   = New-Object System.Text.UTF8Encoding($false)
$QaDir       = $PSScriptRoot
$ZomboidDir  = "C:\Users\danie\Zomboid"
$LuaDir      = Join-Path $ZomboidDir "Lua"
$GoFile      = Join-Path $LuaDir "zedqa.go"
$BridgeLua   = Join-Path $LuaDir "zedqa.lua"
$CounterFile = Join-Path $LuaDir "zedqa.counter"
$AutoFile    = Join-Path $LuaDir "zedqa.autoload"
$LockFile    = Join-Path $LuaDir "zedqa.lock"
$ConsoleFile = Join-Path $ZomboidDir "console.txt"
$LatestSave  = Join-Path $ZomboidDir "latestSave.ini"
$DefaultMods = Join-Path $ZomboidDir "mods\default.txt"
$Saves       = Join-Path $ZomboidDir "Saves\Sandbox"
$QaSave      = Join-Path $Saves "ZeD-QA"
$OffSave     = Join-Path $Saves "ZeD-QA-off"
$ProbeSrc    = Join-Path $QaDir "probe_mod\ZeDQA_Probe"
$ProbeDst    = Join-Path $ZomboidDir "mods\ZeDQA_Probe"
$PhaseLua    = Join-Path $QaDir "zedqa_offsave.lua"
$Shots       = Join-Path $ZomboidDir "Screenshots"
$Stamp       = Get-Date -Format "yyyy-MM-dd_HHmm"
$Work        = Join-Path $QaDir ("..\..\qa\offsave\" + $Stamp)
$Keep        = Join-Path ([System.IO.Path]::GetTempPath()) "ZeD-offsave.$Stamp"
$ModOptions  = Join-Path $LuaDir "ModOptions.ini"

function Write-Text([string]$Path, [string]$Text) { [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom) }
function Read-Text([string]$Path) { try { return [string](Get-Content -LiteralPath $Path -Raw -ErrorAction Stop) } catch { return $null } }
function Test-GameRunning { return [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Say([string]$s) { Write-Output ("  " + $s) }
function Get-Log { $t = Read-Text $ConsoleFile; if ($null -eq $t) { return "" }; return ($t -replace "`0", "") }

function Invoke-Bump {
    [long]$n = 9999
    $t = Read-Text $CounterFile
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    if ($n -lt 9999) { $n = 9999 }
    $n++
    $cur = Read-Text $GoFile
    if ($cur -and $cur.Trim() -eq "$n") { $n++ }
    Write-Text $CounterFile "$n"
    Write-Text $GoFile "$n"
    return $n
}

function Wait-Log([string]$Pattern, [int]$Seconds) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $Seconds) {
        Start-Sleep -Seconds 2
        if ((Get-Log) -match $Pattern) { return $true }
        if (-not (Test-GameRunning)) { return $false }
    }
    return $false
}

function Stop-Game {
    if (-not (Test-GameRunning)) { return "the game was not running" }
    Write-Text $AutoFile "0"
    Write-Text $BridgeLua "-- zedqa_offsave_run.ps1: quit (in game to the main menu, at the menu to the desktop)`ngetCore():quit()`n"
    $len = (Get-Log).Length
    $n1 = Invoke-Bump
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt 90) {
        Start-Sleep -Seconds 2
        if (-not (Test-GameRunning)) { return "quit (go $n1)" }
        $log = Get-Log
        if ($log.Length -gt $len -and $log.Substring([Math]::Min($len, $log.Length)) -match 'bridge armed \(main menu') { break }
    }
    Start-Sleep -Seconds 4
    $null = Invoke-Bump
    $t0 = Get-Date; $again = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 60) {
        Start-Sleep -Seconds 2
        if (-not (Test-GameRunning)) { return "quit to the main menu, then to the desktop" }
        if (-not $again -and ((Get-Date) - $t0).TotalSeconds -ge 20) { $null = Invoke-Bump; $again = $true }
    }
    return "the game was still running after the quit; close it by hand"
}

# One launch on the latest save: run the phase, write down the console, quit (the quit saves)
function Invoke-Phase([string]$Phase) {
    Say "launch ($Phase)"
    $out = & (Join-Path $QaDir "pzlaunchwin.ps1") 2>&1
    Say ("pzlaunchwin: " + (($out | Out-String).Trim() -replace '\s*\r?\n\s*', ' / '))
    if (-not (Wait-Log 'bridge armed \(in game' 120)) { Say "ERR the bridge never armed in game"; Copy-Item $ConsoleFile (Join-Path $Work "console_$Phase.txt"); Say ("quit: " + (Stop-Game)); return $false }
    Start-Sleep -Seconds 6
    Write-Text $BridgeLua ("ZEDQA_OFF_PHASE = `"$Phase`"`n" + (Read-Text $PhaseLua))
    $null = Invoke-Bump
    $done = Wait-Log "ZEDQA off $Phase DONE" 120
    Say "phase $Phase finished: $done"
    if ($Phase -eq "on") {
        Start-Sleep -Seconds 8   # (the window pair settles, then a second picture)
        Write-Text $BridgeLua "getCore():TakeFullScreenshot(`"zqa_off_on_settled.png`")`n"
        $null = Invoke-Bump
        Start-Sleep -Seconds 6
    }
    Say ("quit: " + (Stop-Game))
    Copy-Item $ConsoleFile (Join-Path $Work "console_$Phase.txt")
    $r = & (Join-Path $QaDir "pzrestorewin.ps1") 2>&1
    Say ("pzrestorewin: " + (($r | Out-String).Trim()))
    $f = Join-Path $LuaDir "zedqa_off_$Phase.txt"
    if (Test-Path $f) { Copy-Item $f $Work }
    return $done
}

# ---------------------------------------------------------------------------
if ((Read-Text $LockFile) -match '^busy') { Write-Output "not starting: the lock is busy"; exit 2 }
if (Test-GameRunning) { Write-Output "not starting: the game is running"; exit 2 }
if (((Read-Text $LatestSave) -split "\r?\n")[0].Trim() -ne "ZeD-QA") { Write-Output "not starting: latestSave.ini is not ZeD-QA"; exit 2 }
if (Test-Path $OffSave) { Write-Output "not starting: $OffSave exists (an earlier run was not cleaned up)"; exit 2 }
New-Item -ItemType Directory -Force -Path $Work | Out-Null
$Work = (Resolve-Path $Work).Path
Write-Output "zedqa_offsave_run: $Work"
New-Item -ItemType Directory -Force -Path $Keep | Out-Null
Copy-Item $DefaultMods (Join-Path $Keep "default.txt.bak")
Copy-Item $LatestSave (Join-Path $Keep "latestSave.ini.bak")
if (Test-Path $ModOptions) { Copy-Item $ModOptions (Join-Path $Keep "ModOptions.ini.bak") }
$snap = Join-Path $Keep "ZeD-QA.snapshot"
Copy-Item -Recurse $QaSave $snap
Remove-Item (Join-Path $LuaDir "zedqa_off_*.txt") -ErrorAction SilentlyContinue
$restoredQa = $false
try {
    # before: through the runner, on ZeD-QA
    $man = Join-Path $Work "before_manifest.txt"
    Write-Text $man "zedqa_prelude.lua | pre`nzedqa_offsave.lua | off`n"   # ("ZEDQA off before DONE" ends it)
    $rep = Join-Path $Work "before.md"
    $out = & (Join-Path $QaDir "zedqa_run.ps1") -Mode windowed -Manifest $man -Report $rep 2>&1
    $out | ForEach-Object { Say $_ }
    Copy-Item (Join-Path $LuaDir "zedqa_off_before.txt") $Work
    Copy-Item -Recurse $QaSave $OffSave
    Remove-Item -Recurse -Force $QaSave
    Copy-Item -Recurse $snap $QaSave
    $restoredQa = $true
    Say "ZeD-QA put back from the copy taken first; the test save is ZeD-QA-off"

    Write-Text $LockFile "busy"
    Write-Text $LatestSave "ZeD-QA-off`r`nSandbox`r`n"
    $mo = Read-Text $ModOptions
    if ($null -ne $mo) { Write-Text $ModOptions ((@(($mo -split "`r?`n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' }) -join "`r`n") + "`r`n") }

    # off: ZeD out of both mod lists, the probe in
    Copy-Item -Recurse $ProbeSrc $ProbeDst
    New-Item -ItemType Directory -Force -Path (Join-Path $ProbeDst "common") | Out-Null
    $sm = Join-Path $OffSave "mods.txt"
    Write-Text $sm ((Read-Text $sm) -replace 'mod = ZeD_UI,', 'mod = ZeDQA_Probe,')
    Write-Text $DefaultMods ((Read-Text $DefaultMods) -replace 'mod = ZeD_UI,', 'mod = ZeDQA_Probe,')
    $null = Invoke-Phase "off"

    # on: ZeD back
    Write-Text $sm ((Read-Text $sm) -replace 'mod = ZeDQA_Probe,', 'mod = ZeD_UI,')
    Copy-Item (Join-Path $Keep "default.txt.bak") $DefaultMods -Force
    $null = Invoke-Phase "on"
}
finally {
    if (Test-GameRunning) { Say ("quit: " + (Stop-Game)); $null = & (Join-Path $QaDir "pzrestorewin.ps1") 2>&1 }
    Copy-Item (Join-Path $Keep "default.txt.bak") $DefaultMods -Force
    Copy-Item (Join-Path $Keep "latestSave.ini.bak") $LatestSave -Force
    if (Test-Path (Join-Path $Keep "ModOptions.ini.bak")) { Copy-Item (Join-Path $Keep "ModOptions.ini.bak") $ModOptions -Force }
    if (-not $restoredQa -and (Test-Path $snap) -and -not (Test-GameRunning)) {
        if (Test-Path $QaSave) { Remove-Item -Recurse -Force $QaSave }
        Copy-Item -Recurse $snap $QaSave
        Say "ZeD-QA put back from the copy taken first"
    }
    if (Test-Path $ProbeDst) { Remove-Item -Recurse -Force $ProbeDst }
    if (Test-Path $OffSave) { Copy-Item -Recurse $OffSave (Join-Path $Keep "ZeD-QA-off.save"); Remove-Item -Recurse -Force $OffSave }
    Write-Text $LockFile "free"
    Write-Output "zedqa_offsave_run: done; default.txt, latestSave.ini, ModOptions.ini, the lock put back; the probe and ZeD-QA-off removed (copies in $Keep)"
}
