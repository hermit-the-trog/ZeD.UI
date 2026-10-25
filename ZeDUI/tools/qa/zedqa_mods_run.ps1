#Requires -Version 7.0
<#
.SYNOPSIS
    The regression with other Workshop mods on (Oct 24 2026, before a public
    test: "run tests with the popular mods on").

.DESCRIPTION
    Takes a copy of the ZeD-QA save, writes the save's mod list as -ModList (one
    mod id per line, requirements first) with ZeD_UI after them (or first with
    -ZeDFirst), runs zedqa_run.ps1 (-Mode, -Manifest passed on) and always puts
    the ZeD-QA save back from the copy afterwards, so the other mods leave no
    trace in it. The main menu's mod list (mods/default.txt) is not touched.
    The report goes to ZeDUI/qa/regression/<yyyy-MM-dd_HHmm>_mods_<mode>.md,
    with the mod list beside it (.mods.txt).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ModList,
    [ValidateSet("windowed", "fullscreen4k")][string]$Mode = "windowed",
    [string]$Manifest = "",
    [switch]$ZeDFirst
)
$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$QaDir   = $PSScriptRoot
$QaSave  = "C:\Users\danie\Zomboid\Saves\Sandbox\ZeD-QA"
$LockFile = "C:\Users\danie\Zomboid\Lua\zedqa.lock"
$stamp   = Get-Date -Format "yyyy-MM-dd_HHmm"
$Report  = [System.IO.Path]::GetFullPath((Join-Path $QaDir "..\..\qa\regression\${stamp}_mods_$Mode.md"))
$snap    = Join-Path ([System.IO.Path]::GetTempPath()) "ZeD-QA.mods-snapshot.$stamp"

if ((Get-Content $LockFile -Raw -ErrorAction SilentlyContinue) -match '^busy') { Write-Output "not starting: the lock is busy"; exit 2 }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "not starting: the game is running"; exit 2 }
$ids = @(Get-Content $ModList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "ZeD_UI" })
$all = $(if ($ZeDFirst) { @("ZeD_UI") + $ids } else { $ids + @("ZeD_UI") })
$txt = "VERSION = 1,`r`n`r`nmods`r`n{`r`n" + (($all | ForEach-Object { "    mod = $_," }) -join "`r`n") + "`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
[System.IO.File]::WriteAllText("$Report.mods.txt", $txt, $Utf8NoBom)

Copy-Item -Recurse $QaSave $snap
Write-Output "zedqa_mods_run: $($ids.Count) mods + ZeD_UI ($(if ($ZeDFirst) { 'first' } else { 'last' })); ZeD-QA copied to $snap"
try {
    [System.IO.File]::WriteAllText((Join-Path $QaSave "mods.txt"), $txt, $Utf8NoBom)
    $a = @{ Mode = $Mode; Report = $Report }
    if ($Manifest) { $a.Manifest = $Manifest }
    & (Join-Path $QaDir "zedqa_run.ps1") @a 2>&1 | ForEach-Object { Write-Output $_ }
}
finally {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) {
        Write-Output "zedqa_mods_run: the game is still running; ZeD-QA NOT put back. Close the game, then copy $snap over $QaSave"
    } else {
        Remove-Item -Recurse -Force $QaSave
        Copy-Item -Recurse $snap $QaSave
        Remove-Item -Recurse -Force $snap
        Write-Output "zedqa_mods_run: ZeD-QA put back (its mod list is ZeD_UI only again)"
    }
}
