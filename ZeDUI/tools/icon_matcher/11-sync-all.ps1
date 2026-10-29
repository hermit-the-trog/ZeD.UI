# 11-sync-all.ps1
# Master chain: runs 03 -> 05 -> 04 -> 06 in sequence so one command
# resynchronises the whole icon-matcher toolchain against ContextIcons.lua +
# both icon source packs (SmashIcons and vanilla-icons). Use after editing
# ContextIcons.lua when you want both the mod's texture folder AND the
# in-browser assignment tool to reflect current state.
#
# Step breakdown:
#   03-sync-icons            : copy every SmashIcons PNG referenced by the Lua
#                              (numbered-folder paths like sawmill-070-wood)
#                              into 42/media/textures/ZeD/icons/.
#   05-sync-vanilla          : copy every vanilla-icons PNG referenced by the
#                              Lua (bare names like water, fence, door-closed,
#                              V_BearTrap) into 42/media/textures/ZeD/icons/.
#                              Runs after 03 so later copies layer on top.
#   04-build-vanilla-catalog : rebuild vanilla-catalog.html from the contents
#                              of vanilla-icons/ (ICON_INDEX + VANILLA_CATS
#                              plus a fresh SEEDED_ASSIGNMENTS block from Lua).
#   06-sync-seed-from-lua    : bump SEED_VERSION and upgrade loadAssignments()
#                              so any browser with cached localStorage auto-
#                              reseeds on next open. Idempotent over step 04.
#
# Skip to an individual step for narrower work:
#   Just added icons to the Lua?              -> 03 + 05 alone copy them.
#   Just reorganised vanilla-icons/ folder?   -> 04 alone rebuilds ICON_INDEX.
#   Just re-edited assignments in the Lua?    -> 06 alone re-seeds + versions.
#
# Aborts on first failure so the real error surfaces instead of cascade noise.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-SyncStep {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$ScriptName
    )
    $bar = ("=" * 64)
    Write-Host ""
    Write-Host $bar -ForegroundColor DarkGray
    Write-Host $Label -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor DarkGray

    $path = Join-Path $scriptDir $ScriptName
    if (-not (Test-Path $path)) {
        Write-Host "MISSING: $path" -ForegroundColor Red
        exit 1
    }

    # Reset LASTEXITCODE so a prior step's success doesn't mask a silent no-exit
    # script that nonetheless failed (step scripts that Write-Error + return
    # without 'exit 1' won't set it; run-without-exit remains 0 either way).
    $global:LASTEXITCODE = 0
    & $path
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Step failed: $Label (exit $LASTEXITCODE). Aborting chain." -ForegroundColor Red
        exit 1
    }
}

Invoke-SyncStep -Label "Step 1/4 -- SmashIcons -> mod/textures/ZeD/icons/" `
                -ScriptName "03-sync-icons.ps1"

Invoke-SyncStep -Label "Step 2/4 -- vanilla-icons -> mod/textures/ZeD/icons/" `
                -ScriptName "05-sync-vanilla.ps1"

Invoke-SyncStep -Label "Step 3/4 -- Rebuild vanilla-catalog.html from vanilla-icons/" `
                -ScriptName "04-build-vanilla-catalog.ps1"

Invoke-SyncStep -Label "Step 4/4 -- Seed HTML from Lua (+ SEED_VERSION bump)" `
                -ScriptName "06-sync-seed-from-lua.ps1"

$bar = ("=" * 64)
Write-Host ""
Write-Host $bar -ForegroundColor DarkGray
Write-Host "All sync steps complete. Open vanilla-catalog.html to confirm." -ForegroundColor Green
Write-Host $bar -ForegroundColor DarkGray
