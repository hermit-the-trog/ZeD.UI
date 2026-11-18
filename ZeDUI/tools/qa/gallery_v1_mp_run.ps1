#Requires -Version 7.0
<#
    ZeDUI/tools/qa/gallery_v1_mp_run.ps1  (Nov 17 2026, QA; ZeD-GUI 1.0 gallery, picture 75 "Playing on a Server", a
    retake: the old captures were half black, the map not yet loaded after a teleport). b10_ban_run.ps1's shape, with
    cinema_angel_close.ps1's other players:
      1. the local test server (mp_server.ps1 -Start, through Start-Process with its output in a file), its database,
         settings, sandbox file, the admin's ModOptions and chat window place copied aside first. Names over heads
         shown as user names without a mouse-over, players behind the character not hidden.
      2. the admin joins (zedqa_run.ps1 -Mp, 3840x2160 window, kept open) and runs gallery_v1_mp.txt: the look with no
         debug lines, the console hidden, gallery_v1_mp_stage.lua (11:00, a Muldraugh street, the map loaded around
         it), gallery_unload.lua (the load under its limit, the pointer hidden)
      3. the other players, real clients on QA's own test accounts: mp_client2.ps1 -Slot 2..n (bob, carl, dave), each
         through the new-character screens; each runs gallery_v1_mp_guest.lua in the background, the admin brings them
         over (gallery_cinema_angel_gather.lua), they take their squares and each says a line on General
      4. the admin's window to the front, gallery_v1_mp_shot.lua takes g1_75_server.png (and g1_75_chat.png when the
         two windows do not fit in one picture), gallery_reload.lua puts the load back
      5. every client this run started and the server (only if this run started it) closed by the PIDs the kit saved;
         the copies put back; the lock "free". No process this run did not start is ever stopped.
    Lines go to gallery_v1_mp_run.log as they happen (stall_watch.ps1 can watch it).
      pwsh -File ZeDUI/tools/qa/gallery_v1_mp_run.ps1 [-Guests bob,carl,dave]
#>
param([string[]]$Guests = @("bob", "carl", "dave"))   # (zedqa_p2..p4: the terms of service accepted there by the director, Nov 6 and Nov 12)
$env:ZEDQA_NOSTEAM = "1"
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$Z = "$($env:USERPROFILE)\Zomboid"
$Lua = "$Z\Lua"
$Lock = "$Lua\zedqa.lock"
$Cache = "$Z\zedqa_mp"
$Log = Join-Path $Qa "gallery_v1_mp_run.log"
$Tmp = Join-Path $Qa "gallery_v1_mp_tmp"
$Keep = "$Z\zedqa_g1mp_keep"
$Ws = "$Z\Workshop\ZeD-UI"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
function ConText($p) { try { (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) -replace "`0", "" } catch { "" } }
function Slot($i) { return $i + 2 }
function GuestCon($i) { return "$Z\zedqa_p$(Slot $i)\console.txt" }
function GuestAlive($i) { $f = "$Z\zedqa_p$(Slot $i)\client.pid"; if (-not (Test-Path $f)) { return $false }; return [bool](Get-Process -Id ([int](Get-Content $f -Raw).Trim()) -ErrorAction SilentlyContinue) }
function MenuCount($i) { return ([regex]::Matches((ConText (GuestCon $i)), 'bridge armed \(main menu')).Count }
# a pwsh script as a child with its output in a file (never piped: a server started in a pipeline keeps it open);
# waits for the child itself, never for the processes it started
function Child([string]$Name, [string[]]$ScriptArgs, [int]$TimeoutSec = 900) {
    $out = "$Tmp\$Name.out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File") + $ScriptArgs) -RedirectStandardOutput $out -RedirectStandardError "$Tmp\$Name.err" -NoNewWindow -PassThru
    if (-not $p.WaitForExit($TimeoutSec * 1000)) { L "child $Name timed out after $TimeoutSec s (PID $($p.Id))"; try { Stop-Process -Id $p.Id -Force } catch {} }
    $t = ConText $out
    foreach ($l in ($t -split "`r?`n" | Where-Object { $_.Trim() })) { L "$Name> $l" }
    return $t
}
function Main($file, $tag, $sec) { return Child "admin_$tag" @("$Qa\mp_client2.ps1", "-Main", "-Run", "$Qa\$file", "-Tag", $tag, "-TimeoutSec", "$sec") ($sec + 60) }
function Guest-Start($i) {
    $s = Slot $i; $u = $Guests[$i]
    $shim = "$Z\zedqa_p$s\mods\ZeDQAShim"; if (Test-Path $shim) { Remove-Item $shim -Recurse -Force }
    if (Test-Path "$Z\mods\ZeDQAShim") { New-Item -ItemType Directory -Force "$Z\zedqa_p$s\mods" | Out-Null; Copy-Item "$Z\mods\ZeDQAShim" $shim -Recurse }
    [void](Child "start_$u" @("$Qa\mp_client2.ps1", "-Start", "-Slot", "$s", "-User", $u) 420)
    if (GuestAlive $i) { $script:Started += $i }
    $t0 = Get-Date; $newchar = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 420) {
        if (-not (GuestAlive $i)) { L "[$u] the client closed while loading"; return $false }
        $t = ConText (GuestCon $i)
        if ($t -match 'bridge armed \(in game') { L "[$u] in game"; Start-Sleep 6; return $true }
        if ((MenuCount $i) -ge 2 -and -not $newchar) {
            $newchar = $true; Start-Sleep 6
            [void](Child "newchar_$u" @("$Qa\mp_client2.ps1", "-Slot", "$s", "-Run", "$Qa\mp_p2_newchar.lua", "-Tag", "pnc", "-TimeoutSec", "240") 300)
        }
        if ($t -match 'game loading took') { [void](Child "click_$u" @("$Qa\mp_client2.ps1", "-Slot", "$s", "-Click") 30) }
        Start-Sleep 8
    }
    L "[$u] never reached the game"
    return $false
}

