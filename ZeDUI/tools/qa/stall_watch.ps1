#Requires -Version 7.0
# ZeDUI/tools/qa/stall_watch.ps1  (Nov 8 2026, QA): a check-in for long unattended runs. Run it in the background
# beside a run. It ends (and so wakes QA) as soon as one of these is true:
#   DONE   the run's process (-RunPid) has ended
#   STALL  none of the watched files has changed for -Minutes (default 5): the run is waiting on something that
#          is not happening (a dialog, a game that never opened, a server that never said ready)
# It never stops or touches anything; it only reports. Usage:
#   pwsh -File stall_watch.ps1 -RunPid 1234 -Minutes 5 -Files %USERPROFILE%\Zomboid\console.txt,C:\...\server-console.txt
param([int]$RunPid = 0, [int]$Minutes = 5, [string[]]$Files = @("$env:USERPROFILE\Zomboid\console.txt"))
function Stamp { ($Files | ForEach-Object { if (Test-Path $_) { (Get-Item $_).LastWriteTimeUtc.Ticks } else { 0 } } | Measure-Object -Maximum).Maximum }
$Files = @($Files | ForEach-Object { $_ -split "," } | Where-Object { $_ })   # (-File passes a comma list as one string)
$last = Stamp; $since = Get-Date
while ($true) {
    Start-Sleep -Seconds 30
    if ($RunPid -gt 0 -and -not (Get-Process -Id $RunPid -ErrorAction SilentlyContinue)) { "DONE: the run (PID $RunPid) has ended"; exit 0 }
    $now = Stamp
    if ($now -ne $last) { $last = $now; $since = Get-Date; continue }
    if (((Get-Date) - $since).TotalMinutes -ge $Minutes) {
        $game = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | ForEach-Object { "PZ $($_.Id) window '$($_.MainWindowTitle)'" }
        "STALL: no log change for $Minutes min. Watched: $($Files -join ', '). Game: $(if ($game) { $game -join '; ' } else { 'not running' })"
        exit 1
    }
}
