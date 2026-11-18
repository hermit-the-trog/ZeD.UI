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
      4. a row names an rt_ script tag that release_test.txt does not run.
    zedqa_run.ps1 runs this first for the release test and will not start the game while it fails.
      pwsh -File ZeDUI/tools/qa/rt_coverage.ps1            (exit 0 clean, 1 with the problems listed)
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

# ---- the code: every ZeD Lua file, and all of its text for the function search
$files = @(Get-ChildItem $client, $shared -Recurse -Filter *.lua | ForEach-Object {
    $rel = $_.FullName.Substring($client.Length + 1)
    if ($_.FullName.StartsWith($shared)) { $rel = "shared/" + $_.FullName.Substring($shared.Length + 1) }
    $rel.Replace('\', '/')
})
$text = (Get-ChildItem $client, $shared -Recurse -Filter *.lua | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"

# ---- the release test's tags
$tags = @(Get-Content (Join-Path $qa "release_test.txt") | Where-Object { $_ -match '^\s*[^#\s].*\|' } |
    ForEach-Object { ($_ -split '\|')[1].Trim() })

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
    # 4. an rt_ tag the release test does not run
    if ($check -match '^(rt_[a-z_]+)$' -and $tags -notcontains $Matches[1]) { $problems.Add("'$feat': Check names $($Matches[1]), which release_test.txt does not run") }
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
        $hit = @($files | Where-Object { $_ -eq $o -or $_.EndsWith("/" + $o) })
        if ($hit.Count -eq 0) { $problems.Add("'$feat': its owning file $o is gone (a removed feature: take the row and its check out)") }
        else { foreach ($h in $hit) { $owned[$h] = $true } }
    }
    # files named in the entry column count as owned too (a function in another file)
    foreach ($m in [regex]::Matches($entry, '([A-Za-z0-9_/]+\.lua)')) {
        $o = $m.Groups[1].Value -replace '^42/media/lua/client/ZeD/', '' -replace '^(42/media/lua/)?shared/ZeD/', 'shared/'
        foreach ($h in @($files | Where-Object { $_ -eq $o -or $_.EndsWith("/" + $o) })) { $owned[$h] = $true }
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
    if (-not $owned.ContainsKey($f) -and $plumb -notcontains $f) { $problems.Add("$f is owned by no feature row and is not plumbing: a feature added without a row in FEATURE_MAP.md?") }
}
foreach ($p in $plumb) { if ($files -notcontains $p) { $problems.Add("plumbing list names $p, which is gone: take it off rt_coverage_plumbing.txt") } }

$sum = "rt_coverage: $rows feature rows, $($files.Count) ZeD files ($($owned.Count) owned by rows, $($plumb.Count) plumbing), $($problems.Count) problem(s)"
if (-not $Quiet -or $problems.Count -gt 0) { foreach ($p in $problems) { "FAIL $p" } }
$sum
if ($problems.Count -gt 0) { exit 1 } else { exit 0 }
