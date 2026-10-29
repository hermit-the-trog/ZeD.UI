# 03-sync-icons.ps1
# Reads ContextIcons.lua and copies all referenced Smashicons PNGs to the mod icons folder.
# Run this after updating ContextIcons.lua with new assignments from the catalog export.
#
# Resolution order per icon:
#   1. Exact filename match       (027-hand-saw.png)
#   2. Hyphens -> spaces in name  (027-hand saw.png)
#   3. Keyword search in pack     (first word of name, picks first match)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$smashRoot = Join-Path $scriptDir "Smashicons"
$luaPath   = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\lua\shared\ZeD\ContextIcons.lua"
$destRoot  = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\icons"

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

$lua   = Get-Content $luaPath -Raw
$icons = [regex]::Matches($lua, '= "([^"]+)"') |
         ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

$copied = 0; $fuzzy = 0; $missing = @()

foreach ($icon in $icons) {
    $m = [regex]::Match($icon, '^(.+?)-(\d{3}-.+)$')
    if (-not $m.Success) {
        # Special case: no numeric prefix (e.g. sewing--pliers)
        $parts   = $icon -split '--', 2
        $catName = $parts[0]
        $pngFile = $parts[1] + '.png'
    } else {
        $catName = $m.Groups[1].Value
        $pngFile = $m.Groups[2].Value + '.png'
    }

    $folder = (Get-ChildItem $smashRoot -Directory |
               Where-Object { $_.Name -like "*-$catName" })[0]
    if (-not $folder) { $missing += $icon; continue }

    # Try nested structure first: {folder}/{folder}/png/
    $pngDir = Join-Path (Join-Path $folder.FullName $folder.Name) 'png'
    if (-not (Test-Path $pngDir)) {
        # Try flat structure: {folder}/png/
        $pngDir = Join-Path $folder.FullName 'png'
    }
    $dest   = Join-Path $destRoot ($icon + '.png')

    if (-not (Test-Path $pngDir)) { $missing += $icon; continue }

    # Try 1: exact filename
    $src = Join-Path $pngDir $pngFile
    if (Test-Path $src) { Copy-Item $src $dest -Force; $copied++; continue }

    # Try 2: hyphens -> spaces in the name portion
    $num   = $pngFile -replace '-.*$', ''
    $name  = ($pngFile -replace '^\d+-', '' -replace '\.png$', '' -replace '-', ' ')
    $src2  = Join-Path $pngDir ($num + '-' + $name + '.png')
    if (Test-Path $src2) { Copy-Item $src2 $dest -Force; $copied++; continue }

    # Try 3: keyword search — first word of the name, pick first match in pack
    $kw    = ($pngFile -replace '^\d+-', '' -replace '\.png$', '') -split '-' | Select-Object -First 1
    $found = Get-ChildItem $pngDir -Filter '*.png' |
             Where-Object { $_.BaseName -match [regex]::Escape($kw) } |
             Select-Object -First 1
    if ($found) { Copy-Item $found.FullName $dest -Force; $fuzzy++; continue }

    $missing += $icon
}

Write-Host ""
Write-Host "=== Sync Complete ===" -ForegroundColor Cyan
Write-Host "Exact copies : $copied" -ForegroundColor Green
Write-Host "Fuzzy copies : $fuzzy"  -ForegroundColor Yellow
if ($missing) {
    Write-Host "Not found ($($missing.Count)):" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" }
}
$total = (Get-ChildItem $destRoot -Filter '*.png').Count
Write-Host "Total PNGs in icons folder: $total" -ForegroundColor Cyan
Write-Host ""
