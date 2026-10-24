# ZeDUI/mockups/zed_quick_chords_v1/build.ps1
# Builds ZeDUI/mockups/zed_quick_chords_v1.html from template.html: the ZeD icons
# the mockup names are embedded from 42/media/textures/ZeD/icons (base64), so the
# page opens on its own.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $here '..\..\..')
$icons = Join-Path $repo '42\media\textures\ZeD\icons'
$names = @('apple-whole', 'water-045-drink', 'lightbulb-on', 'smoking', 'bandage-wound', 'knife', 'book-open-reader', 'sitting-ground',
           'fi-br-person-walking-arrow-right', 'bullhorn', 'crafting-game-037-map', 'bed', 'fi-br-shirt-long-sleeve', 'backpack', 'clock',
           'eye', 'info-guide', 'car-mechanic', 'cow', 'carpentry-015-toolbox', 'fi-br-magnifying-glass-wave', 'smile', 'fi-br-map-point')
$map = [ordered]@{}
foreach ($n in $names) {
    $p = Join-Path $icons "$n.png"
    if (-not (Test-Path -LiteralPath $p)) { throw "missing icon $p" }
    $map[$n] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
}
$json = $map | ConvertTo-Json -Compress
$tpl = [IO.File]::ReadAllText((Join-Path $here 'template.html'))
if (-not $tpl.Contains('/*ICONS*/{}')) { throw 'template has no /*ICONS*/{} marker' }
$out = Join-Path $here '..\zed_quick_chords_v1.html'
[IO.File]::WriteAllText($out, $tpl.Replace('/*ICONS*/{}', $json), (New-Object Text.UTF8Encoding($false)))
"wrote $((Resolve-Path $out).Path) ($([math]::Round((Get-Item $out).Length / 1KB)) KB, $($names.Count) icons)"
