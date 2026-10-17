# tabpx: the window tabs in lit pixel art (Oct 16 2026)

The character and world windows' tab icons, redrawn as small objects lit from the top left (director's call: treatment
A, the strip unchanged, the active tab a bevelled lit accent panel, the icons redrawn as lit objects).

- `icons.py` — the fifteen icons, 16 x 16, keyed by tab id, in five tones (w shine, l lit, m accent, d shade, k deep)
- `export_tabs.py [mod root]` — writes the white tone masks and shadow masks (`media/textures/ZeD/TabIcons/px/`)
- `test_tabs.py` — runs `ZeD_TabPx.lua` under LuaJIT in every base theme and several accents at 1x and 2x and checks it
  against this folder's reference drawing, pixel for pixel
- `mock.py`, `render_icons.py` — the concept sheets (the current look and treatments A, B, C) and the icon sheets

In game: `42/media/lua/client/ZeD/ZeD_TabPx.lua`, called from both windows' tab strips. Colours come from ZeD.T every
frame, so every base and accent works. A tab id without an icon here keeps the old flat look.
