# Launch PZ in a 1920x1080 WINDOW for QA (director, Oct 14 2026) and load the
# latest save (the QA save) through the bridge's autoload flag, then click the
# window's centre to pass "click to start". Restore the fullscreen options
# with pzrestorewin.ps1 after the game has closed.
$S = $PSScriptRoot
$opt = "C:\Users\danie\Zomboid\options.ini"
$bak = Join-Path $S "options.ini.fullscreen.bak"
if (-not (Test-Path $bak)) { Copy-Item $opt $bak }
$t = Get-Content $opt
$t = $t -replace '^fullScreen=.*', 'fullScreen=false' -replace '^width=.*', 'width=1920' -replace '^height=.*', 'height=1080'
Set-Content -Path $opt -Value $t
Set-Content -Path "C:\Users\danie\Zomboid\Lua\zedqa.autoload" -Value "1" -NoNewline
$dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $dir
$log = "C:\Users\danie\Zomboid\console.txt"
Start-Sleep -Seconds 10
$loaded = $false
for ($i = 0; $i -lt 150; $i++) {
  Start-Sleep -Seconds 2
  $c = ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "")
  if ($c -match "game loading took") { $loaded = $true; break }
}
if (-not $loaded) { "never finished loading"; exit 1 }
Start-Sleep -Seconds 4
Add-Type @"
using System; using System.Runtime.InteropServices;
public class PZW {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
}
"@
[void][PZW]::SetProcessDPIAware()
& "$S\pzfront.ps1" | Out-Null
$h = (Get-Process ProjectZomboid64 | Select-Object -First 1).MainWindowHandle
$r = New-Object PZW+RECT; [void][PZW]::GetClientRect($h, [ref]$r)
$pt = New-Object PZW+POINT; $pt.X = [int](($r.R - $r.L) / 2); $pt.Y = [int](($r.B - $r.T) / 2)
[void][PZW]::ClientToScreen($h, [ref]$pt)
[void][PZW]::SetCursorPos($pt.X, $pt.Y); Start-Sleep -Milliseconds 400
[void][PZW]::SetCursorPos($pt.X + 2, $pt.Y + 2); Start-Sleep -Milliseconds 300
[PZW]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150
[PZW]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
"launched windowed; clicked client centre ($($pt.X),$($pt.Y)) of $($r.R - $r.L)x$($r.B - $r.T)"
