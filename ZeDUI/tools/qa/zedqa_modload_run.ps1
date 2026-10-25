#Requires -Version 7.0
<#
.SYNOPSIS
    Does a mod list load into the ZeD-QA save, with ZeD on or with ZeD off?
    (Oct 24 2026: a 129-mod list closed the game while the world loaded, with
    no crash report; this tells ZeD's part from the list's own.)

.DESCRIPTION
    One launch in a 1920x1080 window on a copy of the ZeD-QA save, its mod list
    -ModList plus ZeD_UI (-ZeD on) or plus ZeDQA_Probe (-ZeD off, probe_mod/;
    the main menu's mods/default.txt swaps ZeD_UI for the probe the same way).
    Waits up to -WaitSec for the bridge to arm in game, writes a line per
    outcome, takes a picture through the bridge, quits (no save: the copy is
    thrown away) and puts back the ZeD-QA save, default.txt, latestSave.ini,
    ModOptions.ini (ZeD's UI scale Auto for the launch) and the lock. Writes
    ZeDUI/qa/modload/<yyyy-MM-dd_HHmm>_zed-<on|off>.md with the console's
    errors grouped by mod.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ModList,
    [ValidateSet("on", "off")][string]$ZeD = "on",
    [int]$WaitSec = 900
)
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
$ModOptions  = Join-Path $LuaDir "ModOptions.ini"
$ConsoleFile = Join-Path $ZomboidDir "console.txt"
$LatestSave  = Join-Path $ZomboidDir "latestSave.ini"
$DefaultMods = Join-Path $ZomboidDir "mods\default.txt"
$QaSave      = Join-Path $ZomboidDir "Saves\Sandbox\ZeD-QA"
$ProbeSrc    = Join-Path $QaDir "probe_mod\ZeDQA_Probe"
$ProbeDst    = Join-Path $ZomboidDir "mods\ZeDQA_Probe"
$GameDir     = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$Stamp       = Get-Date -Format "yyyy-MM-dd_HHmm"
$OutDir      = [System.IO.Path]::GetFullPath((Join-Path $QaDir "..\..\qa\modload"))
$Report      = Join-Path $OutDir "${Stamp}_zed-$ZeD.md"
$Keep        = Join-Path ([System.IO.Path]::GetTempPath()) "ZeD-modload.$Stamp"

function Write-Text([string]$Path, [string]$Text) { [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom) }
function Read-Text([string]$Path) { try { return [string](Get-Content -LiteralPath $Path -Raw -ErrorAction Stop) } catch { return $null } }
function Test-GameRunning { return [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Get-Log { $t = Read-Text $ConsoleFile; if ($null -eq $t) { return "" }; return ($t -replace "`0", "") }
function Invoke-Bump {
    [long]$n = 9999
    $t = Read-Text $CounterFile
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    if ($n -lt 9999) { $n = 9999 }
    $n++
    Write-Text $CounterFile "$n"; Write-Text $GoFile "$n"
    return $n
}

if ((Read-Text $LockFile) -match '^busy') { Write-Output "not starting: the lock is busy"; exit 2 }
if (Test-GameRunning) { Write-Output "not starting: the game is running"; exit 2 }
if (((Read-Text $LatestSave) -split "\r?\n")[0].Trim() -ne "ZeD-QA") { Write-Output "not starting: latestSave.ini is not ZeD-QA"; exit 2 }
New-Item -ItemType Directory -Force -Path $OutDir, $Keep | Out-Null
Copy-Item $DefaultMods (Join-Path $Keep "default.txt.bak")
Copy-Item $LatestSave (Join-Path $Keep "latestSave.ini.bak")
if (Test-Path $ModOptions) { Copy-Item $ModOptions (Join-Path $Keep "ModOptions.ini.bak") }
$snap = Join-Path $Keep "ZeD-QA.snapshot"
Copy-Item -Recurse $QaSave $snap

$ids = @(Get-Content $ModList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "ZeD_UI" })
$last = $(if ($ZeD -eq "on") { "ZeD_UI" } else { "ZeDQA_Probe" })
$txt = "VERSION = 1,`r`n`r`nmods`r`n{`r`n" + ((@($ids) + @($last) | ForEach-Object { "    mod = $_," }) -join "`r`n") + "`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Mod list load: $($ids.Count) mods + $last ($Stamp)")
$lines.Add("")
$t0 = Get-Date
$outcome = "not launched"
try {
    Write-Text $LockFile "busy"
    Write-Text (Join-Path $QaSave "mods.txt") $txt
    $mo = Read-Text $ModOptions
    if ($null -ne $mo) { Write-Text $ModOptions ((@(($mo -split "`r?`n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' }) -join "`r`n") + "`r`n") }
    if ($ZeD -eq "off") {
        Copy-Item -Recurse $ProbeSrc $ProbeDst -Force
        New-Item -ItemType Directory -Force -Path (Join-Path $ProbeDst "common") | Out-Null
        Write-Text $DefaultMods ((Read-Text $DefaultMods) -replace 'mod = ZeD_UI,', 'mod = ZeDQA_Probe,')
    }
    # the launch (pzlaunchwin.ps1's options swap, without its own wait)
    $opt = Join-Path $ZomboidDir "options.ini"
    $bak = Join-Path $QaDir "options.ini.fullscreen.bak"
    if (-not (Test-Path $bak)) { Copy-Item $opt $bak }
    $o = Get-Content $opt
    $o = $o -replace '^fullScreen=.*', 'fullScreen=false' -replace '^width=.*', 'width=1920' -replace '^height=.*', 'height=1080'
    Set-Content -Path $opt -Value $o
    Write-Text $AutoFile "1"
    $proc = Start-Process -FilePath "$GameDir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $GameDir -PassThru
    Start-Sleep -Seconds 12
    $armed = $false; $clicked = $false; $stuck = $false
    $lastLen = -1; $lastGrow = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $WaitSec) {
        Start-Sleep -Seconds 3
        if ($proc.HasExited) { break }
        $log = Get-Log
        if ($log.Length -ne $lastLen) { $lastLen = $log.Length; $lastGrow = Get-Date }
        elseif (((Get-Date) - $lastGrow).TotalSeconds -ge 120 -and $log -match 'Loading WorldDictionary') {
            # the console stopped while the world loads: a dialog (an error, the Lua debugger) holds the game; a
            # picture of the game's window only (never the whole desktop: the director's other windows stay out)
            Add-Type -AssemblyName System.Drawing
            Add-Type -Name PZR -Namespace Q -MemberDefinition '[StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; } [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r); [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction SilentlyContinue
            [void][Q.PZR]::SetProcessDPIAware()
            $proc.Refresh()
            $wr = New-Object Q.PZR+RECT; [void][Q.PZR]::GetWindowRect($proc.MainWindowHandle, [ref]$wr)
            $bw = [Math]::Max(1, $wr.R - $wr.L); $bh = [Math]::Max(1, $wr.B - $wr.T)
            $bmp = New-Object System.Drawing.Bitmap $bw, $bh
            $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($wr.L, $wr.T, 0, 0, (New-Object System.Drawing.Size $bw, $bh))
            $shot = Join-Path $OutDir "${Stamp}_zed-${ZeD}_stuck.png"
            $bmp.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
            $stuck = $true; break
        }
        if (-not $clicked -and $log -match 'game loading took') {
            & (Join-Path $QaDir "pzfront.ps1") | Out-Null   # (the click to start, as pzlaunchwin.ps1 makes it)
            Add-Type -Name PZC -Namespace Q -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y); [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);' -ErrorAction SilentlyContinue
            [Q.PZC]::SetCursorPos(960, 560) | Out-Null; Start-Sleep -Milliseconds 300
            [Q.PZC]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80; [Q.PZC]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
            $clicked = $true
        }
        if ($log -match 'bridge armed \(in game') { $armed = $true; break }
    }
    $secs = [int]((Get-Date) - $t0).TotalSeconds
    if ($armed) {
        $outcome = "LOADED in game after $secs s"
        Start-Sleep -Seconds 25   # (mods open their notes a little after the game starts)
        Write-Text $BridgeLua ("getCore():TakeFullScreenshot(`"zqa_modload_$ZeD.png`")`nprint(`"ZEDQA modload in game, ZeD_UI active `" .. tostring(getActivatedMods():contains(`"ZeD_UI`")) .. `", mods `" .. tostring(getActivatedMods():size()) .. `", game speed `" .. tostring(getGameSpeed()))`n" +
            "if ZeD and ZeD.Messages then for n, s in pairs(ZeD.Messages.sources) do print(`"ZEDQA modload Messages: `" .. tostring(n) .. `" (`" .. s.kind .. `", `" .. #s.items .. `" kept)`") end end`n" +
            "local ui = UIManager.getUI(); local sh = getCore():getScreenHeight(); for i = 0, ui:size() - 1 do local e = ui:get(i); if e:isVisible() then local t = e:getTable(); print(`"ZEDQA modload ui: `" .. tostring(t and t.Type or e:getClass():getSimpleName()) .. `" at `" .. math.floor(e:getX()) .. `",`" .. math.floor(e:getY()) .. `" `" .. math.floor(e:getWidth()) .. `"x`" .. math.floor(e:getHeight())) end end`n")
        $null = Invoke-Bump
        Start-Sleep -Seconds 6
    } elseif ($stuck) {
        $outcome = "STUCK while the world loads after $secs s: the console stopped for 120 s (a picture of the screen: ${Stamp}_zed-${ZeD}_stuck.png)"
    } elseif ($proc.HasExited) {
        $outcome = "GAME CLOSED after $secs s (exit code $($proc.ExitCode)), not in game"
    } else {
        $outcome = "NOT IN GAME after $secs s (still running)"
    }
}
finally {
    $log = Get-Log
    Copy-Item $ConsoleFile (Join-Path $Keep "console_$ZeD.txt") -ErrorAction SilentlyContinue
    if (Test-GameRunning) {
        # quit without saving the copy: to the main menu, then to the desktop
        Write-Text $AutoFile "0"
        Write-Text $BridgeLua "getCore():quit()`n"
        for ($k = 0; $k -lt 3 -and (Test-GameRunning); $k++) { $null = Invoke-Bump; for ($j = 0; $j -lt 20 -and (Test-GameRunning); $j++) { Start-Sleep -Seconds 3 } }
        if (Test-GameRunning -and $proc) { Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue; Start-Sleep -Seconds 5 }   # (the game this script started, by its id)
    }
    $r = & (Join-Path $QaDir "pzrestorewin.ps1") 2>&1
    Copy-Item (Join-Path $Keep "default.txt.bak") $DefaultMods -Force
    Copy-Item (Join-Path $Keep "latestSave.ini.bak") $LatestSave -Force
    if (Test-Path (Join-Path $Keep "ModOptions.ini.bak")) { Copy-Item (Join-Path $Keep "ModOptions.ini.bak") $ModOptions -Force }
    if (Test-Path $ProbeDst) { Remove-Item -Recurse -Force $ProbeDst }
    if (-not (Test-GameRunning)) {
        Remove-Item -Recurse -Force $QaSave
        Copy-Item -Recurse $snap $QaSave
        $restored = "ZeD-QA put back"
    } else { $restored = "ZeD-QA NOT put back (the game still runs): copy $snap over $QaSave" }
    Write-Text $LockFile "free"

    $lines.Add("**$outcome**")
    $lines.Add("")
    $lines.Add("- $restored; default.txt, latestSave.ini, ModOptions.ini and the lock put back; display: $(($r | Out-String).Trim())")
    $lines.Add("- console: $Keep\console_$ZeD.txt")
    $last5 = @(($log -split "`r?`n") | Where-Object { $_ -match '\S' } | Select-Object -Last 6)
    $lines.Add("")
    $lines.Add("The console's last lines:")
    $lines.Add("")
    $lines.Add('```text'); $last5 | ForEach-Object { $lines.Add($_) }; $lines.Add('```')
    # errors grouped by the mod in their first Lua frame
    $by = @{}
    $cur = $null
    foreach ($l in ($log -split "`r?`n")) {
        if ($l -match '^ERROR') { $cur = "(no mod frame)"; if ($l -match '\(\(MOD:([^)]+)\)\)') { $cur = $Matches[1] }; $by[$cur] = 1 + [int]$by[$cur] }
        elseif ($cur -and $by[$cur] -and $l -match '\(\(MOD:([^)]+)\)\)' -and $cur -eq "(no mod frame)") { }
    }
    $lines.Add("")
    $lines.Add("ERROR lines by the mod named on them (a Lua error names its mod; engine errors name none):")
    $lines.Add("")
    foreach ($k in ($by.Keys | Sort-Object { -$by[$_] })) { $lines.Add("- $k : $($by[$k])") }
    [System.IO.File]::WriteAllLines($Report, $lines, $Utf8NoBom)
    Write-Output "zedqa_modload_run: $outcome -> $Report"
}
