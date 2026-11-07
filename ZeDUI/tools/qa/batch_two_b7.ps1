#Requires -Version 7.0
# ZeDUI/tools/qa/batch_two_b7.ps1  (Nov 7 2026, QA): the next beta's merge 1 with a real second player, the admin's game in German
# (options.ini's language set for the run and put back). The admin claims a house and brings bob into it; bob watches and claims
# it the moment the admin releases it (the server's ZeD log should read two lines); bob invites the admin and the admin presses
# Accept twice (the second must say to wait); then the Admin and ticket cards with their clips counted, at Normal and Large text.
# Results in ZeDUI/qa/two_players_b7.txt; pictures in the scratchpad. Both clients and the server close after.
$Qa = $PSScriptRoot
$Root = "C:\Users\you\Zomboid\mods\ZeD-UI"
$Log = "$Root\ZeDUI\qa\two_players_b7.txt"
$Z = "C:\Users\you\Zomboid"
$Lua = "$Z\Lua"
$Lock = "$Lua\zedqa.lock"
$env:ZEDQA_NOSTEAM = "1"
$Con = "$Z\zedqa_p2\console.txt"
$Shots = "$Z\Screenshots"
$Out = "C:\Users\you\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\two_b7"
New-Item -ItemType Directory -Force $Out | Out-Null
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log }
function Main($f, $t, $s = 120) { & "$Qa\mp_client2.ps1" -Main -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function Bob($f, $t, $s = 180) { & "$Qa\mp_client2.ps1" -Run "$Qa\$f" -Tag $t -TimeoutSec $s | ForEach-Object { Note $_ } }
function Shots($name) { New-Item -ItemType Directory -Force "$Out\$name" | Out-Null; Get-ChildItem $Shots -Filter "*.png" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-20) } | Move-Item -Destination "$Out\$name" -Force }
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
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') next beta merge 1, two players, the admin in German" | Set-Content $Log
$Cache = "$Z\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_b7"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
$MO = "$Lua\ModOptions.ini"; Copy-Item $MO "$Keep\ModOptions.ini" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
$ini = "$Z\options.ini"
$iniText = Get-Content -Raw $ini
$wasLang = if ($iniText -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
Set-Content -Path $ini -Value ($iniText -replace '(?m)^language=.*$', "language=DE") -NoNewline
& "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "PlayerSafehouse=true;AdminSafehouse=true;DoLuaChecksum=false;SafehouseAllowNonResidential=true" | ForEach-Object { if ($_ -match "^set ") { Note $_ } }; Note "server up"
$P2Shim = "$Z\zedqa_p2\mods\ZeDQAShim"; if (Test-Path $P2Shim) { Remove-Item $P2Shim -Recurse -Force }; Copy-Item "$Z\mods\ZeDQAShim" $P2Shim -Recurse
try {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_pin_only.txt" -Mp -Mode windowed -Width 1280 -Height 800 -KeepOpen -Report "$Root\ZeDUI\qa\regression\2026-11-07_two_b7_start.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 1) -join ' ')"
    Set-Content $Lock "busy" -NoNewline
    Main "mp_b6a_claim.lua" "acm" 200
    & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
    function ReArmed { $t0 = Get-Date; while (((Get-Date) - $t0).TotalSeconds -lt 180) { if (([regex]::Matches((Get-Content $Con -Raw -ErrorAction SilentlyContinue), "bridge armed \(main menu")).Count -ge 2) { break }; Start-Sleep 3 }; Start-Sleep 6 }
    ReArmed
    Bob "mp_p2_newchar.lua" "pnc" 120
    if (BobIn) {
        Main "mp_b7_fetch_bob.lua" "fbb" 60
        $job = Start-Job -ScriptBlock { param($q) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Run "$q\mp_b7_reclaim.lua" -Tag brc -TimeoutSec 150 } -ArgumentList $Qa
        Start-Sleep 10
        Main "mp_b7_release.lua" "arl" 90
        Receive-Job -Job $job -Wait | ForEach-Object { Note $_ }
        Remove-Job $job
        Bob "mp_b7_invite_admin.lua" "bia" 60
        Main "mp_b7_double.lua" "adb" 90
        Main "mp_clip_hook.lua" "mch" 30
        Main "mp_admin_cards.lua" "mac" 300
        Main "mp_ticket_cards.lua" "mtc" 300
        Main "mp_clip_report.lua" "mcr" 30
        Shots "normal"
        Main "zedqa_textlarge.lua" "txl" 60
        Main "mp_admin_cards.lua" "mac" 300
        Main "mp_clip_report.lua" "mcr" 30
        Shots "large"
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
    if ($zl) { Note "server ZeD log $($zl.FullName):"; Get-Content $zl.FullName | Select-String "safehouse" | ForEach-Object { Note "  $_" } }
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Copy-Item "$Keep\ModOptions.ini" $MO -Force
    $now = Get-Content -Raw $ini
    Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$wasLang") -NoNewline
    Note "language put back to $wasLang"
    Set-Content $Lock "free" -NoNewline
    Note "closed"
}
