#Requires -Version 7.0
<#
.SYNOPSIS
    QA beast day (Nov 21 2026): ZeD with nine other mods on, one launch (bx_mods.txt: prelude, rt_kit, bx_mods.lua).

.DESCRIPTION
    QA runs with -nosteam (ZEDQA_NOSTEAM=1), so the Workshop folder is not read: the mods under test are copied
    from Steam's Workshop download into Zomboid\mods for the run and taken out again at its end.

      * Only the folders in $Copy below are copied, and only those this script copied are removed (in a finally
        block, by the exact paths it made). It refuses to start when one of those folder names is already in
        Zomboid\mods: it never overwrites and never removes a folder it did not make.
      * SPNCC (Spongie's Character Customisation) is already in Zomboid\mods (the director's own copy): it is used
        as it stands, never copied, never removed. The run refuses to start when it is not there.
      * It refuses to start while Zomboid\Lua\zedqa.lock says busy or the game is running (exit 2).
      * Zomboid\Lua\ZeD_step_aside.txt (ZeD's step-aside record, which a hand-back rewrites) is read first and put
        back at the end, or removed when there was none, as batch_b8_mods.ps1 does. A copy of what the run left is
        kept beside the reports (ZeDUI\qa\bx_mods_step_aside.txt), with the console (bx_mods_console.txt).
      * zedqa_mods_run.ps1 does the rest: the ZeD-QA save's mod list for the run (the mods of bx_mods_list.txt,
        then ZeD_UI last; -ZeDFirst puts ZeD first), 4K fullscreen, and the save put back afterwards.
    While the game is still running at the end (a hung run), nothing is removed: the folders are listed instead.

.EXAMPLE
    pwsh -File %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\bx_mods_run.ps1
.EXAMPLE
    pwsh -File %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\bx_mods_run.ps1 -ZeDFirst
#>
[CmdletBinding()]
param(
    [switch]$ZeDFirst,
    [string]$Workshop = "E:\Project Zomboid\steamapps\workshop\content\108600"
)
$ErrorActionPreference = "Stop"
$Qa       = $PSScriptRoot
$Mods     = "$($env:USERPROFILE)\Zomboid\mods"
$LockFile = "$($env:USERPROFILE)\Zomboid\Lua\zedqa.lock"
$Rec      = "$($env:USERPROFILE)\Zomboid\Lua\ZeD_step_aside.txt"
$Out      = [System.IO.Path]::GetFullPath("$Qa\..\..\qa")
$List     = Join-Path $Qa "bx_mods_list.txt"
$Manifest = Join-Path $Qa "bx_mods.txt"

# mod id -> the Workshop item and the folder under its mods\ (the folder's name is the one made in Zomboid\mods)
$Copy = [ordered]@{
    "ResponsiveUI"               = @{ Ws = "3783387236"; Folder = "ResponsiveUI" }
    "SuperOl3gContextMenuIcons"  = @{ Ws = "3830018449"; Folder = "BetterContextMenuIcons" }
    "ContainerCapacityIndicator" = @{ Ws = "3789660055"; Folder = "ContainerCapacityIndicator" }
    "KADropnLoot"                = @{ Ws = "2871469707"; Folder = "EasyDropnLoot" }
    "moodle_quarters"            = @{ Ws = "2854030563"; Folder = "moodle_quarters" }
    "WoundExpansion"             = @{ Ws = "3819438691"; Folder = "WoundExpansion" }
    "ProximityInventory"         = @{ Ws = "2847184718"; Folder = "ProximityInventory" }
    "CleanHotBar"                = @{ Ws = "3461263912"; Folder = "CleanHotBar" }
}
# mod id -> a folder that is already in Zomboid\mods and stays there
$Local = @{ "SPNCC" = "SpongieCharacterCustomisation" }

if ((Get-Content $LockFile -Raw -ErrorAction SilentlyContinue) -match '^busy') { Write-Output "bx_mods_run: not starting: the lock is busy"; exit 2 }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "bx_mods_run: not starting: the game is running"; exit 2 }
foreach ($f in $List, $Manifest, (Join-Path $Qa "zedqa_mods_run.ps1"), (Join-Path $Qa "bx_mods.lua")) {
    if (-not (Test-Path -LiteralPath $f)) { Write-Output "bx_mods_run: not starting: $f is missing"; exit 2 }
}

