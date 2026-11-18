# For Design: why ~30 gallery pictures were blurred (QA, Nov 17 2026)

The director found about 30 of the 65 gallery pictures blurred. QA measured each suspect alone, at the same spot:

- **The cause: prescription glasses on characters who are not short-sighted.** In Build 42, glasses you don't need
  blur the whole world. Sharpness for the QA character was 74 with `Base.Glasses_Prescription` on and 1089 with them
  off. For Angel after the story stage, it was 26 with the prescription aviators on and 347 off.
- **Not the cause:** panic, stress, drink and pausing changed nothing.
- **Why:** the gallery scripts dressed the glasses from an old note that the QA character was short-sighted. The game
  now logs "short sighted false" for both characters.

**What QA is doing:**
- The scripts now wear prescription glasses only when the character has the Short Sighted trait.
- The blurred set is being retaken from the same spots and angles, so the new pictures drop into the 1.0 layout:
  - g1_01/17 vanilla, g1_25, 26, 35, 39, 46, 04 and 65
  - journal_kills_1, the six themes, gb_simple_*, gb_plain_radio, the gw_ pair, van_20 and van_32
- Also being fixed: the watches in daylight with the map loaded, crafting and building moved to a lived-in place,
  the vanilla craft window's "( DBG:...)" line, the server chat (no teleport lines) and its names (no "zedqa"), and
  the street set's weight.

**For the copy:** if any caption or note mentions Angel's glasses, it no longer matches the retaken pictures.

Reports: `ZeDUI/qa/regression/2026-11-17_blur_probe2.md`, `2026-11-17_blur_probe_story2.md`.
