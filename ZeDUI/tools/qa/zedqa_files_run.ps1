#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_files_run.ps1  (Nov 11 2026, QA, punch list 170; ZeDUI/qa/CHECK_pl170_files_tab.md)
# The Mods screen's Files tab and the plain-words error cards with the real Workshop mods. Copies Bandits, Bandits Week One and
# Ladders!? from Steam's download into Zomboid\mods (only the ones not there already; removed again after, only those), lists them with
# ZeD picks for the run, and makes three runs, one after the other, each Start-Process + WaitForExit:
#   1 in game (zedqa_files_game.lua):   the error cards, Open in Mods
#   2 main menu (zedqa_files_menu.lua): the Files tab, a file switched off, the guards
#   3 in game (zedqa_files_after.lua):  the file's part gone, then turned back on
# File hashes of every copied mod folder are taken before and after (the mods' own folders must never be written), the helper's
# copy of the switched-off file is read between runs 2 and 3. Lines go to zedqa_files_run.log beside this script's -OutDir.
param([string]$OutDir = "")
$ErrorActionPreference = "Stop"
$Qa = $PSScriptRoot
$Z = "$($env:USERPROFILE)\Zomboid"
$Lua = "$Z\Lua"
$Ws = "E:\Project Zomboid\SteamApps\workshop\content\108600"
if (-not $OutDir) { $OutDir = $Qa }
$Log = Join-Path $OutDir "zedqa_files_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { L "refused: the game is running"; exit 2 }
if ((Get-Content "$Lua\zedqa.lock" -Raw -ErrorAction SilentlyContinue).Trim() -ne "free") { L "refused: the lock is not free"; exit 2 }
$env:ZEDQA_NOSTEAM = "1"
$mods = @(
    @{ id = "Bandits";        src = "$Ws\3268487204\mods\Bandits" },
    @{ id = "BanditsWeekOne"; src = "$Ws\3403180543\mods\BanditsWeekOne" },
    @{ id = "Ladders";        src = "$Ws\2737665235\mods\Ladders" }
)
foreach ($m in $mods) { if (-not (Test-Path $m.src)) { L "NOT DOWNLOADED: $($m.id) ($($m.src))"; exit 3 } }
function Folder-Hash([string]$dir) {
    $h = [System.Security.Cryptography.SHA256]::Create()
    $files = Get-ChildItem -LiteralPath $dir -Recurse -File | Sort-Object FullName
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($dir.Length)
        $line = "$rel|$($f.Length)|$((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)`n"
        $b = [System.Text.Encoding]::UTF8.GetBytes($line); [void]$h.TransformBlock($b, 0, $b.Length, $null, 0)
    }
    [void]$h.TransformFinalBlock([byte[]]::new(0), 0, 0)
    return "$($files.Count) files " + [BitConverter]::ToString($h.Hash).Replace("-", "").Substring(0, 16)
}
# what to put back
$picksTxt = "$Lua\ZeD_picks.txt"
$picksWas = if (Test-Path $picksTxt) { [System.IO.File]::ReadAllBytes($picksTxt) } else { $null }
$helperDir = "$Z\mods\ZeD_Picks"
$helperWas = @(Get-ChildItem -LiteralPath $helperDir -Recurse -File | ForEach-Object { $_.FullName })
$copied = @()
$statePath = "$Lua\zedqa_files_state.txt"
$hashBefore = @{}
try {
    foreach ($m in $mods) {
        $dst = "$Z\mods\$($m.id)"
        if (-not (Test-Path $dst)) { Copy-Item $m.src $dst -Recurse; $copied += $dst; L "$($m.id) copied in" } else { L "$($m.id) was already in Zomboid\mods (left alone)" }
        $hashBefore[$m.id] = Folder-Hash $dst
        L "hash before $($m.id): $($hashBefore[$m.id]) (Workshop copy: $(Folder-Hash $m.src))"
    }
    $ml = Join-Path $OutDir "files_mods.txt"; Set-Content $ml @("Bandits", "BanditsWeekOne", "Ladders", "ZeD_Picks")
    $m1 = Join-Path $OutDir "files_manifest1.txt"; Set-Content $m1 @("zedqa_prelude.lua | pre | timeout=120", "zedqa_files_game.lua | fg | timeout=600")
    $m3 = Join-Path $OutDir "files_manifest3.txt"; Set-Content $m3 @("zedqa_prelude.lua | pre | timeout=120", "zedqa_files_after.lua | fa | timeout=600")
    function Run-One([string]$name, [string[]]$args2) {
        $out = Join-Path $OutDir "files_$name.out"
        $p = Start-Process pwsh -ArgumentList (@("-NoProfile", "-File") + $args2) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
        $p.Id | Set-Content (Join-Path $OutDir "files_$name.pid")
        $p.WaitForExit()
        L "run $name exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
    }
    Remove-Item $statePath -ErrorAction SilentlyContinue
    Run-One "1_game" @("$Qa\zedqa_mods_run.ps1", "-ModList", $ml, "-Mode", "fullscreen4k", "-Manifest", $m1)
    Run-One "2_menu" @("$Qa\zedqa_menu_mods_run.ps1", "-ModList", $ml, "-Script", "$Qa\zedqa_files_menu.lua", "-Tag", "fm", "-TimeoutSec", "420")
    # the helper's copy of the switched-off file
    if (Test-Path $statePath) {
        foreach ($l in Get-Content $statePath) {
            if ($l -match "^off`t([^`t]*)`t(.*)$") {
                $id = $Matches[1]; $rel = $Matches[2]
                $h = "$helperDir\common\$($rel.Replace('/', '\'))"
                if (Test-Path $h) {
                    $txt = @(Get-Content -LiteralPath $h)
                    L "helper copy of $rel : $($txt.Count) line(s): $($txt -join ' / ')"
                } else { L "helper copy of $rel : NOT THERE at $h" }
                $own = Get-ChildItem "$Z\mods\$id" -Recurse -File -Filter ([System.IO.Path]::GetFileName($rel)) | Where-Object { $_.FullName -like "*$($rel.Replace('/', '\'))" } | Select-Object -First 1
                L "the mod's own file: $($own.FullName.Replace($env:USERPROFILE, '%USERPROFILE%')) $($own.Length) bytes (unchanged: see the folder hash)"
            }
        }
    } else { L "no state file after run 2" }
    $pn = if (Test-Path $picksTxt) { (Get-Content $picksTxt -Raw) -replace "\t", " " } else { "(none)" }; L "ZeD_picks.txt now: $($pn.Trim())"
    Run-One "3_game" @("$Qa\zedqa_mods_run.ps1", "-ModList", $ml, "-Mode", "fullscreen4k", "-Manifest", $m3)
    # after turning back on: the helper's copy is the mod's own text
    if (Test-Path "$statePath") { }
}
finally {
    foreach ($m in $mods) {
        $dst = "$Z\mods\$($m.id)"
        if (Test-Path $dst) { L "hash after  $($m.id): $(Folder-Hash $dst)  (before: $($hashBefore[$m.id]))" }
    }
    # the helper's copies, as turned back on, against the mod's own text (read before the helper's files are put back)
    foreach ($f in Get-ChildItem -LiteralPath $helperDir -Recurse -File | Where-Object { $helperWas -notcontains $_.FullName }) {
        $rel = $f.FullName.Substring("$helperDir\common\".Length)
        $own = Get-ChildItem "$Z\mods\BanditsWeekOne" -Recurse -File -Filter $f.Name | Where-Object { $_.FullName -like "*$rel" } | Select-Object -First 1
        $same = $own -and ((Get-FileHash $own.FullName).Hash -eq (Get-FileHash $f.FullName).Hash -or (@(Get-Content $own.FullName) -join "`n").Trim() -eq (@(Get-Content $f.FullName) -join "`n").Trim())
        L "helper file $rel : matches the mod's own text: $same ($((Get-Item $f.FullName).Length) bytes)"
        Remove-Item -LiteralPath $f.FullName -Force
    }
    Get-ChildItem -LiteralPath $helperDir -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } | Remove-Item -Force
    foreach ($d in $copied) { if (Test-Path $d) { Remove-Item $d -Recurse -Force; L "removed $d".Replace($env:USERPROFILE, '%USERPROFILE%') } }
    if ($null -ne $picksWas) { [System.IO.File]::WriteAllBytes($picksTxt, $picksWas); L "ZeD_picks.txt put back" } elseif (Test-Path $picksTxt) { Remove-Item $picksTxt; L "ZeD_picks.txt removed (there was none)" }
    Remove-Item $statePath -ErrorAction SilentlyContinue
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
