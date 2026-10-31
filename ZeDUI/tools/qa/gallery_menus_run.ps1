<#
.SYNOPSIS
    The Workshop gallery's main-menu captures in one go (Oct 27 2026, 0.2.0-t7): the desk and its
    wallpapers (gallery_desk_pass.lua), Options, Mods, profiles, load order and the uploader
    (gallery_v4_menus.lua, gallery_v4_upload.lua).
.DESCRIPTION
    Puts the gallery's sample mods back for the run (Zomboid/zed_backups/gallery_samples_20261022:
    Zomboid/mods/Sample*, Zomboid/Workshop/SampleLootTables), turns the "Everything" list on in
    mods/default.txt, starts the game with -debug and no save loaded, and pushes each script through
    the QA bridge at the main menu, waiting for its DONE line. Screenshots: desk_*.png and mm4_*.png in
    Zomboid/Screenshots. Nothing is uploaded (gallery_v4_upload.lua answers Cancel).
    Afterwards it quits the game and puts back default.txt, pz_modlist_settings.cfg,
    ZeD_modprofiles.txt, ZeD_wallpaper.txt, ZeD_workshop.txt, ModOptions.ini and zedqa.autoload, and
    removes the sample mods and the staged sample folder it added. Holds Zomboid/Lua/zedqa.lock.
    Exit 0 every script reached DONE, 1 a script did not, 2 refused.
