#Requires -Version 7.0
# ZeDUI/tools/qa/batch_mp.ps1  (Nov 5 2026, QA): the multiplayer items of the known issues run, on the code as it stands: the
# Ranch step, the board with the marks, then the server steps. The server's user list and settings go back after.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
Note "multiplayer start"
$Cache = "C:\Users\you\Zomboid\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
function RunMp($manifest, $tag, $extra = @{}) {
    $report = Join-Path $Rep "2026-11-05_$tag.md"
    $a = @{ Manifest = "$Qa\$manifest"; Mp = $true; Report = $report } + $extra
    $o = & "$Qa\zedqa_run.ps1" @a 2>&1
    Note "$tag : $(($o | Select-Object -Last 1) -join ' ')"
}
try {
    & "$Qa\mp_server.ps1" -Start | Out-Null; Note "server up"
    RunMp "mp_deck.txt" "mp_deck" @{ Mode = "windowed"; Width = 1280; Height = 800 }
    $s = "C:\Users\you\Zomboid\Screenshots"; New-Item -ItemType Directory -Force "$s\mp_deck_20261105" | Out-Null; Move-Item "$s\mps_*.png" "$s\mp_deck_20261105\" -Force
    RunMp "mp_plain.txt" "mp_plain"
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force
    (Get-Content "$Cache\Server\zedqa.ini") -replace '^SafetySystem=.*$', 'SafetySystem=false' | Set-Content "$Cache\Server\zedqa.ini" -Encoding ascii
    & "$Qa\mp_server.ps1" -Start | Out-Null; Note "server up, safety off"
    RunMp "mp_nosafety.txt" "mp_nosafety"
}
finally {
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Note "server stopped, its users and settings put back"
}
Note "multiplayer end"
