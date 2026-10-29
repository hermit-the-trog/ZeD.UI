# 04-build-vanilla-catalog.ps1
# Builds vanilla-catalog.html -- ZeD-UI PZ Vanilla Icon Assignment Tool
# No server needed -- open the output HTML directly in your browser.
# Images load via relative path: vanilla-icons/{filename}.png

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$vanillaDir = Join-Path $scriptDir "vanilla-icons"
$outputPath = Join-Path $scriptDir "vanilla-catalog.html"
$luaPath    = "C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\lua\shared\ZeD\ContextIcons.lua"

if (-not (Test-Path $vanillaDir)) {
    Write-Host "ERROR: vanilla-icons folder not found at $vanillaDir" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning vanilla-icons..." -ForegroundColor Cyan

# Compound prefixes that must NOT be split at the first underscore
$compoundPrefixes = @("Item_TZ","WItem_TZ","Item_Magazine","Item_Seeds","Item_Fish")

function Get-VanillaCategory($baseName) {
    foreach ($pfx in $compoundPrefixes) {
        if ($baseName.StartsWith($pfx + "_")) { return $pfx }
    }
    return ($baseName -split '_')[0]
}

$files     = Get-ChildItem $vanillaDir -Filter "*.png" | Sort-Object Name
$iconList  = [System.Collections.Generic.List[hashtable]]::new()
$catCounts = @{}

foreach ($f in $files) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $cat  = Get-VanillaCategory $base
    $desc = if ($base.Length -gt ($cat.Length + 1)) {
        $base.Substring($cat.Length + 1) -replace '_', ' '
    } else { $base }
    $iconList.Add(@{ file=$f.Name; cat=$cat; name=$desc; texKey=$base })
    $catCounts[$cat] = ($catCounts[$cat] -as [int]) + 1
}

Write-Host "Found $($iconList.Count) icons across $($catCounts.Count) categories" -ForegroundColor Green

