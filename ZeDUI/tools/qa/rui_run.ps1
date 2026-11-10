# QA (Nov 9 2026): Responsive Context Menus (Workshop 3783387236, mod id ResponsiveUI) with ZeD, at 4K: the mod copied
# from Steam's download into Zomboid\mods for the run and removed after (only if this script copied it); zedqa_mods_run.ps1
# keeps the QA save's mod list clean. Start-Process + WaitForExit, lines to rui_run.log.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "rui_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$src = "E:\Project Zomboid\SteamApps\workshop\content\108600\3783387236\mods\ResponsiveUI"
$dst = "$($env:USERPROFILE)\Zomboid\mods\ResponsiveUI"
$copied = $false
if (-not (Test-Path $dst)) { Copy-Item $src $dst -Recurse; $copied = $true; L "ResponsiveUI copied in" }
$ml = Join-Path $Qa "rui_mods.txt"; Set-Content $ml "ResponsiveUI"
$mf = Join-Path $Qa "rui_manifest.txt"; Set-Content $mf @("zedqa_prelude.lua | pre | timeout=120", "zedqa_responsiveui.lua | rui | timeout=600")
try {
    $out = Join-Path $Qa "rui_run.out"
    $p = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", $ml, "-Mode", "fullscreen4k", "-Manifest", $mf -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    L "run exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
} finally {
    if ($copied -and (Test-Path $dst)) { Remove-Item $dst -Recurse -Force; L "ResponsiveUI removed" }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
