# QA (Nov 11 2026): the mod-settings pages (51, 53, 55) through gallery_b11_panes_run.ps1 with the six test Workshop mods in
# Zomboid\mods for the run: directory junctions to Steam's downloads (the game runs without Steam), made only if the folder
# is absent and removed after (only the links this script made; rmdir on a junction never touches its target).
# Start-Process + WaitForExit; lines to b11_panes_mods.log.
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b11_panes_mods.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$W = "E:\Project Zomboid\SteamApps\workshop\content\108600"
$Mods = "$($env:USERPROFILE)\Zomboid\mods"
$Want = @(
    @("ConeVisionOutline", "3659137034\mods\ConeVisionOutline"), @("SmartRadialMenu", "3494108029\mods\SmartRadialMenu"),
    @("GaelGunStore", "3616176188\mods\GaelGunStore"), @("Escape from Kentucky4215", "3633421539\mods\Escape from Kentucky4215"),
    @("Constown", "3480990544\mods\Constown"), @("New Hartburg", "3741334453\mods\New Hartburg"))
$made = @()
if ($env:B11_DROP_MFS) { $Want = @($Want | Where-Object { $_[0] -ne "Escape from Kentucky4215" }) }
foreach ($m in $Want) {
    $dst = Join-Path $Mods $m[0]
    $src = Join-Path $W $m[1]
    if ((Test-Path -LiteralPath $dst) -or -not (Test-Path -LiteralPath $src)) { L "skip $($m[0]) (exists or no source)"; continue }
    New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
    $made += $dst; L "linked $($m[0])"
}
$env:ZEDQA_NOSTEAM = "1"
try {
    $out = Join-Path $Qa "gallery_b11_panes2.out"
    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Set-Content (Join-Path $Qa "b11_run_panes2.start")
    $p = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\gallery_b11_panes_run.ps1" -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.Id | Set-Content (Join-Path $Qa "b11_run_panes2.pid")
    $p.WaitForExit()
    L "run exit $($p.ExitCode): $((Get-Content $out -Tail 2 -ErrorAction SilentlyContinue) -join ' | ')"
} finally {
    foreach ($d in $made) { if (Test-Path -LiteralPath $d) { cmd /c rmdir "`"$d`""; L "unlinked $d" } }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
