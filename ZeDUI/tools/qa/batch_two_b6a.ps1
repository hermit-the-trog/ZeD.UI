#Requires -Version 7.0
# ZeDUI/tools/qa/batch_two_b6a.ps1  (Nov 6 2026, QA): 0.3.0-beta6a with a real second player: the admin on the first client, bob on the second copy, on the local server. Invitation online, held past two
# server replies, declined; invitation while bob is off, back, accepted; the mute on every stream; Check stats. Results in ZeDUI/qa/two_players_beta6a.txt. Both clients and the server close after.
param([switch]$KeepAfterJoin)
$Qa = $PSScriptRoot
$Root = "C:\Users\danie\Zomboid\mods\ZeD-UI"
$Log = "$Root\ZeDUI\qa\two_players_beta6a.txt"
$Lua = "C:\Users\danie\Zomboid\Lua"
$Lock = "$Lua\zedqa.lock"
$env:ZEDQA_NOSTEAM = "1"
$Con = "C:\Users\danie\Zomboid\zedqa_p2\console.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log }
function Main($f, $t, $s = 120) { & "$Qa\mp_client2.ps1" -Main -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function Bob($f, $t, $s = 180) { & "$Qa\mp_client2.ps1" -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function BobIn {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt 300) {
        $txt = (Get-Content $Con -Raw -ErrorAction SilentlyContinue)
        if ($txt -match 'bridge armed \(in game') { Note "bob in game"; Start-Sleep 6; return $true }
        if ($txt -match 'game loading took') { & "$Qa\mp_client2.ps1" -Click | Out-Null }
        Start-Sleep 8
    }
    Note "bob never reached the game"
    return $false
}
$Cache = "C:\Users\danie\Zomboid\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_two"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
$MO = "$Lua\ModOptions.ini"; Copy-Item $MO "$Keep\ModOptions.ini" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
& "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "PlayerSafehouse=true;AdminSafehouse=true;DoLuaChecksum=false;SafehouseAllowNonResidential=true" | ForEach-Object { if ($_ -match "^set ") { Note $_ } }; Note "server up"   # (safehouses are off on the test server until set)
$P2Shim = "C:\Users\danie\Zomboid\zedqa_p2\mods\ZeDQAShim"; if (Test-Path $P2Shim) { Remove-Item $P2Shim -Recurse -Force }; Copy-Item "C:\Users\danie\Zomboid\mods\ZeDQAShim" $P2Shim -Recurse   # (the server requires it of every client)
try {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_pin_only.txt" -Mp -Mode windowed -Width 1280 -Height 800 -KeepOpen -Report "$Root\ZeDUI\qa\regression\2026-11-06_hotfix_two_start.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 1) -join ' ')"
    Set-Content $Lock "busy" -NoNewline
    Main "mp_b6a_claim.lua" "acm" 200
    & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
    function ReArmed { $t0 = Get-Date; while (((Get-Date) - $t0).TotalSeconds -lt 180) { if (([regex]::Matches((Get-Content $Con -Raw -ErrorAction SilentlyContinue), "bridge armed \(main menu")).Count -ge 2) { break }; Start-Sleep 3 }; Start-Sleep 6 }   # (joining reloads the mods: a script run before that is lost)
    ReArmed
    Bob "mp_p2_newchar.lua" "pnc" 120
    if (BobIn) {
        Main "mp_b6a_mute_on.lua" "amon"
        Bob "mp_b6a_muted.lua" "amd"
        Main "mp_b6a_mute_off.lua" "amoff"
        Bob "mp_b6a_unmuted.lua" "aum"
        Main "mp_b6a_stats.lua" "ast"
        Main "mp_b6a_invite.lua" "ain"
        Bob "mp_b6a_note.lua" "anb"
        & "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
        Start-Sleep 5
        Main "mp_b6a_invite.lua" "ain"
        & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
        ReArmed
        Bob "mp_p2_newchar.lua" "pnc" 25   # (leaving soon after joining, bob comes back to the new character screen)
        if (BobIn) { Bob "mp_b6a_offline.lua" "aof" }
    }
}
finally {
    & "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
    Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "$Lua\zedqa.counter"; [long]$n = (Get-Content $c -Raw).Trim(); $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 30 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    & "$Qa\pzrestorewin.ps1" | Out-Null
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Copy-Item "$Keep\ModOptions.ini" $MO -Force
    Set-Content $Lock "free" -NoNewline
    Note "closed"
}
