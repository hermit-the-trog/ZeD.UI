# QA (Nov 9 2026): start of the beta 11 cycle on the dev mod: the corkboard picture (main menu), then the Deck reruns
# of b9a2, b9a4 and dpn with Build's fixed scripts. Each run through Start-Process to a file + WaitForExit (never piped).
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_start_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
function Run([string]$tag, [string[]]$argv) {
    $out = Join-Path $Qa "b11_start_$tag.out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File") + $argv) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    L "$tag exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
}
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$empty = Join-Path $Qa "b8_empty_mods.txt"; Set-Content -LiteralPath $empty -Value ""
Run "corkboard" @("$Qa\zedqa_menu_mods_run.ps1", "-ModList", $empty, "-Script", "$Qa\zedqa_menunote_shot.lua", "-Tag", "mmn", "-TimeoutSec", "400")
$m = Join-Path $Qa "b11_deck_reruns.txt"
Set-Content $m @("zedqa_prelude.lua | pre | timeout=240", "zedqa_b9a_2.lua | b9a2 | timeout=240", "zedqa_b9a_4.lua | b9a4 | timeout=240", "zedqa_dual_pin.lua | dpn | timeout=960")
Run "deck" @("$Qa\release_check.ps1", "-Manifest", "b11_deck_reruns.txt", "-Width", "1280", "-Height", "800", "-Report", "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-09_b11_deck_reruns.md")
Run "restore" @("$Qa\pzrestorewin.ps1")
"== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
