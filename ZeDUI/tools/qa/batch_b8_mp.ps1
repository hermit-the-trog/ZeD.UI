#Requires -Version 7.0
<#
    ZeDUI/tools/qa/batch_b8_mp.ps1  (Nov 7 2026, QA; beta 8): the scripted multiplayer checks, unattended, on the local test server kit. Modelled on batch_two_b7.ps1.
    Two real players: the admin (zedqa_run.ps1 -Mp) and bob (mp_client2.ps1, profile zedqa_p2). The scripts are zedqa_b8_mp_*.lua, listed with
    their tags and time limits in b8_mp_two.txt; the results go to ZeDUI/qa/two_players_b8.txt (PASS / FAIL / MANUAL lines, then a count) and
    the pictures to Screenshots\b8_mp\<phase>. THIS FILE WAS NOT RUN when it was written (the game must not be launched by the build).
      Phases, in order: setup trade medic claims tools leftovers mail kick desk bans mute rules helper cleanup
      pwsh -File ZeDUI/tools/qa/batch_b8_mp.ps1                    everything (about an hour; the helper session needs Python)
      pwsh -File ZeDUI/tools/qa/batch_b8_mp.ps1 -Only setup,trade   just those phases (setup always runs first; later phases lean on bob's state:
                                                                   kick leaves him at his desk, bans/mute/rules want him there)
      -Slow       also the unanswered-rules Kick (the server owes it after five minutes; about seven more minutes)
      -NoHelper   skip the second session (server restarted with RCON, zed_rcon_helper.py beside it)
      -Width/-Height  the admin's window (default 1280x800, the Deck). 4K 1.75x pictures are a second run with -Width 3840 -Height 2160.
    What it changes and puts back: the server's database, settings and sandbox file and the admin's ModOptions are copied first and copied back;
    bans, mutes, claims, zones and rules are lifted by the scripts and again by zedqa_b8_mp_cleanup.lua. Only bob is ever kicked or banned, by
    name. Both clients and the server are closed at the end, by the PIDs the kit saved. Never ban by IP: both clients are 127.0.0.1.
#>
param([string[]]$Only = @(), [switch]$Slow, [switch]$NoHelper, [int]$Width = 1280, [int]$Height = 800)
$Qa = $PSScriptRoot
$Root = "$env:USERPROFILE\Zomboid\mods\ZeD-UI"
$Z = "$env:USERPROFILE\Zomboid"
$Lua = "$Z\Lua"
$Lock = "$Lua\zedqa.lock"
$ConA = "$Z\console.txt"
$ConB = "$Z\zedqa_p2\console.txt"
$Cache = "$Z\zedqa_mp"
$Log = "$Root\ZeDUI\qa\two_players_b8.txt"
$Shots = "$Z\Screenshots"
$ShotOut = "$Shots\b8_mp"
$env:ZEDQA_NOSTEAM = "1"

