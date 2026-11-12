#Requires -Version 7.0
<#
    ZeDUI/tools/qa/cinema_angel_close.ps1  (Nov 11 2026, QA; the gallery plan v2 shot 6): Angel's closing break on the local
    test server, at night, face to face with the other players. Modelled on batch_b8_mp.ps1.
      1. the server (mp_server.ps1 -Start), its database, settings and sandbox file and the admin's ModOptions copied aside
      2. the admin (Angel): zedqa_run.ps1 -Mp in a 3840x2160 window, kept open (cinema_angel_close_admin.txt); a window and
         not fullscreen so the other clients' windows cannot take the picture's screen away
      3. the others, real clients: mp_client2.ps1 -Slot 2..n (bob, carl, dave), each through the new-character screens
      4. each other client runs gallery_cinema_angel_guest.lua (in the background), the admin brings them over
         (gallery_cinema_angel_gather.lua), then gallery_cinema_angel_close_mode.lua and gallery_cinema_angel.lua take
         the picture, cin_ang_close.png
      5. every client and the server closed by the PIDs the kit saved, the copies put back, the lock "free"
    The real-mouse helper (C.pointerAway) runs for the admin's shot.
      pwsh -File ZeDUI/tools/qa/cinema_angel_close.ps1 [-Guests bob,carl,dave]
#>
param([string[]]$Guests = @("bob"))   # (Nov 11 2026: a new client folder stops at the game's terms of service, which a person must accept: bob's alone has)
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$Z = "$($env:USERPROFILE)\Zomboid"
$Lua = "$Z\Lua"
$Lock = "$Lua\zedqa.lock"
$Cache = "$Z\zedqa_mp"
$Log = Join-Path $env:TEMP "zedqa_cinema_angel_close.txt"
$env:ZEDQA_NOSTEAM = "1"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log; Write-Output $s }
function ConText($p) { try { (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) -replace "`0", "" } catch { "" } }
function Slot($i) { return $i + 2 }
function GuestCon($i) { return "$Z\zedqa_p$(Slot $i)\console.txt" }
function GuestAlive($i) { $f = "$Z\zedqa_p$(Slot $i)\client.pid"; if (-not (Test-Path $f)) { return $false }; return [bool](Get-Process -Id ([int](Get-Content $f -Raw).Trim()) -ErrorAction SilentlyContinue) }
function MenuCount($i) { return ([regex]::Matches((ConText (GuestCon $i)), 'bridge armed \(main menu')).Count }
function Main($file, $tag, $sec) { Note "-- admin runs $file"; & "$Qa\mp_client2.ps1" -Main -Run "$Qa\$file" -Tag $tag -TimeoutSec $sec | ForEach-Object { Note $_ } }
function Guest-Start($i) {
    $s = Slot $i; $u = $Guests[$i]
    $shim = "$Z\zedqa_p$s\mods\ZeDQAShim"; if (Test-Path $shim) { Remove-Item $shim -Recurse -Force }
    if (Test-Path "$Z\mods\ZeDQAShim") { New-Item -ItemType Directory -Force "$Z\zedqa_p$s\mods" | Out-Null; Copy-Item "$Z\mods\ZeDQAShim" $shim -Recurse }
    & "$Qa\mp_client2.ps1" -Start -Slot $s -User $u | ForEach-Object { Note "[$u] $_" }
    $t0 = Get-Date; $newchar = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 420) {
        if (-not (GuestAlive $i)) { Note "[$u] the client closed while loading"; return $false }
        $t = ConText (GuestCon $i)
        if ($t -match 'bridge armed \(in game') { Note "[$u] in game"; Start-Sleep 6; return $true }
        if ((MenuCount $i) -ge 2 -and -not $newchar) {
            $newchar = $true; Start-Sleep 6
            & "$Qa\mp_client2.ps1" -Slot $s -Run "$Qa\mp_p2_newchar.lua" -Tag pnc -TimeoutSec 240 | ForEach-Object { Note "[$u] $_" }
        }
        if ($t -match 'game loading took') { & "$Qa\mp_client2.ps1" -Slot $s -Click | Out-Null }
        Start-Sleep 8
    }
    Note "[$u] never reached the game"
    return $false
}

