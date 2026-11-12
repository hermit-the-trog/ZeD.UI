#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_animals_de_run.ps1  (Nov 11 2026, QA, punch list 169): the Animals band in German at 4K. options.ini's language set to DE for the run, put back after.
$ErrorActionPreference = "Stop"
$Qa = $PSScriptRoot
$ini = "$($env:USERPROFILE)\Zomboid\options.ini"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "refused: the game is running"; exit 2 }
if ((Get-Content "$($env:USERPROFILE)\Zomboid\Lua\zedqa.lock" -Raw).Trim() -ne "free") { Write-Output "refused: lock"; exit 2 }
$was = [System.IO.File]::ReadAllText($ini)
$wasLang = if ($was -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
try {
    [System.IO.File]::WriteAllText($ini, ($was -replace '(?m)^language=.*$', "language=DE"))
    $env:ZEDQA_NOSTEAM = "1"
    $out = Join-Path $Qa "animals_de_run.out"
    $p = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", "$Qa\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", "$Qa\animals_de.txt") -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.Id | Set-Content (Join-Path $Qa "animals_de_run.pid")
    $p.WaitForExit()
    Write-Output "run exit $($p.ExitCode)"
}
finally {
    $now = [System.IO.File]::ReadAllText($ini)
    [System.IO.File]::WriteAllText($ini, ($now -replace '(?m)^language=.*$', "language=$wasLang"))
    Write-Output "language put back to $wasLang"
}
