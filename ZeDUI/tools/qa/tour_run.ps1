#Requires -Version 7.0
<#
    ZeDUI/tools/qa/tour_run.ps1  (Nov 19 2026, QA): the tour's checks (beta 21, ZeD_Tutorial.lua) with the tour asked
    for at launch, so rt_tour.lua also checks that it starts by itself. Zomboid/Lua/ZeD_tutorial.txt is the director's
    own; this wrapper keeps its bytes, writes "1" for the run, and in a finally block puts the file back byte for byte
    (or removes it when there was none). One launch through zedqa_run.ps1 with tour_only.txt.
    It refuses to start (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy.
    Exit: the runner's exit code, 1 when the file did not come back, 2 refused.
      pwsh -File ZeDUI/tools/qa/tour_run.ps1
      pwsh -File ZeDUI/tools/qa/tour_run.ps1 -Mode windowed -Width 1280 -Height 800
#>
param(
    [ValidateSet("windowed", "fullscreen4k")][string]$Mode = "fullscreen4k",
    [int]$Width = 1920,
    [int]$Height = 1080
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$zdir = $(if ($env:ZEDQA_ZDIR) { $env:ZEDQA_ZDIR } else { "$($env:USERPROFILE)\Zomboid" })
$lua = Join-Path $zdir "Lua"
$file = Join-Path $lua "ZeD_tutorial.txt"
$lock = Join-Path $lua "zedqa.lock"

$ls = $null
try { $ls = [string](Get-Content -LiteralPath $lock -Raw -ErrorAction Stop) } catch { }
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "tour_run: not starting: $lock says busy"; exit 2 }
if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "tour_run: not starting: ProjectZomboid64.exe is running"; exit 2 }

$had = Test-Path -LiteralPath $file
$was = $(if ($had) { [IO.File]::ReadAllBytes($file) } else { $null })
$size = @()
if ($Mode -eq "windowed") { $size = @("-Width", $Width, "-Height", $Height) }
$tagSize = $(if ($Mode -eq "windowed") { "_${Width}x${Height}" } else { "_4k" })
$code = 1
try {
    [IO.File]::WriteAllText($file, "1")
    & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "tour_only.txt") -Mode $Mode @size -Report "tour$tagSize"
    $code = $LASTEXITCODE
}
finally {
    if ($had) {
        [IO.File]::WriteAllBytes($file, $was)
        $now = [IO.File]::ReadAllBytes($file)
        if ([Convert]::ToBase64String($now) -eq [Convert]::ToBase64String($was)) { Write-Output "tour_run: ZeD_tutorial.txt put back byte for byte" }
        else { Write-Output "tour_run: ZeD_tutorial.txt did NOT come back"; $code = 1 }
    }
    elseif (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force; Write-Output "tour_run: there was no ZeD_tutorial.txt before; removed" }
}
exit $code
