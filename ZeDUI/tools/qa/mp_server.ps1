<#
.SYNOPSIS
    ZeDUI/tools/qa/mp_server.ps1  (Nov 5 2026, QA): a local Project Zomboid dedicated server for multiplayer QA.
.DESCRIPTION
    Runs the server that ships with the game (zombie.network.GameServer, the same command as the game's own
    ProjectZomboidServer.bat) without Steam, in its own cache folder (C:\Users\danie\Zomboid\zedqa_mp): its world,
    its server settings and its own copy of ZeD (copied from the working mod, 42 + common + mod.info) live there, so
    nothing in the director's Zomboid folder changes. Listens on 127.0.0.1 port 16261 (UDP).
    The admin account is "zedqa"; its password is made once and kept in Zomboid\Lua\zedqa_mp.txt (never committed:
    the repo is public). The client joins as that admin (a -debug client may only join as an admin).
      -Start   copy ZeD in, write the server settings (first time), start the server, wait for it to be ready
      -Stop    stop the server this script started (by the PID it saved), never any other java process
      -Status  is it running
.EXAMPLE
    pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start
#>
param([switch]$Start, [switch]$Stop, [switch]$Status, [switch]$NoServerPart, [string]$Set = "",   # (-Set "A=b;C=d", Nov 6 2026: server options for this start, the caller puts the file back)
      # (-NoServerPart, Nov 6 2026: step 10 of the tickets, no server folder in the server's ZeD and the Lua checksum off)
    [ValidateSet("ZeD_UI", "ZeDQAShim", "ZeD_UI;ZeDQAShim")][string]$Mods = "ZeD_UI")   # (-Mods ZeDQAShim: the game's own windows, for the benchmark's comparison; -Mods "ZeD_UI;ZeDQAShim": ZeD plus the shim's ZeDQA.role, for mp_tickets.lua)
$ErrorActionPreference = "Stop"
$GameDir  = "E:\Project Zomboid\steamapps\common\ProjectZomboid"
$Cache    = "C:\Users\danie\Zomboid\zedqa_mp"
$ModSrc   = "C:\Users\danie\Zomboid\mods\ZeD-UI"
$LuaDir   = "C:\Users\danie\Zomboid\Lua"
$PwFile   = Join-Path $LuaDir "zedqa_mp.txt"
$PidFile  = Join-Path $Cache "server.pid"
$OutLog   = Join-Path $Cache "server-stdout.txt"
$Name     = "zedqa"

function Get-ServerProc {
    if (-not (Test-Path $PidFile)) { return $null }
    $id = [int](Get-Content $PidFile -Raw).Trim()
    $p = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -match '^java') { return $p }
    return $null
}

if ($Status) { $p = Get-ServerProc; if ($p) { "running, PID $($p.Id)" } else { "not running" }; exit 0 }

if ($Stop) {
    $p = Get-ServerProc
    if (-not $p) { "not running"; exit 0 }
    # (a QA world: no clean save needed)
    Stop-Process -Id $p.Id -Force
    Remove-Item $PidFile -Force
    "stopped PID $($p.Id)"
    exit 0
}

if (-not $Start) { "use -Start, -Stop or -Status"; exit 1 }
if (Get-ServerProc) { "already running, PID $((Get-ServerProc).Id)"; exit 0 }

New-Item -ItemType Directory -Force $Cache, (Join-Path $Cache "mods"), (Join-Path $Cache "Server") | Out-Null
# ZeD, fresh from the working copy
$dst = Join-Path $Cache "mods\ZeD-UI"
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item (Join-Path $ModSrc "42") (Join-Path $dst "42") -Recurse
Copy-Item (Join-Path $ModSrc "common") (Join-Path $dst "common") -Recurse
# the QA-only stand-in with the bridge and no ZeD (the comparison runs)
$shimDst = Join-Path $Cache "mods\ZeDQAShim"
$shimSrc = "C:\Users\danie\Zomboid\mods\ZeDQAShim"
if (Test-Path $shimDst) { Remove-Item $shimDst -Recurse -Force }
# (the shim's server file is kept in the repo; the shim on this machine takes it first, so the client's Lua checksum
# and the server's agree)
$roleSrc = Join-Path $ModSrc "ZeDUI\tools\qa\shim\42\media\lua\server\ZeDQAShim\QARole.lua"
if (Test-Path $roleSrc) {
    $roleDir = Join-Path $shimSrc "42\media\lua\server\ZeDQAShim"
    New-Item -ItemType Directory -Force $roleDir | Out-Null
    Copy-Item $roleSrc $roleDir -Force
}
Copy-Item $shimSrc $shimDst -Recurse
# the admin password (made once)
if (-not (Test-Path $PwFile)) {
    $pw = -join ((48..57) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
    Set-Content -Path $PwFile -Value "user=$Name`npassword=$pw" -Encoding ascii
}
$pw = ((Get-Content $PwFile) -match '^password=')[0].Substring(9)
# the server settings: written once; the server fills in every other option with its default
$ini = Join-Path $Cache "Server\$Name.ini"
if (-not (Test-Path $ini)) {
    Set-Content -Path $ini -Encoding ascii -Value @"
PublicName=ZeD QA
Public=false
Open=true
Password=
Mods=ZeD_UI
WorkshopItems=
Map=Muldraugh, KY
MaxPlayers=8
PauseEmpty=true
PVP=false
DefaultPort=16261
UDPPort=16262
"@
}
# the mod list for this start
(Get-Content $ini) -replace '^Mods=.*$', "Mods=$Mods" | Set-Content $ini -Encoding ascii
foreach ($kv in ($Set -split ";" | Where-Object { $_ })) {
    $k = ($kv -split "=")[0]
    (Get-Content $ini) -replace "^$k=.*$", $kv | Set-Content $ini -Encoding ascii
    "set $kv"
}
if ($NoServerPart) {
    Remove-Item (Join-Path $dst "42\media\lua\server\ZeD") -Recurse -Force
    (Get-Content $ini) -replace '^DoLuaChecksum=.*$', 'DoLuaChecksum=false' | Set-Content $ini -Encoding ascii
    "no server part, the Lua checksum off"
}
"mods: $Mods"
$args = @("--enable-native-access=ALL-UNNAMED", "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED", "-XX:+UseZGC",
    "-XX:-CreateCoredumpOnCrash", "-XX:-OmitStackTraceInFastThrow", "-Xmx3072m",
    "-Djava.library.path=./natives/;./natives/win64/;./", "-cp", "./;projectzomboid.jar", "zombie.network.GameServer",
    "-nosteam", "-cachedir=$Cache", "-servername", $Name, "-adminusername", $Name, "-adminpassword", $pw)
$p = Start-Process -FilePath (Join-Path $GameDir "jre64\bin\java.exe") -ArgumentList $args -WorkingDirectory $GameDir `
    -RedirectStandardOutput $OutLog -RedirectStandardError (Join-Path $Cache "server-stderr.txt") -WindowStyle Hidden -PassThru
Set-Content -Path $PidFile -Value $p.Id
"started the server, PID $($p.Id); waiting for it to be ready"
for ($i = 0; $i -lt 180; $i++) {
    Start-Sleep -Seconds 2
    if ($p.HasExited) { "the server exited (code $($p.ExitCode)); see $OutLog"; Get-Content $OutLog -Tail 30; exit 1 }
    $t = Get-Content $OutLog -Raw -ErrorAction SilentlyContinue
    if ($t -match 'SERVER STARTED') { "ready after $(2 * ($i + 1)) s"; exit 0 }
}
"not ready after 6 minutes; see $OutLog"
exit 1
