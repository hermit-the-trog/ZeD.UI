# Handoff: the change note on the main menu's corkboard (Nov 5 2026)

The director, Nov 5 2026: "on the bulletin board next to Princess Quest 3 ... the photo and a post-it note ... get
replaced with one long note, yellow paper, and it's the change notes. At the top, it lists the current beta number.
And then below is a list of very simplified change notes ... using that main menu as a way to just tell a story."
Design (Cowork). Staged, not installed: nothing under 42/ has changed.

## What it is
One long sheet of yellow legal paper pinned beside Princess Quest 3, where the sticky note and the photo were: a torn
perforated top, a red pushpin, a red double rule under the heading, faint blue rules for five lines, the lower right
corner lifting off the cork. The paper is in the picture; **the words are written by the menu**, so a release
changes a word list, not the art.

Previews (`ZeDUI/tools/mainmenu/previews/`): `main_menu_v6_note_sample_4x.png` (1080p, graded, with beta 4's words
written in), `note_v6_sample_8x.png` (the corkboard close up), `main_menu_v6_blank_4x.png` (the art as it ships).

## Files (uncommitted)
- `ZeDUI/tools/mainmenu/gen_desk.py`: THE CHANGE NOTE replaces the sticky note and the photo; four materials
  (`note`, `note_d`, `note_rule`, `note_ink`) in their own palette group `FRESH_NOTE` (14 entries), as the can, the
  book and the pad have theirs. `NOTE_SAMPLE="BETA 4|SERVER TAB|..."` in the environment writes sample words into the
  picture, for previews only.
- `ZeDUI/art/main_menu/v6/`: the art (ungraded), the blank note. Only the note's box changed from v5 (x 49-92,
  y 12-66; 2,376 pixels); lamp_dim.png and dial_clean.png are the same.
- `ZeDUI/art/main_menu/v6/desk_info.json`: v5's colours plus `NOTE_INK` (#000f34, the lit room) and `NOTE_INK_DIM`
  (#00092f, the lamp dipped), measured from the graded sample render.
- `ZeDUI/tools/menugrade/grade.py`: reads v6.

## Install
1. `cd ZeDUI/tools/menugrade`, `py grade.py none 1.0`: v6 graded into `42/media/textures/ZeD/mainmenu/`. Only
   desk.png and desk_lampdim.png should change.
2. **ZeD_MainMenu.lua writes the words** (below). Until it does, the note shows blank paper, which is fine to ship.

## The words: the contract (art pixels of desk.png; the menu draws them at the desk's own whole multiple and origin,
## the lean-in included, after the desk picture and before anything that sits over it)
- **The heading:** the 5 x 7 face from PixelFonts.lua, left edge x 52, top y 17, glyphs 1 pixel apart, a space 3
  pixels. At most 38 pixels wide (six glyphs: "BETA 4", "BETA 3A"). From the mod's version: `0.3.0-beta4` gives
  "BETA 4", `0.3.0-beta3a` "BETA 3A"; a release version gives "V" and its number if it fits ("V1.0"), else nothing.
  The dev copy's version (not a beta) shows "DEV".
- **The lines:** the 3 x 5 face, left edge x 52, tops at y 30, 37, 44, 51, 58 (each sits just above its blue rule).
  Up to five lines, at most 10 glyphs each (39 pixels), capitals; anything longer is cut at 10, never squeezed.
  Glyphs the face lacks are left out.
- **The ink:** `NOTE_INK` in the lit room, `NOTE_INK_DIM` on a lamp dip (the frame that draws desk_lampdim.png). Solid
  pixels, no dither, no shadow.
- **Where the words come from:** a small file, `42/media/lua/client/ZeD/MenuNote.lua` (`ZeD.MenuNote = { "SERVER TAB",
  "PVP MARKER", "CHAT", "ADMIN TAB", "BOX FIX" }`). English only, on purpose: it is Hermit's own note in the room, like
  the posters and the can, and the pixel faces carry capitals only. Not in the translation files.

## Every release
Build drafts the five lines from the build's change note (its headings, boiled down to ten characters each), the
director approves them with the rest of the page text, and they go in MenuNote.lua before staging (RELEASE_CHECKLIST
step 4b). Beta 4's, as drawn in the preview: SERVER TAB, PVP MARKER, CHAT, ADMIN TAB, BOX FIX.

## QA
- The menu at 1080p against `main_menu_v6_note_sample_4x.png`: the heading and lines sit on their rules, crisp, in the
  note's ink; on a lamp dip they dim with the room.
- 4K, 1280x800 and 720 (the lean-in), and ultrawide: the words stay on the paper at every multiple.
- A version without a beta number shows DEV; a line over ten characters is cut, not squeezed.