function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Log; Write-Host $s }
function Want($n) { return ($Only.Count -eq 0) -or ($Only -contains $n) }
function ConText($p) { try { (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) -replace "`0", "" } catch { "" } }
function ConLen($p) { return (ConText $p).Length }
function Count-Matches($p, $rx) { return ([regex]::Matches((ConText $p), $rx)).Count }
function Entry($file) {
    foreach ($l in (Get-Content "$Qa\b8_mp_two.txt")) {
        $t = ($l -replace '\s+#.*$', '').Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $p = @($t -split '\s*\|\s*')
        if ($p[0] -eq $file) { return @{ File = $p[0]; Tag = $p[1]; Timeout = [int](($p[2] -replace 'timeout\s*=\s*', '')) } }
    }
    throw "no line for $file in b8_mp_two.txt"
}
function Main($f) { $e = Entry $f; Note "-- admin runs $f"; & "$Qa\mp_client2.ps1" -Main -Run "$Qa\$($e.File)" -Tag $e.Tag -TimeoutSec $e.Timeout | ForEach-Object { Note $_ } }
function Bob($f) { $e = Entry $f; Note "-- bob runs $f"; & "$Qa\mp_client2.ps1" -Run "$Qa\$($e.File)" -Tag $e.Tag -TimeoutSec $e.Timeout | ForEach-Object { Note $_ } }
function JobMain($f) {
    $e = Entry $f; Note "-- admin starts $f in the background"
    Start-Job -ScriptBlock { param($q, $file, $tag, $sec) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Main -Run "$q\$file" -Tag $tag -TimeoutSec $sec } -ArgumentList $Qa, $e.File, $e.Tag, $e.Timeout
}
function JobBob($f) {
    $e = Entry $f; Note "-- bob starts $f in the background"
    Start-Job -ScriptBlock { param($q, $file, $tag, $sec) $env:ZEDQA_NOSTEAM = "1"; & "$q\mp_client2.ps1" -Run "$q\$file" -Tag $tag -TimeoutSec $sec } -ArgumentList $Qa, $e.File, $e.Tag, $e.Timeout
}
function Collect($job) { Receive-Job -Job $job -Wait | ForEach-Object { Note $_ }; Remove-Job $job -Force }
function WaitMarker($path, $from, $pattern, $sec) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $sec) {
        $t = ConText $path
        $s = if ($t.Length -ge $from) { $t.Substring($from) } else { $t }
        if ($s -match $pattern) { return $true }
        Start-Sleep 3
    }
    Note "marker not seen in $sec s: $pattern"
    return $false
}
function Shots($name) {
    New-Item -ItemType Directory -Force "$ShotOut\$name" | Out-Null
    Get-ChildItem $Shots -Filter "zqa_b8_*.png" -ErrorAction SilentlyContinue | Move-Item -Destination "$ShotOut\$name" -Force
}
function BobAlive { $f = "$Z\zedqa_p2\client.pid"; if (-not (Test-Path $f)) { return $false }; return [bool](Get-Process -Id ([int](Get-Content $f -Raw).Trim()) -ErrorAction SilentlyContinue) }
# bob in the game (after a join): the bridge arms in game, "click to start" is passed. $from: bob's console length before the join call
function BobIn($from) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt 300) {
        if (-not (BobAlive)) { Note "bob's client closed"; return $false }
        $t = ConText $ConB
        $s = if ($t.Length -ge $from) { $t.Substring($from) } else { $t }
        if ($s -match 'bridge armed \(in game') { Note "bob in game"; Start-Sleep 6; return $true }
        if ($s -match 'game loading took') { & "$Qa\mp_client2.ps1" -Click | Out-Null }
        Start-Sleep 8
    }
    Note "bob never reached the game"
    return $false
}
function MenuCount { return (Count-Matches $ConB 'bridge armed \(main menu') }
function WaitMenu($before) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt 240) {
        if ((MenuCount) -gt $before) { Start-Sleep 5; return $true }
        Start-Sleep 3
    }
    Note "bob never came back to the main menu"
    return $false
}
function BobRejoin { $from = ConLen $ConB; Bob "zedqa_b8_mp_bob_rejoin.lua"; return (BobIn $from) }
function Admin-In {
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_pin_only.txt" -Mp -Mode windowed -Width $Width -Height $Height -KeepOpen -Report "$Root\ZeDUI\qa\regression\2026-11-07_b8_mp_start.md" 2>&1
    Note "admin in: $(($o | Select-Object -Last 1) -join ' ')"
}
function Bob-Start {
    $P2Shim = "$Z\zedqa_p2\mods\ZeDQAShim"; if (Test-Path $P2Shim) { Remove-Item $P2Shim -Recurse -Force }
    if (Test-Path "$Z\mods\ZeDQAShim") { New-Item -ItemType Directory -Force "$Z\zedqa_p2\mods" | Out-Null; Copy-Item "$Z\mods\ZeDQAShim" $P2Shim -Recurse }
    & "$Qa\mp_client2.ps1" -Start | ForEach-Object { Note $_ }
    # the first arm is at the menu; a new account then goes back to the menu for its character (a second arm), an old one straight in
    $t0 = Get-Date; $newchar = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 360) {
        if (-not (BobAlive)) { Note "bob's client closed while loading"; return $false }
        $t = ConText $ConB
        if ($t -match 'bridge armed \(in game') { Note "bob in game"; Start-Sleep 6; return $true }
        if ((MenuCount) -ge 2 -and -not $newchar) { $newchar = $true; Start-Sleep 6; Bob "mp_p2_newchar.lua" }
        if ($t -match 'game loading took') { & "$Qa\mp_client2.ps1" -Click | Out-Null }
        Start-Sleep 8
    }
    Note "bob never reached the game"
    return $false
}
function Quit-Admin {
    Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "$Lua\zedqa.counter"; [long]$n = 9999
    if (Test-Path $c) { $n = [long](Get-Content $c -Raw).Trim() }
    $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 30 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    & "$Qa\pzrestorewin.ps1" | Out-Null
}

