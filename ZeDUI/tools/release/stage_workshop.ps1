#Requires -Version 7.0
<#
.SYNOPSIS
    Stages ZeD UI for a Steam Workshop upload (Oct 19 2026).

.DESCRIPTION
    Builds Zomboid/Workshop/ZeD-UI/ from the mod folder (Zomboid/mods/ZeD-UI):

        Workshop/ZeD-UI/
            preview.png                 (copied from ZeDUI/tools/release/preview.png)
            workshop.txt                (NOT written here: ZeD's upload window writes it)
            Contents/mods/ZeD-UI/
                42/...                  (the version folder, game files only)
                common/                 (shared folder; B42 layout)

    Only the mod goes up. At the root of the mod folder that is the version
    folders (names like 42 or 42.13) and common/; everything else there
    (.git, .claude, ZeDUI/, archive/, reference/, the .md / .html / .lnk files)
    is the project. Inside those folders the rules below leave out what the
    game never reads (tools, notes, test and backup art, dev-only Lua).

    Root mod.info: not needed and not made. Read from the game's own code
    (42.21.0 projectzomboid.jar): the mod list finds a mod by common/mod.info
    or <version folder>/mod.info (ZomboidFileSystem.getAllModFoldersAux), and
    the upload check (SteamWorkshopItem.validateModFolder) reads only those
    two places. A root mod.info is the Build 41 layout; adding one would make
    Build 41 offer the mod.

    Mirror: Workshop/ZeD-UI/Contents/ is deleted and rebuilt on every run, so
    files removed from the mod do not linger. workshop.txt is kept: after the
    first upload it holds the item's Workshop id, and without it the next
    Upload would create a second item.

    Refuses to run while the repo has a merge, rebase or cherry-pick in
    progress or conflicted files, or when 42/ (or 42/mod.info) is missing.
    Warns, but stages anyway, when 42/ or common/ have uncommitted changes:
    the working tree is what goes up.

.PARAMETER Version
    Stamps modversion= in the STAGED mod.info files only (the repo's 42/mod.info
    is never touched). Letters, digits and . _ + - only.

.PARAMETER DryRun
    Lists what would be copied, with sizes, and what is left out and why.
    Writes nothing.

.PARAMETER KeepDevTools
    Also ship the dev-only Lua (the F6 test window and the -debug QA bridge).

.EXAMPLE
    & C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/release/stage_workshop.ps1 -DryRun
.EXAMPLE
    & C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-test1
#>
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$DryRun,
    [switch]$KeepDevTools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$ModRoot   = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))         # .../Zomboid/mods/ZeD-UI
$ModFolder = Split-Path $ModRoot -Leaf                                            # ZeD-UI
$Zomboid   = [IO.Path]::GetFullPath((Join-Path $ModRoot '../..'))                 # .../Zomboid
$WsRoot    = Join-Path $Zomboid 'Workshop'
$ItemName  = 'ZeD-UI'
$Item      = Join-Path $WsRoot $ItemName
$Contents  = Join-Path $Item 'Contents'
$Stage     = Join-Path $Contents (Join-Path 'mods' $ModFolder)
$Preview   = Join-Path $PSScriptRoot 'preview.png'

function Fail([string]$msg) { Write-Host "REFUSED: $msg" -ForegroundColor Red; exit 1 }
function Warn([string]$msg) { Write-Host "WARNING: $msg" -ForegroundColor Yellow }
function Mb([double]$b) { '{0:N2} MB' -f ($b / 1MB) }

# ---------------------------------------------------------------------------
# What is left out (first matching rule names the reason)
#   $rel is the path inside the mod folder with forward slashes, e.g.
#   42/media/lua/client/ZeD/QABridge.lua
# ---------------------------------------------------------------------------
$ProjectDirs = @('.git', '.claude', '.vscode', '.idea', '__pycache__', '.svn')
$LitterNames = @('Thumbs.db', 'desktop.ini', '.DS_Store')
$ToolExts = @(
    '.py', '.pyc', '.pyo', '.ps1', '.psm1', '.psd1', '.bat', '.cmd', '.sh',     # tools
    '.md', '.html', '.htm', '.lnk', '.pdf', '.docx',                            # docs
    '.psd', '.kra', '.ase', '.aseprite', '.xcf', '.svg', '.ai', '.blend',       # art sources
    '.bak', '.orig', '.tmp', '.log',                                            # scratch
    '.zip', '.7z', '.rar', '.exe', '.dll', '.so', '.dylib', '.app'              # archives / binaries (the Workshop refuses several)
)
# Lua the game would load but players should not get: the F6 inventory test
# window (its header: "safe to remove from Workshop builds") and the -debug QA
# bridge that runs Zomboid/Lua/zedqa.lua. Nothing requires either.
$DevOnlyLua = @(
    '42/media/lua/client/ZeD/TestInventory.lua',
    '42/media/lua/client/ZeD/QABridge.lua'
)
# The Workshop's own refusal list (SteamWorkshopItem.validateFileTypes), checked on the result.
$WorkshopRefused = @('.exe', '.dll', '.bat', '.app', '.dylib', '.sh', '.so', '.zip')

