# Launch PZ in a WINDOW for QA (1920x1080 by default; -Width / -Height for
# smaller screens, Oct 29 2026) (director, Oct 14 2026) and load the
# latest save (the QA save) through the bridge's autoload flag, then click the
# window's centre to pass "click to start". Restore the fullscreen options
# with pzrestorewin.ps1 after the game has closed.
# -MainMenu: stop at the main menu instead (no autoload, no click); returns
# once the QA bridge has armed there.
param([switch]$MainMenu, [switch]$NoSteam, [int]$Width = 1920, [int]$Height = 1080)   # (Oct 29 2026: -Width / -Height for the small-screen passes: 1280x800 Deck, 1280x720)
$S = $PSScriptRoot
# (Nov 8 2026) with ZEDQA_ZDIR set (a true staged check from its own -cachedir) everything follows that folder:
# options.ini, the autoload flag, console.txt and the launch's -cachedir; the staged-copy refusal does not apply there
$Z = $(if ($env:ZEDQA_ZDIR) { $env:ZEDQA_ZDIR } else { "$($env:USERPROFILE)\Zomboid" })
# refuse to launch while a Workshop staging copy of ZeD-UI exists: the game scans
# Workshop\*\Contents\mods before Zomboid\mods and the first folder with the mod id wins
$staged = @(Get-ChildItem -Path "$($env:USERPROFILE.Replace('\','/'))/Zomboid/Workshop/*/Contents/mods/*/42/mod.info", "$($env:USERPROFILE.Replace('\','/'))/Zomboid/Workshop/*/Contents/mods/*/common/mod.info", "$($env:USERPROFILE.Replace('\','/'))/Zomboid/Workshop/*/Contents/mods/*/mod.info" -ErrorAction SilentlyContinue |
    Where-Object { Select-String -LiteralPath $_.FullName -Pattern '^\s*id=ZeD_UI\s*$' -Quiet -ErrorAction SilentlyContinue } |
    ForEach-Object { $_.FullName -replace '[\\/]mods[\\/].*$', '' } | Select-Object -Unique)
if ($staged.Count -gt 0 -and -not $env:ZEDQA_ZDIR) {
    foreach ($folder in $staged) { Write-Output "A Workshop staging copy of ZeD-UI is at $folder; the game would load it instead of the dev mod. Remove its Contents folder (stage it again right before an upload)." }
    exit 3
}
$opt = Join-Path $Z "options.ini"
$bak = $(if ($env:ZEDQA_ZDIR) { Join-Path $Z "options.ini.fullscreen.bak" } else { Join-Path $S "options.ini.fullscreen.bak" })
if (-not (Test-Path $bak)) { Copy-Item $opt $bak }
$t = Get-Content $opt
$t = $t -replace '^fullScreen=.*', 'fullScreen=false' -replace '^width=.*', "width=$Width" -replace '^height=.*', "height=$Height"
Set-Content -Path $opt -Value $t
Set-Content -Path (Join-Path $Z "Lua\zedqa.autoload") -Value ($(if ($MainMenu) { "0" } else { "1" })) -NoNewline
$dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList ($(if ($NoSteam) { "-debug -nosteam" } else { "-debug" }) + $(if ($env:ZEDQA_ZDIR) { " -cachedir=$Z" } else { "" })) -WorkingDirectory $dir
$log = Join-Path $Z "console.txt"
Start-Sleep -Seconds 10
$want = $(if ($MainMenu) { "bridge armed \(main menu" } else { "game loading took" })
$loaded = $false
for ($i = 0; $i -lt 300; $i++) {   # (up to 10 minutes: a long mod list loads slowly)
  Start-Sleep -Seconds 2
  $c = ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "")
  if ($c -match $want) { $loaded = $true; break }
}
if (-not $loaded) { "never reached: $want"; exit 1 }
if ($MainMenu) { "launched windowed; at the main menu"; exit 0 }
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
# (Nov 11 2026) the pointer parked in the client's bottom-right corner after the click: left at the centre it sat over
# an inventory row in every picture after it, and the row's loot card showed (the director's review: the JS-2000
# Shotgun's card over the Inventory). A script's Mouse.setXY does not move what the game reads; this does.
Start-Sleep -Milliseconds 300
$park = New-Object PZW+POINT; $park.X = [int]($r.R - $r.L - 4); $park.Y = [int]($r.B - $r.T - 4)
[void][PZW]::ClientToScreen($h, [ref]$park)
[void][PZW]::SetCursorPos($park.X, $park.Y)
"launched windowed; clicked client centre ($($pt.X),$($pt.Y)) of $($r.R - $r.L)x$($r.B - $r.T); pointer parked at ($($park.X),$($park.Y))"
