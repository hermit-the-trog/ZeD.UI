#Requires -Version 7.0
# ZeDUI/tools/qa/batch_note_staged.ps1  (Nov 6 2026, QA): the corkboard on the true staged copy at the main menu: a picture in ZomboidStaged\Screenshots, then the game closes.
$Stg = "C:\Users\you\ZomboidStaged"
$GameDir = "E:\Project Zomboid\steamapps\common\ProjectZomboid"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running"; exit 2 }
Set-Content "C:\Users\you\Zomboid\Lua\zedqa.lock" "busy note_staged" -NoNewline
Remove-Item "$Stg\console.txt", "$Stg\Screenshots\zqa_note_b6a.png" -ErrorAction SilentlyContinue
Set-Content "$Stg\Lua\zedqa.autoload" "0" -NoNewline
$p = Start-Process "$GameDir\ProjectZomboid64.exe" -ArgumentList "-debug -nosteam -cachedir=$Stg" -WorkingDirectory $GameDir -PassThru
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt 200) {
    if ((Get-Content "$Stg\console.txt" -Raw -ErrorAction SilentlyContinue) -match 'bridge armed \(main menu') { break }
    Start-Sleep 3
}
Start-Sleep 8
Set-Content "$Stg\Lua\zedqa.lua" 'print("ZEDQA nts version " .. tostring(ZeD.MainMenu and ZeD.MainMenu.zedVersion)); getCore():TakeFullScreenshot("zqa_note_b6a.png")' -NoNewline
[long]$n = 900000; Set-Content "$Stg\Lua\zedqa.counter" "$n" -NoNewline; Set-Content "$Stg\Lua\zedqa.go" "$n" -NoNewline
Start-Sleep 8
Set-Content "$Stg\Lua\zedqa.lua" 'getCore():quitToDesktop()' -NoNewline
$n++; Set-Content "$Stg\Lua\zedqa.counter" "$n" -NoNewline; Set-Content "$Stg\Lua\zedqa.go" "$n" -NoNewline
for ($i = 0; $i -lt 20 -and -not $p.HasExited; $i++) { Start-Sleep 2 }
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
Set-Content "C:\Users\you\Zomboid\Lua\zedqa.lock" "free" -NoNewline
Select-String -Path "$Stg\console.txt" -Pattern "ZEDQA nts|bridge armed" | Select-Object -Last 3 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(120, $_.Line.Length)) }
Get-ChildItem "$Stg\Screenshots" -Filter "zqa_note*" | ForEach-Object { $_.FullName }