#>
$Zomboid = "C:\Users\danie\Zomboid"
$Lua = Join-Path $Zomboid "Lua"
$QA = $PSScriptRoot
$log = Join-Path $Zomboid "console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$Samples = Join-Path $Zomboid "zed_backups\gallery_samples_20261022"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running; not starting"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
if (-not (Test-Path (Join-Path $Samples "mods"))) { "the sample mods are not at $Samples; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy gallery_menus_run" -NoNewline

# what the run changes, kept to put back
$Keep = Join-Path $env:TEMP "gallery_menus_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
$kept = @{
    "default.txt" = Join-Path $Zomboid "mods\default.txt"
    "pz_modlist_settings.cfg" = Join-Path $Lua "pz_modlist_settings.cfg"
    "ZeD_modprofiles.txt" = Join-Path $Lua "ZeD_modprofiles.txt"
    "ZeD_wallpaper.txt" = Join-Path $Lua "ZeD_wallpaper.txt"
    "ZeD_workshop.txt" = Join-Path $Lua "ZeD_workshop.txt"
    "ModOptions.ini" = Join-Path $Lua "ModOptions.ini"
    "zedqa.autoload" = Join-Path $Lua "zedqa.autoload"
    "options.ini" = Join-Path $Zomboid "options.ini"
}
$had = @{}
foreach ($k in $kept.Keys) {
    $had[$k] = Test-Path $kept[$k]
    if ($had[$k]) { Copy-Item $kept[$k] (Join-Path $Keep $k) -Force }
}
# the sample mods and the staged sample folder: added only where they are missing, removed after
$added = @()
foreach ($d in Get-ChildItem (Join-Path $Samples "mods") -Directory) {
    $to = Join-Path $Zomboid ("mods\" + $d.Name)
    if (-not (Test-Path $to)) { Copy-Item $d.FullName $to -Recurse; $added += $to }
}
$ws = Join-Path $Zomboid "Workshop\SampleLootTables"
if (-not (Test-Path $ws)) { Copy-Item (Join-Path $Samples "Workshop\SampleLootTables") $ws -Recurse; $added += $ws }
Copy-Item (Join-Path $Samples "Lua\pz_modlist_settings_with_samples.cfg") $kept["pz_modlist_settings.cfg"] -Force

function Next-Go {
    $cf = Join-Path $Lua "zedqa.counter"; $gf = Join-Path $Lua "zedqa.go"
    [long]$n = 9999
    $t = Get-Content $cf -Raw -ErrorAction SilentlyContinue
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    $cur = Get-Content $gf -Raw -ErrorAction SilentlyContinue
    if ($cur -and $cur.Trim() -match '^\d+$' -and [long]$cur.Trim() -ge $n) { $n = [long]$cur.Trim() }
    $n++
    Set-Content -Path $cf -Value "$n" -NoNewline
    return $n
}
function LogText { ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "") }
function Wait-Log($pattern, $seconds, $from) {
    for ($i = 0; $i -lt $seconds * 2; $i++) {
        Start-Sleep -Milliseconds 500
        $t = LogText
        if ($t.Length -gt $from) { $m = [regex]::Match($t.Substring($from), $pattern); if ($m.Success) { return $m } }
    }
    return $null
}
function Push($file, $tag, $seconds) {
    $from = (LogText).Length
    $g = Next-Go
    Copy-Item (Join-Path $QA $file) (Join-Path $Lua "zedqa.lua") -Force
    Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
    $m = Wait-Log "ZEDQA $tag DONE" $seconds $from
    $t = LogText
    $lines = ($t.Substring([Math]::Min($from, $t.Length)) -split "`n") | Where-Object { $_ -match "ZEDQA $tag |\[ZeD\.QA\]" }
    $lines | ForEach-Object { "    " + $_.Trim() }
    if ($m) { "  $file ($tag): DONE"; return $true }
    "  $file ($tag): no DONE in $seconds s"; return $false
}

$fails = 0
$p = $null
try {
    $list = @("ZeD_UI", "ExtraBooks", "SampleLootTables", "SampleLootRebalance", "SampleCraftingCore", "SampleCraftingPack", "SampleTownMap", "SampleFarmMap")
    $txt = "VERSION = 1,`n`nmods`n{`n" + (($list | ForEach-Object { "    mod = $_," }) -join "`n") + "`n}`n`nmaps`n{`n}`n"
    Set-Content -Path $kept["default.txt"] -Value $txt -NoNewline
    Set-Content -Path $kept["zedqa.autoload"] -Value "0" -NoNewline
    # the desk's second wallpaper is the title video, drawn only with the game's video effects on (put back after)
    $opt = Get-Content $kept["options.ini"] -Raw
    Set-Content -Path $kept["options.ini"] -Value ($opt -replace "doVideoEffects=false", "doVideoEffects=true") -NoNewline
    $dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
    $p = Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $dir -PassThru
    "started the game (process $($p.Id))"
    Start-Sleep -Seconds 15
    if (-not (Wait-Log 'bridge armed \(main menu' 600 0)) { "never reached the main menu"; $fails++; return }
    Start-Sleep -Seconds 12
    # (Oct 30 2026, the t14 retake) the desk's Debug menu left out and the default look (Dark, Orange) for the pictures;
    # gallery_t14_end.lua puts both back before the quit
    if (-not (Push "gallery_t14_look_menu.lua" "g14l" 60)) { $fails++ }
    Start-Sleep -Seconds 2
    if (-not (Push "gallery_desk_pass.lua" "dsk" 120)) { $fails++ }
    Start-Sleep -Seconds 3
    if (-not (Push "gallery_v4_menus.lua" "g4m" 300)) { $fails++ }
    Start-Sleep -Seconds 3
    if (-not (Push "gallery_v4_upload.lua" "g4u" 180)) { $fails++ }
    Start-Sleep -Seconds 2
    if (-not (Push "gallery_t14_end_menu.lua" "g14e" 60)) { $fails++ }
} finally {
    if ($p -and -not $p.HasExited) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quit()" -NoNewline
        Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
        for ($i = 0; $i -lt 60; $i++) { Start-Sleep -Seconds 2; if ($p.HasExited) { break } }
        if ($p.HasExited) { "the game closed" } else { "the game is still running (process $($p.Id)); left open" }
    }
    Copy-Item $log (Join-Path $env:TEMP "gallery_menus_console.txt") -Force -ErrorAction SilentlyContinue
    foreach ($k in $kept.Keys) {
        if ($had[$k]) { Copy-Item (Join-Path $Keep $k) $kept[$k] -Force } else { Remove-Item $kept[$k] -ErrorAction SilentlyContinue }
    }
    foreach ($a in $added) { Remove-Item $a -Recurse -Force -ErrorAction SilentlyContinue }
    "put back: default.txt, pz_modlist_settings.cfg, ZeD_modprofiles.txt, ZeD_wallpaper.txt, ZeD_workshop.txt, ModOptions.ini, zedqa.autoload, options.ini; removed $($added.Count) sample folders"
    if (-not ($p -and -not $p.HasExited)) { Set-Content -Path $lock -Value "free" -NoNewline }
    if ($fails -eq 0) { "every script reached DONE" } else { "$fails script(s) did not reach DONE" }
}
if ($fails -eq 0) { exit 0 } else { exit 1 }
