#Requires -Version 7.0
# QA b9 (Nov 8 2026): the host helper restores a banned moderator's role when a timed ban ends with no staff online.
# Server with RCON + Host Helper on, the helper (python), the admin client, a second client as b9_mod (a plain account), the role/ban
# script, then both clients leave and the ban runs out. Every step logs to b9_hr_run.log as it happens (stall_watch.ps1 watches it).
# Every child (server, helper, scripts) starts with Start-Process and its output in a file; nothing is piped (a server that is started
# in a pipeline keeps it open forever). ALWAYS puts back: Contents, the server's ini, sandbox file and db, ModOptions.
$env:ZEDQA_NOSTEAM = "1"
$Qa = $PSScriptRoot
$Z = "C:\Users\you\Zomboid"
$Cache = "$Z\zedqa_mp"
$Lua = "$Z\Lua"
$Lock = "$Lua\zedqa.lock"
$ConA = "$Z\console.txt"
$ConB = "$Z\zedqa_p2\console.txt"
$Log = "$Qa\b9_hr_run.log"
$Tmp = "$Qa\b9_hr_tmp"
$HelperLog = "$Qa\b9_hr_helper.log"
$Py = "C:\Users\you\Documents\ComfyUI\.venv\Scripts\python.exe"
$Ws = "C:\Users\you\Zomboid\Workshop\ZeD-UI"
$Keep = "$Z\zedqa_b9hr_keep"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
function ConText($p) { try { (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) -replace "`0", "" } catch { "" } }
New-Item -ItemType Directory -Force $Tmp, $Keep | Out-Null
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log

