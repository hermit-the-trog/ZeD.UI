#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_ts_run.ps1  (Nov 11 2026, QA, punch list 171): zedqa_tab_search.lua with Skill Recovery Journal on (its step 4 needs the
# mod and a Bound Journal). Copies Skill Recovery Journal, errorMagnifier and chuckleberryModdingAlertSystem from Steam's download into
# Zomboid\mods (only those not there already; removed again after, only those), lists them for the run, runs zedqa_mods_run.ps1.
#   -Mode 4k | deck | deckL      4K 1.75x fullscreen | 1280x800 window, Auto, Normal text | the same with Large text (zedqa_large_text.lua first)
param([ValidateSet("4k", "deck", "deckL")][string]$Mode = "4k", [string]$OutDir = "")
$ErrorActionPreference = "Stop"
$Qa = $PSScriptRoot
$Z = "$($env:USERPROFILE)\Zomboid"
$Ws = "E:\Project Zomboid\SteamApps\workshop\content\108600"
if (-not $OutDir) { $OutDir = $Qa }
$Log = Join-Path $OutDir "zedqa_ts_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start $Mode" | Add-Content $Log
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { L "refused: the game is running"; exit 2 }
if ((Get-Content "$Z\Lua\zedqa.lock" -Raw -ErrorAction SilentlyContinue).Trim() -ne "free") { L "refused: the lock is not free"; exit 2 }
$env:ZEDQA_NOSTEAM = "1"
$mods = @(
    @{ id = "ChuckleberryFinnAlertSystem"; dir = "chuckleberryModdingAlertSystem"; src = "$Ws\3077900375\mods\chuckleberryModdingAlertSystem" },
    @{ id = "errorMagnifier"; dir = "errorMagnifier"; src = "$Ws\2896041179\mods\errorMagnifier" },
    @{ id = "SkillRecoveryJournal"; dir = "Skill Recovery Journal"; src = "$Ws\2503622437\mods\Skill Recovery Journal" }
)
foreach ($m in $mods) { if (-not (Test-Path -LiteralPath $m.src)) { L "NOT DOWNLOADED: $($m.dir)"; exit 3 } }
$copied = @()
try {
    foreach ($m in $mods) {
        $dst = "$Z\mods\$($m.dir)"
        if (-not (Test-Path -LiteralPath $dst)) { Copy-Item -LiteralPath $m.src $dst -Recurse; $copied += $dst; L "$($m.dir) copied in" } else { L "$($m.dir) already there (left alone)" }
    }
    $ml = Join-Path $OutDir "ts_mods.txt"; Set-Content $ml ($mods | ForEach-Object { $_.id })
    $lines = @("zedqa_prelude.lua | pre | timeout=120")
    if ($Mode -eq "deckL") { $lines += "zedqa_large_text.lua | ltx | timeout=120" }
    $lines += @("zedqa_ts_journal.lua | tsj1 | timeout=60", "zedqa_tab_search.lua | ts | timeout=600", "zedqa_ts_journal.lua | tsj2 | timeout=60", "zedqa_journal_tags.lua | jtag | timeout=600")
    $mf = Join-Path $OutDir "ts_manifest_$Mode.txt"; Set-Content $mf $lines
    $al = @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", $ml, "-Manifest", $mf)
    if ($Mode -eq "4k") { $al += @("-Mode", "fullscreen4k") } else { $al += @("-Mode", "windowed", "-Width", "1280", "-Height", "800") }
    $out = Join-Path $OutDir "ts_run_$Mode.out"
    $p = Start-Process pwsh -ArgumentList $al -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.Id | Set-Content (Join-Path $OutDir "ts_run_$Mode.pid")
    $p.WaitForExit()
    L "run $Mode exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
}
finally {
    foreach ($d in $copied) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force; L ("removed " + $d.Replace($env:USERPROFILE, '%USERPROFILE%')) } }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