function Get-ExcludeReason([string]$rel, [string[]]$topFiles) {
    $segs = $rel.Split('/')
    $name = $segs[-1]
    $ext  = [IO.Path]::GetExtension($name).ToLowerInvariant()
    foreach ($s in $segs[0..($segs.Count - 2)]) { if ($ProjectDirs -contains $s) { return "project folder ($s)" } }
    if ($LitterNames -contains $name -or $name.StartsWith('~$') -or $name.EndsWith('~')) { return 'OS / editor litter' }
    if ($ToolExts -contains $ext) { return "tool, doc or source file ($ext): the game does not read it" }
    if ($segs.Count -eq 2) {
        if ($topFiles -notcontains $name) { return 'loose file beside media/: the game reads only mod.info and its poster / icon there' }
    } elseif ($segs[1] -ne 'media') {
        return "outside media/ ($($segs[0])/$($segs[1])/): the game does not read it"
    }
    if ($rel -like '*/media/textures/*' -and $name -like 'test_*') { return 'test texture (test_*)' }
    if ($rel -like '*/media/textures/*' -and ($segs | Where-Object { $_ -like 'originals*' })) { return 'backup art (an originals* folder)' }
    if (-not $KeepDevTools -and $DevOnlyLua -contains $rel) { return 'dev-only Lua (use -KeepDevTools to ship it)' }
    return $null
}

# ---------------------------------------------------------------------------
# Checks before anything happens
# ---------------------------------------------------------------------------
$v42 = Join-Path $ModRoot '42'
if (-not (Test-Path -LiteralPath $v42 -PathType Container)) { Fail "$v42 is missing" }
if (-not (Test-Path -LiteralPath (Join-Path $v42 'mod.info') -PathType Leaf)) { Fail "$v42/mod.info is missing" }
if ($Version -and $Version -notmatch '^[A-Za-z0-9._+-]+$') { Fail "-Version '$Version': use letters, digits and . _ + - only" }

$git = Get-Command git -ErrorAction SilentlyContinue
$dirty = @()
if ($git) {
    foreach ($marker in 'MERGE_HEAD', 'rebase-merge', 'rebase-apply', 'CHERRY_PICK_HEAD') {
        $p = (& git -C $ModRoot rev-parse --git-path $marker 2>$null)
        if ($LASTEXITCODE -eq 0 -and $p) {
            if (-not [IO.Path]::IsPathRooted($p)) { $p = Join-Path $ModRoot $p }
            if (Test-Path -LiteralPath $p) { Fail "the repo has a merge in progress ($marker); finish or abort it first" }
        }
    }
    $unmerged = @(& git -C $ModRoot ls-files -u 2>$null)
    if ($unmerged.Count -gt 0) { Fail 'the repo has conflicted (unmerged) files' }
    $dirty = @(& git -C $ModRoot status --porcelain -- 42 common 2>$null)
} elseif (Test-Path -LiteralPath (Join-Path $ModRoot '.git/MERGE_HEAD')) {
    Fail 'the repo has a merge in progress (MERGE_HEAD); finish or abort it first'
}

# ---------------------------------------------------------------------------
# Collect: the version folders and common/ from the root; nothing else there
# ---------------------------------------------------------------------------
$rootDirs = Get-ChildItem -LiteralPath $ModRoot -Directory -Force |
    Where-Object { $_.Name -eq 'common' -or $_.Name -match '^\d+(\.\d+)*$' } | Sort-Object Name
$skippedRoot = Get-ChildItem -LiteralPath $ModRoot -Force |
    Where-Object { $rootDirs.Name -notcontains $_.Name } | ForEach-Object { if ($_.PSIsContainer) { "$($_.Name)/" } else { $_.Name } }