# a pwsh script as a child with its output in a file; waits for the child itself (never the processes it started)
function Child([string]$Name, [string[]]$ScriptArgs, [int]$TimeoutSec = 900) {
    $out = "$Tmp\$Name.out"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File") + $ScriptArgs) -RedirectStandardOutput $out -RedirectStandardError "$Tmp\$Name.err" -NoNewWindow -PassThru
    if (-not $p.WaitForExit($TimeoutSec * 1000)) { L "child $Name timed out after $TimeoutSec s (PID $($p.Id))"; try { Stop-Process -Id $p.Id -Force } catch {} }
    $t = ConText $out
    foreach ($l in ($t -split "`r?`n" | Where-Object { $_.Trim() })) { L "$Name> $l" }
    return $t
}
function Quit-Admin {
    Set-Content "$Lua\zedqa.lua" "getCore():quitToDesktop()" -NoNewline
    $c = "$Lua\zedqa.counter"; [long]$n = 9999
    if (Test-Path $c) { $n = [long](Get-Content $c -Raw).Trim() }
    $n++; Set-Content $c "$n" -NoNewline; Set-Content "$Lua\zedqa.go" "$n" -NoNewline
    for ($i = 0; $i -lt 30 -and (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
    [void](Child "restorewin" @("$Qa\pzrestorewin.ps1") 60)
}
function P2Pid { $f = "$Z\zedqa_p2\client.pid"; if (-not (Test-Path $f)) { return 0 }; [int](Get-Content $f -Raw).Trim() }
function P2Alive { $i = P2Pid; return ($i -gt 0 -and [bool](Get-Process -Id $i -ErrorAction SilentlyContinue)) }
function ReadRoles([string]$Tag) {
    Copy-Item "$Cache\db\zedqa.db" "$Tmp\read_$Tag.db" -Force
    $code = "import sqlite3`nc = sqlite3.connect(r'$Tmp\read_$Tag.db')`nfor r in c.execute(`"select w.username, w.role, r.name from whitelist w left join role r on r.id = w.role where w.username like 'b9%'`"): print('ROW', r)`n"
    Set-Content "$Tmp\readrole_$Tag.py" $code -Encoding ascii
    $o = & $Py -I "$Tmp\readrole_$Tag.py" 2>&1
    foreach ($l in $o) { L "db $Tag> $l" }
}

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class B9Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool repaint);
}
"@
[void][B9Win]::SetProcessDPIAware()
# the two windows side by side (the second client's "click to start" must land on its own window, not on the admin's on top of it)
function Place-Windows {
    $p2 = P2Pid
    foreach ($g in (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
        if ($g.MainWindowHandle -eq 0) { continue }
        $r = New-Object B9Win+RECT; [void][B9Win]::GetWindowRect($g.MainWindowHandle, [ref]$r)
        $w = $r.R - $r.L; $h = $r.B - $r.T
        if ($w -lt 300 -or $w -gt 3000) { continue }
        $x = $(if ($g.Id -eq $p2) { 1450 } else { 40 })
        [void][B9Win]::MoveWindow($g.MainWindowHandle, $x, 40, $w, $h, $true)
    }
}
function Shot([string]$Name) {
    try {
        Add-Type -AssemblyName System.Drawing, System.Windows.Forms
        $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
        $gr = [System.Drawing.Graphics]::FromImage($bmp); $gr.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
        $f = "$Tmp\$Name.png"; $bmp.Save($f, [System.Drawing.Imaging.ImageFormat]::Png); $gr.Dispose(); $bmp.Dispose(); L "screenshot $f"
    } catch { L "screenshot failed: $($_.Exception.Message)" }
}
$helperProc = $null; $adminUp = $false
$ini = "$Cache\Server\zedqa.ini"; $sbx = "$Cache\Server\zedqa_SandboxVars.lua"
try {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { L "ABORT: the game is running"; throw "game running" }
    if ((Get-Content $Lock -Raw) -notmatch 'free') { L "ABORT: lock is not free"; throw "lock busy" }
    if (Test-Path "$Ws\Contents") { Rename-Item "$Ws\Contents" "Contents.hold"; L "staged Contents held aside" }
    # copies before anything changes
    Copy-Item $ini "$Keep\zedqa.ini" -Force; Copy-Item $sbx "$Keep\zedqa_SandboxVars.lua" -Force
    Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force
    if (Test-Path "$Lua\ModOptions.ini") { Copy-Item "$Lua\ModOptions.ini" "$Keep\ModOptions.ini" -Force }
    L "copies of the ini, sandbox file, db and ModOptions kept in $Keep"

    # RCON (random password, never printed) and Host Helper on
    $pw = -join ((48..57) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    $s = Get-Content $sbx -Raw
    $s = $s -replace 'HostHelper\s*=\s*\w+', 'HostHelper = true'
    Set-Content $sbx $s -NoNewline -Encoding ascii
    L "sandbox HostHelper = true"
    Remove-Item "$Cache\Lua\ZeD_helper\queue.txt", "$Cache\Lua\ZeD_helper\answers.txt" -ErrorAction SilentlyContinue   # (before the server starts: it writes the queue only when its text changes)
    $t = Child "server_start" @("$Qa\mp_server.ps1", "-Start", "-Mods", "ZeD_UI;ZeDQAShim", "-Set", "RCONPort=27015;RCONPassword=$pw;DoLuaChecksum=false") 600
    if ($t -notmatch 'ready') { throw "server did not get ready" }
    L "RCON port listening: $([bool](Get-NetTCPConnection -LocalPort 27015 -State Listen -ErrorAction SilentlyContinue))"

    # the helper
    $helperProc = Start-Process $Py -ArgumentList @("-I", "$Qa\..\..\server_helper\zed_rcon_helper.py", "--zomboid", $Cache, "--server", "zedqa") -RedirectStandardOutput $HelperLog -RedirectStandardError "$Tmp\helper.err" -WindowStyle Hidden -PassThru
    L "helper started, PID $($helperProc.Id)"
    $ans = "$Cache\Lua\ZeD_helper\answers.txt"
    $t0 = Get-Date; $fresh = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 90) {
        if ($helperProc.HasExited) { L "the helper exited, code $($helperProc.ExitCode)"; break }
        if ((Test-Path $ans) -and ((Get-Date) - (Get-Item $ans).LastWriteTime).TotalSeconds -lt 20) { $fresh = $true; break }
        Start-Sleep 3
    }
    L "answers.txt fresh (helper logged in to RCON): $fresh"
    if (-not $fresh) { throw "helper never answered (see $HelperLog and $Tmp\helper.err)" }

    # the admin client in, left open
    Set-Content $Lock "free" -NoNewline
    $t = Child "admin_in" @("$Qa\zedqa_run.ps1", "-Manifest", "$Qa\mp_pin_only.txt", "-Mp", "-Mode", "windowed", "-Width", "1280", "-Height", "800", "-KeepOpen", "-Report", "$Qa\b9_hr_admin_in") 900
    Set-Content $Lock "busy" -NoNewline
    $adminUp = $true

    # b9_mod: the second client, a new account
    $P2Shim = "$Z\zedqa_p2\mods\ZeDQAShim"; if (Test-Path $P2Shim) { Remove-Item $P2Shim -Recurse -Force }
    if (Test-Path "$Z\mods\ZeDQAShim") { New-Item -ItemType Directory -Force "$Z\zedqa_p2\mods" | Out-Null; Copy-Item "$Z\mods\ZeDQAShim" $P2Shim -Recurse }
    $startJob = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\mp_client2.ps1", "-Start", "-User", "b9_mod" -RedirectStandardOutput "$Tmp\p2start.out" -RedirectStandardError "$Tmp\p2start.err" -NoNewWindow -PassThru
    $t0 = Get-Date; $newchar = $false; $inGame = $false; $shotDone = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 420) {
        Start-Sleep 8
        if (-not (P2Alive)) { L "b9_mod client not up (yet or closed)"; if (((Get-Date) - $t0).TotalSeconds -gt 120) { break } else { continue } }
        $t = ConText $ConB
        if ($t -match 'bridge armed \(in game') { L "b9_mod in game"; Start-Sleep 6; $inGame = $true; break }
        Place-Windows
        if (((Get-Date) - $t0).TotalSeconds -gt 100 -and -not $shotDone) { $shotDone = $true; Shot "p2_wait" }
        $menus = ([regex]::Matches($t, 'bridge armed \(main menu')).Count
        if ($menus -ge 2 -and -not $newchar) { $newchar = $true; Start-Sleep 6; [void](Child "p2_newchar" @("$Qa\mp_client2.ps1", "-Run", "$Qa\mp_p2_newchar.lua", "-Tag", "pnc", "-TimeoutSec", "120") 200) }
        if ($t -match 'game loading took') { [void](Child "p2_click" @("$Qa\mp_client2.ps1", "-Click") 30) }
    }
    if (-not $inGame) { throw "b9_mod never reached the game" }

    # the script on the admin client
    $tm = Get-Date
    $t = Child "admin_run" @("$Qa\mp_client2.ps1", "-Main", "-Run", "$Qa\zedqa_b9_helper_role.lua", "-Tag", "b9hr", "-TimeoutSec", "420") 500
    if ($t -notmatch 'ZEDQA b9hr DONE') { L "the admin script did not reach DONE" }
    if ($t -match 'FAIL') { L "the admin script has FAIL lines" }

    # nobody on: both clients quit
    L "quitting the admin client"
    Quit-Admin; $adminUp = $false
    L "quitting b9_mod client"
    [void](Child "p2_stop" @("$Qa\mp_client2.ps1", "-Stop") 120)
    Set-Content $Lock "free" -NoNewline
    L "no staff online; ban made about $($tm.ToString('HH:mm:ss')), waiting for its end (up to 7 min)"

    # wait for the helper's answers
    $seen = @{}
    $t0 = Get-Date; $okSet = $false
    while (((Get-Date) - $t0).TotalSeconds -lt 420) {
        Start-Sleep 5
        $h = ConText $HelperLog
        foreach ($l in ($h -split "`r?`n" | Where-Object { $_.Trim() })) { if (-not $seen.ContainsKey($l)) { $seen[$l] = 1; L "helper> $l" } }
        $qt = ConText "$Cache\Lua\ZeD_helper\queue.txt"
        foreach ($l in ($qt -split "`r?`n" | Where-Object { $_ -match 'SetRole' })) { $k = "Q:" + $l; if (-not $seen.ContainsKey($k)) { $seen[$k] = 1; L "queue.txt> $($l -replace "`t", ' | ')" } }
        if ($h -match 'ok SetRole b9_mod') { $okSet = $true; break }
    }
    L "ok SetRole seen in the helper log: $okSet"
    Start-Sleep 6
    L "answers.txt: $((ConText $ans) -replace "`r?`n", ' // ')"
    ReadRoles "after"
    # step 4a: a hand-added five-field SetRole line is refused
    $q = ConText "$Cache\Lua\ZeD_helper\queue.txt"
    $head = ($q -split "`r?`n")[0]
    if ($head -match '^ZEDQ 1 (\S+)$') {
        $ep = $Matches[1]
        [IO.File]::WriteAllText("$Cache\Lua\ZeD_helper\queue.txt", "ZEDQ 1 $ep`n9001`t1`tSetRole`tb9_mod`tadmin`nZEDQ end`n")
        L "hand-added the five-field line 9001 SetRole b9_mod admin to queue.txt"
        Start-Sleep 10
        $h = ConText $HelperLog
        foreach ($l in ($h -split "`r?`n" | Where-Object { $_.Trim() })) { if (-not $seen.ContainsKey($l)) { $seen[$l] = 1; L "helper> $l" } }
        L "answers.txt after: $((ConText $ans) -replace "`r?`n", ' // ')"
    } else { L "no queue head to build the hand-added line from: '$head'" }
    ReadRoles "end"
}
catch { L "STOPPED: $($_.Exception.Message)" }
finally {
    if ($adminUp) { try { Quit-Admin } catch { L "quit-admin: $($_.Exception.Message)" } }
    if (P2Alive) { try { [void](Child "p2_stop_final" @("$Qa\mp_client2.ps1", "-Stop") 120) } catch {} }
    if ($helperProc -and -not $helperProc.HasExited) {
        $cl = (Get-CimInstance Win32_Process -Filter "ProcessId=$($helperProc.Id)").CommandLine
        if ($cl -match 'zed_rcon_helper') { Stop-Process -Id $helperProc.Id -Force; L "helper stopped (PID $($helperProc.Id))" } else { L "helper PID command line did not match, left alone: $cl" }
    }
    [void](Child "server_stop" @("$Qa\mp_server.ps1", "-Stop") 60)
    Start-Sleep 4
    if (Test-Path "$Keep\zedqa.ini") { Copy-Item "$Keep\zedqa.ini" $ini -Force; L "ini put back" }
    if (Test-Path "$Keep\zedqa_SandboxVars.lua") { Copy-Item "$Keep\zedqa_SandboxVars.lua" $sbx -Force; L "sandbox file put back" }
    if (Test-Path "$Keep\zedqa.db") { Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force; L "db put back" }
    if (Test-Path "$Keep\ModOptions.ini") { Copy-Item "$Keep\ModOptions.ini" "$Lua\ModOptions.ini" -Force }
    Set-Content $Lock "free" -NoNewline
    if (Test-Path "$Ws\Contents.hold") { Rename-Item "$Ws\Contents.hold" "Contents"; L "staged Contents put back" }
    L "Contents exists: $(Test-Path "$Ws\Contents")"
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