# --- Serialize icon array to JS ---
Write-Host "Serializing icon data..." -ForegroundColor Cyan
$sb = [System.Text.StringBuilder]::new()
[void]$sb.Append("`nconst VANILLA_ICONS=[`n")
for ($i = 0; $i -lt $iconList.Count; $i++) {
    $ic    = $iconList[$i]
    $comma = if ($i -lt $iconList.Count - 1) { ',' } else { '' }
    $file  = $ic.file    -replace '"','\"'
    $cat   = $ic.cat     -replace '"','\"'
    $nm    = $ic.name    -replace '"','\"'
    $tex   = $ic.texKey  -replace '"','\"'
    [void]$sb.Append("{f:`"$file`",c:`"$cat`",n:`"$nm`",t:`"$tex`"}$comma`n")
}
[void]$sb.Append("];`n")

$catEntries = ($catCounts.GetEnumerator() | Sort-Object Name |
    ForEach-Object { "`"$($_.Key)`":$($_.Value)" }) -join ","
[void]$sb.Append("const VANILLA_CATS={$catEntries};`n")
$iconDataJs = $sb.ToString()

# --- SEEDED_ASSIGNMENTS from ContextIcons.lua ---
$seededJs = "const SEEDED_ASSIGNMENTS={};"
if (Test-Path $luaPath) {
    $lua = Get-Content $luaPath -Raw
    $seen = @{}
    $pairs = [regex]::Matches($lua, '\["([^"]+)"\]\s*=\s*"([^"]+)"') |
        ForEach-Object {
            $k = $_.Groups[1].Value; $v = $_.Groups[2].Value
            if (-not $seen.ContainsKey($k)) { $seen[$k] = $v; "`"$k`":`"$v`"" }
        } | Where-Object { $_ }
    if ($pairs) {
        $seededJs = "const SEEDED_ASSIGNMENTS={`n  " + ($pairs -join ",`n  ") + "`n};"
        Write-Host "Seeded $($seen.Count) existing assignments from ContextIcons.lua" -ForegroundColor Cyan
    }
}

$totalIcons  = $iconList.Count
$totalCats   = $catCounts.Count
$vanillaRoot = $vanillaDir -replace '\\', '\\\\'  # escaped for JS string literal

# =============================================================================
# HTML TEMPLATE
# =============================================================================
$htmlTop = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Vanilla PZ x ZeD-UI // Icon Assignment Tool</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@300;400;500;600&family=Fira+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
:root{
  --bg0:#0a0b0d;--bg1:#12141a;--bg2:#1a1d26;--bg3:#232733;
  --border:#2a2e3a;--border-hi:#3a3f50;
  --text0:#e8e9ed;--text1:#b0b3be;--text2:#6e7283;
  --accent:#4a9eff;--accent-dim:#2a5a99;--accent-glow:rgba(74,158,255,0.15);
  --green:#4ae08a;--warning:#f5a623;--danger:#e05252;
  --mono:'Fira Mono',monospace;--sans:'Fira Sans',sans-serif;
  --pv-bg:#131313;--pv-surf:#1a1a1a;--pv-surf2:#222222;
  --pv-border:#2a2a2a;--pv-text:rgb(199,199,199);--pv-text-dim:rgba(150,150,150,.55);
  --pv-accent:#D4922A;--pv-accent-glow:rgba(212,146,42,.18);
}
[data-pv="dark"] {--pv-bg:#131313;--pv-surf:#1a1a1a;--pv-surf2:#222222;--pv-border:#2a2a2a;--pv-text:rgb(199,199,199);--pv-text-dim:rgba(150,150,150,.55);}
[data-pv="light"]{--pv-bg:#e8e6e0;--pv-surf:#dddbd5;--pv-surf2:#d0cec8;--pv-border:#b0aea8;--pv-text:rgb(41,38,36);--pv-text-dim:rgba(89,87,82,.70);}
[data-pv="hicon"]{--pv-bg:#0a0a0a;--pv-surf:#141414;--pv-surf2:#1e1e1e;--pv-border:#555555;--pv-text:rgb(255,255,255);--pv-text-dim:rgba(199,199,199,.75);}
[data-pva="orange"]{--pv-accent:#D4922A;--pv-accent-glow:rgba(212,146,42,.18);}
[data-pva="red"]   {--pv-accent:#CC4444;--pv-accent-glow:rgba(204,68,68,.18);}
[data-pva="yellow"]{--pv-accent:#CCAA22;--pv-accent-glow:rgba(204,170,34,.18);}
[data-pva="green"] {--pv-accent:#44AA44;--pv-accent-glow:rgba(68,170,68,.18);}
[data-pva="blue"]  {--pv-accent:#4488CC;--pv-accent-glow:rgba(68,136,204,.18);}
[data-pva="teal"]  {--pv-accent:#47A18C;--pv-accent-glow:rgba(71,161,140,.18);}
[data-pva="purple"]{--pv-accent:#8855BB;--pv-accent-glow:rgba(136,85,187,.18);}
[data-pva="pink"]  {--pv-accent:#DD5588;--pv-accent-glow:rgba(221,85,136,.18);}
[data-pva="mono"]  {--pv-accent:#888888;--pv-accent-glow:rgba(136,136,136,.18);}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{font-family:var(--sans);background:var(--bg0);color:var(--text0);height:100vh;display:flex;flex-direction:column;overflow:hidden;}
.header{display:flex;align-items:center;gap:16px;padding:8px 16px;background:var(--bg1);border-bottom:1px solid var(--border);flex-shrink:0;min-height:42px;}
.header-title{font-family:var(--mono);font-size:13px;font-weight:600;color:var(--accent);white-space:nowrap;}
.header-title span{color:var(--text2);font-weight:300;}
.header-stats{font-family:var(--mono);font-size:11px;color:var(--text2);}
.header-stats b{color:var(--green);}
.vanillatag{font-family:var(--mono);font-size:9px;padding:2px 7px;background:rgba(71,161,140,.12);border:1px solid rgba(71,161,140,.35);border-radius:3px;color:#47A18C;white-space:nowrap;}
.main{display:flex;flex:1;overflow:hidden;}
.panel-library{width:310px;flex-shrink:0;display:flex;flex-direction:column;border-right:1px solid var(--border);background:var(--bg1);}
.lib-search{padding:7px 8px;border-bottom:1px solid var(--border);}
.lib-search input{width:100%;padding:5px 9px;background:var(--bg2);border:1px solid var(--border);border-radius:4px;color:var(--text0);font-family:var(--mono);font-size:12px;outline:none;}
.lib-search input:focus{border-color:var(--accent);}
.lib-search input::placeholder{color:var(--text2);}
.domain-strip{display:flex;flex-wrap:wrap;gap:3px;padding:5px 8px;border-bottom:1px solid var(--border);}
.dbtn{padding:3px 7px;background:var(--bg2);border:1px solid var(--border);border-radius:3px;color:var(--text2);font-family:var(--mono);font-size:9px;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;white-space:nowrap;transition:all .1s;}
.dbtn:hover{color:var(--text1);border-color:var(--border-hi);}
.dbtn.active{background:var(--accent-dim);border-color:var(--accent);color:var(--text0);}
.lib-body{display:flex;flex:1;overflow:hidden;}
.lib-sidebar{width:130px;flex-shrink:0;overflow-y:auto;border-right:1px solid var(--border);}
.cat-item{padding:4px 8px;cursor:pointer;border-left:2px solid transparent;display:flex;justify-content:space-between;align-items:center;}
.cat-item:hover{background:var(--bg2);}
.cat-item.active{background:var(--bg2);border-left-color:var(--accent);}
.cat-name{font-size:10px;color:var(--text1);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.cat-item.active .cat-name{color:var(--text0);}
.cat-count{font-family:var(--mono);font-size:9px;color:var(--text2);flex-shrink:0;margin-left:3px;}
.lib-grid-area{flex:1;overflow-y:auto;padding:6px;}
.icon-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(58px,1fr));gap:4px;}
.icon-card{background:var(--pv-surf);border:1px solid var(--pv-border);border-radius:4px;padding:5px 3px;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:3px;user-select:none;transition:border-color .1s,background .1s;}
.icon-card:hover{border-color:var(--pv-accent);background:var(--pv-surf2);}
.icon-card.selected{border-color:var(--pv-accent);background:var(--pv-accent-glow);box-shadow:0 0 0 1px var(--pv-accent);}
.ic-preview{width:38px;height:38px;display:flex;align-items:center;justify-content:center;background:var(--pv-surf2);border-radius:3px;overflow:hidden;}
.ic-preview img{width:30px;height:30px;object-fit:contain;}
.ic-name{font-size:9px;color:var(--pv-text-dim);text-align:center;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.2;max-height:2.4em;word-break:break-word;}
.panel-actions{flex:1;display:flex;flex-direction:column;border-right:1px solid var(--border);min-width:0;}
.actions-header{padding:7px 12px;border-bottom:1px solid var(--border);background:var(--bg1);display:flex;align-items:center;gap:8px;flex-shrink:0;}
.actions-title{font-family:var(--mono);font-size:11px;font-weight:600;color:var(--text1);text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;}
.assign-count{font-family:var(--mono);font-size:10px;padding:2px 6px;background:var(--bg3);border:1px solid var(--border);border-radius:3px;color:var(--text2);}
.assign-count b{color:var(--green);}
.actions-search{padding:5px 12px;border-bottom:1px solid var(--border);background:var(--bg1);flex-shrink:0;}
.actions-search input{width:100%;padding:4px 8px;background:var(--bg2);border:1px solid var(--border);border-radius:3px;color:var(--text0);font-family:var(--mono);font-size:11px;outline:none;}
.actions-search input:focus{border-color:var(--accent);}
.actions-search input::placeholder{color:var(--text2);}
.actions-domain-strip{display:flex;flex-wrap:wrap;gap:3px;padding:5px 12px;border-bottom:1px solid var(--border);flex-shrink:0;background:var(--bg1);}
.actions-list{flex:1;overflow-y:auto;}
.dg-header{display:flex;align-items:center;gap:8px;padding:7px 12px 4px;position:sticky;top:0;background:var(--bg0);z-index:1;border-bottom:1px solid var(--border);}
.dg-label{font-family:var(--mono);font-size:10px;font-weight:600;color:var(--accent);text-transform:uppercase;letter-spacing:.7px;}
.dg-count{font-family:var(--mono);font-size:9px;color:var(--text2);}
.action-row{display:flex;align-items:center;padding:2px 12px;cursor:pointer;border-left:2px solid transparent;gap:7px;min-height:26px;}
.action-row:hover{background:var(--bg2);}
.action-row.selected{background:var(--bg2);border-left-color:var(--accent);}
.action-icon-slot{width:18px;height:18px;flex-shrink:0;display:flex;align-items:center;justify-content:center;border:1px solid var(--border);border-radius:2px;background:var(--bg3);overflow:hidden;}
.action-icon-slot img{width:14px;height:14px;object-fit:contain;}
.empty-dot{width:4px;height:4px;background:var(--border);border-radius:50%;}
.action-name{flex:1;font-size:12px;color:var(--text1);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.action-row.has-icon .action-name{color:var(--text0);}
.action-row.selected .action-name{color:var(--text0);}
.action-tex{font-family:var(--mono);font-size:9px;color:var(--text2);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:140px;flex-shrink:0;}
.ubtn{width:15px;height:15px;background:none;border:none;color:var(--text2);cursor:pointer;font-size:10px;line-height:1;display:none;align-items:center;justify-content:center;border-radius:2px;flex-shrink:0;padding:0;}
.action-row:hover .ubtn{display:flex;}
.ubtn:hover{color:var(--danger);background:rgba(224,82,82,.12);}
.panel-detail{width:310px;flex-shrink:0;display:flex;flex-direction:column;background:var(--bg1);}
.detail-tabs{display:flex;flex-wrap:wrap;border-bottom:1px solid var(--border);flex-shrink:0;}
.dtab{flex:1;padding:8px 10px;background:none;border:none;border-bottom:2px solid transparent;color:var(--text2);font-family:var(--mono);font-size:11px;cursor:pointer;text-transform:uppercase;letter-spacing:.5px;}
.dtab:hover{color:var(--text1);}
.dtab.active{color:var(--accent);border-bottom-color:var(--accent);}
.detail-pane{display:none;flex:1;flex-direction:column;overflow-y:auto;padding:12px;}
.detail-pane.active{display:flex;}
.big-preview{width:100%;height:110px;background:var(--pv-surf);border:1px solid var(--pv-border);border-radius:5px;display:flex;align-items:center;justify-content:center;margin-bottom:10px;overflow:hidden;flex-shrink:0;transition:background .15s,border-color .15s;}
.big-preview img{width:72px;height:72px;object-fit:contain;}
.big-preview .no-sel{font-family:var(--mono);font-size:10px;color:var(--text2);text-align:center;line-height:1.8;}
.df{margin-bottom:8px;}
.dl{font-family:var(--mono);font-size:9px;color:var(--text2);text-transform:uppercase;letter-spacing:.5px;margin-bottom:2px;}
.dv{font-size:12px;color:var(--text0);}
.dv.mono{font-family:var(--mono);font-size:11px;color:var(--accent);}
.divider{height:1px;background:var(--border);margin:10px 0;}
.assign-btn{width:100%;padding:7px;margin:4px 0;background:var(--accent-dim);border:1px solid var(--accent);border-radius:4px;color:var(--text0);font-family:var(--mono);font-size:11px;cursor:pointer;text-transform:uppercase;letter-spacing:.5px;}
.assign-btn:hover:not(:disabled){background:var(--accent);}
.assign-btn:disabled{opacity:.4;cursor:not-allowed;background:var(--bg3);border-color:var(--border);}
.sel-action-box{padding:6px 8px;background:var(--bg2);border:1px solid var(--border);border-radius:3px;margin-top:6px;}
.sel-action-box .sal{font-family:var(--mono);font-size:9px;color:var(--text2);text-transform:uppercase;margin-bottom:2px;}
.sel-action-box .sav{font-size:11px;color:var(--text1);}
.mockup-intro{font-family:var(--mono);font-size:9px;color:var(--text2);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;}
.mockup-menu{background:var(--pv-bg);border:1px solid var(--pv-border);border-radius:3px;overflow:hidden;font-family:'Courier New',monospace;transition:background .15s,border-color .15s;}
.mockup-row{display:flex;align-items:center;gap:6px;padding:2px 8px;min-height:22px;border-bottom:1px solid var(--pv-border);}
.mockup-row:last-child{border-bottom:none;}
.mockup-icon{width:16px;height:16px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
.mockup-icon img{width:13px;height:13px;object-fit:contain;opacity:.85;}
.mockup-empty{width:13px;height:13px;background:var(--pv-surf2);border-radius:2px;}
.mockup-text{font-size:11px;color:var(--pv-text);}
.exp-section{margin-bottom:14px;}
.exp-title{font-family:var(--mono);font-size:10px;font-weight:600;color:var(--accent);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;display:flex;align-items:center;justify-content:space-between;}
.copy-btn{padding:3px 8px;background:var(--bg3);border:1px solid var(--border);border-radius:3px;color:var(--text1);font-family:var(--mono);font-size:9px;cursor:pointer;text-transform:uppercase;}
.copy-btn:hover{border-color:var(--accent);color:var(--accent);}
.copy-btn.copied{color:var(--green);border-color:var(--green);}
.exp-ta{width:100%;height:160px;padding:7px;background:var(--bg0);border:1px solid var(--border);border-radius:4px;color:var(--text1);font-family:var(--mono);font-size:10px;resize:vertical;outline:none;line-height:1.5;}
.exp-ta:focus{border-color:var(--border-hi);}
.exp-note{font-family:var(--mono);font-size:9px;color:var(--text2);padding:5px 7px;background:rgba(71,161,140,.07);border:1px solid rgba(71,161,140,.25);border-radius:3px;margin-bottom:8px;line-height:1.6;}
.exp-note b{color:#47A18C;}
.statusbar{padding:3px 16px;background:var(--bg1);border-top:1px solid var(--border);display:flex;align-items:center;gap:16px;flex-shrink:0;}
.si{font-family:var(--mono);font-size:10px;color:var(--text2);}
.si b{color:var(--green);}
::-webkit-scrollbar{width:5px;height:5px;}
::-webkit-scrollbar-track{background:transparent;}
::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px;}
::-webkit-scrollbar-thumb:hover{background:var(--border-hi);}
.resize-handle{width:4px;flex-shrink:0;cursor:col-resize;background:var(--border);transition:background .12s;z-index:10;position:relative;}
.resize-handle::after{content:'';position:absolute;inset:-3px 0;}
.resize-handle:hover,.resize-handle.dragging{background:var(--accent);}
.theme-bar{display:flex;align-items:center;gap:8px;padding:4px 16px;background:var(--bg1);border-bottom:1px solid var(--border);flex-shrink:0;}
.tb-label{font-family:var(--mono);font-size:9px;color:var(--text2);text-transform:uppercase;letter-spacing:.6px;white-space:nowrap;}
.tb-themes{display:flex;gap:2px;}
.tbtn{padding:2px 8px;background:var(--bg2);border:1px solid var(--border);border-radius:3px;color:var(--text2);font-family:var(--mono);font-size:9px;cursor:pointer;text-transform:uppercase;letter-spacing:.4px;transition:all .1s;}
.tbtn:hover{color:var(--text1);border-color:var(--border-hi);}
.tbtn.active{background:var(--bg3);border-color:var(--border-hi);color:var(--text0);}
.tb-sep{flex:0 0 1px;height:14px;background:var(--border);margin:0 4px;}
.tb-accents{display:flex;gap:4px;align-items:center;}
.abtn{width:14px;height:14px;border-radius:50%;border:2px solid transparent;cursor:pointer;padding:0;transition:border-color .1s,transform .1s;flex-shrink:0;}
.abtn:hover{transform:scale(1.25);}
.abtn.active{border-color:rgba(255,255,255,.85);box-shadow:0 0 0 1px rgba(0,0,0,.5);}
</style>
</head>
<body>

<div class="header">
  <div class="header-title">VANILLA PZ <span>x</span> ZeD-UI <span>// ICON ASSIGNMENT TOOL</span></div>
  <span class="vanillatag">native PZ assets</span>
  <div class="header-stats" id="hStats">Loading...</div>
</div>

<div class="theme-bar">
  <span class="tb-label">Preview</span>
  <div class="tb-themes">
    <button class="tbtn" data-pv="dark">Dark</button>
    <button class="tbtn" data-pv="light">Light</button>
    <button class="tbtn" data-pv="hicon">Hi-Con</button>
  </div>
  <div class="tb-sep"></div>
  <div class="tb-accents">
    <button class="abtn" data-pva="orange" style="background:#D4922A" title="Orange"></button>
    <button class="abtn" data-pva="red"    style="background:#CC4444" title="Red"></button>
    <button class="abtn" data-pva="yellow" style="background:#CCAA22" title="Yellow"></button>
    <button class="abtn" data-pva="green"  style="background:#44AA44" title="Green"></button>
    <button class="abtn" data-pva="blue"   style="background:#4488CC" title="Blue"></button>
    <button class="abtn" data-pva="teal"   style="background:#47A18C" title="PZ Teal"></button>
    <button class="abtn" data-pva="purple" style="background:#8855BB" title="Purple"></button>
    <button class="abtn" data-pva="pink"   style="background:#DD5588" title="Pink"></button>
    <button class="abtn" data-pva="mono"   style="background:#888888" title="Mono"></button>
  </div>
</div>

<div class="main">

  <!-- LEFT: Icon Library -->
  <div class="panel-library">
    <div class="lib-search">
      <input type="text" id="iconSearch" placeholder="Search icons... (axe, food, gun, medic)" autocomplete="off">
    </div>
    <div class="domain-strip" id="libDomainStrip">
      <button class="dbtn active" data-ld="all">All</button>
      <button class="dbtn" data-ld="items">Items</button>
      <button class="dbtn" data-ld="weapons">Weapons</button>
      <button class="dbtn" data-ld="building">Building</button>
      <button class="dbtn" data-ld="character">Character</button>
      <button class="dbtn" data-ld="world">World</button>
    </div>
    <div class="lib-body">
      <div class="lib-sidebar" id="libSidebar"></div>
      <div class="lib-grid-area" id="libGrid"></div>
    </div>
  </div>

  <!-- RESIZE HANDLE 1 -->
  <div class="resize-handle" id="rh1"></div>

  <!-- CENTER: PZ Actions -->
  <div class="panel-actions">
    <div class="actions-header">
      <span class="actions-title">PZ Context Actions</span>
      <span class="assign-count" id="assignCount"><b>0</b> / 0 assigned</span>
    </div>
    <div class="actions-search">
      <input type="text" id="actionSearch" placeholder="Filter actions..." autocomplete="off">
    </div>
    <div class="actions-domain-strip" id="actionDomainStrip"></div>
    <div class="actions-list" id="actionsList"></div>
  </div>

  <!-- RESIZE HANDLE 2 -->
  <div class="resize-handle" id="rh2"></div>

  <!-- RIGHT: Detail / Export -->
  <div class="panel-detail">
    <div class="detail-tabs">
      <button class="dtab active" data-pane="icon">Icon</button>
      <button class="dtab" data-pane="mockup">Mockup</button>
      <button class="dtab" data-pane="export">Export</button>
    </div>

    <div class="detail-pane active" id="pane-icon">
      <div class="big-preview" id="bigPreview">
        <span class="no-sel">Select an icon<br>from the library</span>
      </div>
      <div class="df"><div class="dl">Name</div><div class="dv" id="dName">--</div></div>
      <div class="df"><div class="dl">Category</div><div class="dv" id="dCat">--</div></div>
      <div class="df"><div class="dl">Texture key (Lua value)</div><div class="dv mono" id="dTex">--</div></div>
      <div class="divider"></div>
      <button class="assign-btn" id="assignBtn" disabled>Assign to selected action</button>
      <div class="sel-action-box">
        <div class="sal">Selected action</div>
        <div class="sav" id="selActionName">None - click an action first</div>
      </div>
    </div>

    <div class="detail-pane" id="pane-mockup">
      <div class="mockup-intro">Context menu preview -- ZeD theme</div>
      <div class="mockup-menu" id="mockupMenu"></div>
    </div>

    <div class="detail-pane" id="pane-export">
      <div class="exp-section">
        <div class="exp-title">ContextIcons.lua <button class="copy-btn" id="cpLua">Copy</button></div>
        <textarea class="exp-ta" id="luaTa" readonly placeholder="Assign icons to generate Lua..."></textarea>
      </div>
      <div class="exp-section">
        <div class="exp-title">Sync Script (PowerShell) <button class="copy-btn" id="cpPs">Copy</button></div>
        <div class="exp-note"><b>Vanilla icons resolve natively</b> -- getTexture("Item_Axe") works without copying files. Run 05-sync-vanilla.ps1 only if you want local PNG copies in the mod icons folder.</div>
        <textarea class="exp-ta" id="psTa" readonly placeholder="Assign icons to generate sync script..."></textarea>
      </div>
    </div>
  </div>

</div>

<div class="statusbar">
  <span class="si">Library: <b id="sbTotal">--</b> icons</span>
  <span class="si">Assigned: <b id="sbAssigned">0</b></span>
  <span class="si">Selected: <span id="sbSel">none</span></span>
  <span class="si" style="margin-left:auto;color:var(--text2);">/ = search * Esc = clear</span>
</div>

<script>window.onerror=function(m,s,l,c){document.getElementById('hStats').textContent='ERR L'+l+':'+c+' '+m;return true;};</script>
<script>
// ================================================================
// PZ ACTIONS & DOMAINS
// ================================================================
const PZ_DOMAINS=[
  {key:'movement',  label:'Movement'},
  {key:'food',      label:'Food & Eating'},
  {key:'drink',     label:'Drinks'},
  {key:'ingredient',label:'Ingredients'},
  {key:'additive',  label:'Cooking Additives'},
  {key:'craft',     label:'Crafting & Construction'},
  {key:'fire',      label:'Fire'},
  {key:'fluid',     label:'Fluids'},
  {key:'clean',     label:'Cleaning'},
  {key:'combat',    label:'Combat & Weapons'},
  {key:'medical',   label:'Medical'},
  {key:'vehicle',   label:'Vehicles'},
  {key:'farm',      label:'Farming & Nature'},
  {key:'clothing',  label:'Clothing'},
  {key:'survival',  label:'Survival'},
  {key:'electric',  label:'Electrical'},
  {key:'reading',   label:'Reading'},
  {key:'inventory', label:'Inventory'},
  {key:'igui',      label:'IGUI Keys'},
];
const PZ_ACTIONS=[
  {domain:'movement',name:'Walk to'},
  {domain:'movement',name:'Sit on ground'},
  {domain:'movement',name:'Sleep'},
  {domain:'movement',name:'Sleep on Ground'},
  {domain:'movement',name:'Sleep on Ground with Pillow'},
  {domain:'movement',name:'Sleep in Tent'},
  {domain:'movement',name:'Rest'},
  {domain:'movement',name:'Climb over'},
  {domain:'movement',name:'Climb through'},
  {domain:'movement',name:'Climb Sheet Rope'},
  {domain:'movement',name:'Exercise'},
  {domain:'food',name:'Eat'},
  {domain:'food',name:'Open and Eat'},
  {domain:'food',name:'Omelette'},
  {domain:'food',name:'Soup'},
  {domain:'food',name:'Stew'},
  {domain:'food',name:'Pie'},
  {domain:'food',name:'Cake'},
  {domain:'food',name:'Stir-fry'},
  {domain:'food',name:'Roast'},
  {domain:'food',name:'Sandwich'},
  {domain:'food',name:'Muffin'},
  {domain:'food',name:'Burger'},
  {domain:'food',name:'Salad'},
  {domain:'food',name:'Fruit Salad'},
  {domain:'food',name:'Pasta'},
  {domain:'food',name:'Rice'},
  {domain:'food',name:'Hotdog'},
  {domain:'food',name:'Taco'},
  {domain:'food',name:'Burrito'},
  {domain:'food',name:'Waffles'},
  {domain:'food',name:'Pancakes'},
  {domain:'food',name:'Bread'},
  {domain:'food',name:'Toast'},
  {domain:'food',name:'Pizza'},
  {domain:'food',name:'Sushi'},
  {domain:'food',name:'Wrap'},
  {domain:'food',name:'Quesadilla'},
  {domain:'food',name:'Dumplings'},
  {domain:'food',name:'Casserole'},
  {domain:'food',name:'Curry'},
  {domain:'food',name:'Ramen'},
  {domain:'food',name:'Baked Potato'},
  {domain:'food',name:'Stuffed Pepper'},
  {domain:'food',name:'Scrambled Eggs'},
  {domain:'food',name:'Fried Eggs'},
  {domain:'food',name:'Boiled Egg'},
  {domain:'food',name:'Poached Eggs'},
  {domain:'food',name:'French Toast'},
  {domain:'food',name:'Nachos'},
  {domain:'food',name:'Spring Rolls'},
  {domain:'food',name:'Kebab'},
  {domain:'food',name:'Granola'},
  {domain:'food',name:'Porridge'},
  {domain:'food',name:'Meatloaf'},
  {domain:'food',name:'Meatballs'},
  {domain:'food',name:'Fish and Chips'},
  {domain:'food',name:'Sausage'},
  {domain:'food',name:'Bacon'},
  {domain:'food',name:'Ham'},
  {domain:'food',name:'Pork Chop'},
  {domain:'food',name:'Steak'},
  {domain:'food',name:'Chicken'},
  {domain:'food',name:'Turkey'},
  {domain:'food',name:'Rabbit'},
  {domain:'food',name:'Venison'},
  {domain:'food',name:'Fish'},
  {domain:'food',name:'Paella'},
  {domain:'food',name:'Risotto'},
  {domain:'food',name:'Lasagna'},
  {domain:'food',name:'Macaroni and Cheese'},
  {domain:'food',name:'Chili'},
  {domain:'food',name:'BBQ Ribs'},
  {domain:'food',name:'Pulled Pork'},
  {domain:'food',name:'Beef Stew'},
  {domain:'food',name:'Fried Chicken'},
  {domain:'food',name:'Chicken Soup'},
  {domain:'food',name:'Cookies'},
  {domain:'food',name:'Cheesecake'},
  {domain:'food',name:'Ice Cream'},
  {domain:'drink',name:'Drink'},
  {domain:'drink',name:'Brew Tea'},
  {domain:'drink',name:'Brew Coffee'},
  {domain:'drink',name:'Brew Herbal Tea'},
  {domain:'drink',name:'Make Juice'},
  {domain:'drink',name:'Make Lemonade'},
  {domain:'drink',name:'Make Cocktail'},
  {domain:'drink',name:'Mix Drink'},
  {domain:'drink',name:'Blend'},
  {domain:'drink',name:'Pour'},
  {domain:'drink',name:'Fill Water Bottle'},
  {domain:'drink',name:'Boil Water'},
  {domain:'drink',name:'Brew Beer'},
  {domain:'drink',name:'Make Wine'},
  {domain:'drink',name:'Distill'},
  {domain:'drink',name:'Ferment'},
  {domain:'ingredient',name:'Chop'},
  {domain:'ingredient',name:'Slice'},
  {domain:'ingredient',name:'Dice'},
  {domain:'ingredient',name:'Mince'},
  {domain:'ingredient',name:'Grate'},
  {domain:'ingredient',name:'Peel'},
  {domain:'ingredient',name:'Crush'},
  {domain:'ingredient',name:'Grind'},
  {domain:'ingredient',name:'Mix'},
  {domain:'ingredient',name:'Stir'},
  {domain:'ingredient',name:'Knead'},
  {domain:'ingredient',name:'Fillet'},
  {domain:'ingredient',name:'Skin'},
  {domain:'ingredient',name:'Gut'},
  {domain:'ingredient',name:'Add Ingredient'},
  {domain:'additive',name:'Add Salt'},
  {domain:'additive',name:'Add Sugar'},
  {domain:'additive',name:'Add Pepper'},
  {domain:'additive',name:'Add Oil'},
  {domain:'additive',name:'Add Butter'},
  {domain:'additive',name:'Add Flour'},
  {domain:'additive',name:'Add Eggs'},
  {domain:'additive',name:'Add Milk'},
  {domain:'additive',name:'Add Cheese'},
  {domain:'additive',name:'Add Sauce'},
  {domain:'additive',name:'Add Vinegar'},
  {domain:'additive',name:'Add Honey'},
  {domain:'additive',name:'Season'},
  {domain:'craft',name:'Build'},
  {domain:'craft',name:'Barricade'},
  {domain:'craft',name:'Disassemble'},
  {domain:'craft',name:'Craft'},
  {domain:'craft',name:'Repair'},
  {domain:'craft',name:'Upgrade'},
  {domain:'craft',name:'Reinforce'},
  {domain:'craft',name:'Install'},
  {domain:'craft',name:'Uninstall'},
  {domain:'craft',name:'Place'},
  {domain:'craft',name:'Pick up'},
  {domain:'craft',name:'Rotate'},
  {domain:'craft',name:'Saw'},
  {domain:'craft',name:'Hammer'},
  {domain:'craft',name:'Nail'},
  {domain:'craft',name:'Screw'},
  {domain:'craft',name:'Weld'},
  {domain:'craft',name:'Cut'},
  {domain:'craft',name:'Carve'},
  {domain:'craft',name:'Whittle'},
  {domain:'craft',name:'Apply'},
  {domain:'craft',name:'Remove'},
  {domain:'craft',name:'Sew'},
  {domain:'craft',name:'Knit'},
  {domain:'craft',name:'Weave'},
  {domain:'craft',name:'Spin'},
  {domain:'craft',name:'Dye'},
  {domain:'fire',name:'Light Fire'},
  {domain:'fire',name:'Extinguish'},
  {domain:'fire',name:'Add Fuel'},
  {domain:'fire',name:'Tend Fire'},
  {domain:'fire',name:'Light Campfire'},
  {domain:'fire',name:'Use Lighter'},
  {domain:'fire',name:'Use Matches'},
  {domain:'fluid',name:'Fill'},
  {domain:'fluid',name:'Empty'},
  {domain:'fluid',name:'Transfer'},
  {domain:'fluid',name:'Siphon'},
  {domain:'fluid',name:'Drain'},
  {domain:'fluid',name:'Collect Rain'},
  {domain:'fluid',name:'Distill Water'},
  {domain:'fluid',name:'Filter Water'},
  {domain:'fluid',name:'Pour Water'},
  {domain:'clean',name:'Wash'},
  {domain:'clean',name:'Wash Hands'},
  {domain:'clean',name:'Wash Clothing'},
  {domain:'clean',name:'Clean'},
  {domain:'clean',name:'Clean Weapon'},
  {domain:'clean',name:'Mop'},
  {domain:'clean',name:'Sweep'},
  {domain:'clean',name:'Bleach'},
  {domain:'clean',name:'Disinfect'},
  {domain:'combat',name:'Attack'},
  {domain:'combat',name:'Aim'},
  {domain:'combat',name:'Fire'},
  {domain:'combat',name:'Reload'},
  {domain:'combat',name:'Unload'},
  {domain:'combat',name:'Rack'},
  {domain:'combat',name:'Shove'},
  {domain:'combat',name:'Stomp'},
  {domain:'combat',name:'Smash'},
  {domain:'combat',name:'Equip'},
  {domain:'combat',name:'Unequip'},
  {domain:'combat',name:'Equip Primary'},
  {domain:'combat',name:'Equip Secondary'},
  {domain:'combat',name:'Equip Back'},
  {domain:'combat',name:'Equip Belt Left'},
  {domain:'combat',name:'Equip Belt Right'},
  {domain:'combat',name:'Holster'},
  {domain:'combat',name:'Attach Weapon Mod'},
  {domain:'combat',name:'Detach Weapon Mod'},
  {domain:'combat',name:'Attach Scope'},
  {domain:'combat',name:'Attach Suppressor'},
  {domain:'combat',name:'Attach Bayonet'},
  {domain:'combat',name:'Clean Gun'},
  {domain:'combat',name:'Check Ammo'},
  {domain:'combat',name:'Combine Ammo'},
  {domain:'combat',name:'Open Can'},
  {domain:'medical',name:'Bandage'},
  {domain:'medical',name:'Apply Bandage'},
  {domain:'medical',name:'Remove Bandage'},
  {domain:'medical',name:'Apply Splint'},
  {domain:'medical',name:'Apply Tourniquet'},
  {domain:'medical',name:'Disinfect Wound'},
  {domain:'medical',name:'Apply Antiseptic'},
  {domain:'medical',name:'Apply Ointment'},
  {domain:'medical',name:'Apply Burn Salve'},
  {domain:'medical',name:'Suture'},
  {domain:'medical',name:'Take Pulse'},
  {domain:'medical',name:'Check Temperature'},
  {domain:'medical',name:'Give CPR'},
  {domain:'medical',name:'Cauterize'},
  {domain:'medical',name:'Extract Bullet'},
  {domain:'medical',name:'Take Medication'},
  {domain:'medical',name:'Apply Eye Drops'},
  {domain:'vehicle',name:'Enter Vehicle'},
  {domain:'vehicle',name:'Exit Vehicle'},
  {domain:'vehicle',name:'Hotwire'},
  {domain:'vehicle',name:'Repair Vehicle'},
  {domain:'vehicle',name:'Refuel'},
  {domain:'vehicle',name:'Change Tire'},
  {domain:'vehicle',name:'Check Engine'},
  {domain:'vehicle',name:'Open Trunk'},
  {domain:'vehicle',name:'Close Trunk'},
  {domain:'vehicle',name:'Open Hood'},
  {domain:'vehicle',name:'Install Part'},
  {domain:'vehicle',name:'Remove Part'},
  {domain:'farm',name:'Plant'},
  {domain:'farm',name:'Water Plant'},
  {domain:'farm',name:'Harvest'},
  {domain:'farm',name:'Till Soil'},
  {domain:'farm',name:'Fertilize'},
  {domain:'farm',name:'Prune'},
  {domain:'farm',name:'Pick Berries'},
  {domain:'farm',name:'Forage'},
  {domain:'farm',name:'Hunt'},
  {domain:'farm',name:'Trap'},
  {domain:'farm',name:'Fish'},
  {domain:'farm',name:'Skin Animal'},
  {domain:'farm',name:'Butcher'},
  {domain:'farm',name:'Collect Feathers'},
  {domain:'clothing',name:'Equip Clothing'},
  {domain:'clothing',name:'Unequip Clothing'},
  {domain:'clothing',name:'Repair Clothing'},
  {domain:'clothing',name:'Wash Clothing'},
  {domain:'clothing',name:'Sew Patch'},
  {domain:'clothing',name:'Add Patch'},
  {domain:'clothing',name:'Remove Patch'},
  {domain:'clothing',name:'Cut Clothing'},
  {domain:'clothing',name:'Thread Needle'},
  {domain:'clothing',name:'Rip Sheets'},
  {domain:'clothing',name:'Tear Clothing'},
  {domain:'survival',name:'Set Up Tent'},
  {domain:'survival',name:'Take Down Tent'},
  {domain:'survival',name:'Set Trap'},
  {domain:'survival',name:'Check Trap'},
  {domain:'survival',name:'Use Generator'},
  {domain:'survival',name:'Refuel Generator'},
  {domain:'survival',name:'Build Rain Collector'},
  {domain:'survival',name:'Fortify'},
  {domain:'survival',name:'Dig Grave'},
  {domain:'survival',name:'Bury'},
  {domain:'electric',name:'Wire Generator'},
  {domain:'electric',name:'Install Light'},
  {domain:'electric',name:'Remove Light'},
  {domain:'electric',name:'Connect Pipe'},
  {domain:'electric',name:'Turn On'},
  {domain:'electric',name:'Turn Off'},
  {domain:'electric',name:'Tune Radio'},
  {domain:'electric',name:'Set Alarm'},
  {domain:'electric',name:'Fix Wiring'},
  {domain:'reading',name:'Read'},
  {domain:'reading',name:'Read Map'},
  {domain:'reading',name:'Write Journal'},
  {domain:'reading',name:'Study'},
  {domain:'reading',name:'Check Recipe'},
  {domain:'reading',name:'Tear Out Page'},
  {domain:'inventory',name:'Take'},
  {domain:'inventory',name:'Put In'},
  {domain:'inventory',name:'Take Out'},
  {domain:'inventory',name:'Transfer All'},
  {domain:'inventory',name:'Drop'},
  {domain:'inventory',name:'Examine'},
  {domain:'inventory',name:'Inspect'},
  {domain:'inventory',name:'Favorite'},
  {domain:'inventory',name:'Unfavorite'},
  {domain:'inventory',name:'Protect from Craft'},
  {domain:'inventory',name:'Mark Unwanted'},
  {domain:'inventory',name:'Rename'},
  {domain:'inventory',name:'Open'},
  {domain:'inventory',name:'Close'},
  {domain:'inventory',name:'Lock'},
  {domain:'inventory',name:'Unlock'},
  {domain:'inventory',name:'Combine'},
  {domain:'inventory',name:'Activate'},
  {domain:'inventory',name:'Deactivate'},
  {domain:'inventory',name:'Charge'},
  {domain:'igui',name:'ContextMenu_Build'},
  {domain:'igui',name:'ContextMenu_Craft'},
  {domain:'igui',name:'ContextMenu_Eat'},
  {domain:'igui',name:'ContextMenu_Drink'},
  {domain:'igui',name:'ContextMenu_Read'},
  {domain:'igui',name:'ContextMenu_Sleep'},
  {domain:'igui',name:'ContextMenu_Attack'},
  {domain:'igui',name:'ContextMenu_Equip'},
  {domain:'igui',name:'ContextMenu_Place'},
  {domain:'igui',name:'ContextMenu_Repair'},
  {domain:'igui',name:'ContextMenu_Barricade'},
  {domain:'igui',name:'ContextMenu_Disassemble'},
  {domain:'igui',name:'ContextMenu_WashClothes'},
  {domain:'igui',name:'ContextMenu_WashItem'},
  {domain:'igui',name:'ContextMenu_CleanWeapon'},
  {domain:'igui',name:'ContextMenu_DropItems'},
  {domain:'igui',name:'ContextMenu_TransferItems'},
  {domain:'igui',name:'ContextMenu_EnterVehicle'},
  {domain:'igui',name:'ContextMenu_ExitVehicle'},
  {domain:'igui',name:'ContextMenu_HotwireVehicle'},
  {domain:'igui',name:'ContextMenu_RepairVehicle'},
  {domain:'igui',name:'IGUI_FavoriteName'},
  {domain:'igui',name:'IGUI_DeflateTire'},
  {domain:'igui',name:'IGUI_RepairEngine'},
  {domain:'igui',name:'IGUI_TakeEngineParts'},
  {domain:'igui',name:'IGUI_TradingUI_SealOffer'},
  {domain:'igui',name:'IGUI_CraftUI_Favorite'},
  {domain:'igui',name:'IGUI_MakeUp'},
  {domain:'igui',name:'IGUI_PlaceObject'},
  {domain:'igui',name:'IGUI_SelectBodyLocation'},
];

// Library domain -> vanilla category groups
const LIB_DOMAIN_MAP={
  items:    ['Item','Item_TZ','Item_Magazine','Item_Seeds','Item_Fish'],
  weapons:  ['WItem','WItem_TZ'],
  building: ['Build','BuildBar','Container'],
  character:['trait','profession','Moodle'],
  world:    ['AnimalActions','vehicle'],
};

// ================================================================
// STATE
// ================================================================
let ICON_INDEX=[];
let TEX_LOOKUP=new Map();  // texKey -> ICON_INDEX idx
let selIconIdx=null;
let selAction=null;
let libDomain='all';
let libCat=null;
let libQ='';
let actDomain='all';
let actQ='';
let assignments={};  // {actionName: texKey}

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
function saveAssignments(){
  localStorage.setItem('zed-vanilla-assignments',JSON.stringify(assignments));
}

// ================================================================
// HELPERS
// ================================================================
function esc(s){
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}
function getTexKey(icon){ return icon?icon.t:''; }
function imgSrc(icon){ return icon?'vanilla-icons/'+icon.f:''; }
function getAssignedIcon(name){
  const key=assignments[name];
  if(!key)return null;
  const idx=TEX_LOOKUP.get(key);
  return idx!==undefined?ICON_INDEX[idx]:null;
}

// ================================================================
// PREVIEW THEME
// ================================================================
function setPreviewTheme(t){
  document.body.setAttribute('data-pv',t);
  document.querySelectorAll('.tbtn').forEach(b=>b.classList.toggle('active',b.dataset.pv===t));
  localStorage.setItem('zed-pv-theme',t);
}
function setPreviewAccent(a){
  document.body.setAttribute('data-pva',a);
  document.querySelectorAll('.abtn').forEach(b=>b.classList.toggle('active',b.dataset.pva===a));
  localStorage.setItem('zed-pv-accent',a);
}

// ================================================================
// INIT
// ================================================================
function init(){
  // Build ICON_INDEX from VANILLA_ICONS and populate TEX_LOOKUP
  ICON_INDEX=VANILLA_ICONS;
  ICON_INDEX.forEach((ic,idx)=>TEX_LOOKUP.set(ic.t,idx));

  loadAssignments();
  setPreviewTheme(localStorage.getItem('zed-pv-theme')||'dark');
  setPreviewAccent(localStorage.getItem('zed-pv-accent')||'orange');

  const total=ICON_INDEX.length;
  const cats=Object.keys(VANILLA_CATS).length;
  document.getElementById('hStats').innerHTML=`<b>${total.toLocaleString()}</b> icons &middot; <b>${cats}</b> categories`;
  document.getElementById('sbTotal').textContent=total.toLocaleString();
  renderLibSidebar();
  renderIconGrid();
  renderActionDomainStrip();
  renderActionsList();
  updateCount();
  renderMockup();
  setupEvents();
}

// ================================================================
// ICON LIBRARY
// ================================================================
function libCatsFiltered(){
  if(libDomain==='all')return Object.keys(VANILLA_CATS).sort();
  return (LIB_DOMAIN_MAP[libDomain]||[]).filter(c=>VANILLA_CATS[c]!==undefined);
}

function renderLibSidebar(){
  const cats=libCatsFiltered();
  const total=cats.reduce((a,c)=>a+(VANILLA_CATS[c]||0),0);
  let h=`<div class="cat-item ${!libCat?'active':''}" data-cat="">
    <span class="cat-name">All</span><span class="cat-count">${total}</span></div>`;
  for(const c of cats){
    h+=`<div class="cat-item ${libCat===c?'active':''}" data-cat="${esc(c)}">
      <span class="cat-name">${esc(c)}</span><span class="cat-count">${VANILLA_CATS[c]||0}</span></div>`;
  }
  document.getElementById('libSidebar').innerHTML=h;
}

function renderIconGrid(){
  const allowed=new Set(libCat?[libCat]:libCatsFiltered());
  const q=libQ.toLowerCase();
  const el=document.getElementById('libGrid');
  let h='<div class="icon-grid">',n=0;
  for(let i=0;i<ICON_INDEX.length;i++){
    const ic=ICON_INDEX[i];
    if(!allowed.has(ic.c))continue;
    if(q&&!ic.n.toLowerCase().includes(q)&&!ic.c.toLowerCase().includes(q)&&!ic.t.toLowerCase().includes(q))continue;
    const sel=i===selIconIdx;
    h+=`<div class="icon-card${sel?' selected':''}" data-idx="${i}" title="${esc(ic.t)}">
      <div class="ic-preview"><img src="${imgSrc(ic)}" loading="lazy" alt="${esc(ic.n)}" onerror="this.style.opacity=.15"></div>
      <div class="ic-name">${esc(ic.n)}</div></div>`;
    n++;
  }
  h+='</div>';
  if(!n)h=`<div style="padding:20px;font-family:var(--mono);font-size:11px;color:var(--text2);text-align:center;">No icons match<br>"${esc(libQ||'current filter')}"</div>`;
  el.innerHTML=h;
}

function selectIcon(idx){
  selIconIdx=idx;
  const ic=ICON_INDEX[idx];
  if(!ic)return;
  document.getElementById('bigPreview').innerHTML=`<img src="${imgSrc(ic)}" alt="${esc(ic.n)}">`;
  document.getElementById('dName').textContent=ic.n;
  document.getElementById('dCat').textContent=ic.c;
  document.getElementById('dTex').textContent=ic.t;
  document.getElementById('assignBtn').disabled=!selAction;
  document.getElementById('sbSel').textContent=ic.n+' ('+ic.c+')';
  if(selAction!==null)doAssign(selAction,idx);
  renderIconGrid();
}

// ================================================================
// PZ ACTIONS
// ================================================================
function renderActionDomainStrip(){
  let h=`<button class="dbtn ${actDomain==='all'?'active':''}" data-ad="all">All</button>`;
  for(const d of PZ_DOMAINS)
    h+=`<button class="dbtn ${actDomain===d.key?'active':''}" data-ad="${d.key}">${d.label}</button>`;
  document.getElementById('actionDomainStrip').innerHTML=h;
}

function renderActionsList(){
  const q=actQ.toLowerCase();
  const el=document.getElementById('actionsList');
  const domains=actDomain==='all'?PZ_DOMAINS:PZ_DOMAINS.filter(d=>d.key===actDomain);
  let h='';
  for(const dom of domains){
    const acts=PZ_ACTIONS.filter(a=>{
      if(a.domain!==dom.key)return false;
      if(q&&!a.name.toLowerCase().includes(q))return false;
      return true;
    }).sort((a,b)=>a.name.localeCompare(b.name));
    if(!acts.length)continue;
    const nAssigned=acts.filter(a=>assignments[a.name]!==undefined).length;
    h+=`<div class="dg-header"><span class="dg-label">${esc(dom.label)}</span><span class="dg-count">${nAssigned}/${acts.length}</span></div>`;
    for(const a of acts){
      const ic=getAssignedIcon(a.name);
      const hasPic=!!ic;
      const isSel=selAction===a.name;
      const slot=ic?`<img src="${imgSrc(ic)}" alt="${esc(ic.n)}">`:`<div class="empty-dot"></div>`;
      const tex=hasPic?`<span class="action-tex" title="${esc(ic.t)}">${esc(ic.t)}</span>`:'';
      const ubtn=hasPic?`<button class="ubtn" data-ua="${esc(a.name)}" title="Unassign">&#x2715;</button>`:'';
      h+=`<div class="action-row${isSel?' selected':''}${hasPic?' has-icon':''}" data-ac="${esc(a.name)}">
        <div class="action-icon-slot">${slot}</div>
        <span class="action-name">${esc(a.name)}</span>
        ${tex}${ubtn}</div>`;
    }
  }
  if(!h)h=`<div style="padding:20px;font-family:var(--mono);font-size:11px;color:var(--text2);text-align:center;">No actions match "${esc(actQ)}"</div>`;
  el.innerHTML=h;
  updateCount();
}

function selectAction(name){
  selAction=name;
  document.getElementById('selActionName').textContent=name;
  document.getElementById('assignBtn').disabled=selIconIdx===null;
  renderActionsList();
}

function doAssign(name,iconIdx){
  assignments[name]=ICON_INDEX[iconIdx].t;
  saveAssignments();
  renderActionsList();
  if(document.getElementById('pane-mockup').classList.contains('active'))renderMockup();
  if(document.getElementById('pane-export').classList.contains('active'))renderExport();
}

function doUnassign(name){
  delete assignments[name];
  saveAssignments();
  if(selAction===name){
    selAction=null;
    document.getElementById('selActionName').textContent='None -- click an action first';
    document.getElementById('assignBtn').disabled=true;
  }
  renderActionsList();
  if(document.getElementById('pane-mockup').classList.contains('active'))renderMockup();
  if(document.getElementById('pane-export').classList.contains('active'))renderExport();
}

function updateCount(){
  const t=PZ_ACTIONS.length,a=Object.keys(assignments).length;
  document.getElementById('assignCount').innerHTML=`<b>${a}</b> / ${t} assigned`;
  document.getElementById('sbAssigned').textContent=a;
}

// ================================================================
// MOCKUP
// ================================================================
function renderMockup(){
  const el=document.getElementById('mockupMenu');
  const src=actDomain==='all'?PZ_ACTIONS:PZ_ACTIONS.filter(a=>a.domain===actDomain);
  let h='';
  for(const a of src.slice(0,18)){
    const ic=getAssignedIcon(a.name);
    const icHtml=ic?`<img src="${imgSrc(ic)}" alt="${esc(ic.n)}">`:`<div class="mockup-empty"></div>`;
    h+=`<div class="mockup-row"><div class="mockup-icon">${icHtml}</div><span class="mockup-text">${esc(a.name)}</span></div>`;
  }
  el.innerHTML=h||'<div style="padding:12px;font-family:monospace;font-size:10px;color:#6e7283;">No actions in filter</div>';
}

// ================================================================
// EXPORT
// ================================================================
function renderExport(){
  const vanillaRoot=DATA.root_path;
  const modIcons='C:\\Users\\danie\\Zomboid\\mods\\ZeD-UI\\42\\media\\textures\\ZeD\\icons';
  const entries=PZ_ACTIONS.filter(a=>getAssignedIcon(a.name)!==null);
  if(!entries.length){
    document.getElementById('luaTa').value='-- No icons assigned yet.\n-- Assign icons in the Actions panel, then return here.';
    document.getElementById('psTa').value='# No icons assigned yet.';
    return;
  }
  // LUA
  let lua='-- ZeD-UI/42/media/lua/shared/ZeD/ContextIcons.lua\n-- Generated by vanilla-catalog assignment tool\nZeD = ZeD or {}\nZeD.ContextIcons = {\n';
  let lastDom=null;
  for(const a of entries){
    const ic=getAssignedIcon(a.name);
    if(!ic)continue;
    if(a.domain!==lastDom){
      const lbl=PZ_DOMAINS.find(d=>d.key===a.domain)?.label||a.domain;
      lua+=`\n    -- ${lbl.toUpperCase()}\n`;
      lastDom=a.domain;
    }
    const pad=Math.max(0,42-a.name.length);
    lua+=`    ["${a.name}"]${' '.repeat(pad)}= "${ic.t}",\n`;
  }
  lua+='}\n';
  document.getElementById('luaTa').value=lua;
  // PS sync script
  let ps='# ZeD-UI Vanilla Icon Sync\n# Copies vanilla PNGs from vanilla-icons/ to mod texture directory\n';
  ps+='# NOTE: Not required -- vanilla texKeys resolve via getTexture() without this step.\n\n';
  ps+=`$src = "${vanillaRoot}"\n$dst = "${modIcons}"\nNew-Item -ItemType Directory -Force -Path $dst | Out-Null\n\n`;
  for(const a of entries){
    const ic=getAssignedIcon(a.name);
    if(!ic)continue;
    ps+=`Copy-Item "$src\\${ic.f}" "$dst\\${ic.f}" -Force\n`;
  }
  ps+=`\nWrite-Host "Done. Copied ${entries.length} icons." -ForegroundColor Green\n`;
  document.getElementById('psTa').value=ps;
}

// ================================================================
// EVENTS
// ================================================================
function setupEvents(){
  document.getElementById('libGrid').addEventListener('click',e=>{
    const card=e.target.closest('.icon-card');
    if(!card)return;
    const idx=parseInt(card.dataset.idx);
    if(!isNaN(idx))selectIcon(idx);
  });
  document.getElementById('libSidebar').addEventListener('click',e=>{
    const item=e.target.closest('.cat-item');
    if(!item)return;
    libCat=item.dataset.cat||null;
    renderLibSidebar();
    renderIconGrid();
  });
  document.getElementById('libDomainStrip').addEventListener('click',e=>{
    const btn=e.target.closest('[data-ld]');
    if(!btn)return;
    libDomain=btn.dataset.ld;
    libCat=null;
    document.querySelectorAll('[data-ld]').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    renderLibSidebar();
    renderIconGrid();
  });
  document.getElementById('iconSearch').addEventListener('input',e=>{
    libQ=e.target.value.trim();
    renderIconGrid();
  });
  document.getElementById('actionDomainStrip').addEventListener('click',e=>{
    const btn=e.target.closest('[data-ad]');
    if(!btn)return;
    actDomain=btn.dataset.ad;
    document.querySelectorAll('[data-ad]').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    renderActionDomainStrip();
    renderActionsList();
    renderMockup();
  });
  document.getElementById('actionSearch').addEventListener('input',e=>{
    actQ=e.target.value.trim();
    renderActionsList();
  });
  document.getElementById('actionsList').addEventListener('click',e=>{
    const ubtn=e.target.closest('[data-ua]');
    if(ubtn){e.stopPropagation();doUnassign(ubtn.dataset.ua);return;}
    const row=e.target.closest('.action-row');
    if(!row||!row.dataset.ac)return;
    selectAction(row.dataset.ac);
  });
  document.getElementById('assignBtn').addEventListener('click',()=>{
    if(selIconIdx!==null&&selAction!==null)doAssign(selAction,selIconIdx);
  });
  document.querySelectorAll('.dtab').forEach(tab=>{
    tab.addEventListener('click',()=>{
      const pane=tab.dataset.pane;
      document.querySelectorAll('.dtab').forEach(t=>t.classList.remove('active'));
      document.querySelectorAll('.detail-pane').forEach(p=>p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById('pane-'+pane).classList.add('active');
      if(pane==='export')renderExport();
      if(pane==='mockup')renderMockup();
    });
  });
  document.getElementById('cpLua').addEventListener('click',()=>copyText(document.getElementById('luaTa').value,'cpLua'));
  document.getElementById('cpPs').addEventListener('click',()=>copyText(document.getElementById('psTa').value,'cpPs'));
  document.querySelectorAll('.tbtn').forEach(b=>b.addEventListener('click',()=>setPreviewTheme(b.dataset.pv)));
  document.querySelectorAll('.abtn').forEach(b=>b.addEventListener('click',()=>setPreviewAccent(b.dataset.pva)));
  setupResizeHandles();
  document.addEventListener('keydown',e=>{
    if(e.key==='/'&&document.activeElement.tagName!=='INPUT'){e.preventDefault();document.getElementById('iconSearch').focus();}
    if(e.key==='Escape'){
      document.querySelectorAll('input').forEach(i=>{i.value='';});
      libQ='';actQ='';
      renderIconGrid();renderActionsList();
    }
  });
}

// ================================================================
// COLUMN RESIZE
// ================================================================
function setupResizeHandles(){
  const lib=document.querySelector('.panel-library');
  const det=document.querySelector('.panel-detail');
  function initHandle(handle,getW,setW,minW){
    let startX,startW;
    handle.addEventListener('mousedown',e=>{
      startX=e.clientX;startW=getW();
      handle.classList.add('dragging');
      document.body.style.cursor='col-resize';
      document.body.style.userSelect='none';
      const onMove=ev=>{const dx=ev.clientX-startX;setW(Math.max(minW,startW+dx));};
      const onUp=()=>{
        handle.classList.remove('dragging');
        document.body.style.cursor='';document.body.style.userSelect='';
        document.removeEventListener('mousemove',onMove);
        document.removeEventListener('mouseup',onUp);
      };
      document.addEventListener('mousemove',onMove);
      document.addEventListener('mouseup',onUp);
      e.preventDefault();
    });
  }
  initHandle(document.getElementById('rh1'),()=>lib.offsetWidth,w=>{lib.style.width=w+'px';},160);
  const rh2=document.getElementById('rh2');
  let startX2,startW2;
  rh2.addEventListener('mousedown',e=>{
    startX2=e.clientX;startW2=det.offsetWidth;
    rh2.classList.add('dragging');
    document.body.style.cursor='col-resize';
    document.body.style.userSelect='none';
    const onMove=ev=>{const dx=ev.clientX-startX2;det.style.width=Math.max(200,startW2-dx)+'px';};
    const onUp=()=>{
      rh2.classList.remove('dragging');
      document.body.style.cursor='';document.body.style.userSelect='';
      document.removeEventListener('mousemove',onMove);
      document.removeEventListener('mouseup',onUp);
    };
    document.addEventListener('mousemove',onMove);
    document.addEventListener('mouseup',onUp);
    e.preventDefault();
  });
}

function copyText(text,btnId){
  const btn=document.getElementById(btnId);
  const orig=btn.textContent;
  navigator.clipboard.writeText(text).then(()=>{
    btn.textContent='Copied!';btn.classList.add('copied');
    setTimeout(()=>{btn.textContent=orig;btn.classList.remove('copied');},1500);
  }).catch(()=>{
    const ta=document.createElement('textarea');ta.value=text;document.body.appendChild(ta);ta.select();
    document.execCommand('copy');document.body.removeChild(ta);
    btn.textContent='Copied!';setTimeout(()=>{btn.textContent=orig;},1500);
  });
}

// ICON DATA (injected by build script below)
'@

$htmlBottom = @"
;
// Build config
const DATA={root_path:'$vanillaRoot',total_icons:$totalIcons,total_categories:$totalCats};
$seededJs
try{init();}catch(e){document.getElementById('hStats').textContent='JS ERROR: '+e.message+' :: '+e.stack.split('\n')[1];}
</script>
</body>
</html>
"@

Write-Host "Writing vanilla-catalog.html..." -ForegroundColor Cyan
$fullHtml = $htmlTop + $iconDataJs + $htmlBottom
[System.IO.File]::WriteAllText($outputPath, $fullHtml, [System.Text.UTF8Encoding]::new($false))

$sizeMB = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Cyan
Write-Host "Output : $outputPath" -ForegroundColor Green
Write-Host "Size   : $sizeMB MB"  -ForegroundColor Green
Write-Host "Icons  : $totalIcons across $totalCats categories" -ForegroundColor Green
Write-Host ""
Write-Host "Open vanilla-catalog.html in your browser to start assigning." -ForegroundColor Yellow
Write-Host ""