$copy = [System.Collections.Generic.List[object]]::new()
$excl = [System.Collections.Generic.List[object]]::new()
$modInfos = @()
foreach ($d in $rootDirs) {
    # mod.info and the poster / icon it names may sit beside media/
    $top = @('mod.info')
    $mi = Join-Path $d.FullName 'mod.info'
    if (Test-Path -LiteralPath $mi) {
        $modInfos += "$($d.Name)/mod.info"
        foreach ($line in Get-Content -LiteralPath $mi) {
            if ($line -match '^\s*(poster|icon)\s*=\s*(.+?)\s*$') { $top += $Matches[2] }
        }
    }
    foreach ($f in Get-ChildItem -LiteralPath $d.FullName -Recurse -File -Force) {
        $rel = [IO.Path]::GetRelativePath($ModRoot, $f.FullName).Replace('\', '/')
        $why = Get-ExcludeReason $rel $top
        $row = [pscustomobject]@{ Rel = $rel; Size = $f.Length; Full = $f.FullName; Why = $why }
        if ($why) { $excl.Add($row) } else { $copy.Add($row) }
    }
}
$copy = @($copy | Sort-Object Rel)

$bad = @($copy | Where-Object { $WorkshopRefused -contains [IO.Path]::GetExtension($_.Rel).ToLowerInvariant() -and $_.Rel -notlike '*pyramid.zip' })
if ($bad.Count -gt 0) { Fail ("the Workshop refuses these file types: " + ($bad.Rel -join ', ')) }

$emptyCommon = (Test-Path -LiteralPath (Join-Path $ModRoot 'common')) -and -not ($copy | Where-Object { $_.Rel -like 'common/*' })

# the modversion that goes up
$srcInfo = Get-Content -LiteralPath (Join-Path $v42 'mod.info') -Raw
$srcVer = if ($srcInfo -match '(?m)^modversion=(.*?)\r?$') { $Matches[1] } else { '(none)' }
$upVer = if ($Version) { $Version } else { $srcVer }

# the preview picture: Steam wants a 256 x 256 PNG of 1000 KB at most
function Test-Preview([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return 'missing (run make_preview.py)' }
    $b = [IO.File]::ReadAllBytes($path)
    if ($b.Length -gt 1000KB) { return "too big ($($b.Length) bytes; 1000 KB at most)" }
    if ($b.Length -lt 24 -or $b[0] -ne 0x89 -or $b[1] -ne 0x50 -or $b[2] -ne 0x4E -or $b[3] -ne 0x47) { return 'not a PNG' }
    $w = ([int]$b[16] -shl 24) -bor ([int]$b[17] -shl 16) -bor ([int]$b[18] -shl 8) -bor [int]$b[19]
    $h = ([int]$b[20] -shl 24) -bor ([int]$b[21] -shl 16) -bor ([int]$b[22] -shl 8) -bor [int]$b[23]
    if ($w -ne 256 -or $h -ne 256) { return "${w} x ${h} (must be 256 x 256)" }
    return $null
}
$previewProblem = Test-Preview $Preview

# ---------------------------------------------------------------------------
# Dry run: the lists, nothing written
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host "DRY RUN: nothing is written. Would build $Stage" -ForegroundColor Cyan
    Write-Host ''
    Write-Host "WOULD COPY ($($copy.Count) files):"
    foreach ($r in $copy) { '{0,12:N0}  {1}' -f $r.Size, $r.Rel }
}