# ------------------------------------------------------------------------------------------------
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
if ((Test-Path $Lock) -and ((Get-Content $Lock -Raw) -match 'busy')) { Write-Output "Lua/zedqa.lock says busy, stop"; exit 2 }
"== $(Get-Date -Format 'yyyy-MM-dd HH:mm') beta 8 multiplayer checks, two players, the admin at ${Width}x${Height}" | Set-Content $Log
New-Item -ItemType Directory -Force $ShotOut | Out-Null
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_b8"
New-Item -ItemType Directory -Force $Keep | Out-Null
if (Test-Path "$Cache\db\zedqa.db") { Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force }
if (Test-Path "$Cache\Server\zedqa.ini") { Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force }
$SbxFile = "$Cache\Server\zedqa_SandboxVars.lua"
if (Test-Path $SbxFile) { Copy-Item $SbxFile "$Keep\zedqa_SandboxVars.lua" -Force }
$MO = "$Lua\ModOptions.ini"; if (Test-Path $MO) { Copy-Item $MO "$Keep\ModOptions.ini" -Force }
$helperProc = $null
try {
    # ---- setup
    & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "PlayerSafehouse=true;AdminSafehouse=true;DoLuaChecksum=false;SafehouseAllowNonResidential=true;FactionDaySurvivedToCreate=0" | ForEach-Object { if ($_ -match "^set |ready|already") { Note $_ } }
    Note "server up"
    Admin-In
    Set-Content $Lock "busy" -NoNewline
    $bobOk = Bob-Start
    if (-not $bobOk) { throw "bob did not reach the game; the run stops" }
    Main "zedqa_b8_mp_stage.lua"
    Shots "setup"

    if (Want "trade") {
        $j = JobBob "zedqa_b8_mp_bob_trade.lua"; Start-Sleep 8
        Main "zedqa_b8_mp_trade.lua"; Collect $j; Shots "trade"
    }
    if (Want "medic") {
        $j = JobBob "zedqa_b8_mp_bob_medic.lua"; Start-Sleep 8
        Main "zedqa_b8_mp_medic.lua"; Collect $j; Shots "medic"
    }
    if (Want "claims") {
        $j = JobBob "zedqa_b8_mp_bob_claims.lua"; Start-Sleep 8
        Main "zedqa_b8_mp_claims.lua"; Collect $j; Shots "claims"
        Main "zedqa_b8_mp_stage.lua"      # bob and the admin together again for what follows
    }
    if (Want "tools") { Main "zedqa_b8_mp_admin_tools.lua"; Shots "tools" }
    if (Want "leftovers") { Main "zedqa_b8_mp_leftovers.lua"; Shots "leftovers" }
    if (Want "mail") {
        $j = JobBob "zedqa_b8_mp_bob_mail.lua"; Start-Sleep 8
        Main "zedqa_b8_mp_mail.lua"; Collect $j; Shots "mail"
    }

    # ---- the kick (C17 1) and the desk
    if (Want "kick") {
        $m0 = MenuCount
        $j = JobBob "zedqa_b8_mp_bob_leave_kick.lua"; Start-Sleep 5
        Main "zedqa_b8_mp_kick.lua"; Collect $j
        [void](WaitMenu $m0)
        Shots "kick"
    }
    # ---- bans: bob is rejoined, banned for an hour through ZeD (tries to come back), unbanned through ZeD, rejoined, banned again and the game's own unban typed
    if (Want "bans") {
        if (-not (BobRejoin)) { Note "bob did not rejoin; bans skipped" } else {
            $a = ConLen $ConA; $m0 = MenuCount
            $jA = JobMain "zedqa_b8_mp_bans.lua"; Start-Sleep 5
            $jL = JobBob "zedqa_b8_mp_bob_leave_ban.lua"; Collect $jL
            [void](WaitMenu $m0)
            # bob tries to come back while the ban stands
            $o = ConLen $ConB
            Bob "zedqa_b8_mp_bob_rejoin.lua"
            Start-Sleep 40
            $tail = (ConText $ConB); if ($tail.Length -gt $o) { $tail = $tail.Substring($o) }
            $lines = @(($tail -split "`r?`n") | Where-Object { $_ -match 'ban|refus|denied|fail|disconnect|kick' } | Select-Object -Last 8)
            Note "bob's console after the join attempt while banned: $($lines -join ' / ')"
            $inGame = $tail -match 'bridge armed \(in game'
            Note "bob back in the game while banned (must be False): $inGame"
            if (WaitMarker $ConA $a 'ZEDQA b8bn (PASS|FAIL) 2: the game''s ban was lifted' 420) {
                $m0 = MenuCount
                if (BobRejoin) {
                    $jL2 = JobBob "zedqa_b8_mp_bob_leave_ban.lua"
                    Collect $jA
                    Collect $jL2
                    [void](WaitMenu $m0)
                } else { Collect $jA }
            } else { Collect $jA }
            Shots "bans"
        }
    }

    # ---- the desk at bob's main menu (he is off the server after the bans): notes, Documents, a letter put in his Outbox for the next join
    if (Want "desk") {
        Bob "zedqa_b8_mp_bob_desk.lua"
        Shots "desk"
    }

    # ---- the offline mute, the offline letter, the join rules with a fresh join, and the voice ban owed on the second connection
    if (Want "mute") {
        Main "zedqa_b8_mp_mute_set.lua"
    }
    if (Want "rules") {
        Main "zedqa_b8_mp_mail_offline_send.lua"
        $a = ConLen $ConA
        $jR = JobMain "zedqa_b8_mp_rules_gate.lua"
        [void](WaitMarker $ConA $a 'ZEDQA b8ru RULES SET' 90)
        if (BobRejoin) {
            Bob "zedqa_b8_mp_bob_join_gate.lua"
            Bob "zedqa_b8_mp_bob_mail_offline.lua"
        }
        Collect $jR
        Main "zedqa_b8_mp_mail_offline_read.lua"
        Shots "rules"
    }
    if (Want "mute") {
        $a = ConLen $ConA; $m0 = MenuCount
        $jM = JobMain "zedqa_b8_mp_mute_after.lua"
        if (WaitMarker $ConA $a 'ZEDQA b8mua KICKING BOB' 120) {
            $jL = JobBob "zedqa_b8_mp_bob_leave_kick.lua"; Collect $jL
            [void](WaitMenu $m0)
            if (WaitMarker $ConA $a 'ZEDQA b8mua BOB MAY JOIN AGAIN' 120) { [void](BobRejoin) }
        }
        Collect $jM
        Shots "mute"
    }
    if ((Want "rules") -and $Slow) {
        # bob must be off: kick him, then the rules go on, he joins fresh and says nothing
        $m0 = MenuCount
        $j = JobBob "zedqa_b8_mp_bob_leave_kick.lua"; Start-Sleep 5
        Main "zedqa_b8_mp_kick.lua"; Collect $j
        [void](WaitMenu $m0)
        $a = ConLen $ConA; $m0 = MenuCount
        $jR = JobMain "zedqa_b8_mp_rules_kick.lua"
        [void](WaitMarker $ConA $a 'ZEDQA b8rk RULES SET' 90)
        if (BobRejoin) {
            Bob "zedqa_b8_mp_bob_join_silent.lua"
            $jL = JobBob "zedqa_b8_mp_bob_leave_kick.lua"; Collect $jL
        }
        Collect $jR
        Shots "rules_kick"
    }
    Note "session 1 done"
}
catch { Note "STOPPED: $($_.Exception.Message)" }
finally {
    # the safety net: whatever a stopped script left on the server goes back (needs the admin client; times out harmlessly without it)
    if (Test-Path $Lock) { try { Main "zedqa_b8_mp_cleanup.lua" } catch { Note "cleanup: $($_.Exception.Message)" } }
    Shots "last"
}

