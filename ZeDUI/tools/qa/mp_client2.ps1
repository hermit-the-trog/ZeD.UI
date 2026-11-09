#Requires -Version 7.0
<#
    ZeDUI/tools/qa/mp_client2.ps1  (Nov 5 2026, QA; the director: yes, a second copy of the game): a second player on the local test server, a plain
    player with no admin rights. Its own folder, %USERPROFILE%\Zomboid\zedqa_p2, with its own options, saves and copy of ZeD; nothing in the director's
    Zomboid folder changes. Launched without -debug (a -debug client may only join as an admin), so its copy of QABridge.lua is patched to arm anyway.
    That copy is never staged; the repo's file is untouched.
      -Start        copy ZeD in, write the options, start the second client, wait for its bridge, join the server as -User
      -Run <file>   run a Lua file on it, wait for "ZEDQA <Tag> DONE", print its ZEDQA lines
      -Stop         close it (quit through the bridge, then by the PID this script saved)
#>
param([switch]$Start, [switch]$Stop, [switch]$Main, [switch]$Click, [string]$Run = "", [string]$Tag = "", [string]$User = "bob", [int]$TimeoutSec = 180)   # (-Main: -Run on the first client, the admin, in Zomboid\; -Click: "click to start" on the second client's window)
$ErrorActionPreference = "Stop"
$U = New-Object System.Text.UTF8Encoding($false)
$Z = "$($env:USERPROFILE)\Zomboid"
$P2 = "$Z\zedqa_p2"
$Lua = $(if ($Main) { "$Z\Lua" } else { "$P2\Lua" })
$Con = $(if ($Main) { "$Z\console.txt" } else { "$P2\console.txt" })
$PidFile = "$P2\client.pid"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
function W($p, $t) { [IO.File]::WriteAllText($p, $t, $U) }
function RT($p) { try { [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { "" } }
function L { (RT $Con) -replace "`0", "" }
function Bump { [long]$n = 9999; $t = RT "$Lua\zedqa.counter"; if ($t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }; $n++; W "$Lua\zedqa.counter" "$n"; W "$Lua\zedqa.go" "$n" }
function ClientUp { if (-not (Test-Path $PidFile)) { return $false }; [bool](Get-Process -Id ([int](RT $PidFile).Trim()) -ErrorAction SilentlyContinue) }

if ($Stop) {
    if (ClientUp) {
        W "$Lua\zedqa.lua" "getCore():quitToDesktop()"; Bump
        for ($i = 0; $i -lt 30 -and (ClientUp); $i++) { Start-Sleep 2 }
        if (ClientUp) { Stop-Process -Id ([int](RT $PidFile).Trim()) -Force }
    }
    Remove-Item $PidFile -ErrorAction SilentlyContinue
    "second client stopped"; exit 0
}
if ($Click) {
    Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class P2Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
}
"@
    [void][P2Win]::SetProcessDPIAware()
    $p = Get-Process -Id ([int](RT $PidFile).Trim())
    [void][P2Win]::SetForegroundWindow($p.MainWindowHandle); Start-Sleep -Milliseconds 400
    $r = New-Object P2Win+RECT; [void][P2Win]::GetWindowRect($p.MainWindowHandle, [ref]$r)
    [void][P2Win]::SetCursorPos([int](($r.L + $r.R) / 2), [int](($r.T + $r.B) / 2)); Start-Sleep -Milliseconds 400
    [P2Win]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150; [P2Win]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    "clicked"; exit 0
}
if ($Run) {
    $before = (L).Length
    Copy-Item -LiteralPath $Run "$Lua\zedqa.lua" -Force; Bump
    $t0 = Get-Date
    while (((L).Substring([Math]::Min($before, (L).Length))) -notmatch "ZEDQA $Tag DONE") {
        if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) { "TIMEOUT"; break }
        if (-not $Main -and -not (ClientUp)) { "the second client closed"; break }
        Start-Sleep 2
    }
    ((L).Substring([Math]::Min($before, (L).Length)) -split "\r?\n") | Where-Object { $_ -match "ZEDQA $Tag |attempted index|Exception thrown" } | ForEach-Object { $_ -replace '^.*?ZEDQA ', 'ZEDQA ' }
    exit 0
}
if (-not $Start) { "use -Start, -Run or -Stop"; exit 1 }
if (ClientUp) { "already running"; exit 0 }
New-Item -ItemType Directory -Force "$P2\mods\ZeD-UI", $Lua | Out-Null
foreach ($d in "42", "common") {
    if (Test-Path "$P2\mods\ZeD-UI\$d") { Remove-Item -Recurse -Force "$P2\mods\ZeD-UI\$d" }
    if (Test-Path "$Z\mods\ZeD-UI\$d") { Copy-Item -Recurse "$Z\mods\ZeD-UI\$d" "$P2\mods\ZeD-UI\$d" }
}
$b = "$P2\mods\ZeD-UI\42\media\lua\client\ZeD\QABridge.lua"
W $b ((RT $b).Replace("isDebugEnabled and isDebugEnabled()", "true"))
if (-not (Test-Path "$P2\options.ini")) { (RT "$Z\zedqa_mp\options.ini") | ForEach-Object { W "$P2\options.ini" $_ } }
W "$P2\mods\default.txt" "VERSION = 1,`r`n`r`nmods`r`n{`r`n    mod = ZeD_UI,`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
W "$Lua\zedqa_mp.txt" "user=$User`npassword=qa-second-player`n"
W "$Lua\zedqa.autoload" "0"
Remove-Item $Con -ErrorAction SilentlyContinue
$proc = Start-Process "$GameDir\ProjectZomboid64.exe" -ArgumentList "-nosteam -cachedir=$P2" -WorkingDirectory $GameDir -PassThru
W $PidFile "$($proc.Id)"
$t0 = Get-Date
while (-not ((L) -match '\[ZeD\.QA\] bridge armed \(main menu')) {
    if (-not (ClientUp)) { throw "the second client closed while loading" }
    if (((Get-Date) - $t0).TotalSeconds -gt 300) { throw "its bridge never armed" }
    Start-Sleep 2
}
Start-Sleep 4
W "$Lua\zedqa.lua" @"
local r = getFileReader("zedqa_mp.txt", false)
local u, p = "$User", nil
if r then local l = r:readLine(); while l do local k, v = l:match("^(%w+)=(.*)`$"); if k == "password" then p = v end; l = r:readLine() end; r:close() end
print("ZEDQA p2j connecting as " .. u)
ConnectToServer.instance:connect(MainScreen.instance, "", u, p, "127.0.0.1", "127.0.0.1", "16261", "", false, true, 1)
"@
Bump
"second client joining as $User"
