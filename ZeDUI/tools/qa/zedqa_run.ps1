#Requires -Version 7.0
<#
.SYNOPSIS
    Unattended ZeD-UI regression run through the QA bridge (Oct 19 2026).

.DESCRIPTION
    Launches Project Zomboid with -debug on the ZeD-QA save (a 1920x1080 window,
    or the director's 3840x2160 fullscreen), runs every script listed in a
    manifest through the QA bridge (Zomboid/Lua/zedqa.lua + zedqa.go), quits
    the game and writes a Markdown report.

    The game is one shared instance. The runner refuses to start (exit 2) while
    Zomboid/Lua/zedqa.lock says "busy" or ProjectZomboid64.exe is running. It
    writes "busy" for the whole run and always writes "free" at the end, also
    when the run fails or the runner itself errors.

    Per script: copy it to Zomboid/Lua/zedqa.lua, bump zedqa.go (a counter kept
    in Zomboid/Lua/zedqa.counter, above 9999), then read only what console.txt
    gained since the bump until "ZEDQA <tag> DONE" (counted only after this
    bump's own "[ZeD.QA] run #" line), "[ZeD.QA] run #N ok=false" or the
    timeout. No console line at all within 20 s of the bump: bump once more (a
    game that is logging is never bumped twice). A timeout, a paused game (the
    prelude's "ERR OnTick never ran", after two more clicks), the game closing or
    dropping to the main menu stops the run: the rest are SKIP. Every tag in the
    manifest must be unique.

      PASS     reached DONE with no ERR line and no Lua error
      WARN     DONE with an ERR line of its own (ERR, FAIL, "spawn failed",
               "step error", "step <n> failed"), or the script ran twice
      FAIL     ok=false / compile error, a Java "Exception thrown" or
               "attempted index" in the window (minus the manifest's expect=),
               or the game closed / dropped to the main menu during it
      TIMEOUT  no DONE before the timeout (the run stops there)
      SKIP     not run (the run stopped before it)
    "(expect ...)" prints are shown in the report, not checked.

    Before every script the windows go back to their default spread, as the
    footer's R does (ZeD_Window.resetLayout), so no script inherits another's
    window places or sizes (director, Oct 22 2026).

    ZeD's UI scale is set for the run in Zomboid/Lua/ModOptions.ini: 1.75x in
    fullscreen4k (director, Oct 22 2026: "for 4k, set scale to 1.75"), Auto in the
    1080p window. The director's own ModOptions.ini is copied aside first and put
    back once the game has closed (kept beside the report as <report>.modoptions.ini
    if it could not be put back).

    Exit codes: 0 no FAIL / TIMEOUT / SKIP, 1 otherwise, 2 refused to start.

.PARAMETER Manifest
    The manifest (default regression.txt beside this script). One script per
    line, relative to ZeDUI/tools/qa:
        <script> | <tag> | timeout=<s> | end=<regex> | expect=<regex>   # comment

.PARAMETER Mode
    fullscreen4k (default since Oct 22 2026, "test it at real play scale"):
    pzrestorewin.ps1 first, then the director's own options (3840x2160
    fullscreen), the start click at the screen centre.
    windowed: pzlaunchwin.ps1, a 1920x1080 window; the fullscreen options are
    put back with pzrestorewin.ps1 once the game has closed.

.PARAMETER TimeoutSec
    Seconds per script (default 180); a manifest line's timeout= wins.

.PARAMETER Report
    The report path (default ZeDUI/qa/regression/<yyyy-MM-dd_HHmm>_<mode>.md).

.PARAMETER KeepOpen
    Leave the game running at the end (no quit, no options restore).

.PARAMETER Check
    Read and check the manifest only (scripts, tags, the allowlist rule) and
    list the QA scripts it leaves out. Touches neither the lock nor the game.

.EXAMPLE
    & C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1
.EXAMPLE
    & C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1 -Mode fullscreen4k
.EXAMPLE
    & C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1 -Check
#>
[CmdletBinding()]
param(
    [string]$Manifest = "C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/regression.txt",
    [ValidateSet("windowed", "fullscreen4k")][string]$Mode = "fullscreen4k",   # (director, Oct 22 2026: test at real play scale)
    [ValidateRange(5, 86400)][int]$TimeoutSec = 180,
    [string]$Report = "",
    [switch]$KeepOpen,
    [switch]$Check
)

# ============================================================================
# Places (fixed: the director's machine)
# ============================================================================
$ZomboidDir  = "C:\Users\danie\Zomboid"
$LuaDir      = Join-Path $ZomboidDir "Lua"
$LockFile    = Join-Path $LuaDir "zedqa.lock"
$GoFile      = Join-Path $LuaDir "zedqa.go"
$BridgeLua   = Join-Path $LuaDir "zedqa.lua"
$CounterFile = Join-Path $LuaDir "zedqa.counter"
$AutoFile    = Join-Path $LuaDir "zedqa.autoload"
$ConsoleFile = Join-Path $ZomboidDir "console.txt"
$ShotDir     = Join-Path $ZomboidDir "Screenshots"
$LatestSave  = Join-Path $ZomboidDir "latestSave.ini"
$OptionsIni  = Join-Path $ZomboidDir "options.ini"
$ModOptions  = Join-Path $LuaDir "ModOptions.ini"
$ResetPrefix = 'pcall(function() if ZeD_Window and ZeD_Window.resetLayout then ZeD_Window.resetLayout(); print("[ZeD.QA] windows reset (R)") end end); '
$VersionTxt  = Join-Path $ZomboidDir "version.txt"
$QaDir       = "C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa"
$ReportDir   = "C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression"
$ModInfo     = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\mod.info"
$GameDir     = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$GameExe     = Join-Path $GameDir "ProjectZomboid64.exe"
$LaunchWin   = Join-Path $QaDir "pzlaunchwin.ps1"
$RestoreWin  = Join-Path $QaDir "pzrestorewin.ps1"
$FrontWin    = Join-Path $QaDir "pzfront.ps1"

# Never unattended (director): a save, the character's death, the Workshop,
# the overnight / main-menu / design-capture scripts. Matched on the file name.
$NeverRun = @(
    '^zedqa_new_qa_save', '^zedqa_mod_workshop', '^zedqa_mods_', 'workshop', 'upload',
    '^zedqa_overnight_', '^zedqa_menu_', '^zedqa_desktop', '^zedqa_desk_v3', '^zedqa_menushot',
    '^zedqa_titlevideo', '^zedqa_death_sleep', '^zedqa_modapi_probe', '^zedqa_body',
    '^zedqa_avatar', '^zedqa_figure_tabs'
)
# A script that can quit the game, make a save, reach the Workshop or only runs
# at the main menu is refused whatever its name.
$NeverSource = 'getCore\(\)\s*:\s*quit|quitToDesktop|createWorld\s*\(|workshopSubmit|SteamWorkshop|MM\.act\.(quit|workshop)|Events\.OnFETick'

$PausedAbort = "the game is paused (OnTick never ran)"   # the prelude's "ERR OnTick never ran"

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$EntryStart = '^(\[[^\]]*\]\s*)?(LOG|WARN|ERROR|DEBUG|INFO|TRACE|FATAL)\s*:'

# run state (script scope)
$script:ConsoleLog         = New-Object System.Text.StringBuilder   # console.txt of this launch, NULs stripped
$script:ConsoleSeen = 0                                      # chars of the stripped console.txt taken in
$script:RunNotes    = New-Object System.Collections.Generic.List[string]
$script:GoNumbers   = New-Object System.Collections.Generic.List[long]
$script:Launched    = $false

# ============================================================================
# Small helpers
# ============================================================================
function Write-Text([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function Read-Text([string]$Path) {
    try { return [string](Get-Content -LiteralPath $Path -Raw -ErrorAction Stop) } catch { return $null }
}

function Add-Note([string]$Text) {
    $script:RunNotes.Add($Text)
    Write-Host "  $Text"
}

# tasklist, as the lock rule says; Get-Process as a second opinion
function Test-GameRunning {
    $out = ""
    try { $out = (& tasklist.exe /FI "IMAGENAME eq ProjectZomboid64.exe" /NH 2>$null) -join "`n" } catch { }
    if ($out -match 'ProjectZomboid64\.exe') { return $true }
    return [bool](Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)
}

# the cheap check inside the wait loops
function Test-GameAlive { return [bool](Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue) }

function Get-LockState {
    $t = Read-Text $LockFile
    if ($null -eq $t) { return "" }
    return $t.Trim().ToLowerInvariant()
}

# ZeD's settings to their defaults for the run; the director's own file is kept to put back
$script:ModOptionsSaved = $null
function Reset-ZeDSettings([string]$RunMode, [string]$Keep) {
    $t = Read-Text $ModOptions
    if ($null -eq $t) { $t = "" }
    $script:ModOptionsSaved = $t
    Write-Text $Keep $t
    # only the UI scale is set: 1.75x at 4K, ZeD's default (Auto) in the 1080p window; the rest stay the director's
    $lines = @(($t -split "\r?\n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' })
    $set = "UI scale Auto (1080p window)"
    if ($RunMode -eq "fullscreen4k") { $lines += "combobox|ZeD_UI|uiScale|7"; $set = "UI scale 1.75x (4K)" }
    Write-Text $ModOptions (($lines -join "`r`n") + "`r`n")
    Add-Note "ZeD settings: $set (the director's ModOptions.ini kept aside)"
}
function Restore-ZeDSettings([string]$Keep) {
    if ($null -eq $script:ModOptionsSaved) { return }
    if (Test-GameRunning) { Add-Note "ZeD settings NOT put back (the game is still running): copy $Keep over $ModOptions once it has closed"; return }
    Write-Text $ModOptions $script:ModOptionsSaved
    Remove-Item -LiteralPath $Keep -ErrorAction SilentlyContinue
    Add-Note "ZeD settings: the director's ModOptions.ini put back"
}

function Set-Lock([string]$State) {
    try { Write-Text $LockFile $State } catch { Write-Warning "could not write $LockFile ($State): $($_.Exception.Message)" }
}

# ============================================================================
# console.txt: everything this launch wrote, taken in whole lines
# ============================================================================
# Reads console.txt (-Raw, NULs stripped) and appends the complete lines it
# gained since the last read to $script:ConsoleLog; returns the log's length. If the
# file got shorter, the game started a new one (it does when the log grows
# large): the new file is taken from its start.
function Update-Log {
    $raw = Read-Text $ConsoleFile
    if ($null -eq $raw) { return $script:ConsoleLog.Length }
    $text = $raw -replace "`0", ""
    if ($text.Length -lt $script:ConsoleSeen) {
        $script:RunNotes.Add("console.txt restarted at $(Get-Date -Format 'HH:mm:ss') (the game starts a new one when it grows large); anything between the last read and the restart is missing")
        $script:ConsoleSeen = 0
    }
    if ($text.Length -gt $script:ConsoleSeen) {
        $new = $text.Substring($script:ConsoleSeen)
        $nl = $new.LastIndexOf("`n")
        if ($nl -ge 0) {
            [void]$script:ConsoleLog.Append($new.Substring(0, $nl + 1))
            $script:ConsoleSeen += $nl + 1
        }
    }
    return $script:ConsoleLog.Length
}

function Get-LogText([int]$From, [int]$To = -1) {
    $len = $script:ConsoleLog.Length
    if ($To -lt 0 -or $To -gt $len) { $To = $len }
    if ($From -lt 0) { $From = 0 }
    if ($From -ge $To) { return "" }
    return $script:ConsoleLog.ToString($From, $To - $From)
}

# A log entry is a line starting with "LOG :", "ERROR:", ... (console.txt) or
# "[timestamp] LOG :" (a Logs/*_DebugLog.txt) plus the lines under it.
function Split-Entries([string]$Text) {
    $entries = New-Object System.Collections.Generic.List[psobject]
    $cur = $null
    foreach ($line in ($Text -split "`n")) {
        $l = $line -replace "`r", ""   # (the logger can leave a CR inside a line, before its closing ".")
        if ($l.Trim() -eq "") { continue }
        if ($null -eq $cur -or $l -match $EntryStart) {
            $cur = [pscustomobject]@{ Head = $l; More = (New-Object System.Collections.Generic.List[string]) }
            $entries.Add($cur)
        } else {
            $cur.More.Add($l)
        }
    }
    return , $entries
}

# A line as the report shows it: Lua prints lose the "LOG : Lua f:123>" prefix.
function Get-Display([string]$Line) {
    $s = $Line -replace '^(\[[^\]]*\]\s*)?LOG\s*:\s*Lua\s+f:\d+>\s*', ''
    return ($s -replace '\s{2,}', ' ').Trim()
}

# The lines under an ERROR entry worth keeping: the message and the Lua frames,
# not the dashes or the Java frames.
function Get-ErrorDetail($Entry, [int]$Max = 6) {
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($m in $Entry.More) {
        $t = $m.Trim()
        if ($t -eq "" -or $t -match '^-+\.?$' -or $t -match '^(DEBUG-MODE )?STACK TRACE:?\.?$' -or $t -match '^Stack trace:$') { continue }
        if ($t -match '^(se|zombie|java|jdk|sun|org|com)\.[\w\.$<>/]+\(.*\)\.?$' -and $t -notmatch ': ') { continue }
        $out.Add($t)
        if ($out.Count -ge $Max) { break }
    }
    return $out.ToArray()   # callers wrap it in @()
}

# -debug prints every Lua error three more times as stack dumps ("dumping Lua
# stack trace", "DEBUG-MODE STACK TRACE" and its frames as ERROR lines); the
# report keeps the message and the "Exception thrown" entry only.
function Test-StackDump([string]$Head) {
    if ($Head -match 'dumping Lua stack trace|DEBUG-MODE STACK TRACE') { return $true }
    return ($Head -match '^(\[[^\]]*\]\s*)?ERROR\s*:\s*Lua\s+f:\d+>\s*Lua\([^)]*\)\.\S+\(.*\)\.?\s*$')
}

# ============================================================================
# Scripts and the manifest
# ============================================================================
# The tag a script prints after "ZEDQA ": its say() prefix, else the tag of
# its DONE line, else the first "ZEDQA <word>" in it.
function Get-ScriptTag([string]$Source) {
    $m = [regex]::Match($Source, 'function\s+say\s*\([^)]*\)\s*print\s*\(\s*"ZEDQA (\w+)')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Source, '"ZEDQA (\w+)[^"\r\n]*\bDONE\b')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Source, '"ZEDQA (\w+):? done\b', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Source, '"ZEDQA (\w+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Screenshot name stems: in a script's source the quoted "zqa_bw_" /
# "zedqa_win_100" strings it builds names from; in its output (-Printed) the
# names it printed ("zqa_x_1.png").
function Get-ShotPrefixes([string]$Text, [switch]$Printed) {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $rx = $(if ($Printed) { '(z(?:ed)?qa_[\w\-]+)\.png' } else { '["''](z(?:ed)?qa_[A-Za-z0-9_\-]*)' })
    foreach ($m in [regex]::Matches($Text, $rx)) { [void]$set.Add($m.Groups[1].Value) }
    return [string[]]@($set)
}

# A line that ends a script: the manifest's end=, "ZEDQA <tag> ... DONE", or
# "ZEDQA <tag> done" (the suites print it in lower case).
function Test-DoneLine([string]$Line, [string]$Tag, [string]$EndRegex) {
    if ($Line -notmatch 'ZEDQA') { return $false }
    if ($EndRegex -and $Line -match $EndRegex) { return $true }
    $t = [regex]::Escape($Tag)
    if ($Line -cmatch ('ZEDQA\s+' + $t + '\b.*\bDONE\b')) { return $true }
    if ($Line -match ('ZEDQA\s+' + $t + ':?\s+done\b')) { return $true }
    return $false
}

function Read-Manifest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "manifest not found: $Path" }
    $items = New-Object System.Collections.Generic.List[psobject]
    $problems = New-Object System.Collections.Generic.List[string]
    $root = [System.IO.Path]::GetFullPath($QaDir).TrimEnd('\') + '\'
    $no = 0
    foreach ($raw in (Get-Content -LiteralPath $Path)) {
        $no++
        $line = ($raw -replace '\s+#.*$', '').Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }
        $parts = @($line -split '\|' | ForEach-Object { $_.Trim() })
        $rel = $parts[0]
        $tag = ""; $timeout = $TimeoutSec; $end = $null; $expect = $null
        for ($i = 1; $i -lt $parts.Count; $i++) {
            $p = $parts[$i]
            if ($p -match '^timeout\s*=\s*(\d+)$') { $timeout = [int]$Matches[1] }
            elseif ($p -match '^end\s*=\s*(.+)$') { $end = $Matches[1].Trim() }
            elseif ($p -match '^expect\s*=\s*(.+)$') { $expect = $Matches[1].Trim() }
            elseif ($i -eq 1 -and $p -match '^\w+$') { $tag = $p }
            elseif ($p -ne "") { $problems.Add("line ${no}: '$p' is not a tag, timeout=, end= or expect=") }
        }
        $full = [System.IO.Path]::GetFullPath((Join-Path $QaDir $rel))
        $name = [System.IO.Path]::GetFileName($full)
        if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $problems.Add("line ${no}: $rel is outside $QaDir"); continue }
        if ($name -notmatch '\.lua$') { $problems.Add("line ${no}: $rel is not a .lua script"); continue }
        if (-not (Test-Path -LiteralPath $full)) { $problems.Add("line ${no}: $rel not found"); continue }
        $bad = @($NeverRun | Where-Object { $name.ToLowerInvariant() -match $_ })
        if ($bad.Count -gt 0) { $problems.Add("line ${no}: $name is never run unattended (director's rule)"); continue }
        $src = [string](Get-Content -LiteralPath $full -Raw)
        if ($src -match $NeverSource) { $problems.Add("line ${no}: $name can quit the game, make a save, reach the Workshop or runs at the main menu ('$($Matches[0])')"); continue }
        foreach ($rx in @($end, $expect)) {
            if ($rx) { try { [void][regex]::new($rx) } catch { $problems.Add("line ${no}: bad regex '$rx'") } }
        }
        $inferred = Get-ScriptTag $src
        if (-not $tag) { $tag = $inferred }
        if (-not $tag) { $problems.Add("line ${no}: no ZEDQA tag in $name; give one as '$rel | <tag>'"); continue }
        $items.Add([pscustomobject]@{
            Line = $no; Rel = $rel; Name = $name; Path = $full; Tag = $tag; Inferred = $inferred
            Timeout = $timeout; End = $end; Expect = $expect; Prefixes = (Get-ShotPrefixes $src)
        })
    }
    # one tag per script across the whole manifest: a script's DONE and ERR lines
    # are told apart from another's by the tag alone
    $byTag = @{}
    foreach ($it in $items) {
        $k = $it.Tag.ToLowerInvariant()
        if ($byTag.ContainsKey($k)) { $problems.Add("line $($it.Line): tag '$($it.Tag)' ($($it.Name)) is already line $($byTag[$k].Line)'s ($($byTag[$k].Name)); every script needs its own tag") }
        else { $byTag[$k] = $it }
    }
    if ($problems.Count -gt 0) { throw ("manifest problems in ${Path}:`n  " + ($problems -join "`n  ")) }
    if ($items.Count -eq 0) { throw "the manifest lists no script: $Path" }
    $allTags = @($items | ForEach-Object { $_.Tag })
    foreach ($it in $items) {
        $own = $it.Tag
        $it | Add-Member -NotePropertyName Others -NotePropertyValue ([string[]]@($allTags | Where-Object { $_ -ne $own }))
    }
    return , $items
}

# ============================================================================
# The bridge
# ============================================================================
# Writes the next number to zedqa.go (the counter lives in zedqa.counter and
# starts above 9999 so it never repeats numbers written by hand).
function Invoke-Bump {
    [long]$n = 9999
    $t = Read-Text $CounterFile
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    if ($n -lt 9999) { $n = 9999 }
    $n++
    $cur = Read-Text $GoFile
    if ($cur -and $cur.Trim() -eq "$n") { $n++ }
    Write-Text $CounterFile "$n"
    Write-Text $GoFile "$n`n"
    $script:GoNumbers.Add($n)
    return $n
}

# ============================================================================
# Launch and quit
# ============================================================================
function Initialize-Input {
    if (-not ('ZedQaRunnerInput' -as [type])) {
        Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedQaRunnerInput {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
}
"@
    }
    [void][ZedQaRunnerInput]::SetProcessDPIAware()
}

# The "click to start" click: the game's window to the front (pzfront.ps1),
# then a left click at its centre (4K fullscreen: the screen centre 1920,1080).
function Invoke-StartClick {
    # never click the desktop: only with the game's window there
    $proc = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc -or $proc.MainWindowHandle -eq [IntPtr]::Zero) { return "no click (no game window)" }
    Initialize-Input
    try { & $FrontWin | Out-Null } catch { }
    $x = 1920; $y = 1080
    if ($Mode -eq "windowed") {
        $h = $proc.MainWindowHandle
        $r = New-Object ZedQaRunnerInput+RECT
        [void][ZedQaRunnerInput]::GetClientRect($h, [ref]$r)
        $pt = New-Object ZedQaRunnerInput+POINT
        $pt.X = [int](($r.R - $r.L) / 2); $pt.Y = [int](($r.B - $r.T) / 2)
        [void][ZedQaRunnerInput]::ClientToScreen($h, [ref]$pt)
        $x = $pt.X; $y = $pt.Y
    }
    [void][ZedQaRunnerInput]::SetCursorPos($x, $y); Start-Sleep -Milliseconds 400
    [void][ZedQaRunnerInput]::SetCursorPos($x + 2, $y + 2); Start-Sleep -Milliseconds 300
    [ZedQaRunnerInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150
    [ZedQaRunnerInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    return "$x,$y"
}

function Start-GameWindowed {
    $global:LASTEXITCODE = 0
    $script:Launched = $true   # (pzlaunchwin.ps1 changes options.ini first thing)
    $out = (& $LaunchWin 2>&1 | Out-String).Trim()
    $code = $LASTEXITCODE
    Add-Note "pzlaunchwin.ps1: $($out -replace '\s*\r?\n\s*', ' / ')"
    if ($code -ne 0 -or $out -match 'never reached') { throw "the game did not finish loading (pzlaunchwin.ps1 exit $code)" }
}

function Start-Game4K {
    $global:LASTEXITCODE = 0
    $out = (& $RestoreWin 2>&1 | Out-String).Trim()
    Add-Note "pzrestorewin.ps1 (before a fullscreen run): $($out -replace '\s*\r?\n\s*', ' / ')"
    Write-Text $AutoFile "1"
    $script:Launched = $true
    # the last session's console.txt also says "game loading took": only the new
    # one counts (different from the old text, or written since the launch)
    $old = Read-Text $ConsoleFile
    $oldText = $(if ($old) { $old -replace "`0", "" } else { "" })
    $launchAt = (Get-Date).AddSeconds(-2)
    Start-Process -FilePath $GameExe -ArgumentList "-debug" -WorkingDirectory $GameDir | Out-Null
    Add-Note "started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)"
    Start-Sleep -Seconds 10   # the game moves the old console.txt to Logs/ as it starts
    $loaded = $false
    for ($i = 0; $i -lt 150; $i++) {
        Start-Sleep -Seconds 2
        if (-not (Test-GameAlive)) { throw "the game closed (or never started) while loading" }
        $c = Read-Text $ConsoleFile
        if (-not $c) { continue }
        $t = $c -replace "`0", ""
        $fresh = ($oldText.Length -eq 0) -or ($t.Length -lt $oldText.Length) -or (-not $t.StartsWith($oldText, [StringComparison]::Ordinal))
        if (-not $fresh) { try { $fresh = (Get-Item -LiteralPath $ConsoleFile -ErrorAction Stop).LastWriteTime -ge $launchAt } catch { } }
        if ($fresh -and $t -match 'game loading took') { $loaded = $true; break }
    }
    if (-not $loaded) { throw "the game never reached 'game loading took' (5 minutes)" }
    Start-Sleep -Seconds 4
    $at = Invoke-StartClick
    Add-Note "loaded; clicked the screen centre ($at) to pass 'click to start'"
}

# Waits for the bridge to arm in game (clicking again if "click to start" did
# not take), then makes sure the save is Saves/Sandbox/ZeD-QA. With -Prelude
# (the manifest's zedqa_prelude.lua and its result) it also runs the prelude,
# and while the prelude finds the game paused ("ERR OnTick never ran": the
# bridge can arm before "click to start" is passed) it clicks again and runs the
# prelude again, twice at most; a prelude still paused after that leaves the
# abort in its result.
function Wait-BridgeInGame($Prelude = $null, $PreludeRes = $null) {
    $t0 = Get-Date; $clicks = 1
    while ($true) {
        Start-Sleep -Seconds 2
        $null = Update-Log
        $all = $script:ConsoleLog.ToString()
        if ($all -match '\[ZeD\.QA\] bridge armed \(in game') { break }
        if ($all -match '\[ZeD\.QA\] autoload: no Continue') { throw "the main menu had no Continue for the autoload" }
        if (-not (Test-GameAlive)) { throw "the game closed while loading" }
        $el = ((Get-Date) - $t0).TotalSeconds
        if ($el -ge 30 * $clicks -and $clicks -lt 3) {
            $at = Invoke-StartClick; $clicks++
            Add-Note "clicked again at $at (the bridge had not armed in game after $([int]$el) s)"
        }
        if ($el -ge 120) { throw "the bridge never armed in game (no '[ZeD.QA] bridge armed (in game' in console.txt)" }
    }
    Start-Sleep -Seconds 3
    $null = Update-Log
    $all = $script:ConsoleLog.ToString()
    $m = [regex]::Match($all, 'Loading WorldDictionary:([^\r\n]*)')
    if ($m.Success) { $isQa = $m.Groups[1].Value -match 'Saves[\\/]+Sandbox[\\/]+ZeD-QA[\\/]' }
    else { $isQa = $all -match '\[ZeD\.QA\] ZeD-QA: the whole map known' }
    if (-not $isQa) { throw "the loaded save is not Saves/Sandbox/ZeD-QA ($($m.Groups[1].Value)); no script was run" }
    Add-Note "the bridge armed in game on Saves/Sandbox/ZeD-QA"
    if (-not $Prelude) { return }
    for ($try = 1; ; $try++) {
        Invoke-QaScript $Prelude $PreludeRes
        if ($PreludeRes.Abort -ne $PausedAbort -or $try -ge 3) { break }
        $at = Invoke-StartClick
        Add-Note "the prelude found the game paused (OnTick never ran): clicked again at $at and ran it again"
        Reset-Result $PreludeRes
    }
}

# Quit through the bridge: autoload off, getCore():quit() once (in game: to the
# main menu, with a Lua reload), then again once the bridge has re-armed at the
# menu (to the desktop). Gives up after about a minute per step, never kills.
function Stop-Game {
    if (-not (Test-GameRunning)) { return "the game was not running" }
    Write-Text $AutoFile "0"
    Write-Text $BridgeLua "-- zedqa_run.ps1: quit (in game to the main menu, at the menu to the desktop)`ngetCore():quit()`n"
    $from = Update-Log
    $n1 = Invoke-Bump
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt 60) {
        Start-Sleep -Seconds 2
        if (-not (Test-GameRunning)) { return "quit (go $n1)" }
        $null = Update-Log
        if ((Get-LogText $from) -match '\[ZeD\.QA\] bridge armed \(main menu') { break }
    }
    Start-Sleep -Seconds 4
    $n2 = Invoke-Bump; $bumps = "$n1, $n2"
    $t0 = Get-Date; $again = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 60) {
        Start-Sleep -Seconds 2
        if (-not (Test-GameRunning)) { return "quit to the main menu, then to the desktop (go $bumps)" }
        if (-not $again -and ((Get-Date) - $t0).TotalSeconds -ge 20) { $bumps += ", $(Invoke-Bump)"; $again = $true }
    }
    return "the game was still running after the quit (go $bumps); close it by hand"
}

# ============================================================================
# One script
# ============================================================================
# Everything a script window (bump to the next bump) says: the verdict and the
# lines the report keeps.
#
# DONE counts only after the window's own "[ZeD.QA] run #" line (the bridge
# prints it once the chunk has returned; every script prints DONE from a later
# tick), so a late DONE of the script before cannot end this one.
# ERR lines: a "ZEDQA" line is charged to this script unless its first word is
# another manifest entry's tag (-OtherTags): that is late output of that script,
# listed as such. Untagged prints ("ZEDQA step error: ...", the suites' "ZEDQA
# after ...") stay charged to this script. Charged when the line has ERR or FAIL
# (case-sensitive words), "spawn failed", "step error" or "step <n> failed".
# "(expect ...)" prints are shown, not checked.
function Measure-Window([string]$Text, [string]$Tag, [string]$EndRegex, [string]$ExpectRegex, [string[]]$OtherTags = @()) {
    $v = [pscustomobject]@{
        Done = $false; OkFalse = $false; Responded = $false; MainMenu = $false; Paused = $false
        Runs = 0; ErrLines = 0; Exceptions = 0; Expected = 0
        Late = [ordered]@{}
        Lines = (New-Object System.Collections.Generic.List[string])
    }
    $others = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($o in @($OtherTags)) { if ($o -and $o -ne $Tag) { [void]$others.Add($o) } }
    $entries = Split-Entries $Text
    # which exception entries count (the "Exception thrown" ones when there are
    # any, else every "attempted index" entry): each of them is always shown
    $thrown = 0; $evidence = 0; $expThrown = 0; $expEvidence = 0
    $kind = New-Object 'object[]' ($entries.Count)
    for ($x = 0; $x -lt $entries.Count; $x++) {
        $e = $entries[$x]
        if ($e.Head -match '\[ZeD\.QA\]|ZEDQA') { continue }
        $all = $e.Head
        if ($e.More.Count -gt 0) { $all = $e.Head + "`n" + ($e.More -join "`n") }
        if ($all -notmatch 'Exception thrown|attempted index') { continue }
        $expected = [bool]($ExpectRegex -and $all -match $ExpectRegex)
        $isThrown = [bool]($e.Head -match 'Exception thrown')
        $kind[$x] = [pscustomobject]@{ Expected = $expected; Thrown = $isThrown }
        if ($expected) { $expEvidence++; if ($isThrown) { $expThrown++ } }
        else { $evidence++; if ($isThrown) { $thrown++ } }
    }
    $ran = $false
    for ($x = 0; $x -lt $entries.Count; $x++) {
        $e = $entries[$x]; $head = $e.Head
        if ($head -match '\[ZeD\.QA\]') {
            $v.Lines.Add((Get-Display $head))
            if ($head -match '\[ZeD\.QA\] run #\d+') { $v.Runs++; $ran = $true }
            if ($head -match '\[ZeD\.QA\] (run #\d+|compile error|zedqa\.lua missing)') { $v.Responded = $true }
            if ($head -match '\[ZeD\.QA\] (run #\d+ ok=false|compile error|zedqa\.lua missing)') { $v.OkFalse = $true }
            if ($head -match '\[ZeD\.QA\] bridge armed \(main menu') { $v.MainMenu = $true }
            continue
        }
        if ($head -match 'ZEDQA') {
            $mt = [regex]::Match($head, 'ZEDQA\s+(\w+)')
            $lineTag = $(if ($mt.Success) { $mt.Groups[1].Value } else { "" })
            $own = [bool]($head -match ('ZEDQA\s+' + [regex]::Escape($Tag) + '\b'))
            if (-not $own -and $lineTag -and $others.Contains($lineTag)) {
                $v.Lines.Add((Get-Display $head) + "   (late output from $lineTag)")
                foreach ($m in $e.More) { $v.Lines.Add("    " + $m.Trim()) }
                if ($v.Late.Contains($lineTag)) { $v.Late[$lineTag] = $v.Late[$lineTag] + 1 } else { $v.Late[$lineTag] = 1 }
                continue
            }
            $v.Lines.Add((Get-Display $head))
            foreach ($m in $e.More) { $v.Lines.Add("    " + $m.Trim()) }
            if ($ran -and (Test-DoneLine $head $Tag $EndRegex)) { $v.Done = $true }
            if ($head -cmatch '\b(ERR|FAIL)\b' -or $head -match 'spawn failed|step error|step \d+ failed') { $v.ErrLines++ }
            if ($head -match 'ERR OnTick never ran') { $v.Paused = $true }
            continue
        }
        $all = $head
        if ($e.More.Count -gt 0) { $all = $head + "`n" + ($e.More -join "`n") }
        $k = $kind[$x]
        $expected = [bool]($k -and $k.Expected)
        $counted = $false
        if ($k) {
            if ($k.Expected) { $counted = ($expThrown -eq 0) -or $k.Thrown }
            else { $counted = ($thrown -eq 0) -or $k.Thrown }
        }
        if ($head -match '^(\[[^\]]*\]\s*)?ERROR\s*:' -and $all -match 'ZeD|Lua' -and -not (Test-StackDump $head)) {
            $v.Lines.Add((Get-Display $head) + $(if ($expected) { "   (expected)" } else { "" }))
            foreach ($d in @(Get-ErrorDetail $e)) { $v.Lines.Add("    " + $d) }
        }
        elseif ($counted) {
            # an entry counted as an exception is always shown: its head and first detail line
            $v.Lines.Add((Get-Display $head) + $(if ($expected) { "   (expected)" } else { "" }))
            $d = @(Get-ErrorDetail $e 1)
            if ($d.Count -eq 0) { $d = @($e.More | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1 | ForEach-Object { $_.Trim() }) }
            if ($d.Count -gt 0) { $v.Lines.Add("    " + $d[0]) }
        }
    }
    $v.Exceptions = $(if ($evidence -eq 0) { 0 } elseif ($thrown -gt 0) { $thrown } else { $evidence })
    $v.Expected = $(if ($expEvidence -eq 0) { 0 } elseif ($expThrown -gt 0) { $expThrown } else { $expEvidence })
    return $v
}

# Repeated lines once, with a count; at most $Max lines.
function Compress-Lines($Lines, [int]$Max = 400) {
    $out = New-Object System.Collections.Generic.List[string]
    $arr = @($Lines)
    $i = 0
    while ($i -lt $arr.Count) {
        $j = $i
        while ($j + 1 -lt $arr.Count -and $arr[$j + 1] -eq $arr[$i]) { $j++ }
        $n = $j - $i + 1
        $out.Add($(if ($n -gt 1) { "$($arr[$i])   (x$n)" } else { [string]$arr[$i] }))
        $i = $j + 1
    }
    if ($out.Count -gt $Max) {
        $extra = $out.Count - $Max
        $out.RemoveRange($Max, $extra)
        $out.Add("... ($extra more lines; see console.txt)")
    }
    return $out.ToArray()   # callers wrap it in @()
}

function Get-Shots($Prefixes, [datetime]$Since) {
    $pre = @($Prefixes | Where-Object { $_ })
    if ($pre.Count -eq 0 -or -not (Test-Path -LiteralPath $ShotDir)) { return @() }
    $since2 = $Since.AddSeconds(-2)
    return @(Get-ChildItem -LiteralPath $ShotDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $since2 } |
        Where-Object { $n = $_.Name; @($pre | Where-Object { $n.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0 } |
        Sort-Object LastWriteTime | ForEach-Object { $_.Name })
}

function Invoke-QaScript($Item, $Res) {
    # every script starts from the windows' default spread: the footer's R (ZeD_Window.resetLayout)
    # is pressed first (director, Oct 22 2026: "reset the window location ... they keep jumping
    # around or are opening at too large of scale"). It goes on the script's own first line,
    # before whatever is there ("-- header" becomes a comment after it), so line numbers in
    # errors still match the file.
    $body = [System.IO.File]::ReadAllText($Item.Path)
    $body = $ResetPrefix + $body
    try { Write-Text $BridgeLua $body }
    catch { Start-Sleep -Seconds 1; Write-Text $BridgeLua $body }
    $from = Update-Log
    $t0 = Get-Date
    $Res.Started = $t0
    $Res.From = $from
    $Res.Go.Add((Invoke-Bump))
    $deadline = $t0.AddSeconds($Item.Timeout)
    $scan = $from; $responded = $false; $ran = $false; $rebumped = $false; $waitNoted = $false
    $done = $false; $failNow = $false; $menu = $false; $gone = $false; $timedOut = $false
    while ($true) {
        Start-Sleep -Milliseconds 1000
        $len = Update-Log
        if ($len -gt $scan) {
            foreach ($line in ((Get-LogText $scan $len) -split "`n")) {
                if ($line -match '\[ZeD\.QA\] run #\d+') { $ran = $true }
                if ($line -match '\[ZeD\.QA\] (run #\d+|compile error|zedqa\.lua missing)') { $responded = $true }
                if ($line -match '\[ZeD\.QA\] (run #\d+ ok=false|compile error|zedqa\.lua missing)') { $failNow = $true }
                if ($line -match '\[ZeD\.QA\] bridge armed \(main menu') { $menu = $true }
                # (only after this window's own "run #" line: see Measure-Window)
                if ($ran -and (Test-DoneLine $line $Item.Tag $Item.End)) { $done = $true }
            }
            $scan = $len
        }
        if ($done -or $failNow -or $menu) { break }
        if (-not (Test-GameAlive)) { $gone = $true; break }
        $el = ((Get-Date) - $t0).TotalSeconds
        if (-not $responded -and -not $rebumped -and $el -ge 20) {
            # bump again only when the game has written nothing at all since the
            # bump; a game that is logging but slow gets no second bump (it would
            # run the script twice)
            if ($len -le $from) {
                $Res.Go.Add((Invoke-Bump)); $rebumped = $true
                $Res.Notes.Add("no console line at all within 20 s of the bump: bumped again")
            } elseif (-not $waitNoted) {
                $waitNoted = $true
                $Res.Notes.Add("no '[ZeD.QA] run #' within 20 s, but the game was logging: not bumped again")
            }
        }
        if ((Get-Date) -ge $deadline) { $timedOut = $true; break }
    }
    $Res.Seconds = [int][math]::Round(((Get-Date) - $t0).TotalSeconds)
    # the 3 s between scripts: trailing lines and screenshots belong to this one
    if (-not $gone) { Start-Sleep -Seconds 3 }
    $Res.To = Update-Log
    $v = Measure-Window (Get-LogText $Res.From $Res.To) $Item.Tag $Item.End $Item.Expect @($Item.Others)
    $Res.Lines = @(Compress-Lines $v.Lines)
    $printed = @(Get-ShotPrefixes ((@($v.Lines) | Where-Object { $_ -match '\.png' }) -join "`n") -Printed)
    $Res.Shots = @(Get-Shots (@($Item.Prefixes) + $printed) $t0)
    $lost = $false
    if ($gone) { $Res.Abort = "the game closed during this script"; $lost = $true }
    elseif ($v.MainMenu) { $Res.Abort = "the game dropped to the main menu during this script"; $lost = $true }
    elseif ($timedOut -and -not $v.Done) { $Res.Abort = "no DONE within $($Item.Timeout) s; the script may still be running in the game" }
    elseif ($v.Paused) { $Res.Abort = $PausedAbort }
    if ($v.OkFalse) { $Res.Notes.Add("the bridge reported ok=false / a compile error") }
    if ($v.Exceptions -gt 0) { $Res.Notes.Add("$($v.Exceptions) Java exception(s) in the log") }
    if ($v.Expected -gt 0) { $Res.Notes.Add("$($v.Expected) expected exception(s) ignored (expect=)") }
    if ($v.ErrLines -gt 0) { $Res.Notes.Add("$($v.ErrLines) ERR line(s)") }
    if ($v.Runs -gt 1) { $Res.Notes.Add("the script ran twice (re-bump)") }
    foreach ($lt in $v.Late.Keys) { $Res.Notes.Add("late output from $lt ($($v.Late[$lt]) line(s), not counted)") }
    if (-not $v.Done -and -not $timedOut) { $Res.Notes.Add("no DONE") }
    if ($Res.Abort) { $Res.Notes.Add($Res.Abort) }
    $Res.Status = $(if ($v.OkFalse -or $v.Exceptions -gt 0 -or $lost) { "FAIL" }
        elseif (-not $v.Done) { "TIMEOUT" }
        elseif ($v.ErrLines -gt 0 -or $v.Runs -gt 1) { "WARN" }
        else { "PASS" })
}

# A result back to "not run", for the prelude's second try.
function Reset-Result($Res) {
    $Res.Status = "SKIP"; $Res.Seconds = 0; $Res.Abort = $null
    $Res.Notes.Clear(); $Res.Lines = @(); $Res.Shots = @()
}

# ============================================================================
# The report
# ============================================================================
function Get-Counts($Results) {
    $c = @{ PASS = 0; WARN = 0; FAIL = 0; TIMEOUT = 0; SKIP = 0 }
    foreach ($r in $Results) { $c[$r.Status] = $c[$r.Status] + 1 }
    return $c
}

# The one stdout line: "<pass>/<total> pass, <warn> warn, <fail> fail, <timeout> timeout[, <n> not run] -> <report>"
# (scripts not run count in the total, so the line adds up; the report names them).
function Get-SummaryLine($Results, [string]$Path) {
    $c = Get-Counts $Results
    $skip = $(if ($c.SKIP -gt 0) { ", $($c.SKIP) not run" } else { "" })
    return "$($c.PASS)/$(@($Results).Count) pass, $($c.WARN) warn, $($c.FAIL) fail, $($c.TIMEOUT) timeout$skip -> $Path"
}

function ConvertTo-Cell([string]$s) { return ($s -replace '\|', '\|' -replace '\r?\n', ' ') }

# ERROR entries of this launch outside every script window, once each with a count.
function Get-OutsideErrors($Results) {
    $wins = @($Results | Where-Object { $null -ne $_.From -and $null -ne $_.To } | Sort-Object From)
    $segments = New-Object System.Collections.Generic.List[string]
    $pos = 0
    foreach ($w in $wins) {
        if ($w.From -gt $pos) { $segments.Add((Get-LogText $pos $w.From)) }
        if ($w.To -gt $pos) { $pos = $w.To }
    }
    $segments.Add((Get-LogText $pos))
    $seen = [ordered]@{}
    foreach ($seg in $segments) {
        foreach ($e in (Split-Entries $seg)) {
            if ($e.Head -notmatch '^(\[[^\]]*\]\s*)?ERROR\s*:' -or (Test-StackDump $e.Head)) { continue }
            $key = (Get-Display $e.Head) -replace '^\[[^\]]*\]\s*', '' -replace 'f:\d+', 'f:N'
            $d = @(Get-ErrorDetail $e 1)
            if ($d.Count -gt 0) { $key += "  :: " + $d[0] }
            if ($seen.Contains($key)) { $seen[$key] = $seen[$key] + 1 } else { $seen[$key] = 1 }
        }
    }
    return $seen
}

function Write-Report($Results, [string]$Path, $Info) {
    $sb = New-Object System.Text.StringBuilder
    function Add([string]$s = "") { [void]$sb.AppendLine($s) }
    $c = Get-Counts $Results
    $total = @($Results).Count
    $logText = $script:ConsoleLog.ToString()
    $build = [regex]::Match($logText, 'version=(\S+\s+\S+)\s+demo=')
    $buildText = $(if ($build.Success) { $build.Groups[1].Value } else { $v = Read-Text $VersionTxt; if ($v) { ($v -split "`n")[0].Trim() + " (version.txt)" } else { "unknown" } })
    $modVer = "unknown"
    $mi = Read-Text $ModInfo
    if ($mi -and $mi -match '(?m)^modversion=(.+)$') { $modVer = $Matches[1].Trim() }
    $finished = $(if ($Info.Finished) { $Info.Finished } else { Get-Date })
    $dur = $finished - $Info.Started

    Add "# ZeD-UI regression - $($Info.Started.ToString('yyyy-MM-dd HH:mm')) - $($Info.ModeText)"
    Add ""
    Add "| | |"
    Add "|---|---|"
    Add "| Started | $($Info.Started.ToString('yyyy-MM-dd HH:mm:ss')) |"
    Add "| Finished | $($finished.ToString('yyyy-MM-dd HH:mm:ss')) ($([math]::Floor($dur.TotalMinutes)) min $($dur.Seconds) s)$(if (-not $Info.Finished) { ' - still running' }) |"
    Add "| Mode | $(ConvertTo-Cell $Info.ModeText) |"
    Add "| Display | $(ConvertTo-Cell $Info.Display) |"
    Add "| Game build | $(ConvertTo-Cell $buildText) |"
    Add "| Mod version | $(ConvertTo-Cell $modVer) |"
    Add "| Save | Saves/Sandbox/ZeD-QA |"
    Add "| Manifest | $(ConvertTo-Cell $Info.Manifest) ($total scripts) |"
    Add "| Result | **$($c.PASS)/$total pass**, $($c.WARN) warn, $($c.FAIL) fail, $($c.TIMEOUT) timeout$(if ($c.SKIP) { ", $($c.SKIP) not run" }) |"
    if ($script:GoNumbers.Count -gt 0) { Add "| Go numbers | $($script:GoNumbers[0]) to $($script:GoNumbers[$script:GoNumbers.Count - 1]) |" }
    Add ""
    Add "Screenshots are in ``C:/Users/danie/Zomboid/Screenshots`` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. ""(expect ...)"" prints are shown, not checked."
    Add ""
    if ($script:RunNotes.Count -gt 0) {
        Add "## Run notes"
        Add ""
        foreach ($n in $script:RunNotes) { Add "- $n" }
        Add ""
    }
    Add "## Results"
    Add ""
    Add "| # | Script | Tag | Status | Seconds | Screenshots | Notes |"
    Add "|---:|---|---|---|---:|---|---|"
    $i = 0
    foreach ($r in $Results) {
        $i++
        $st = $(if ($r.Status -in @("FAIL", "TIMEOUT")) { "**$($r.Status)**" } else { $r.Status })
        $shots = $(if (@($r.Shots).Count) { (@($r.Shots) -join ", ") } else { "" })
        $sec = $(if ($r.Status -eq "SKIP") { "" } else { "$($r.Seconds)" })
        Add "| $i | $(ConvertTo-Cell $r.Script) | $(ConvertTo-Cell $r.Tag) | $st | $sec | $(ConvertTo-Cell $shots) | $(ConvertTo-Cell (@($r.Notes) -join '; ')) |"
    }
    Add ""
    Add "## Scripts"
    $i = 0
    foreach ($r in $Results) {
        $i++
        Add ""
        $sec = $(if ($r.Status -eq "SKIP") { "not run" } else { "$($r.Seconds) s" })
        Add "### $i. $($r.Script) (``ZEDQA $($r.Tag)``) - $($r.Status), $sec"
        Add ""
        if (@($r.Go).Count) { Add "- go $((@($r.Go)) -join ', ')$(if ($r.Started) { ' at ' + $r.Started.ToString('HH:mm:ss') })" }
        foreach ($n in $r.Notes) { Add "- $n" }
        if (@($r.Shots).Count) { Add "- screenshots: $(@($r.Shots) -join ', ')" }
        if (@($r.Lines).Count) {
            Add ""
            Add '```text'
            foreach ($l in $r.Lines) { Add $l }
            Add '```'
        }
    }
    Add ""
    Add "## Console errors outside scripts"
    Add ""
    if ($logText.Length -eq 0) { Add "(console.txt was never read: the game did not start)" }
    else {
        $out = Get-OutsideErrors $Results
        if ($out.Count -eq 0) { Add "None." }
        else {
            Add "ERROR lines from launch to quit that fall in no script's window, once each (count first)."
            Add ""
            Add '```text'
            $k = 0
            foreach ($key in $out.Keys) {
                $k++
                if ($k -gt 300) { Add "... ($($out.Count - 300) more kinds)"; break }
                Add ("{0,5}x {1}" -f $out[$key], $key)
            }
            Add '```'
        }
    }
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Write-Text $Path $sb.ToString()
}

# Dot-sourced (". .\zedqa_run.ps1"): the functions only, nothing runs.
if ($MyInvocation.InvocationName -eq '.') { return }

# ============================================================================
# Main
# ============================================================================
try { $items = Read-Manifest $Manifest }
catch { Write-Output "zedqa_run: not starting: $($_.Exception.Message)"; exit 2 }

if ($Check) {
    Write-Host "Manifest $Manifest : $($items.Count) scripts"
    $k = 0
    foreach ($it in $items) {
        $k++
        $extra = @()
        if ($it.Inferred -and $it.Inferred -ne $it.Tag) { $extra += "script says '$($it.Inferred)'" }
        if ($it.Timeout -ne $TimeoutSec) { $extra += "timeout=$($it.Timeout)" }
        if ($it.End) { $extra += "end=$($it.End)" }
        if ($it.Expect) { $extra += "expect=$($it.Expect)" }
        Write-Host ("{0,3}. {1,-40} {2,-8} {3}" -f $k, $it.Rel, $it.Tag, ($extra -join "  "))
    }
    $listed = @($items | ForEach-Object { $_.Name.ToLowerInvariant() })
    $manText = (Get-Content -LiteralPath $Manifest -Raw)
    $missing = @(Get-ChildItem -LiteralPath $QaDir -File -Filter "*.lua" |
        Where-Object { $_.Name -match '^(zedqa_|suite_)' -and $listed -notcontains $_.Name.ToLowerInvariant() } |
        Where-Object { $manText -notmatch [regex]::Escape($_.Name) } | ForEach-Object { $_.Name })
    if ($missing.Count) { Write-Host "Not in the manifest and not named in its comments: $($missing -join ', ')" }
    else { Write-Host "Every zedqa_*.lua / suite_*.lua here is either listed or named in a comment." }
    exit 0
}

# refuse to start: a Workshop staging copy of ZeD-UI would shadow the dev mod (checked before the lock is read or written)
$staged = @(Get-ChildItem -Path "C:/Users/danie/Zomboid/Workshop/*/Contents/mods/*/42/mod.info", "C:/Users/danie/Zomboid/Workshop/*/Contents/mods/*/common/mod.info", "C:/Users/danie/Zomboid/Workshop/*/Contents/mods/*/mod.info" -ErrorAction SilentlyContinue |
    Where-Object { Select-String -LiteralPath $_.FullName -Pattern '^\s*id=ZeD_UI\s*$' -Quiet -ErrorAction SilentlyContinue } |
    ForEach-Object { $_.FullName -replace '[\\/]mods[\\/].*$', '' } | Select-Object -Unique)
if ($staged.Count -gt 0) {
    foreach ($folder in $staged) { Write-Output "A Workshop staging copy of ZeD-UI is at $folder; the game would load it instead of the dev mod. Remove its Contents folder (stage it again right before an upload)." }
    exit 3
}

# refuse to start: the shared game
$lock = Get-LockState
if ($lock -match '^busy') { Write-Output "zedqa_run: not starting: $LockFile says busy (another session holds the game)"; exit 2 }
if (Test-GameRunning) { Write-Output "zedqa_run: not starting: ProjectZomboid64.exe is running"; exit 2 }
$ls = Read-Text $LatestSave
$lsLines = @(([string]$ls) -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($lsLines.Count -lt 1 -or $lsLines[0] -ne "ZeD-QA" -or ($lsLines.Count -ge 2 -and $lsLines[1] -ne "Sandbox")) {
    Write-Output "zedqa_run: not starting: $LatestSave does not point at Saves/Sandbox/ZeD-QA (it reads '$($lsLines -join ' / ')'); the autoload would continue another save"
    exit 2
}
if (-not (Test-Path -LiteralPath $GameExe)) { Write-Output "zedqa_run: not starting: $GameExe not found"; exit 2 }

$started = Get-Date
if (-not $Report) { $Report = Join-Path $ReportDir ("{0}_{1}.md" -f $started.ToString("yyyy-MM-dd_HHmm"), $Mode) }
$Report = [System.IO.Path]::GetFullPath($Report)
$info = [pscustomobject]@{
    Started = $started; Finished = $null; Manifest = $Manifest
    ModeText = $(if ($Mode -eq "windowed") { "windowed (1920x1080 window)" } else { "fullscreen4k (3840x2160 fullscreen)" })
    Display = "not launched"
}
$results = New-Object System.Collections.Generic.List[psobject]
foreach ($it in $items) {
    $results.Add([pscustomobject]@{
        Script = $it.Rel; Tag = $it.Tag; Status = "SKIP"; Seconds = 0; Started = $null
        From = $null; To = $null; Go = (New-Object System.Collections.Generic.List[long])
        Notes = (New-Object System.Collections.Generic.List[string]); Lines = @(); Shots = @(); Abort = $null
    })
}

Write-Host "zedqa_run: $($items.Count) scripts, $Mode; report $Report"
try {
    Set-Lock "busy"   # (inside the try: the finally below always writes "free")
    Reset-ZeDSettings $Mode ($Report + ".modoptions.ini")
    if ($Mode -eq "windowed") { Start-GameWindowed } else { Start-Game4K }
    $opt = Read-Text $OptionsIni
    if ($opt) { $info.Display = ((([regex]::Matches($opt, '(?m)^(fullScreen|width|height)=\S+')) | ForEach-Object { $_.Value }) -join " ") }
    # the prelude runs inside Wait-BridgeInGame (a paused game gets another click)
    $preludeFirst = ($items[0].Name -ieq "zedqa_prelude.lua")
    if ($preludeFirst) { Wait-BridgeInGame $items[0] $results[0] } else { Wait-BridgeInGame }
    for ($i = 0; $i -lt $items.Count; $i++) {
        $it = $items[$i]; $res = $results[$i]
        Write-Host ("[{0}/{1}] {2} ({3}) ..." -f ($i + 1), $items.Count, $it.Rel, $it.Tag) -NoNewline
        if (-not ($i -eq 0 -and $preludeFirst)) { Invoke-QaScript $it $res }
        Write-Host " $($res.Status) $($res.Seconds) s$(if ($res.Notes.Count) { ' - ' + ($res.Notes -join '; ') })"
        try { Write-Report $results $Report $info } catch { }
        if ($res.Abort) {
            for ($j = $i + 1; $j -lt $items.Count; $j++) { $results[$j].Notes.Add("not run: $($res.Abort)") }
            Add-Note "stopped after $($it.Rel): $($res.Abort)"
            break
        }
        # (the 3 s between scripts are inside Invoke-QaScript, so they count to the script before)
    }
}
catch {
    Add-Note "runner stopped: $($_.Exception.Message) (zedqa_run.ps1 line $($_.InvocationInfo.ScriptLineNumber))"
    foreach ($r in $results) { if ($r.Status -eq "SKIP" -and $r.Notes.Count -eq 0) { $r.Notes.Add("not run: the runner stopped") } }
}
finally {
    try {
        if ($script:Launched -or (Test-GameRunning)) {
            if ($KeepOpen) {
                Add-Note "-KeepOpen: the game was left running$(if ($Mode -eq 'windowed') { '; run pzrestorewin.ps1 after closing it' })"
            } else {
                Add-Note ("quit: " + (Stop-Game))
            }
            $null = Update-Log
        }
        if ($Mode -eq "windowed" -and $script:Launched -and -not $KeepOpen) {
            if (Test-GameRunning) { Add-Note "options.ini is still the 1080p window: run pzrestorewin.ps1 once the game has closed" }
            else {
                $global:LASTEXITCODE = 0
                $out = (& $RestoreWin 2>&1 | Out-String).Trim()
                Add-Note "pzrestorewin.ps1: $($out -replace '\s*\r?\n\s*', ' / ')"
            }
        }
        if (-not $KeepOpen) { Restore-ZeDSettings ($Report + ".modoptions.ini") }
        else { Add-Note "-KeepOpen: ZeD settings are still the test's; the director's file is $Report.modoptions.ini" }
        $info.Finished = Get-Date
        Write-Report $results $Report $info
    }
    catch { Write-Warning "zedqa_run: the end of the run failed: $($_.Exception.Message)" }
    finally { Set-Lock "free" }
}

Write-Output (Get-SummaryLine $results $Report)
$cnt = Get-Counts $results
if ($cnt.FAIL -gt 0 -or $cnt.TIMEOUT -gt 0 -or $cnt.SKIP -gt 0) { exit 1 }
exit 0
