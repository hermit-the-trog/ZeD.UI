#Requires -Version 7.0
<#
.SYNOPSIS
    One in-game script with a mod list and ZeD-UI OFF, at the director's 4K fullscreen (Oct 26 2026,
    compatibility round 3: "test with -ZeD off before blaming ZeD", with pictures of the mods' own UI).

.DESCRIPTION
    zedqa_modload_run.ps1 -ZeD off loads a list without ZeD in a 1080p window and takes one picture; this
    runs a bridge script instead, fullscreen. On a copy of the ZeD-QA save: its mod list is -ModList plus
    ZeDQA_Probe (probe_mod/, the bridge stand-in; the main menu's mods/default.txt swaps ZeD_UI for it the
    same way), zedqa.autoload continues the save, the start click as zedqa_run.ps1 makes it, then -Script
    through the probe until "ZEDQA <Tag> DONE" (or -TimeoutSec), then quit without saving. Puts back the
    ZeD-QA save, default.txt, latestSave.ini, the autoload flag and the lock (busy for the whole run).
    Refuses to start (exit 2) while the lock is busy or the game runs. Prints the script's ZEDQA lines and
    the console's ERROR lines grouped by the mod in their stack; keeps the console beside the output
    (<OutDir>/<Tag>_console.txt).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ModList,
    [Parameter(Mandatory)][string]$Script,
    [Parameter(Mandatory)][string]$Tag,
    [int]$TimeoutSec = 600,
    [string]$OutDir = ""
)
$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$QaDir = $PSScriptRoot
$Z = "C:\Users\danie\Zomboid"
$Lua = Join-Path $Z "Lua"
$Lock = Join-Path $Lua "zedqa.lock"
$GoFile = Join-Path $Lua "zedqa.go"
$Counter = Join-Path $Lua "zedqa.counter"
$AutoFile = Join-Path $Lua "zedqa.autoload"
$Console = Join-Path $Z "console.txt"
$LatestSave = Join-Path $Z "latestSave.ini"
$DefaultMods = Join-Path $Z "mods\default.txt"
$QaSave = Join-Path $Z "Saves\Sandbox\ZeD-QA"
$ProbeSrc = Join-Path $QaDir "probe_mod\ZeDQA_Probe"
$ProbeDst = Join-Path $Z "mods\ZeDQA_Probe"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$Stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
if (-not $OutDir) { $OutDir = [System.IO.Path]::GetFullPath((Join-Path $QaDir "..\..\qa\modload")) }
$Keep = Join-Path ([System.IO.Path]::GetTempPath()) "ZeD-offrun.$Stamp"
function Write-T([string]$p, [string]$t) { [System.IO.File]::WriteAllText($p, $t, $Utf8NoBom) }
function Read-T([string]$p) { try { return [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { return "" } }
function Log { return ((Read-T $Console) -replace "`0", "") }
function Running { return [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Bump {
    [long]$n = 9999; $t = Read-T $Counter; if ($t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    if ($n -lt 9999) { $n = 9999 }
    $n++; Write-T $Counter "$n"; Write-T $GoFile "$n"
}
Add-Type -Name OffRunIn -Namespace Q -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
'@ -ErrorAction SilentlyContinue
function StartClick($proc) {
    try { & (Join-Path $QaDir "pzfront.ps1") | Out-Null } catch { }
    [uint32]$fg = 0; [void][Q.OffRunIn]::GetWindowThreadProcessId([Q.OffRunIn]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$proc.Id) { return "no click (the game is not the front window)" }
    [void][Q.OffRunIn]::SetProcessDPIAware()
    [void][Q.OffRunIn]::SetCursorPos(1920, 1080); Start-Sleep -Milliseconds 400
    [void][Q.OffRunIn]::SetCursorPos(1922, 1082); Start-Sleep -Milliseconds 300
    [Q.OffRunIn]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150
    [Q.OffRunIn]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    return "clicked"
}

if ((Read-T $Lock) -match '^busy') { Write-Output "not starting: the lock is busy"; exit 2 }
if (Running) { Write-Output "not starting: the game is running"; exit 2 }
if (((Read-T $LatestSave) -split "\r?\n")[0].Trim() -ne "ZeD-QA") { Write-Output "not starting: latestSave.ini is not ZeD-QA"; exit 2 }
New-Item -ItemType Directory -Force -Path $OutDir, $Keep | Out-Null
Write-T $Lock "busy"
$keepDefault = Read-T $DefaultMods; $keepLatest = Read-T $LatestSave; $keepAuto = Read-T $AutoFile
$snap = Join-Path $Keep "ZeD-QA.snapshot"
Copy-Item -Recurse $QaSave $snap
$proc = $null
try {
    $ids = @(Get-Content $ModList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "ZeD_UI" }) + @("ZeDQA_Probe")
    Write-T (Join-Path $QaSave "mods.txt") ("VERSION = 1,`r`n`r`nmods`r`n{`r`n" + (($ids | ForEach-Object { "    mod = $_," }) -join "`r`n") + "`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n")
    Copy-Item -Recurse $ProbeSrc $ProbeDst -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $ProbeDst "common") | Out-Null
    Write-T $DefaultMods ($keepDefault -replace 'mod = ZeD_UI,', 'mod = ZeDQA_Probe,')
    Write-T $AutoFile "1"
    $proc = Start-Process -FilePath (Join-Path $GameDir "ProjectZomboid64.exe") -ArgumentList "-debug" -WorkingDirectory $GameDir -PassThru
    Start-Sleep -Seconds 12
    $t0 = Get-Date; $clicked = 0; $armed = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 900) {
        Start-Sleep -Seconds 3
        if ($proc.HasExited) { throw "the game closed while loading" }
        $log = Log
        if ($log -match 'bridge armed \(in game|\[ZeDQA\.Probe\] armed \(in game|Probe.*in game') { $armed = $true; break }
        if ($log -match 'game loading took' -and $clicked -lt 3 -and ((Get-Date) - $t0).TotalSeconds -ge (20 + 30 * $clicked)) { $r = StartClick $proc; $clicked++; Write-Output "start click: $r" }
    }
    if (-not $armed) { throw "the probe never armed in game" }
    Write-Output "in game after $([int]((Get-Date) - $t0).TotalSeconds) s (ZeD off)"
    Start-Sleep -Seconds 8
    Copy-Item -LiteralPath $Script -Destination (Join-Path $Lua "zedqa.lua") -Force
    Bump
    $t1 = Get-Date
    while (-not ((Log) -match "ZEDQA $Tag DONE")) {
        if ($proc.HasExited) { throw "the game closed during the script" }
        if (((Get-Date) - $t1).TotalSeconds -gt $TimeoutSec) { Write-Output "TIMEOUT"; break }
        Start-Sleep -Seconds 2
    }
    $log = Log
    ($log -split "\r?\n") | Where-Object { $_ -match "ZEDQA $Tag " } | ForEach-Object { ($_ -replace '^.*?ZEDQA ', 'ZEDQA ') }
}
finally {
    $log = Log
    Write-T (Join-Path $OutDir "${Stamp}_${Tag}_console.txt") $log
    if (Running) {
        Write-T $AutoFile "0"
        Write-T (Join-Path $Lua "zedqa.lua") "getCore():quit()`n"
        for ($k = 0; $k -lt 3 -and (Running); $k++) { Bump; for ($j = 0; $j -lt 20 -and (Running); $j++) { Start-Sleep -Seconds 3 } }
        if ((Running) -and $proc) { Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue; Start-Sleep -Seconds 5 }   # (the game this script started, by its id)
    }
    Write-T $DefaultMods $keepDefault; Write-T $LatestSave $keepLatest; Write-T $AutoFile $(if ($keepAuto) { $keepAuto } else { "0" })
    if (Test-Path $ProbeDst) { Remove-Item -Recurse -Force $ProbeDst }
    if (-not (Running)) { Remove-Item -Recurse -Force $QaSave; Copy-Item -Recurse $snap $QaSave; Write-Output "ZeD-QA put back" }
    else { Write-Output "the game still runs: ZeD-QA NOT put back (copy $snap over $QaSave)" }
    Write-T $Lock "free"
    # errors grouped by the mod named in their stack
    $by = @{}
    foreach ($l in ($log -split "`r?`n")) { if ($l -match '\(\(MOD:([^)]+)\)\)' -and $l -match 'Exception thrown|Lua fail|ERROR') { $by[$Matches[1]] = 1 + [int]$by[$Matches[1]] } }
    foreach ($k in $by.Keys) { Write-Output "errors naming $k : $($by[$k])" }
    Write-Output "console kept: $(Join-Path $OutDir "${Stamp}_${Tag}_console.txt")"
}