New-Item -ItemType Directory -Force $Tmp, $Keep | Out-Null
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') start: picture 75 on the test server, guests $($Guests -join ', ')" | Set-Content $Log
if (Test-Path "$Ws\Contents") { L "a build is staged in Workshop\ZeD-UI\Contents: not starting"; exit 3 }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { L "the game is running: not starting"; exit 2 }
if ((Test-Path $Lock) -and ((Get-Content $Lock -Raw) -match 'busy')) { L "Lua/zedqa.lock says busy: not starting"; exit 2 }
$srvStatus = Child "server_status" @("$Qa\mp_server.ps1", "-Status") 60
if ($srvStatus -match 'running, PID') { L "a test server is already running and this run did not start it: not starting"; exit 2 }

# copies before anything changes
$ini = "$Cache\Server\zedqa.ini"; $sbx = "$Cache\Server\zedqa_SandboxVars.lua"; $MO = "$Lua\ModOptions.ini"; $ChatPlace = "$Lua\ZeD_chatwin.txt"
foreach ($pair in @(@("$Cache\db\zedqa.db", "zedqa.db"), @($ini, "zedqa.ini"), @($sbx, "zedqa_SandboxVars.lua"), @($MO, "ModOptions.ini"), @($ChatPlace, "ZeD_chatwin.txt"))) {
    $k = Join-Path $Keep $pair[1]
    if (Test-Path $k) { Remove-Item $k -Force }
    if (Test-Path $pair[0]) { Copy-Item $pair[0] $k -Force }
}
L "copies of the server's db, ini and sandbox file, ModOptions and the chat window's place kept in $Keep"

