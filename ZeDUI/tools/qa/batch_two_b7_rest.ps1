#Requires -Version 7.0
# ZeDUI/tools/qa/batch_two_b7_rest.ps1  (Nov 7 2026, QA; the director: "Yes, run them"): the next beta's three cases left from the
# night, with a real second player on the local test server:
#   1 an invitation to a safehouse arriving while bob's yes is on its way, safe mode switched on in that moment (mp_b7_safe_join.lua)
#   2 the dash with two players: bob outside while the admin drives, then bob as the passenger (mp_b7_dash_*.lua)
#   3 the offline Player card's role box for a role that changes roles but cannot see every account, and the server's
#     refusal (mp_b7_role_setup.lua, mp_b7_closed_card.lua)
# Results in ZeDUI/qa/two_players_b7_rest.txt; pictures in the scratchpad. Both clients and the server close after, and the
# server's database, its ini and ModOptions are put back.
param([switch]$DashOnly, [switch]$RoleOnly, [switch]$SafeOnly)
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$Log = "$Root\ZeDUI\qa\two_players_b7_rest.txt"
$Z = "$($env:USERPROFILE)\Zomboid"
$Lua = "$Z\Lua"
$P2 = "$Z\zedqa_p2"
$Lock = "$Lua\zedqa.lock"
$env:ZEDQA_NOSTEAM = "1"
$Con = "$P2\console.txt"
$Out = "$($env:USERPROFILE)\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\two_b7_rest"
New-Item -ItemType Directory -Force $Out | Out-Null
$all = -not ($DashOnly -or $RoleOnly -or $SafeOnly)
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log }
function Main($f, $t, $s = 120) { & "$Qa\mp_client2.ps1" -Main -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function Bob($f, $t, $s = 180) { & "$Qa\mp_client2.ps1" -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function BobJob($f, $t, $s) { Start-Job -ScriptBlock { param($q, $f, $t, $s) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Run "$q\$f" -Tag $t -TimeoutSec $s } -ArgumentList $Qa, $f, $t, $s }
function JobOut($j) { Receive-Job -Job $j -Wait | ForEach-Object { Note $_ }; Remove-Job $j }
function Phase($p) { Set-Content "$P2\Lua\zedqa_dash_phase.txt" $p -NoNewline; Note "-- dash phase: $p" }
function Shots($name) {
    New-Item -ItemType Directory -Force "$Out\$name" | Out-Null
    foreach ($d in "$Z\Screenshots", "$P2\Screenshots") {
        if (Test-Path $d) { Get-ChildItem $d -Filter "*.png" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } | Move-Item -Destination "$Out\$name" -Force }
    }
}
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
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
if ((Get-Content $Lock -Raw -ErrorAction SilentlyContinue) -match "busy") { Write-Output "the QA lock is taken, stop"; exit 2 }
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') next beta: the three two-player cases left from the night" | Set-Content $Log
$Cache = "$Z\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_b7rest"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
$MO = "$Lua\ModOptions.ini"; Copy-Item $MO "$Keep\ModOptions.ini" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
if (Test-Path "$P2\Lua\ModOptions.ini") { Copy-Item "$P2\Lua\ModOptions.ini" "$Keep\p2_ModOptions.ini" -Force }
& "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "PlayerSafehouse=true;AdminSafehouse=true;DoLuaChecksum=false;SafehouseAllowNonResidential=true" | ForEach-Object { if ($_ -match "^set ") { Note $_ } }; Note "server up"
$P2Shim = "$P2\mods\ZeDQAShim"; if (Test-Path $P2Shim) { Remove-Item $P2Shim -Recurse -Force }; Copy-Item "$Z\mods\ZeDQAShim" $P2Shim -Recurse
try {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_pin_only.txt" -Mp -Mode windowed -Width 1280 -Height 800 -KeepOpen -Report "$Root\ZeDUI\qa\regression\2026-11-07_two_b7_rest_start.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 1) -join ' ')"
    Set-Content $Lock "busy" -NoNewline
    if ($all -or $SafeOnly) { Main "mp_b6a_claim.lua" "acm" 200 }
    & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
    $t0 = Get-Date; while (((Get-Date) - $t0).TotalSeconds -lt 180) { if ((Get-Content $Con -Raw -ErrorAction SilentlyContinue) -match "bridge armed \(main menu") { break }; Start-Sleep 3 }; Start-Sleep 6
    Bob "mp_p2_newchar.lua" "pnc" 120
    if (BobIn) {
        if ($all -or $SafeOnly) {
            Note "== 1 an invitation while a yes is on its way, safe mode on"
            Main "mp_b6a_invite.lua" "ain" 60
            Bob "mp_b7_safe_join.lua" "bsj" 120
            Shots "safe_join"
        }
        if ($all -or $DashOnly) {
            Note "== 2 the dash with two players"
            Main "mp_b7_dash_stage.lua" "dsg" 150
            Copy-Item "$Lua\zedqa_dash_car.txt" "$P2\Lua\zedqa_dash_car.txt" -Force -ErrorAction SilentlyContinue
            Phase "watch"
            $j = BobJob "mp_b7_dash_bob.lua" "dbb" 120
            Start-Sleep 4
            Main "mp_b7_dash_drive.lua" "ddr" 120
            JobOut $j
            Main "mp_b7_fetch_bob.lua" "fbb" 60
            Phase "board"
            Bob "mp_b7_dash_bob.lua" "dbb" 120
            Phase "ride"
            $j = BobJob "mp_b7_dash_bob.lua" "dbb" 150
            Start-Sleep 4
            Main "mp_b7_dash_drive.lua" "ddr" 120
            JobOut $j
            Shots "dash"
        }
        if ($all -or $RoleOnly) {
            Note "== 3 the offline Player card's role box"
            Main "mp_b7_role_setup.lua" "rsu" 90
            Bob "mp_b7_closed_card.lua" "bcc" 180
            Shots "closed_card"
        }
    }
}
finally {
    & "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
    Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "$Lua\zedqa.counter"; [long]$n = (Get-Content $c -Raw).Trim(); $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 30 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    & "$Qa\pzrestorewin.ps1" | Out-Null
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    $zl = Get-ChildItem "$Cache\Logs" -Recurse -Filter "*_ZeD.txt" | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($zl) { Note "server ZeD log $($zl.FullName):"; Get-Content $zl.FullName | Select-String "safehouse|role|kick" | Select-Object -Last 20 | ForEach-Object { Note "  $_" } }
    $sl = Get-ChildItem "$Cache" -Filter "server-console.txt" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($sl) { Get-Content $sl.FullName | Select-String "ZeDQA|kick|AntiCheat" | Select-Object -Last 30 | ForEach-Object { Note "  server: $_" } }
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Copy-Item "$Keep\ModOptions.ini" $MO -Force
    if (Test-Path "$Keep\p2_ModOptions.ini") { Copy-Item "$Keep\p2_ModOptions.ini" "$P2\Lua\ModOptions.ini" -Force }
    Remove-Item "$Lua\zedqa_dash_car.txt", "$P2\Lua\zedqa_dash_car.txt", "$P2\Lua\zedqa_dash_phase.txt" -ErrorAction SilentlyContinue
    Shots "end"
    Set-Content $Lock "free" -NoNewline
    Note "closed"
}
