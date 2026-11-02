# Handoff: the book on the main menu desk (Nov 1 2026)

Design → Code. The Workshop cover's book, Bitchin' znix Programs, now leans spine out on the monitor in the main menu
desk (v4), and THE SIMZ turned spine out beside it. Decisions and how to rebuild: `tools/mainmenu/README.md`.

> **Status: installed (build, Nov 1 2026, 4:06 pm; the director: "V4 is great").** grade.py none 1.0 wrote desk.png, desk_lampdim.png and dial_clean.png into the mod; the printed margin and lens colours equal ZeD_MainMenu.lua's to the byte. The check pass (the 1080p captures against the preview) is QA's next screen slot.

## What's in this (Design's files, plus one string he asked for)

| File | What |
|---|---|
| `tools/mainmenu/gen_desk.py` | the book (`book_spine`, leaned by `lean_left`), THE SIMZ spine (`simz_spine`), the boxes beside it, the book's own palette group (`FRESH_BOOK`) |
| `art/main_menu/v4/` | the staged textures: `desk.png`, `desk_lampdim.png`, `lamp_dim.png`, `dial_clean.png`, `desk_info.json` |
| `tools/mainmenu/previews/main_menu_v4_4x.png` | v4 at 1920 x 1080, graded as the mod draws it, the S125 screen pasted in |
| `tools/mainmenu/previews/spines_v3_vs_v4_6x.png` | the right of the desk, v3 then v4, graded |
| `tools/menugrade/grade.py` | reads `art/main_menu/v4`; runs without the title-video frames (they fed only a printout) |
| `42/media/lua/shared/Translate/EN/UI.json` | `UI_ZeD_MainMenu_AboutPara`: the director's rewritten note (below). Already in, at his request |

v4 keeps v3's contract and colours: `desk_info.json` is v3's, every pixel left of x 380 is v3's, the dial and needle
are untouched, and the graded margin and lens colours print exactly what `ZeD_MainMenu.lua` has.

## What Code needs to do (after sign-off)

1. From `ZeDUI/tools/menugrade`: `py grade.py none 1.0`. It writes the graded `desk.png`, `desk_lampdim.png` and
   `dial_clean.png` into `42/media/textures/ZeD/mainmenu/`. No Lua change.
2. Check pass: capture the main menu at 1920 x 1080 (normal and on a lamp dim beat), compare with
   `previews/main_menu_v4_4x.png`, captures to `ZeDUI/qa/`.

## The About text (director, Nov 1 2026, worked out line by line; the lemons and potatoes are his)

One man, not a "we". He broke into the research facility and pulled the tech for the 16-bit upgrade out of it; he got
it installed before the FBI caught up with him, and the paragraph is his note to them. Where he is now stays untold
(director: environmental storytelling; no named body, no ID). Vanilla calls them the FBI too (its "FBI Incident
Report: San Fernando Bank Robbery" magazine). The whole paragraph, as it now reads:

> Zero Day OS is a homemade SECURE kernal of ZNIX made by a freedom loving hard working good guy. thats me. FBI and you
> government slime, if you are reading this, well, you must have got me. but I got you. This thing has state of the art
> anti phone tap programming in the BIOS and I just upgraded it from 8 to 16bit thanks to some clever tech I pulled out
> of that research facility. Suck on it commies!! You cant crack ZeD-OS. oh yeah man, and by the way this thing runs off
> a truck battery, a generator, a bicycle, a hand crank, and if it comes to that, all you gotta do is grab five lemons and
> 20 potatoes and you got yourself a couple hours of quality time. LONG LIVE FREEDOM

**Check:** it is about a third longer than before (three more lines in the ZeD menu at 1080p). The ZeD menu grows to
fit it (menu-bar lists are not cut), so look at the ZeD menu at 720p and on the Deck (1280 x 800): it must still end
inside the monitor's glass.

## Parked: the book in the world (brainstorm, Nov 1 2026; not built)

- One Literature item: the book's own icon, its name, "by Hermit the Trog" where a book card shows the author.
  The author's name appears here and on the cover, never on the menu's spine.
- It does nothing: no XP, no recipe, no unlock, no achievement (director: "oh yeah, that's the book from the Steam
  page... and then they move on").
- One per world, placed, not rolled: in the desk drawer of a lone house with a PC in its basement. On world init, if
  the world's ModData flag is unset, add the book to that drawer and set the flag. The director picks the house on the
  community map (floors toggle; the basement is a negative z); confirm the basement is fixed in that house's
  definition, not generated per world.
- Open: the item's name. The cover and the spine say Bitchin' znix Programs; the director has also called it "the
  Bitchin' Guide to ZNIX".
