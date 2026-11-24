#Requires -Version 7.0
<#
    ZeDUI/tools/qa/rt_coverage.ps1  (Nov 18 2026, QA): the release test's ledger check. The director asked: "Is there an
    intake when something is added? Or something is removed that no longer requires that test?" This is that intake,
    in the tools, not in anyone's memory. It reads ZeDUI/tools/qa/FEATURE_MAP.md (every shipped feature, one row each,
    with a Check column) against the code and the release test, and fails when:
      1. a row's Check is TODO (a feature with no check and no reason);
      2. a row's owning file is gone, or none of its entry functions exist in the code any more (a removed feature:
         take its row out, and its check with it);
      3. a ZeD Lua file is owned by no row and is not on the plumbing list rt_coverage_plumbing.txt (a feature added
         without a row);
      4. a row's check is not proven: a covered row is written rt_tag: "the check's words", the tag must be one
         release_test.txt runs, and those words must be in that script (so a reworded or removed check shows up).
    zedqa_run.ps1 runs this first for the release test and will not start the game while it fails.
      pwsh -File ZeDUI/tools/qa/rt_coverage.ps1            (exit 0 clean, 1 with the problems listed)
    (Nov 23 2026, QA: the Loadouts split. The add-on ZeD-GUI: Loadouts, mods\ZeD-Loadouts beside ZeD-UI, is read too
    when it is there: its Lua under 42/media/lua counts as code, each file named "ZeD-Loadouts/<file>" for one in
    client/ZeDLoadouts/ ("ZeD-Loadouts/<path under 42/media/lua>" elsewhere). An owning-file cell "ZeD-Loadouts/<file>"
    is a file of the add-on's tree and owns it there; a cell without the prefix names a file of ZeD's own tree only.
    Rule 3 holds the add-on's files to a row once the map names any "ZeD-Loadouts/" file: before the split's map
    lands, the add-on's own files are read for the function search but not asked to have rows.)
#>
param([string]$Map = "", [switch]$Quiet)
$ErrorActionPreference = "Stop"
$qa = $PSScriptRoot
$root = (Resolve-Path (Join-Path $qa "..\..\..")).Path
$client = Join-Path $root "42\media\lua\client\ZeD"
$shared = Join-Path $root "42\media\lua\shared\ZeD"
if (-not $Map) { $Map = Join-Path $qa "FEATURE_MAP.md" }
$plumbFile = Join-Path $qa "rt_coverage_plumbing.txt"
$problems = New-Object System.Collections.Generic.List[string]
$AP = "ZeD-Loadouts/"   # (the prefix of the add-on's files, in the map and in $files)

# ---- the code: every ZeD Lua file, and all of its text for the function search
$files = @(Get-ChildItem $client, $shared -Recurse -Filter *.lua | ForEach-Object {
    $rel = $_.FullName.Substring($client.Length + 1)
    if ($_.FullName.StartsWith($shared)) { $rel = "shared/" + $_.FullName.Substring($shared.Length + 1) }
    $rel.Replace('\', '/')
})
$text = (Get-ChildItem $client, $shared -Recurse -Filter *.lua | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"

# ---- the add-on ZeD-GUI: Loadouts (its own repo, beside ZeD-UI; else in the user's Zomboid\mods), when it is there
$addonRoot = $null
foreach ($cand in @((Join-Path (Split-Path $root -Parent) "ZeD-Loadouts"), (Join-Path $env:USERPROFILE "Zomboid\mods\ZeD-Loadouts"))) {
    if (-not $addonRoot -and (Test-Path (Join-Path $cand "42\media\lua"))) { $addonRoot = (Resolve-Path $cand).Path }
}
$addonFiles = @()
if ($addonRoot) {
    $aLua = Join-Path $addonRoot "42\media\lua"
    $aClient = Join-Path $aLua "client\ZeDLoadouts"
    $aSrc = @(Get-ChildItem $aLua -Recurse -Filter *.lua)
    $addonFiles = @($aSrc | ForEach-Object {
        if ($_.FullName.StartsWith($aClient + "\")) { $rel = $_.FullName.Substring($aClient.Length + 1) }
        else { $rel = $_.FullName.Substring($aLua.Length + 1) }
        $AP + $rel.Replace('\', '/')
    })
    $files += $addonFiles
    if ($aSrc.Count -gt 0) { $text += "`n" + (($aSrc | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n") }
}
# a cell's file among the code: "ZeD-Loadouts/<file>" in the add-on's tree only, any other in ZeD's own only
function Find-Owned([string]$o) {
    if ($o.StartsWith($AP)) {
        $rest = $o.Substring($AP.Length)
        return @($files | Where-Object { $_.StartsWith($AP) -and ($_ -eq $o -or $_.EndsWith("/" + $rest)) })
    }
    return @($files | Where-Object { -not $_.StartsWith($AP) -and ($_ -eq $o -or $_.EndsWith("/" + $o)) })
}
$mapNamesAddon = $false

# ---- the release test's tags, and each tag's script text (a claimed check's words must be in it)
$tags = @()
$scriptOf = @{}
foreach ($ln in Get-Content (Join-Path $qa "release_test.txt")) {
    if ($ln -notmatch '^\s*[^#\s].*\|') { continue }
    $parts = $ln -split '\|'
    $tg = $parts[1].Trim()
    $tags += $tg
    $sf = Join-Path $qa $parts[0].Trim()
    if (Test-Path $sf) { $scriptOf[$tg] = [IO.File]::ReadAllText($sf) }
}

# ---- the map: abbreviations ("CW = ZeD_CharacterWindow.lua") and the feature rows
$abbr = @{}
$owned = @{}
$rows = 0
$prevOwners = @()
foreach ($l in Get-Content $Map) {
    foreach ($m in [regex]::Matches($l, '\b([A-Z]{2,5}) = ([A-Za-z0-9_/]+\.lua)')) { $abbr[$m.Groups[1].Value] = $m.Groups[2].Value }
    if (-not $l.StartsWith('|') -or $l.StartsWith('|---')) { continue }
    $c = @($l.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    if ($c.Count -ne 8 -or $c[0] -eq 'Feature') { continue }
    $rows++
    $feat, $own, $entry, $check = $c[0], $c[1], $c[2], $c[7]
    # 1. a gap
    if ($check -eq 'TODO' -or -not $check) { $problems.Add("no check: '$feat' (Check is $(if ($check) { $check } else { 'empty' }))") }
    # 4. a claimed check: rt_tag: "the check's own words" (Nov 18 2026: a bare tag is no proof; the first pass marked
    # rows covered because a script mentioned a function, and the audit found many with no check at all)
    if ($check -match '^(rt_[a-z_]+)\s*$') { $problems.Add("'$feat': Check says $($Matches[1]) but names no check (write it as $($Matches[1]): ""the check's words"")") }
    elseif ($check -match '^(rt_[a-z_]+):\s*"(.+)"\s*$') {
        $tg, $phrase = $Matches[1], $Matches[2]
        if ($tags -notcontains $tg) { $problems.Add("'$feat': Check names $tg, which release_test.txt does not run") }
        elseif (-not $scriptOf.ContainsKey($tg) -or -not $scriptOf[$tg].Contains($phrase)) { $problems.Add("'$feat': $tg has no check with the words ""$phrase"" (the check was removed or reworded: fix the row)") }
    }
    elseif ($check -match '^rt_') { $problems.Add("'$feat': Check '$check' is not in the form rt_tag: ""words""") }
    # 2. the owning files
    $owners = @()
    if ($own -match '^as above') { $owners = $prevOwners }
    else {
        # (a cell may list several: "A.lua, B.lua", "CW / HealthTab.lua", "AdminTab.lua -> ZeD_SandboxInGame.lua")
        foreach ($tok in ($own -split ',| / | -> |;')) {
            $t = $tok.Trim() -replace '`', '' -replace ':\d+.*$', '' -replace '\s*\(.*$', ''
            if ($abbr.ContainsKey($t)) { $t = $abbr[$t] }
            if ($t -match '\.lua$') { $owners += ($t -replace '^42/media/lua/client/ZeD/', '' -replace '^(42/media/lua/)?shared/ZeD/', 'shared/') }
        }
    }
    $prevOwners = $owners
    foreach ($o in $owners) {
        if ($o.StartsWith($AP)) { $mapNamesAddon = $true }
        $hit = Find-Owned $o
        if ($hit.Count -eq 0) {
            if ($o.StartsWith($AP) -and -not $addonRoot) { $problems.Add("'$feat': its owning file $o is in the add-on ZeD-GUI: Loadouts, which is not beside ZeD-UI (mods\ZeD-Loadouts)") }
            else { $problems.Add("'$feat': its owning file $o is gone (a removed feature: take the row and its check out)") }
        }
        else { foreach ($h in $hit) { $owned[$h] = $true } }
    }
    # files named in the entry column count as owned too (a function in another file; "ZeD-Loadouts/<file>" the add-on's)
    foreach ($m in [regex]::Matches($entry, '((?:ZeD-Loadouts/)?[A-Za-z0-9_/]+\.lua)')) {
        $o = $m.Groups[1].Value -replace '^42/media/lua/client/ZeD/', '' -replace '^(42/media/lua/)?shared/ZeD/', 'shared/'
        foreach ($h in (Find-Owned $o)) { $owned[$h] = $true }
    }
    # 2b. the entry functions: at least one named function still in the code
    $names = @([regex]::Matches($entry, '`([^`]+)`') | ForEach-Object {
        $n = $_.Groups[1].Value -replace '\(.*$', ''
        ($n -split '[.:]')[-1]
    } | Where-Object { $_ -match '^[A-Za-z_][A-Za-z0-9_]{3,}$' })
    if ($names.Count -gt 0) {
        $any = $false
        foreach ($n in $names) { if ($text -match ('\b' + [regex]::Escape($n) + '\b')) { $any = $true; break } }
        if (-not $any) { $problems.Add("'$feat': none of its entry functions are in the code any more ($($names -join ', ')): removed or renamed; fix the row or take it out") }
    }
}

# ---- 3. files no row owns, less the plumbing list
$plumb = @()
if (Test-Path $plumbFile) { $plumb = @(Get-Content $plumbFile | Where-Object { $_ -match '^\s*[^#\s]' } | ForEach-Object { ($_ -split '\s+#')[0].Trim() }) }
foreach ($f in $files) {
    # (the add-on's files are held to a row once the map names the add-on's tree: the Loadouts split's map)
    if ($f.StartsWith($AP) -and -not $mapNamesAddon) { continue }
    if (-not $owned.ContainsKey($f) -and $plumb -notcontains $f) { $problems.Add("$f is owned by no feature row and is not plumbing: a feature added without a row in FEATURE_MAP.md?") }
}
foreach ($p in $plumb) { if ($files -notcontains $p) { $problems.Add("plumbing list names $p, which is gone: take it off rt_coverage_plumbing.txt") } }

$aSum = $(if ($addonRoot) { " + $($addonFiles.Count) ZeD-GUI: Loadouts files$(if (-not $mapNamesAddon) { ' (not in the map yet)' })" } else { "" })
$sum = "rt_coverage: $rows feature rows, $($files.Count - $addonFiles.Count) ZeD files$aSum ($($owned.Count) owned by rows, $($plumb.Count) plumbing), $($problems.Count) problem(s)"
if (-not $Quiet -or $problems.Count -gt 0) { foreach ($p in $problems) { "FAIL $p" } }
$sum
if ($problems.Count -gt 0) { exit 1 } else { exit 0 }
