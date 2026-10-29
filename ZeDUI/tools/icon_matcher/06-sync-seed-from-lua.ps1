# 06-sync-seed-from-lua.ps1
# Regenerates the SEEDED_ASSIGNMENTS block in vanilla-catalog.html from the
# authoritative ContextIcons.lua mapping, and bumps SEED_VERSION so browsers
# with cached assignments automatically re-seed on next load.
#
# Rationale: the HTML tool previously hard-coded fi-br-* prefixed icon
# assignments that pre-date the SmashIcons migration. Opening the tool fresh
# seeded stale names, and any edits exported Lua that used out-of-date icons.
# This script makes the Lua file the single source of truth and reflects it
# back into the tool, so opening the tool shows your current reality.
#
# Idempotent: safe to re-run after any ContextIcons.lua edit. Also upgrades
# loadAssignments() on first run to version-check against SEED_VERSION; later
# runs leave that function unchanged.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$luaPath   = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\lua\shared\ZeD\ContextIcons.lua"
$htmlPath  = Join-Path $scriptDir "vanilla-catalog.html"

if (-not (Test-Path $luaPath))  { Write-Host "Lua file not found: $luaPath" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $htmlPath)) { Write-Host "HTML file not found: $htmlPath" -ForegroundColor Red; exit 1 }

# ---- Parse ContextIcons.lua -------------------------------------------------
# Regex captures every ["Action Name"] = "icon-name" entry. Ignores comments
# and the file-level table wrapper. Multiple entries per line would work too
# but the Lua file is one-per-line by convention.
$lua     = Get-Content $luaPath -Raw
$entries = [regex]::Matches($lua, '\["([^"]+)"\]\s*=\s*"([^"]+)"')
if ($entries.Count -eq 0) {
    Write-Host "No ContextIcons entries found in $luaPath. Aborting." -ForegroundColor Red
    exit 1
}

# ---- Build JS SEEDED_ASSIGNMENTS block --------------------------------------
# Preserve Lua insertion order so diffs against the prior seed stay readable.
# JS-escape quotes and backslashes defensively even though the Lua file's
# keys/values don't currently contain either.
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("const SEEDED_ASSIGNMENTS={")
for ($i = 0; $i -lt $entries.Count; $i++) {
    $k = $entries[$i].Groups[1].Value -replace '\\', '\\' -replace '"', '\"'
    $v = $entries[$i].Groups[2].Value -replace '\\', '\\' -replace '"', '\"'
    $comma = if ($i -lt $entries.Count - 1) { "," } else { "" }
    [void]$sb.AppendLine("  `"$k`":`"$v`"$comma")
}
[void]$sb.Append("};")
$newBlock    = $sb.ToString()
$seedVersion = Get-Date -Format "yyyyMMdd-HHmmss"

# ---- Splice into HTML -------------------------------------------------------
$html = [System.IO.File]::ReadAllText($htmlPath)

# Replace the full SEEDED_ASSIGNMENTS block. `(?s)` makes `.` match newlines.
# `.*?` is non-greedy so we stop at the first `};`. The HTML has exactly one
# such block today.
$blockPattern = '(?s)const SEEDED_ASSIGNMENTS=\{.*?\};'
$blockRegex   = [regex]::new($blockPattern)
if (-not $blockRegex.IsMatch($html)) {
    Write-Host "SEEDED_ASSIGNMENTS block not found in HTML. Did the tool change shape?" -ForegroundColor Red
    exit 1
}
$html = $blockRegex.Replace($html, $newBlock, 1)

# Inject / update SEED_VERSION immediately above SEEDED_ASSIGNMENTS.
$versionLine = "const SEED_VERSION='$seedVersion';"
$vPattern    = "const SEED_VERSION='[^']*';"
$vRegex      = [regex]::new($vPattern)
if ($vRegex.IsMatch($html)) {
    $html = $vRegex.Replace($html, $versionLine, 1)
} else {
    # First run: inject right before SEEDED_ASSIGNMENTS=. The \r\n keeps
    # Windows line endings consistent with the rest of the file.
    $html = $html -replace '(const SEEDED_ASSIGNMENTS=)', "$versionLine`r`n`$1"
}

# ---- Upgrade loadAssignments() to honor SEED_VERSION ------------------------
# Original body loads localStorage unconditionally — meaning a user with any
# cached assignments never sees a fresh seed even after this script runs. New
# body compares the stored version string; if mismatched, we drop cache and
# re-seed. Idempotent: the replace is a no-op once the upgraded body is in.
$oldLoad = @'
function loadAssignments(){
  try{
    const stored=localStorage.getItem('zed-vanilla-assignments');
    if(stored){assignments=JSON.parse(stored);}
    else if(typeof SEEDED_ASSIGNMENTS!=='undefined'&&Object.keys(SEEDED_ASSIGNMENTS).length){
      // Only seed vanilla texKeys (those that exist in ICON_INDEX)
      const seeded={};
      for(const [k,v] of Object.entries(SEEDED_ASSIGNMENTS)){
        if(TEX_LOOKUP.has(v))seeded[k]=v;
      }
      if(Object.keys(seeded).length){assignments=seeded;saveAssignments();}
      else{assignments={};}
    }else{assignments={};}
  }catch(e){assignments={};}
}
'@

$newLoad = @'
function loadAssignments(){
  try{
    const stored=localStorage.getItem('zed-vanilla-assignments');
    const storedVer=localStorage.getItem('zed-vanilla-seed-version');
    // Honor stored assignments only when their seed version matches the
    // current build. A SEED_VERSION bump (from 06-sync-seed-from-lua.ps1)
    // forces a reseed so ContextIcons.lua edits appear in the tool.
    if(stored&&storedVer===SEED_VERSION){assignments=JSON.parse(stored);}
    else if(typeof SEEDED_ASSIGNMENTS!=='undefined'&&Object.keys(SEEDED_ASSIGNMENTS).length){
      const seeded={};
      for(const [k,v] of Object.entries(SEEDED_ASSIGNMENTS)){
        if(TEX_LOOKUP.has(v))seeded[k]=v;
      }
      if(Object.keys(seeded).length){
        assignments=seeded;
        saveAssignments();
        localStorage.setItem('zed-vanilla-seed-version',SEED_VERSION);
      }else{assignments={};}
    }else{assignments={};}
  }catch(e){assignments={};}
}
'@

if ($html.Contains($oldLoad)) {
    $html = $html.Replace($oldLoad, $newLoad)
    $loadMsg = "Upgraded loadAssignments() to honor SEED_VERSION."
} else {
    $loadMsg = "loadAssignments() already version-aware (skipped)."
}

[System.IO.File]::WriteAllText($htmlPath, $html)

# ---- Report -----------------------------------------------------------------
Write-Host ""
Write-Host "=== Seed Sync Complete ===" -ForegroundColor Cyan
Write-Host "Lua file       : $luaPath" -ForegroundColor Gray
Write-Host "HTML file      : $htmlPath" -ForegroundColor Gray
Write-Host "Entries seeded : $($entries.Count)" -ForegroundColor Green
Write-Host "SEED_VERSION   : $seedVersion" -ForegroundColor Green
Write-Host "$loadMsg" -ForegroundColor Cyan
Write-Host ""
Write-Host "The tool will auto-reseed next time it's opened; no manual" -ForegroundColor Yellow
Write-Host "localStorage clear is needed. Bump Lua -> rerun this script." -ForegroundColor Yellow