Write-Host ''
Write-Host "LEFT OUT at the root (project, not mod): $($skippedRoot -join '  ')"
Write-Host "LEFT OUT inside the mod ($($excl.Count) files):"
foreach ($g in ($excl | Group-Object Why | Sort-Object Name)) {
    Write-Host "  $($g.Name): $($g.Count)"
    if ($DryRun -or $g.Count -le 12) {
        foreach ($r in ($g.Group | Sort-Object Rel)) { '    {0,10:N0}  {1}' -f $r.Size, $r.Rel }
    } else {
        $dirs = $g.Group | ForEach-Object { ($_.Rel -split '/')[0..(($_.Rel -split '/').Count - 2)] -join '/' } | Sort-Object -Unique
        foreach ($dd in $dirs) { "    $dd/ ($(@($g.Group | Where-Object { $_.Rel -like "$dd/*" }).Count) files)" }
    }
}

if ($dirty.Count -gt 0) {
    Write-Host ''
    Warn "$($dirty.Count) uncommitted change(s) under 42/ or common/: the working tree goes up as it is (another session's work included). Commit or set aside first if that is not wanted."
    foreach ($l in ($dirty | Select-Object -First 12)) { "    $l" }
    if ($dirty.Count -gt 12) { "    ... and $($dirty.Count - 12) more (git status -- 42 common)" }
}

# ---------------------------------------------------------------------------
# The real run
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    # the wipe stays inside Zomboid/Workshop/<item>/Contents
    $full = [IO.Path]::GetFullPath($Contents)
    if (-not $full.StartsWith([IO.Path]::GetFullPath($WsRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        Fail "staging path $full is not inside $WsRoot"
    }
    if (Test-Path -LiteralPath $Contents) { Remove-Item -LiteralPath $Contents -Recurse -Force }
    [void][IO.Directory]::CreateDirectory($Stage)

    foreach ($r in $copy) {
        $dest = Join-Path $Stage $r.Rel
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest))
        [IO.File]::Copy($r.Full, $dest, $true)
    }
    foreach ($d in $rootDirs) { [void][IO.Directory]::CreateDirectory((Join-Path $Stage $d.Name)) }   # empty ones too

    # Steam does not carry empty folders; early Build 42 builds would not list a mod
    # without common/. One small note keeps the folder (42.21 itself does not need it).
    if ($emptyCommon) {
        [IO.File]::WriteAllText((Join-Path $Stage 'common/placeholder.txt'),
            "ZeD UI keeps its files in 42/. This file only keeps common/ in the Workshop upload.`r`n",
            [Text.UTF8Encoding]::new($false))
    }

    if ($Version) {
        foreach ($m in $modInfos) {
            $p = Join-Path $Stage $m
            $t = [IO.File]::ReadAllText($p)
            if ($t -match '(?m)^modversion=') {
                $t = [regex]::Replace($t, '(?m)^modversion=.*?(\r?)$', { param($mm) "modversion=$Version" + $mm.Groups[1].Value })
            } else {
                $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
                if ($t.Length -gt 0 -and -not $t.EndsWith("`n")) { $t += $nl }
                $t += "modversion=$Version$nl"
            }
            [IO.File]::WriteAllText($p, $t, [Text.UTF8Encoding]::new($false))
        }
    }

    if ($previewProblem) { Warn "preview.png $previewProblem; not copied (the Workshop will not take the item without it)" }
    else { Copy-Item -LiteralPath $Preview -Destination (Join-Path $Item 'preview.png') -Force }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$total = ($copy | Measure-Object Size -Sum).Sum
if ($null -eq $total) { $total = 0 }
$wsTxt = Join-Path $Item 'workshop.txt'
$wsId = $null
if (Test-Path -LiteralPath $wsTxt) {
    $m = Select-String -LiteralPath $wsTxt -Pattern '^id=(\d+)' | Select-Object -First 1
    if ($m) { $wsId = $m.Matches[0].Groups[1].Value }
}

Write-Host ''
Write-Host '== SUMMARY ==' -ForegroundColor Cyan
"  {0} {1}" -f ($(if ($DryRun) { 'would stage' } else { 'staged' })), $Stage
"  files:       {0}{1}" -f $copy.Count, $(if ($emptyCommon) { ' (+ common/placeholder.txt)' } else { '' })
"  total:       {0} ({1:N0} bytes)" -f (Mb $total), $total
"  modversion:  {0}{1}" -f $upVer, $(if ($Version) { " (stamped in the staged copy; the repo keeps $srcVer)" } else { ' (as in the repo)' })
"  mod.info:    {0}" -f ($modInfos -join ', ')
"  dev tools:   {0}" -f $(if ($KeepDevTools) { 'shipped (-KeepDevTools)' } else { 'left out' })
"  preview.png: {0}" -f $(if ($previewProblem) { $previewProblem } else { '256 x 256 PNG, ok' + $(if ($DryRun) { '' } else { ' (copied into the item folder)' }) })
"  workshop.txt: {0}" -f $(if ($wsId) { "kept; item id $wsId (Upload updates that item)" } elseif (Test-Path -LiteralPath $wsTxt) { 'kept; no id yet (the first Upload creates the item)' } else { 'none yet (ZeD''s upload window writes it on Save)' })
'  biggest files:'
foreach ($r in ($copy | Sort-Object Size -Descending | Select-Object -First 10)) { '    {0,10}  {1}' -f (Mb $r.Size), $r.Rel }
exit 0
