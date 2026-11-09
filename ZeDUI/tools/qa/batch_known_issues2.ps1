#Requires -Version 7.0
# ZeDUI/tools/qa/batch_known_issues2.ps1  (Nov 5 2026, QA): the second half of the known issues run: the main menu's scroll bars
# with the round 4 mods on (4K, the Deck with Large text), Profiles alone, Hair and beard's three sets, then the multiplayer
# items: the radio keys over a rejoin, the controller's map and a plain player, a server with its safety system off, and the
# multiplayer surfaces at the Deck with Large text. The server's user list and settings are copied first and put back after.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
Note "second half start"
$r4 = "$Qa\compat_r4_mods.txt"
$none = "$Qa\mods_none.txt"
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList $none -Mode fullscreen4k -Manifest "$Qa\after_f59f.txt" 2>&1; Note "Ranch page 4K: $(($o | Select-Object -Last 2) -join ' | ')"
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList $none -Mode windowed -Width 1280 -Height 800 -Manifest "$Qa\after_f59f_deck.txt" 2>&1; Note "Ranch page Deck: $(($o | Select-Object -Last 2) -join ' | ')"
$o = & pwsh -NoProfile -File "$Qa\zedqa_menu_bars_run.ps1" -ModList $r4 2>&1; Note "bars 4K: $(($o | Select-Object -Last 2) -join ' | ')"
$o = & pwsh -NoProfile -File "$Qa\zedqa_menu_bars_run.ps1" -ModList $r4 -Width 1280 -Height 800 -Large -TimeoutSec 600 2>&1; Note "bars Deck Large: $(($o | Select-Object -Last 2) -join ' | ')"
$lines = & pwsh -NoProfile -File "$Qa\zedqa_menu_mods_run.ps1" -ModList $r4 -Script "$Qa\zedqa_mods_profiles.lua" -Tag mp -TimeoutSec 120 2>&1
$lines | Set-Content ([IO.Path]::GetFullPath("$Qa\..\..\qa\mods_profiles_20261105.log"))
Note "profiles: $(@($lines).Count) lines"
$A = "SuperOl3gContextMenuIcons,ImmersiveMoodles,ParavelsEnhancedUI,ParavelsEnhancedInventory,LightBelt"
& "$Qa\hb_bisect.ps1" -Sets @("$A,SladeBagCheck,HandsOnInteractionsIso,ImmersiveSleep", "$A,SladeBagCheck", "$A,HandsOnInteractionsIso")
Note "hair sets done"

# multiplayer
$Cache = "$($env:USERPROFILE)\Zomboid\zedqa_mp"
$Keep = Join-Path $env:TEMP "zedqa_mp_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item "$Cache\db\zedqa.db" "$Keep\zedqa.db" -Force
Copy-Item "$Cache\Server\zedqa.ini" "$Keep\zedqa.ini" -Force
function RunMp($manifest, $tag, $extra = @{}) {
    $report = Join-Path $Rep "2026-11-05_$tag.md"
    $a = @{ Manifest = "$Qa\$manifest"; Mp = $true; Report = $report } + $extra
    $o = & "$Qa\zedqa_run.ps1" @a 2>&1
    Note "$tag : $(($o | Select-Object -Last 1) -join ' ')"
}
try {
    & "$Qa\mp_server.ps1" -Start | Out-Null; Note "server up"
    RunMp "mp_radio.txt" "mp_radio"
    RunMp "mp_radio2.txt" "mp_radio_after"
    RunMp "mp_deck.txt" "mp_deck" @{ Mode = "windowed"; Width = 1280; Height = 800 }
    RunMp "mp_plain.txt" "mp_plain"
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force
    (Get-Content "$Cache\Server\zedqa.ini") -replace '^SafetySystem=.*$', 'SafetySystem=false' | Set-Content "$Cache\Server\zedqa.ini" -Encoding ascii
    & "$Qa\mp_server.ps1" -Start | Out-Null; Note "server up, safety off"
    RunMp "mp_nosafety.txt" "mp_nosafety"
}
finally {
    & "$Qa\mp_server.ps1" -Stop | Out-Null
    Copy-Item "$Keep\zedqa.db" "$Cache\db\zedqa.db" -Force
    Copy-Item "$Keep\zedqa.ini" "$Cache\Server\zedqa.ini" -Force
    Note "server stopped, its users and settings put back"
}
Note "second half end"
