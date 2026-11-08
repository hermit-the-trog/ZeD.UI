<#
.SYNOPSIS
    (Nov 3 2026, QA) ZeD's Workshop upload page on the ZeD-UI folder, looked at only (zedqa_ws_preview.lua): the
    preview picture's size, dot and words. A copy of gallery_beta_hidden_run.ps1 pushing that script instead.
.DESCRIPTION
    Starts the game with -debug and no save loaded (mods/default.txt set to ZeD_UI alone, zedqa.autoload 0), waits for
    the QA bridge at the main menu, pushes gallery_t14_look_menu.lua, zedqa_ws_preview.lua and gallery_t14_end_menu.lua,
    quits through the bridge and puts back default.txt, pz_modlist_settings.cfg, ModOptions.ini and zedqa.autoload.
    Upload is never pressed. Holds Zomboid/Lua/zedqa.lock. Exit 0 every script reached DONE, 1 one did not, 2 refused.
#>
$Zomboid = "$env:USERPROFILE\Zomboid"
$Lua = Join-Path $Zomboid "Lua"
$QA = $PSScriptRoot
$log = Join-Path $Zomboid "console.txt"
$lock = Join-Path $Lua "zedqa.lock"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running; not starting"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy ws_preview_run" -NoNewline

# what the run changes, kept to put back
$Keep = Join-Path $env:TEMP "ws_preview_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
$kept = @{
    "default.txt" = Join-Path $Zomboid "mods\default.txt"
    "pz_modlist_settings.cfg" = Join-Path $Lua "pz_modlist_settings.cfg"
    "ModOptions.ini" = Join-Path $Lua "ModOptions.ini"
    "zedqa.autoload" = Join-Path $Lua "zedqa.autoload"
}
$had = @{}
foreach ($k in $kept.Keys) {
    $had[$k] = Test-Path $kept[$k]
    if ($had[$k]) { Copy-Item $kept[$k] (Join-Path $Keep $k) -Force }
}

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
    $txt = "VERSION = 1,`n`nmods`n{`n    mod = ZeD_UI,`n}`n`nmaps`n{`n}`n"
    Set-Content -Path $kept["default.txt"] -Value $txt -NoNewline
    Set-Content -Path $kept["zedqa.autoload"] -Value "0" -NoNewline
    $dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
    $p = Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $dir -PassThru
    "started the game (process $($p.Id))"
    Start-Sleep -Seconds 15
    if (-not (Wait-Log 'bridge armed \(main menu' 600 0)) { "never reached the main menu"; $fails++; return }
    Start-Sleep -Seconds 12
    if (-not (Push "gallery_t14_look_menu.lua" "g14l" 60)) { $fails++ }
    Start-Sleep -Seconds 2
    if (-not (Push "zedqa_ws_preview.lua" "wsp" 120)) { $fails++ }
    Start-Sleep -Seconds 2
    if (-not (Push "gallery_t14_end_menu.lua" "g14e" 60)) { $fails++ }
} finally {
    # only the game this run started is asked to quit (through the bridge, as gallery_menus_run.ps1 does)
    if ($p -and -not $p.HasExited) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quit()" -NoNewline
        Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
        for ($i = 0; $i -lt 60; $i++) { Start-Sleep -Seconds 2; if ($p.HasExited) { break } }
        if ($p.HasExited) { "the game closed" } else { "the game is still running (process $($p.Id)); left open" }
    }
    Copy-Item $log (Join-Path $env:TEMP "ws_preview_console.txt") -Force -ErrorAction SilentlyContinue
    foreach ($k in $kept.Keys) {
        if ($had[$k]) { Copy-Item (Join-Path $Keep $k) $kept[$k] -Force } else { Remove-Item $kept[$k] -ErrorAction SilentlyContinue }
    }
    "put back: default.txt, pz_modlist_settings.cfg, ModOptions.ini, zedqa.autoload"
    if (-not ($p -and -not $p.HasExited)) { Set-Content -Path $lock -Value "free" -NoNewline }
    if ($fails -eq 0) { "every script reached DONE" } else { "$fails script(s) did not reach DONE" }
}
if ($fails -eq 0) { exit 0 } else { exit 1 }
