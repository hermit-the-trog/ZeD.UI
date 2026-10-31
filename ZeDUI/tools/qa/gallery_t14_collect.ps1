<#
.SYNOPSIS
    The Workshop gallery retake on 0.2.0-t14 (Oct 30 2026): gathers every picture shots.json uses into
    Zomboid/Screenshots/gallery_t14, under the names the slides already use.
.DESCRIPTION
    Reads ZeDUI/workshop/shots/shots.json, lists every source (each slide's src and each crop's src; a bare name is in
    the "screens" folder, an absolute path under Screenshots/workshop_src_t8 is a t8 picture). For each, a copy in
    Zomboid/Screenshots written at or after -Since (the retake: gallery_t14_manifest.txt, gallery_menus_run.ps1,
    zedqa_mods_panes_run.ps1) goes to gallery_t14. A source with no fresh copy is KEPT from where shots.json reads it
    now when it is one the retake does not take on purpose (the vanilla halves van_*: the vanilla run needs ZeD off;
    zqa_r6p_taxi_extras: zedqa_dash_r6_parts.lua leaves two cars for its reload run, so it is not in the manifest);
    anything else is MISSING. Sources outside Zomboid/Screenshots (the controller drawing) are left alone.
    -Switch then points shots.json at gallery_t14: the "screens" folder, and the workshop_src_t8 paths made bare names
    (text replaced in place, the file's layout kept). Run -Switch only when nothing is MISSING.
    Touches neither the game nor the lock.
.EXAMPLE
    & ZeDUI/tools/qa/gallery_t14_collect.ps1 -Since "2026-10-30 23:00"
    & ZeDUI/tools/qa/gallery_t14_collect.ps1 -Since "2026-10-30 23:00" -Switch
#>
param(
    [Parameter(Mandatory = $true)][datetime]$Since,
    [switch]$Switch
)
$Shots = Join-Path $PSScriptRoot "..\..\workshop\shots\shots.json"
$Shots = [System.IO.Path]::GetFullPath($Shots)
$Scr = "C:\Users\danie\Zomboid\Screenshots"
$Out = Join-Path $Scr "gallery_t14"
$Kept = @('^van_\d+_', '^zqa_r6p_taxi_extras\.png$')
New-Item -ItemType Directory -Force $Out | Out-Null
$j = Get-Content $Shots -Raw | ConvertFrom-Json
$screens = $j.screens -replace '/', '\'
$src = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($s in $j.shots) {
    if ($s.src) { [void]$src.Add($s.src) }
    foreach ($c in @($s.crops)) { if ($c -and $c.src) { [void]$src.Add($c.src) } }
}
$fresh = 0; $kept = 0; $missing = @()
foreach ($p in $src) {
    $path = $p -replace '/', '\'
    if (-not [System.IO.Path]::IsPathRooted($path)) { $path = Join-Path $screens $path }
    if (-not $path.StartsWith($Scr, [StringComparison]::OrdinalIgnoreCase)) { continue }   # the controller drawing
    $name = [System.IO.Path]::GetFileName($path)
    $new = Join-Path $Scr $name
    if ((Test-Path $new) -and (Get-Item $new).LastWriteTime -ge $Since) {
        Copy-Item $new (Join-Path $Out $name) -Force; $fresh++; continue
    }
    $keep = $false
    foreach ($k in $Kept) { if ($name -match $k) { $keep = $true } }
    if ($keep -and (Test-Path $path)) { Copy-Item $path (Join-Path $Out $name) -Force; $kept++; "KEPT    $name (from $path)"; continue }
    $missing += $name
    "MISSING $name"
}
"fresh $fresh, kept $kept, missing $($missing.Count) -> $Out"
if ($Switch) {
    if ($missing.Count -gt 0) { "not switching: $($missing.Count) missing"; exit 1 }
    $t = Get-Content $Shots -Raw
    $t = $t.Replace('"screens": "C:/Users/danie/Zomboid/Screenshots/gallery_t13"', '"screens": "C:/Users/danie/Zomboid/Screenshots/gallery_t14"')
    $t = $t.Replace('C:/Users/danie/Zomboid/Screenshots/workshop_src_t8/', '')
    [System.IO.File]::WriteAllText($Shots, $t, (New-Object System.Text.UTF8Encoding($false)))
    "shots.json now reads Screenshots/gallery_t14"
}
if ($missing.Count -gt 0) { exit 1 } else { exit 0 }
