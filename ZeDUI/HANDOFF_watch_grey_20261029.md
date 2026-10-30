# Handoff: the watches' grey screen, the face outline and the strap (Oct 29 2026)

The director's calls, in the Cowork chat on Oct 29 2026:

- **One grey screen on every watch.** Every CaZio (the four digitals and the four classics' small window) and both Timez digitals' day glass now share one period-correct grey. The figures are dark and the unlit segments faint. The black digital's negative display (light figures on black glass) is gone. The Timez glow light (INDIGLOW) stays as it was.
- **The digital face's outline follows the metal keys.** The gold ring's flat bottom sits 2 px above the SPEED and START keys, and its bottom corners run parallel to the keys' swept-up corners. That leaves 2 dark pixels between them both ways, the same gap as before on the flat. The top corners don't change.
- **The bottom strap connection.** The strap's ridges and links showed through the case as a line where the strap tucks under it. Fixed on every watch.

Pictures the director approved, in `ZeDUI/tools/dashpx/out/` (gitignored): `watch_live_grey.png` (the game's Lua drawing the plates, with live readouts), `miniwatch_grey.png`, `cazio_frame_gap.png` (the gap he picked is the top row).

## What's already in the working tree (uncommitted)

- **`tools/physpx/d_watches.py`**
  - The new ramps are `lcdwatch` `#b3b7ab` (light 1.05) and its night `lcdwatch_n` `#4a4c46`, registered in `NIGHT` and `BULB_STEPS`.
  - In `DIGITAL`, all four use glass `lcdwatch`, ink `#1a1c16` and ghost `#a6aa9f`.
  - In `CLASSIC`, all four use glass `lcdwatch`, and the classic readout uses ink `#1a1c16`, ghost `#a6aa9f` and night `lcd_night("lcdwatch")`.
  - `face_pts(gap=2, dgap=3)` builds the digital face from `metal_key_pts`, so the outline follows the keys if they ever move.
  - `cover(d, mask)` clears the seam darkening (`d.dark`) under a part laid over the straps. It's called after the digital case, the classic's lugs and body, and the expensive one's lugs and body. The cause: `Dash.seam` writes `d.dark`, and a later `slab` doesn't reset it.
  - `lcdneg` and `BULB_INK_NEG` are still defined but nothing uses them now. Leave them or remove them, your call.
- **`tools/physpx/d_timez.py`**
  - The digital's day glass is `lcdwatch` (the lit glass `lcdglow` is untouched), with ghost `#a6aa9f` and night `lcd_night("lcdwatch")`.
  - `cover` is called after the Timez digital case and the analog's lugs and body.
  - `variants()` now gives every watch its night picture. Until now the black digital was skipped because its glass was already dark, so **`digital_black_night.png` is a new file** in the export.
- **`tools/physpx/d_miniwatch.py`** (the file is CRLF on disk; keep it that way)
  - All four digital minis use `lcd="#b8bbb3"`.
  - The black's `neg=True` is gone.
- **`42/media/lua/client/ZeD/WatchMini.lua`**
  - The four digitals share `fg #1e2416`, `off #a9aca4` and `nightFg #1a1e14`.
  - The black's `bulbInk` (the negative display's lit figures) is gone.
- **`42/media/textures/ZeD/physpx/mini/`**
  - These are regenerated. Only the 12 digital minis changed (`digital_black*`, `digital_gold*`, `timez_red`, `timez_red_night`, `timez_steel`, `timez_steel_night`).
  - The analog minis came out pixel-identical and were put back byte for byte from HEAD, so they don't show as noise.
  - `tools/physpx/miniwatch_sheet.png` is updated.

Right now the game shows the old full-size watches with the new minis. Nothing is broken; it's waiting on the export.

## What's left for Code

1. **Export the plates into the mod**, from `ZeDUI/tools/physpx`: `py export_phys.py <the mod root, the folder that holds 42/>`.
   - **Wait for the other physpx session first.** At 03:39 UTC Oct 30 it had exported the machine plates and had 491 uncommitted files, including `PhysPx.lua`. The export rewrites `PhysPx.lua` and every plate picture, so run it once that work is committed, or as part of it.
   - Expect the watch plates' pictures to change, plus a new `digital_black_night.png`. In `PhysPx.lua`, the watch plates' `radioDisplay` colours change, and the black digital's `bulbDay` / `bulbNight` figure inks are gone.
2. **Run the watch tests** (`test_watch.py`, then `platesame.py` for the nine watch plates).
   - On a scratch copy (HEAD plus these changes, exported into the copy's own `42/`) the results were 248 ok and 2 failed, and `platesame` gave 114 pictures, 0 different.
   - The 2 failures (`1.0x / 2.0x SPEED steps to 2`) fail on plain HEAD too, so they aren't from this change. They still need looking at.
3. **Fix the test harness. It doesn't run against the committed code.** I patched these in the scratch copy only:
   - `orgtest.py` doesn't load `42/media/lua/shared/ZeD/Tr.lua`, so the `ZeD.trDefaults` call at the top of `ZeD_Plate.lua` fails. In scratch I put Tr.lua first in the list of files `Org.__init__` executes.
   - `test_watch.py`'s `world()` runs `ZeD_Watch.lua`, whose `ZeD.Safe.register(...)` fails with `ZeD.Safe` nil. In scratch I stubbed `ZeD.Safe` before it.
   - `ZeD_PixelParts.lua` builds its upper-case table with `string.char` on codes above 255 (Cyrillic, `ÿ`→`Ÿ`, `pair` and `put`). Kahlua takes those, but LuaJIT (lupa) throws. In scratch I wrapped `string.char` in the harness prelude to map codes over 255 to `?`. A proper fix belongs in the harness, not the mod.
4. **Check in game** the way the director tests: fullscreen at 4K, ZeD scale 1.75, windows reset (the footer's R) first. Check by day, at night, with the bulb (LIGHT) on, while setting the alarm, the Timez lit, and the belt minis.
5. **Update the docs.**
   - `DASHBOARD_WATCH_SPEC.md` line 110 still says "positive and negative LCDs varied across the digital items". It's now one grey positive display for every watch, with the Timez lit glow as the only other screen.
   - Add a line to `WATCH_ADDON_GUIDE.md` (and the Project doc `claude/watch-addon-guide.md`) under "The rules the built-ins follow": add-on watches use the `lcdwatch` glass, so every screen matches.
   - Add a line to STATE.md.
6. **Commit.** The director hasn't asked for a commit from Cowork. Suggested message: `Watches: one grey screen on every CaZio and Timez (Indiglo kept); digital face outline follows the metal keys; strap seams no longer show through the case`.
