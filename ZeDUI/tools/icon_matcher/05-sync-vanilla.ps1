# 05-sync-vanilla.ps1
# Reads ContextIcons.lua and copies all referenced VANILLA icons to the mod icons folder.
# Vanilla icons are identified by checking if the texKey file exists in vanilla-icons/.
#
# NOTE: Vanilla texKeys (e.g. "Item_Axe") resolve via PZ's getTexture() without copying.
#       This script is OPTIONAL — only run it if you want local PNG copies in the mod.

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$vanillaDir = Join-Path $scriptDir "vanilla-icons"
$luaPath    = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\lua\shared\ZeD\ContextIcons.lua"
$destRoot   = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\icons"

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

$lua   = Get-Content $luaPath -Raw
$icons = [regex]::Matches($lua, '= "([^"]+)"') |
         ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

$copied  = 0
$skipped = 0

foreach ($icon in $icons) {
    $src = Join-Path $vanillaDir ($icon + ".png")
    if (Test-Path $src) {
        $dst = Join-Path $destRoot ($icon + ".png")
        Copy-Item $src $dst -Force
        $copied++
    } else {
        $skipped++
    }
}

$total = (Get-ChildItem $destRoot -Filter "*.png").Count
Write-Host ""
Write-Host "=== Vanilla Sync Complete ===" -ForegroundColor Cyan
Write-Host "Copied  : $copied vanilla icons" -ForegroundColor Green
Write-Host "Skipped : $skipped (non-vanilla / Smashicons)" -ForegroundColor Yellow
Write-Host "Total PNGs in icons folder: $total" -ForegroundColor Cyan
Write-Host ""
