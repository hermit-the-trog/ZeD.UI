#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_msc_run.ps1  (Nov 12 2026, QA 177): Maskarad's Summer Car baseline runs for the compatibility fix.
#   -Run 1   ZeD on + Summer Car, 4K, with the real-mouse helper (zedqa_msc_run1.lua)
#   -Run 2   ZeD out of the list (the QA shim's bridge), Summer Car on, 4K (zedqa_msc_run2.lua)
# The mod is copied from the Steamcmd download into Zomboid\mods for the run and removed after (only if this script copied it).
# The ZeD-QA save is copied to a backup outside Saves first and put back after (zedqa_mods_run.ps1 also keeps its own snapshot).
param([ValidateSet(1, 2)][int]$Run = 1, [string]$Backup = "")
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "msc_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start run $Run" | Add-Content $Log
$env:ZEDQA_NOSTEAM = "1"
$Lua = "$($env:USERPROFILE)\Zomboid\Lua"
$src = "C:\steamcmd\steamapps\workshop\content\108600\3790160840\mods\MaskaradsSummerCar"
$dst = "$($env:USERPROFILE)\Zomboid\mods\MaskaradsSummerCar"
$save = "$($env:USERPROFILE)\Zomboid\Saves\Sandbox\ZeD-QA"
$copied = $false
if (-not (Test-Path $dst)) { Copy-Item $src $dst -Recurse; $copied = $true; L "MaskaradsSummerCar copied in" }
if ($Backup -and -not (Test-Path $Backup)) { Copy-Item $save $Backup -Recurse; L "ZeD-QA backed up to $Backup" }
$ml = Join-Path $Qa $(if ($Run -eq 1) { "msc_run1_mods.txt" } else { "msc_run2_mods.txt" })
if ($Run -eq 1) { Set-Content $ml "MaskaradsSummerCar" } else { Set-Content $ml @("MaskaradsSummerCar", "ZeDQAShim") }
$mf = Join-Path $Qa "msc_run${Run}_manifest.txt"
if ($Run -eq 1) { Set-Content $mf @("zedqa_prelude.lua | pre | timeout=120", "zedqa_msc_run1.lua | msc1 | timeout=420") }
else { Set-Content $mf @("zedqa_msc_run2.lua | msc2 | timeout=300") }
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = $null
if ($Run -eq 1) { $h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "12" -WindowStyle Hidden -PassThru; L "mouse helper pid $($h.Id)" }
try {
    $out = Join-Path $Qa "msc_run$Run.out"
    $a = @("-NoProfile", "-File", "$Qa\zedqa_mods_run.ps1", "-ModList", $ml, "-Mode", "fullscreen4k", "-Manifest", $mf)
    if ($Run -eq 2) { $a += "-NoZeD" }
    $p = Start-Process pwsh -ArgumentList $a -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    L "runner pid $($p.Id)"
    $p.WaitForExit()
    L "run exit $($p.ExitCode): $((Get-Content $out -Tail 3 -ErrorAction SilentlyContinue) -join ' | ')"
} finally {
    if ($h) {
        Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
        for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
        if (-not $h.HasExited) { Stop-Process -Id $h.Id -Force }
        Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
    }
    if ($copied -and (Test-Path $dst)) { Remove-Item $dst -Recurse -Force; L "MaskaradsSummerCar removed" }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
