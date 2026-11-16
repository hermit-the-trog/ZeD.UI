#Requires -Version 7.0
# ZeDUI/tools/qa/stage_branch_run.ps1  (Nov 15 2026, QA): run the game on a branch's ZeD (a worktree) plus another mod,
# from a separate game folder (-cachedir %USERPROFILE%\ZomboidBranch), so neither the shared main checkout nor the real
# Zomboid folder is touched. Same rig as batch_stage_true.ps1: the staged mods, the bridge, a copy of the test save and
# the options, then zedqa_run.ps1 with ZEDQA_ZDIR pointing there.
# The real lock (Zomboid\Lua\zedqa.lock) is still the one the sessions share: this script refuses to start while a game
# runs or the lock is busy, holds it "busy" for the run and puts it back to "free" after.
# Example (the Dishes mod on the dishwasher-faces branch):
#   pwsh -File stage_branch_run.ps1 -ZedDir "$env:USERPROFILE\Zomboid\mods\ZeD-UI\.claude\worktrees\dishwasher-faces" `
#        -ExtraMod "$env:USERPROFILE\Zomboid\Dishes" -ExtraId Dishes -Manifest <manifest.txt> -Report dishes_faces_4k
# Pass -Mode windowed -Width 1280 -Height 800 for a Deck-sized window (default: fullscreen4k).
param(
    [Parameter(Mandatory)] [string]$ZedDir,       # the worktree (holds 42\ and mod.info under it)
    [string]$ExtraMod = "",                       # another mod's folder (holds 42\), optional
    [string]$ExtraId = "",                        # that mod's id from its 42\mod.info
    [string]$ExtraQaDir = "",                    # the add-on's own tests folder: its manifest may name scripts there by full path
    [Parameter(Mandatory)] [string]$Manifest,
    [Parameter(Mandatory)] [string]$Report,
    [string]$Mode = "fullscreen4k",
    [int]$Width = 0, [int]$Height = 0,
    [string]$Stg = "$($env:USERPROFILE)\ZomboidBranch"
)
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$Z = "$($env:USERPROFILE)\Zomboid"
$Lock = "$Z\Lua\zedqa.lock"

if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "a game is running: not started"; exit 1 }
if ((Test-Path $Lock) -and ((Get-Content $Lock -Raw).Trim() -ne "free")) { "the lock reads busy: not started"; exit 1 }
if (-not (Test-Path "$ZedDir\42\mod.info")) { "no 42\mod.info in $ZedDir"; exit 1 }
if ($ExtraMod -and -not (Test-Path "$ExtraMod\42\mod.info")) { "no 42\mod.info in $ExtraMod"; exit 1 }
Set-Content $Lock "busy" -NoNewline

try {
    # a fresh game folder each run
    if (Test-Path $Stg) { Remove-Item $Stg -Recurse -Force }
    foreach ($d in "mods\ZeD-UI", "Lua", "Saves\Sandbox", "Screenshots") { New-Item -ItemType Directory -Force "$Stg\$d" | Out-Null }
    # the branch's ZeD (42\ and an empty common\, as the Workshop layout has it), with the QA bridge from main
    Copy-Item "$ZedDir\42" "$Stg\mods\ZeD-UI\42" -Recurse
    New-Item -ItemType Directory -Force "$Stg\mods\ZeD-UI\common" | Out-Null
    Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" "$Stg\mods\ZeD-UI\42\media\lua\client\ZeD\" -Force
    $ids = @("ZeD_UI")
    if ($ExtraMod) {
        $name = Split-Path $ExtraMod -Leaf
        New-Item -ItemType Directory -Force "$Stg\mods\$name" | Out-Null
        Copy-Item "$ExtraMod\42" "$Stg\mods\$name\42" -Recurse
        if (Test-Path "$ExtraMod\common") { Copy-Item "$ExtraMod\common" "$Stg\mods\$name\common" -Recurse }
        else { New-Item -ItemType Directory -Force "$Stg\mods\$name\common" | Out-Null }
        $ids += $ExtraId
    }
    # the test save, the options and the ZeD settings, copied (the originals are never written)
    Copy-Item "$Z\Saves\Sandbox\ZeD-QA" "$Stg\Saves\Sandbox\ZeD-QA" -Recurse
    Copy-Item "$Z\options.ini" "$Stg\options.ini"
    if (Test-Path "$Z\version.txt") { Copy-Item "$Z\version.txt" "$Stg\version.txt" }
    Copy-Item "$Z\Lua\ModOptions.ini" "$Stg\Lua\ModOptions.ini" -ErrorAction SilentlyContinue
    Copy-Item "$Z\mods\reset-mods-*.txt" "$Stg\mods\" -ErrorAction SilentlyContinue   # (without it the game clears the mod list on its first start in a folder)
    $list = "VERSION = 1,`r`n`r`nmods`r`n{`r`n" + (($ids | ForEach-Object { "    mod = $_,`r`n" }) -join "") + "}`r`n`r`nmaps`r`n{`r`n}`r`n"
    Set-Content "$Stg\mods\default.txt" $list -NoNewline
    Set-Content "$Stg\Saves\Sandbox\ZeD-QA\mods.txt" $list -NoNewline
    Set-Content "$Stg\latestSave.ini" "ZeD-QA`r`nSandbox" -NoNewline
    Set-Content "$Stg\Lua\zedqa.lock" "free" -NoNewline
    "staged: $Stg (ZeD from $ZedDir$(if ($ExtraMod) { ", $ExtraId from $ExtraMod" }))"

    $env:ZEDQA_NOSTEAM = "1"
    $env:ZEDQA_ZDIR = $Stg
    if ($ExtraQaDir) { $env:ZEDQA_EXTRA_QADIR = $ExtraQaDir }
    $runArgs = @{ Manifest = $Manifest; Mode = $Mode; Report = $Report }
    if ($Width -gt 0) { $runArgs.Width = $Width; $runArgs.Height = $Height }
    & "$Qa\zedqa_run.ps1" @runArgs
} finally {
    Remove-Item Env:\ZEDQA_ZDIR -ErrorAction SilentlyContinue
    Remove-Item Env:\ZEDQA_EXTRA_QADIR -ErrorAction SilentlyContinue
    Set-Content $Lock "free" -NoNewline
    "screenshots: $Stg\Screenshots | console: $Stg\console.txt | lock: free"
}
