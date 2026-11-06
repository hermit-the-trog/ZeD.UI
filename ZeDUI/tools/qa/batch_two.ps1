#Requires -Version 7.0
# ZeDUI/tools/qa/batch_two.ps1  (Nov 5 2026, QA): two players on the local server: the admin on the first client at the Deck's size, a plain player on the
# second copy. The results land in ZeDUI/qa/two_players_20261105.txt. Both clients and the server are closed after; the lock is held for the run.
$Qa = $PSScriptRoot
$Root = "C:\Users\you\Zomboid\mods\ZeD-UI"
$Log = "$Root\ZeDUI\qa\two_players_20261105.txt"
$Lock = "C:\Users\you\Zomboid\Lua\zedqa.lock"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log }
$MO = "C:\Users\you\Zomboid\Lua\ModOptions.ini"; Copy-Item $MO "$env:TEMP\ModOptions.two.ini" -Force   # (-KeepOpen leaves the run's settings in place)
& "$Qa\mp_server.ps1" -Start | Out-Null; Note "server up"
try {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_pin_only.txt" -Mp -Mode windowed -Width 1280 -Height 800 -KeepOpen -Report "$Root\ZeDUI\qa\regression\2026-11-05_mp_two_start.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 1) -join ' ')"
    Set-Content $Lock "busy" -NoNewline
    & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
    Start-Sleep 12
    & "$Qa\mp_client2.ps1" -Run "$Qa\mp_p2_newchar.lua" -Tag pnc -TimeoutSec 120 | ForEach-Object { Note $_ }
    $con = "C:\Users\you\Zomboid\zedqa_p2\console.txt"
    $t0 = Get-Date
    $armed = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 300) {
        $txt = (Get-Content $con -Raw -ErrorAction SilentlyContinue)
        if ($txt -match 'bridge armed \(in game') { $armed = $true; break }
        if ($txt -match 'game loading took') { & "$Qa\mp_client2.ps1" -Click | Out-Null }
        Start-Sleep 8
    }
    Note "second client in game: $armed"
    if ($armed) {
        Start-Sleep 6
        & "$Qa\mp_client2.ps1" -Run "$Qa\mp_two_plain.lua" -Tag m2p -TimeoutSec 60 | ForEach-Object { Note $_ }
        & "$Qa\mp_client2.ps1" -Main -Run "$Qa\mp_two_admin.lua" -Tag m2a -TimeoutSec 60 | ForEach-Object { Note $_ }
    }
}
finally {
    & "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
    Set-Content "C:\Users\you\Zomboid\Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "C:\Users\you\Zomboid\Lua\zedqa.counter"; [long]$n = (Get-Content $c -Raw).Trim(); $n++; Set-Content $c "$n" -NoNewline; Set-Content "C:\Users\you\Zomboid\Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 30 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    & "$Qa\pzrestorewin.ps1" | Out-Null
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    Copy-Item "$env:TEMP\ModOptions.two.ini" $MO -Force
    Set-Content $Lock "free" -NoNewline
    Note "closed"
}