$serverOurs = $false; $adminPid = 0; $script:Started = @(); $joined = @()
try {
    $srvOut = "$Tmp\server_start.out"
    $sp = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\mp_server.ps1", "-Start", "-Mods", "ZeD_UI;ZeDQAShim", "-Set", "DoLuaChecksum=false;DisplayUserName=true;ShowFirstAndLastName=false;MouseOverToSeeDisplayName=false;HidePlayersBehindYou=false" -RedirectStandardOutput $srvOut -NoNewWindow -PassThru; $sp.WaitForExit()
    $st = ConText $srvOut
    L "server start exit $($sp.ExitCode): $(($st -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 2) -join ' | ')"
    if ($st -match 'started the server') { $serverOurs = $true }
    if ($st -notmatch 'ready') { throw "the server did not get ready" }

    # the admin in, staged, kept open
    $rp = Start-Process pwsh -ArgumentList "-NoProfile -File $Qa\zedqa_run.ps1 -Mp -Mode windowed -Width 3840 -Height 2160 -KeepOpen -Manifest $Qa\gallery_v1_mp.txt -Report $Root\ZeDUI\qa\regression\$(Get-Date -Format yyyy-MM-dd_HHmm)_g1mp_admin.md" -RedirectStandardOutput "$Tmp\admin_run.out" -RedirectStandardError "$Tmp\admin_run.err" -NoNewWindow -PassThru
    if (-not $rp.WaitForExit(1200 * 1000)) { L "the admin's runner did not finish in 20 minutes" }
    L "admin run exit $($rp.ExitCode): $(((ConText "$Tmp\admin_run.out") -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 2) -join ' | ')"
    $adminPid = (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1).Id   # (the only copy so far: the guests start after, and none ran before this run)
    if (-not $adminPid) { throw "the admin client is not running" }
    L "admin PID $adminPid"
    $env:ZEDQA_FRONT_PID = "$adminPid"   # (pzfront.ps1 brings THIS window forward, never a guest's: a guest in front iconified the admin and its picture came out black, Nov 12)
    $con = ConText "$Z\console.txt"
    if ($con -notmatch 'ZEDQA g1mst PASS map loaded') { L "the stage did not report the map loaded: $((([regex]::Matches($con, 'ZEDQA g1mst [^\r\n]*') | Select-Object -Last 3) | ForEach-Object { $_.Value }) -join ' / ')" }
    Set-Content $Lock "busy" -NoNewline

    # the other players
    for ($i = 0; $i -lt $Guests.Count; $i++) { try { if (Guest-Start $i) { $joined += $Guests[$i] } } catch { L "[$($Guests[$i])] $($_.Exception.Message)" } }
    L "joined: $($joined -join ', ')"
    if ($joined.Count -eq 0) { throw "no other player reached the game" }
    Set-Content "$Lua\zedqa_cang_guests.txt" ($joined -join "`n") -NoNewline   # (read by gallery_cinema_angel_gather.lua and gallery_v1_mp_shot.lua)
    $jobs = @()
    for ($i = 0; $i -lt $Guests.Count; $i++) {
        if ($joined -notcontains $Guests[$i]) { continue }
        $jobs += Start-Job -ScriptBlock { param($q, $slot) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Slot $slot -Run "$q\gallery_v1_mp_guest.lua" -Tag g1mpg -TimeoutSec 300 } -ArgumentList $Qa, (Slot $i)
    }
    Start-Sleep 10
    [void](Main "gallery_cinema_angel_gather.lua" "cangg" 60)
    foreach ($j in $jobs) { Receive-Job -Job $j -Wait -AutoRemoveJob | ForEach-Object { L "guest> $_" } }

    # the picture
    L "front: $((& "$Qa\pzfront.ps1" -ProcId $adminPid) -join ' ')"
    [void](Main "gallery_v1_mp_shot.lua" "g1mps" 600)
    L "g1_75_server.png: $(Test-Path "$Z\Screenshots\g1_75_server.png") | g1_75_chat.png: $(Test-Path "$Z\Screenshots\g1_75_chat.png")"
    [void](Main "gallery_reload.lua" "rel" 60)
}
catch { L "STOPPED: $($_.Exception.Message)" }
finally {
    $env:ZEDQA_FRONT_PID = $null
    # the other players this run started (mp_client2 quits each through its bridge, then by the PID it saved)
    foreach ($i in $script:Started) { [void](Child "stop_$($Guests[$i])" @("$Qa\mp_client2.ps1", "-Stop", "-Slot", "$(Slot $i)") 120) }
    # the admin: quit through the bridge; only the copy this run started, by its PID, if it will not go
    if ($adminPid -and (Get-Process -Id $adminPid -ErrorAction SilentlyContinue)) {
        Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
        $c = "$Lua\zedqa.counter"; [long]$n = 9999
        if (Test-Path $c) { $n = [long](Get-Content $c -Raw).Trim() }
        $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
        for ($k = 0; $k -lt 40 -and (Get-Process -Id $adminPid -ErrorAction SilentlyContinue); $k++) { Start-Sleep 2 }
        $ap = Get-Process -Id $adminPid -ErrorAction SilentlyContinue
        if ($ap -and $ap.ProcessName -eq "ProjectZomboid64") { L "the admin did not quit; stopping PID $adminPid (started by this run)"; Stop-Process -Id $adminPid -Force }
        [void](Child "restorewin" @("$Qa\pzrestorewin.ps1") 60)
    }
    # the server, only when this run started it, by the PID mp_server.ps1 saved
    if ($serverOurs) {
        $stopOut = "$Tmp\server_stop.out"
        Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\mp_server.ps1", "-Stop" -RedirectStandardOutput $stopOut -NoNewWindow -PassThru | ForEach-Object { $_.WaitForExit() }
        L "server stop: $((Get-Content $stopOut -Tail 1) -join ' ')"
        Start-Sleep 3
    }
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
    if (Test-Path "$Keep\zedqa.ini") { Copy-Item "$Keep\zedqa.ini" $ini -Force }
    if (Test-Path "$Keep\zedqa_SandboxVars.lua") { Copy-Item "$Keep\zedqa_SandboxVars.lua" $sbx -Force }
    if (Test-Path "$Keep\ModOptions.ini") { Copy-Item "$Keep\ModOptions.ini" $MO -Force }
    if (Test-Path "$Keep\ZeD_chatwin.txt") { Copy-Item "$Keep\ZeD_chatwin.txt" $ChatPlace -Force } elseif (Test-Path $ChatPlace) { Remove-Item $ChatPlace -Force }
    Remove-Item "$Lua\zedqa_cang_guests.txt" -ErrorAction SilentlyContinue
    Set-Content $Lock "free" -NoNewline
    L "put back: server db, ini, sandbox file, ModOptions, chat window place; lock free; game still running: $([bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue))"
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
