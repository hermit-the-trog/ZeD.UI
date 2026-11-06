#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tickets.ps1  (Nov 5 2026, QA): Part D's ticket runs on the local server with the shim loaded. -Runs names manifests as
# "manifest:tag:width:height:keep" (0 x 0 = fullscreen 4K). The server's ticket database and settings go back after, so each pass starts from a known state
# unless -KeepDb. Results land in ZeDUI/qa/tickets_20261105.txt, the reports in ZeDUI/qa/regression/.
param([string]$Runs = "mp_tickets.txt:tickets", [switch]$KeepDb)   # (one string, runs parted by commas: an array does not pass through pwsh -File)
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Cache = "C:\Users\you\Zomboid\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
$MO = "C:\Users\you\Zomboid\Lua\ModOptions.ini"; Copy-Item $MO "$Keep\ModOptions.ini" -Force
try {
    & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" | ForEach-Object { Note $_ }
    foreach ($r in ($Runs -split ",")) {
        $f = $r -split ":"
        $a = @{ Manifest = "$Qa\$($f[0])"; Mp = $true; Report = (Join-Path $Rep "2026-11-05_$($f[1]).md") }
        if ($f.Count -ge 4 -and [int]$f[2] -gt 0) { $a.Mode = "windowed"; $a.Width = [int]$f[2]; $a.Height = [int]$f[3] }
        $o = & "$Qa\zedqa_run.ps1" @a 2>&1
        Note "$($f[1]) : $(($o | Select-Object -Last 1) -join ' ')"
    }
}
finally {
    & "$Qa\mp_server.ps1" -Stop | ForEach-Object { Note $_ }
    if (-not $KeepDb -and (Test-Path "$Keep\zedqa.db")) { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Copy-Item "$Keep\ModOptions.ini" $MO -Force
    Note "closed"
}
