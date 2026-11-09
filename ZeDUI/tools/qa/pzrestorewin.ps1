# Put back the director's fullscreen display settings after a windowed QA run.
# Run only once the game has closed (the game rewrites options.ini on exit).
$S = $PSScriptRoot
$Z = $(if ($env:ZEDQA_ZDIR) { $env:ZEDQA_ZDIR } else { "$env:USERPROFILE\Zomboid" })   # (Nov 8 2026: a staged -cachedir run restores its own folder)
$opt = Join-Path $Z "options.ini"
$bak = $(if ($env:ZEDQA_ZDIR) { Join-Path $Z "options.ini.fullscreen.bak" } else { Join-Path $S "options.ini.fullscreen.bak" })
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is still running"; exit 1 }
if (-not (Test-Path $bak)) { "no backup"; exit 1 }
$t = Get-Content $opt
$b = Get-Content $bak
$keep = @{}
foreach ($l in $b) { if ($l -match '^(fullScreen|width|height|borderless)=') { $keep[$Matches[1]] = $l } }
$t = $t | ForEach-Object { if ($_ -match '^(fullScreen|width|height|borderless)=' -and $keep.ContainsKey($Matches[1])) { $keep[$Matches[1]] } else { $_ } }
Set-Content -Path $opt -Value $t
Remove-Item $bak
Set-Content -Path "$env:USERPROFILE\Zomboid\Lua\zedqa.autoload" -Value "0" -NoNewline
(Select-String -Path $opt -Pattern '^(fullScreen|width|height)=').Line -join " "