# the list and the two tables must name the same mods: nothing is copied that the list does not ask for
$ids = @(Get-Content -LiteralPath $List | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith("#") -and $_ -ne "ZeD_UI" })
$unknown = @($ids | Where-Object { -not $Copy.Contains($_) -and -not $Local.ContainsKey($_) })
if ($unknown.Count -gt 0) { Write-Output "bx_mods_run: not starting: bx_mods_list.txt names mods this script has no folder for: $($unknown -join ', ')"; exit 2 }

# every source there, every target free, before anything is copied
$plan = @()
foreach ($id in $ids) {
    if ($Local.ContainsKey($id)) {
        $have = Join-Path $Mods $Local[$id]
        if (-not (Test-Path -LiteralPath $have -PathType Container)) { Write-Output "bx_mods_run: not starting: $id is expected in $have (it is used as it stands) and is not there"; exit 2 }
        continue
    }
    $c   = $Copy[$id]
    $src = Join-Path $Workshop "$($c.Ws)\mods\$($c.Folder)"
    $dst = Join-Path $Mods $c.Folder
    if (-not (Test-Path -LiteralPath $src -PathType Container)) { Write-Output "bx_mods_run: not starting: $id is not downloaded ($src)"; exit 2 }
    if (Test-Path -LiteralPath $dst) { Write-Output "bx_mods_run: not starting: $dst is already there (this script only removes folders it made, so it will not use or replace it)"; exit 2 }
    $plan += @{ Id = $id; Src = $src; Dst = $dst }
}

$recBak = $null
if (Test-Path -LiteralPath $Rec) { $recBak = [System.IO.File]::ReadAllBytes($Rec) }
$nosteamWas = $env:ZEDQA_NOSTEAM
$Copied = @()
$code = 1
try {
    foreach ($p in $plan) {
        # (noted before the copy starts: a copy that stops half way is still this script's folder to remove)
        $Copied += $p.Dst
        Copy-Item -LiteralPath $p.Src -Destination $p.Dst -Recurse
    }
    Write-Output "bx_mods_run: copied $($Copied.Count) mod folders into $Mods; $($ids.Count) mods + ZeD_UI ($(if ($ZeDFirst) { 'first' } else { 'last' }))"
    $env:ZEDQA_NOSTEAM = "1"
    $a = @{ ModList = $List; Mode = "fullscreen4k"; Manifest = $Manifest }
    if ($ZeDFirst) { $a.ZeDFirst = $true }
    & (Join-Path $Qa "zedqa_mods_run.ps1") @a 2>&1 | ForEach-Object { Write-Output $_ }
    $code = $LASTEXITCODE
    Copy-Item "$($env:USERPROFILE)\Zomboid\console.txt" (Join-Path $Out "bx_mods_console.txt") -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Rec) { Copy-Item -LiteralPath $Rec (Join-Path $Out "bx_mods_step_aside.txt") -Force -ErrorAction SilentlyContinue }
}
finally {
    $env:ZEDQA_NOSTEAM = $nosteamWas
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) {
        Write-Output "bx_mods_run: the game is still running: nothing removed. Close the game, then remove these folders this script copied: $($Copied -join ', ')"
        Write-Output "bx_mods_run: ZeD_step_aside.txt NOT put back (it was $(if ($recBak) { 'there' } else { 'not there' }) before the run)"
    } else {
        $removed = 0
        foreach ($c in $Copied) {
            # (only a path this script made, and only directly under Zomboid\mods)
            if ((Test-Path -LiteralPath $c -PathType Container) -and ((Split-Path -Parent $c) -eq $Mods)) {
                Remove-Item -LiteralPath $c -Recurse -Force
                $removed++
            }
        }
        Write-Output "bx_mods_run: removed $removed of the $($Copied.Count) mod folders it copied"
        if ($recBak) { [System.IO.File]::WriteAllBytes($Rec, $recBak) } elseif (Test-Path -LiteralPath $Rec) { Remove-Item -LiteralPath $Rec -Force }
        Write-Output "bx_mods_run: ZeD_step_aside.txt $(if ($recBak) { 'put back as it was' } else { 'removed (there was none before the run)' })"
    }
}
exit $code
