#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6_stage.ps1  (Nov 6 2026, QA): the last game runs of beta 6, in order. Spongie's in game (its copies' version folders named 42: the plain copies never loaded
# with no Steam), the German cards once more with the console kept, then 0.3.0-beta6 staged and the release check on the staged copy. Stops at the check: the upload is the director's.
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$env:ZEDQA_NOSTEAM = "1"
$Out = "$Root\ZeDUI\qa\tickets_20261105.txt"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$Wk = "E:\Project Zomboid\steamapps\workshop\content\108600"
$Mods = "$($env:USERPROFILE)\Zomboid\mods"
$Shots = "$($env:USERPROFILE)\Zomboid\Screenshots"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
$Copied = @()
foreach ($id in 3414634809, 3814843526) {
    foreach ($d in Get-ChildItem "$Wk\$id\mods" -Directory) {
        $to = Join-Path $Mods $d.Name
        if (-not (Test-Path $to)) {
            Copy-Item $d.FullName $to -Recurse
            $Copied += $to
            Get-ChildItem $to -Directory -Filter "42.*" | ForEach-Object { Rename-Item $_.FullName "42" }
        }
    }
}
try {
    $o = & "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\spncc_long_mods.txt" -Mode fullscreen4k -Manifest "$Qa\spncc_long_manifest.txt" 2>&1
    Note "spncc in game : $(($o | Select-Object -Last 1) -join ' ')"
    Copy-Item "$($env:USERPROFILE)\Zomboid\console.txt" "$Keep\console_spncc.txt" -Force
}
finally { foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }; Note "the copied mods taken out" }
$Opt = "$($env:USERPROFILE)\Zomboid\options.ini"
$KeepOpt = Join-Path $env:TEMP "options_lang_keep.ini"
Copy-Item $Opt $KeepOpt -Force
try {
    (Get-Content $Opt) -replace '^language=.*$', "language=DE" | Set-Content $Opt -Encoding ascii
    & "$Qa\batch_tickets.ps1" -Runs "mp_lang.txt:lang_DE:1280:800" | Out-Null
    Copy-Item "$($env:USERPROFILE)\Zomboid\console.txt" "$Keep\console_de.txt" -Force
    New-Item -ItemType Directory -Force "$Shots\lang_DE" | Out-Null
    foreach ($p in "mtc_", "mac_", "zqa_id2_") { Get-ChildItem $Shots -Filter "$p*.png" | Move-Item -Destination "$Shots\lang_DE" -Force }
}
finally { Copy-Item $KeepOpt $Opt -Force }
Note "german cards done"
$W = "$Root\ZeDUI\workshop"
$o = & pwsh -NoProfile -File "$Root\ZeDUI\tools\release\stage_workshop.ps1" -Version 0.3.0-beta6 -Description "$W\tester_description_0.3.0-beta6.bbcode" -ChangeNote "$W\tester_changenote_0.3.0-beta6.txt" 2>&1
$o | Select-Object -Last 14 | Set-Content "$Root\ZeDUI\qa\stage_beta6.txt"
Note "staged: $(($o | Select-Object -Last 1) -join ' ')"
$dest = "$($env:USERPROFILE)\Zomboid\Workshop\ZeD-UI\Contents\mods\ZeD-UI\42\media\lua\client\ZeD"
Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" $dest -Force
try {
    $r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Staged -Manifest "release_check_pinned.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-06_beta6_release_check_staged.md" 2>&1
    Note "release check: $(($r | Select-Object -Last 2) -join ' | ')"
}
finally { Remove-Item (Join-Path $dest "QABridge.lua") -Force -ErrorAction SilentlyContinue }
Note "stage done, bridge out"