if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
if ((Test-Path $Lock) -and ((Get-Content $Lock -Raw) -match 'busy')) { Write-Output "Lua/zedqa.lock says busy, stop"; exit 2 }
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') the closing break on the test server, guests: $($Guests -join ', ')" | Set-Content $Log
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_cang"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
if (Test-Path "$Cache\Server\zedqa.ini") { Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force }
$SbxFile = "$Cache\Server\zedqa_SandboxVars.lua"
if (Test-Path $SbxFile) { Copy-Item $SbxFile "$Keep\zedqa_SandboxVars.lua" -Force }
$MO = "$Lua\ModOptions.ini"; if (Test-Path $MO) { Copy-Item $MO "$Keep\ModOptions.ini" -Force }
$helper = $null
$joined = @()
try {
    & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "DoLuaChecksum=false" | ForEach-Object { if ($_ -match "^set |ready|already|PID") { Note $_ } }
    Note "server up"
    $o = & pwsh -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\cinema_angel_close_admin.txt" -Mp -Mode windowed -Width 3840 -Height 2160 -KeepOpen -Report "$Root\ZeDUI\qa\regression\$(Get-Date -Format yyyy-MM-dd_HHmm)_cang_admin.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 2) -join ' / ')"
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { throw "the admin client is not running" }
    Set-Content $Lock "busy" -NoNewline
    for ($i = 0; $i -lt $Guests.Count; $i++) { try { if (Guest-Start $i) { $joined += $Guests[$i] } } catch { Note "[$($Guests[$i])] $($_.Exception.Message)" } }
    Note "joined: $($joined -join ', ')"
    if ($joined.Count -eq 0) { throw "no other player reached the game" }
    Set-Content "$Lua\zedqa_cang_guests.txt" ($joined -join "`n") -NoNewline
    $jobs = @()
    for ($i = 0; $i -lt $Guests.Count; $i++) {
        if ($joined -notcontains $Guests[$i]) { continue }
        $s = Slot $i
        $jobs += Start-Job -ScriptBlock { param($q, $slot) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Slot $slot -Run "$q\gallery_cinema_angel_guest.lua" -Tag cagu -TimeoutSec 600 } -ArgumentList $Qa, $s
    }
    Start-Sleep 10
    foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $Lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
    $helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "30") -WindowStyle Hidden -PassThru
    Main "gallery_cinema_angel_gather.lua" "cangg" 60
    foreach ($j in $jobs) { Receive-Job -Job $j -Wait -AutoRemoveJob | ForEach-Object { Note "guest: $_" } }
    Main "gallery_cinema_angel_close_mode.lua" "cangm" 30
    Main "gallery_cinema_angel.lua" "cang" 600
    Note "shot: $(Test-Path "$Z\Screenshots\cin_ang_close.png")"
}
catch { Note "STOPPED: $($_.Exception.Message)" }
finally {
    if ($helper) { Set-Content -Path "$Lua\zedqa_click_stop.txt" -Value "stop"; Start-Sleep -Milliseconds 800; if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force } }
    for ($i = 0; $i -lt $Guests.Count; $i++) { & "$Qa\mp_client2.ps1" -Stop -Slot (Slot $i) | ForEach-Object { Note "[$($Guests[$i])] $_" } }
    # the admin: quit through the bridge (the game this run started), then the options back
    Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "$Lua\zedqa.counter"; [long]$n = 9999
    if (Test-Path $c) { $n = [long](Get-Content $c -Raw).Trim() }
    $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 40 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    & "$Qa\pzrestorewin.ps1" | Out-Null
    & "$Qa\mp_server.ps1" -Stop | ForEach-Object { Note "server: $_" }
    Start-Sleep 3
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    if (Test-Path "$Keep\zedqa.ini") { Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force }
    if (Test-Path "$Keep\zedqa_SandboxVars.lua") { Copy-Item "$Keep\zedqa_SandboxVars.lua" $SbxFile -Force }
    if (Test-Path "$Keep\ModOptions.ini") { Copy-Item "$Keep\ModOptions.ini" $MO -Force }
    Remove-Item "$Lua\zedqa_cang_guests.txt" -ErrorAction SilentlyContinue
    Set-Content $Lock "free" -NoNewline
    Note "closed; the server's files and the admin's mod options put back; game still running: $([bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue))"
}
