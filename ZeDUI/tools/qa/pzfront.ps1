# Bring the fullscreen Project Zomboid window to the foreground.
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class PZF {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool OpenIcon(IntPtr h);
  [DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool alt);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string title);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
"@
# Hide the "Windows Input Experience" window if it is around (it steals the foreground).
$wie = [PZF]::FindWindow($null, "Windows Input Experience"); if ($wie -ne [IntPtr]::Zero) { [void][PZF]::ShowWindow($wie, 0) }
Get-Process TextInputHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$p = Get-Process ProjectZomboid64 | Select-Object -First 1; $h = $p.MainWindowHandle
$fg = [PZF]::GetForegroundWindow(); $fgpid = [uint32]0; $fgt = [PZF]::GetWindowThreadProcessId($fg, [ref]$fgpid)
$me = [PZF]::GetCurrentThreadId()
[void][PZF]::AttachThreadInput($me, $fgt, $true)
[PZF]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [PZF]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
[void][PZF]::OpenIcon($h); [void][PZF]::ShowWindow($h, 9); [void][PZF]::BringWindowToTop($h); [void][PZF]::SetForegroundWindow($h); [PZF]::SwitchToThisWindow($h, $true)
[void][PZF]::AttachThreadInput($me, $fgt, $false)
Start-Sleep -Milliseconds 1500
$fg = [PZF]::GetForegroundWindow(); $sb = New-Object System.Text.StringBuilder 256; [void][PZF]::GetWindowText($fg, $sb, 256)
"foreground='$($sb.ToString())' iconic=$([PZF]::IsIconic($h))"
