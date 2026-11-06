#Requires -Version 7.0
# ZeDUI/tools/qa/pz_startclick.ps1  (Nov 5 2026, QA): the "click to start" click for a run outside zedqa_run.ps1: the game's
# window to the front, a left click at the 4K screen's center, only if the game really is the front window.
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class PzClick {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
$proc = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "no game"; exit 1 }
[void][PzClick]::SetProcessDPIAware()
try { & (Join-Path $PSScriptRoot "pzfront.ps1") | Out-Null } catch { }
Start-Sleep -Milliseconds 300
$fg = [uint32]0
[void][PzClick]::GetWindowThreadProcessId([PzClick]::GetForegroundWindow(), [ref]$fg)
if ($fg -ne [uint32]$proc.Id) { "no click: process $fg is in front"; exit 1 }
[void][PzClick]::SetCursorPos(1920, 1080); Start-Sleep -Milliseconds 400
[void][PzClick]::SetCursorPos(1922, 1082); Start-Sleep -Milliseconds 300
[PzClick]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150
[PzClick]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
"clicked"