# ---- the host helper session: the server restarted with RCON on, the helper beside it
$py = $null
foreach ($c in @("$env:USERPROFILE\Documents\ComfyUI\.venv\Scripts\python.exe")) { if (Test-Path $c) { $py = $c } }
if (-not $py) { $g = Get-Command py -ErrorAction SilentlyContinue; if ($g) { $py = $g.Source } }
if ((Want "helper") -and -not $NoHelper) {
    if (-not $py) { Note "helper session skipped: no Python found (py, or the ComfyUI venv)" }
    else {
        try {
            Note "== helper session"
            & "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
            Quit-Admin
            & "$Qa\mp_server.ps1" -Stop | Out-Null
            Start-Sleep 5
            # RCON in the settings (a random password, never printed), the sandbox option Host Helper on
            $ini = "$Cache\Server\zedqa.ini"
            $pw = -join ((48..57) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
            $lines = @(Get-Content $ini | Where-Object { $_ -notmatch '^(RCONPort|RCONPassword)=' })
            $lines += "RCONPort=27015"; $lines += "RCONPassword=$pw"
            Set-Content $ini $lines -Encoding ascii
            $okSbx = $false
            if (Test-Path $SbxFile) {
                $s = Get-Content $SbxFile -Raw
                if ($s -match 'HostHelper\s*=\s*\w+') { $s = $s -replace 'HostHelper\s*=\s*\w+', 'HostHelper = true'; $okSbx = $true }
                elseif ($s -match '(?m)^(\s*)ZeD\s*=\s*\{') { $s = $s -replace '(?m)^(\s*)ZeD\s*=\s*\{', "`$1ZeD = {`r`n`$1    HostHelper = true,"; $okSbx = $true }
                if ($okSbx) { Set-Content $SbxFile $s -NoNewline -Encoding ascii }
            }
            if (-not $okSbx) { Note "helper session skipped: the server's sandbox file has no ZeD block to hold HostHelper (start the server once with ZeD, or set Host Helper (RCON) in its sandbox options)" }
            else {
                & "$Qa\mp_server.ps1" -Start -Mods "ZeD_UI;ZeDQAShim" -Set "DoLuaChecksum=false" | ForEach-Object { if ($_ -match "^set |ready|already") { Note $_ } }
                $hLog = "$Cache\helper-stdout.txt"; $hErr = "$Cache\helper-stderr.txt"
                Remove-Item $hLog, $hErr -ErrorAction SilentlyContinue
                $helperProc = Start-Process $py -ArgumentList @("$Root\ZeDUI\server_helper\zed_rcon_helper.py", "--zomboid", $Cache, "--server", "zedqa") -RedirectStandardOutput $hLog -RedirectStandardError $hErr -WindowStyle Hidden -PassThru
                Note "helper started, PID $($helperProc.Id)"
                $ans = "$Cache\Lua\ZeD_helper\answers.txt"
                $t0 = Get-Date; $fresh = $false
                while (((Get-Date) - $t0).TotalSeconds -lt 90) {
                    if ($helperProc.HasExited) { Note "the helper exited with code $($helperProc.ExitCode)"; break }
                    if ((Test-Path $ans) -and ((Get-Date) - (Get-Item $ans).LastWriteTime).TotalSeconds -lt 20) { $fresh = $true; break }
                    Start-Sleep 3
                }
                Note "E23: the helper's answers.txt is fresh (the helper reached the console and logged in): $fresh"
                Note "E24: RCON listening on 27015: $([bool](Get-NetTCPConnection -LocalPort 27015 -State Listen -ErrorAction SilentlyContinue))  (the flag -Drconlo=true cannot be added by this kit's server launcher: manual)"
                Set-Content $Lock "free" -NoNewline
                Admin-In
                Set-Content $Lock "busy" -NoNewline
                if (-not (Bob-Start)) { throw "bob did not reach the game in the helper session" }
                Main "zedqa_b8_mp_stage.lua"
                $a = ConLen $ConA; $m0 = MenuCount
                $jH = JobMain "zedqa_b8_mp_helper.lua"; Start-Sleep 5
                $jL = JobBob "zedqa_b8_mp_bob_leave_ban.lua"; Collect $jL
                [void](WaitMenu $m0)
                if (WaitMarker $ConA $a 'ZEDQA b8hp BOB MAY JOIN' 300) { [void](BobRejoin) }
                Collect $jH
                Note "E22: the queue file exists in the server's own Lua folder: $(Test-Path "$Cache\Lua\ZeD_helper\queue.txt")"
                if (Test-Path $hLog) { foreach ($l in (Get-Content $hLog -Tail 40)) { Note "helper> $l" } }
                if (Test-Path $hErr) { foreach ($l in (Get-Content $hErr -Tail 10)) { Note "helper!> $l" } }
                $hl = if (Test-Path $hLog) { Get-Content $hLog -Raw } else { "" }
                Note "E23: the helper made banuser: $($hl -match 'banuser'), unbanuser: $($hl -match 'unbanuser'), voiceban: $($hl -match 'voiceban'), kickuser: $($hl -match 'kickuser')"
                try { Main "zedqa_b8_mp_cleanup.lua" } catch { Note "cleanup: $($_.Exception.Message)" }
                Shots "helper"
            }
        }
        catch { Note "STOPPED in the helper session: $($_.Exception.Message)" }
        finally {
            if ($helperProc -and -not $helperProc.HasExited) { Stop-Process -Id $helperProc.Id -Force; Note "helper stopped" }
        }
    }
}

# ---- close everything, put back
& "$Qa\mp_client2.ps1" -Stop | ForEach-Object { Note $_ }
Quit-Admin
& "$Qa\mp_server.ps1" -Stop | Out-Null
Start-Sleep 3
if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force }
if (Test-Path "$Keep\zedqa.ini") { Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force }
if (Test-Path "$Keep\zedqa_SandboxVars.lua") { Copy-Item "$Keep\zedqa_SandboxVars.lua" $SbxFile -Force }
if (Test-Path "$Keep\ModOptions.ini") { Copy-Item "$Keep\ModOptions.ini" $MO -Force }
Set-Content $Lock "free" -NoNewline
Note "closed; the server's database, settings and sandbox file and the admin's mod options are put back"

# ---- the count
$all = Get-Content $Log
$pass = @($all | Where-Object { $_ -match 'ZEDQA \w+ PASS ' }).Count
$fail = @($all | Where-Object { $_ -match 'ZEDQA \w+ FAIL ' })
$man = @($all | Where-Object { $_ -match 'ZEDQA \w+ MANUAL ' }).Count
Note "TOTAL: $pass PASS, $($fail.Count) FAIL, $man MANUAL items printed"
foreach ($f in $fail) { Note "FAILED: $f" }
Write-Output "b8 mp: $pass pass, $($fail.Count) fail, $man manual; $Log"
