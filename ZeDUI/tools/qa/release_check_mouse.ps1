# ZeDUI/tools/qa/release_check_mouse.ps1  (Nov 2 2026, QA; punch list 70)
# The release check's real mouse. Watches C:\Users\you\Zomboid\Lua\zedqa_click.txt ("right x y" or "left x y",
# the game's pixels, turned into the desktop's through the game window's client corner); for each request brings the game to the front (pzfront.ps1), moves the desktop cursor there and
# presses the button, then writes "done" to zedqa_click_done.txt and deletes the request. Stops by itself after
# -MaxMinutes, or when the file zedqa_click_stop.txt appears. Started by release_check.ps1; never on its own while the
# director uses the machine.
param([int]$MaxMinutes = 15)
$ErrorActionPreference = "Stop"
$lua = "C:\Users\you\Zomboid\Lua"
$req = Join-Path $lua "zedqa_click.txt"
$done = Join-Path $lua "zedqa_click_done.txt"
$stop = Join-Path $lua "zedqa_click_stop.txt"
Add-Type -Namespace ZedQA -Name Mouse -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, System.UIntPtr extra);
[StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
[DllImport("user32.dll")] public static extern bool ClientToScreen(System.IntPtr hWnd, ref POINT p);
'@
[ZedQA.Mouse]::SetProcessDPIAware() | Out-Null
$front = Join-Path $PSScriptRoot "pzfront.ps1"
$until = (Get-Date).AddMinutes($MaxMinutes)
while ((Get-Date) -lt $until -and -not (Test-Path $stop)) {
    if (Test-Path $req) {
        $line = (Get-Content $req -Raw).Trim()
        Remove-Item $req -Force
        if ($line -match '^(right|left)\s+(\d+)\s+(\d+)$') {
            $btn, $x, $y = $Matches[1], [int]$Matches[2], [int]$Matches[3]
            if (Test-Path $front) { & $front | Out-Null }
            Start-Sleep -Milliseconds 300
            # the game's pixels are its window's client area: in a windowed game they start at the client's corner
            $pz = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
            if ($pz) {
                $pt = New-Object ZedQA.Mouse+POINT
                $pt.X = $x; $pt.Y = $y
                [ZedQA.Mouse]::ClientToScreen($pz.MainWindowHandle, [ref]$pt) | Out-Null
                $x, $y = $pt.X, $pt.Y
            }
            [ZedQA.Mouse]::SetCursorPos($x, $y) | Out-Null
            Start-Sleep -Milliseconds 250   # (the game reads the cursor every frame: let it see the move first)
            $down, $up = if ($btn -eq "right") { 0x8, 0x10 } else { 0x2, 0x4 }
            [ZedQA.Mouse]::mouse_event($down, 0, 0, 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 120   # (held past one 100 ms UI update)
            [ZedQA.Mouse]::mouse_event($up, 0, 0, 0, [UIntPtr]::Zero)
            Set-Content -Path $done -Value "done $btn $x $y" -NoNewline
            Write-Output "release_check_mouse: $btn-click at $x,$y"
        }
    }
    Start-Sleep -Milliseconds 200
}
if (Test-Path $stop) { Remove-Item $stop -Force }
