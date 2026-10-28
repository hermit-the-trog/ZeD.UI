# Licensed pictures out of the mod (Oct 28 2026)

With the director's OK, after the right-click menu moved to ZeD's pixel icons (`ZeDUI/qa/Oct28_ctx_icons/`):
915 pictures left `42/media/textures/ZeD/icons/` (`msg_note.png`, ours, stays) and the 236 flat tab pictures left
`42/media/textures/ZeD/TabIcons/` (the tabs draw their pixel art from `TabIcons/px/`). The code that loaded them went
with them: the tab definitions' `icon`, `ZeD.Atoms.sizedTexture`, `ZeD.ActionStrip.getTex` (the action strip, which
nothing draws, now names pixel icons), the item card's zone-dock pictures (the dock draws its own mark) and the D-pad
wheels' tab-picture fallback (every tab has a wheel icon).

`report_4k.md`: manifest `ZeDUI/tools/qa/icons_cleanup_manifest.txt`, 9/9 at 4K fullscreen, UI scale 1.75x: every
tab of both windows, the right-click menu, the windows' pixel icons and the item card's marks, the UI scale steps
(`zedqa_uiscale.lua` now reads the pixel icon drawn for a 16-unit box: 24 at 1.75x and 1.5x), a garment's card, the
grid, the wheels and the D-pad wheels. The console has no missing ZeD picture; its only picture errors are the game's
own three font pages (AngelCodeFont), logged on every start.
