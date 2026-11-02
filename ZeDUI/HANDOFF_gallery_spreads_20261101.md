# Handoff: the Workshop gallery laid out as a worked-through manual (Nov 1 2026)

Design to QA and the director. This answers `HANDOFF_gallery_manual_20261101.md`. How a spread is built is in
`workshop/gallery/SPREADS.md`, and the folder is described in `workshop/gallery/README.md`.

## Where it stands

- **Laid out:** the cover, the title spread and all 60 spreads. The spreads are `workshop/gallery/spreads/NN_id.json`,
  drawn into `out_spread/`. A full render prints no CHECK lines. Spread 21 is the sample the director approved
  ("Nailed it!").
- **Upload set:** 62 JPEGs in `workshop/gallery/upload/`, made by `make_upload.py`: `00_cover.jpg`,
  `00_title.jpg`, then `01_hero.jpg` to `60_machine_plates.jpg`. Upload them in file order. Each is under Steam's
  1 MB (the largest, 31, is 737,640 bytes) and keeps full colour resolution, so the red and blue ink stays sharp. This set
  replaces the Oct 30 one, which stays in git history.
- **Proofread:** a separate pass checked every word against `shots.json`, `REVIEW_20261101.md`, the specs and the
  game's own UI strings, and changed text on 41 spreads. Design then made follow-up fixes on 12 spreads and the
  title spread. All of it is wording; no layout changed. House style is now in `SPREADS.md`:
  - ZNIX in the publisher's text, ZeD only in screen names;
  - "click" for the screen, "press" for keys;
  - *View*, not Select;
  - American spelling;
  - names as the screen shows them.
- **Privacy:** Windows OCR over all 170 printed crops found no user name, folder path, e-mail address or account.
  The mod manager prints show other modders' public Workshop mod names, which is fine. 55's crop stops above the
  mod's folder path on purpose.
- **Fonts:** Fira Sans SemiBold and Fira Mono (OFL) are copied into `gallery/fonts/`, and `spread.py` loads them
  from there. Before, they lived in `zed_backups/`, which git ignores.

## For QA: retakes

Each item names the capture that is printed now and what the retake needs to show. If the retake keeps the same
window rect, the JSON needs nothing. If anything moved, Design re-reads the crops and points with `peek.py`.

1. **46 Wallpapers and 47 The Desk.** The captures are `desk_02_painting_wallpaper_setting.png`,
   `desk_04_video_wallpaper_setting.png` and `desk_05_trash_computer.png`. They were taken Oct 31 at 0:13, before
   the v4 desk art went in (Nov 1, 4:06 PM), so they show the old desk: no znix book against the monitor, and the
   SIMZ box face on.
   - Retake all three on the v4 desk.
   - On 46, move the Project Zomboid window aside so more of each wallpaper shows (optional).
   - 47 points at four things on the desk, at capture pixels (2765, 345), (1700, 1790), (2190, 1040) and (2765, 1575).
2. **23 Health tab.** `zed_11_health_exercise.png` (Oct 30). Retake with the Exercise pop-up open and a body part
   hovered (needs a real pointer). Two printed sentences, on the dimmed exercise and the hover, were cut until then.
3. **3 The Plan.** `story_02a_journal_entry.png` (Oct 31). Retake with the journal's Page pop-up open (needs a real
   pointer).
4. **29 Foraging (if it can be done).** `zed_51_forage.png` (Nov 1, 3:12 PM). Three of the five finds show "?" where
   the bearing goes.
5. **48 Options (only if the director wants it).** The left print is `_before_nov1/mm4_01_options_zed.png`
   (Oct 31), the Look section at the top of ZeD setup.
6. **Optional:**
   - 15: a control's plain-words help in the help line (needs a real pointer).
   - 26: the action bar while reading a book with a short title, so the bar shows it whole, plus the Simple style.
   - 56: the Save to loadout submenu open.

## For the director

**The sticky notes are yours.** Each taped page has one, in black, at the bottom. These are Design's drafts from the
slide captions, with no jokes. 21's went out with the approved sample.

| Ch. | Title | Left page | Right page |
|---|---|---|---|
| 1 | Introduction | - | The whole screen: two windows and the belt. |
| 2 | Old Job | Six days in: Mechanics 7, Welding 6, Cooking 2. | Angel pumped gas at the Fossoil. |
| 3 | The Plan | The plan, in a note in the journal. | A flyer for the old station. |
| 4 | The Route | Marks and notes on the map. | The map: World window, Maps tab. |
| 5 | Driving In | The dashboard, drawn to match the car. | Seat 1 is the driver's seat. |
| 6 | Fixing the Car | Fixing the wagon: the Vehicle tab. | The job runs: the band and the action bar. |
| 7 | Barricading | - | Boarding up the front window. |
| 8 | Stocking Shelves | Stocking the shelves, one drag at a time. | Three shelves and the ground, all in reach. |
| 9 | Open for Business | The Fossoil's colors: Light and Blue. | Open for business: Light theme, Blue accent. |
| 10 | Pumping Gas | Filling a gas can at the pump. | The wagon's tank after refueling: near F. |
| 11 | Customers | The belt: watch, hands, slots and buckle. | - |
| 12 | Smoke Break | The bar says what you are doing. | Point at a moodle to read it. |
| 13 | Keeping Count | The Journal keeps count for you. | - |
| 14 | Night Shift | Night: the lights come on. | Dark theme, blue accent. |
| 15 | Every Window | The window box pulls down the window menu. | The help line is at the foot. |
| 16 | See-through | Solid while in use. | See-through: 100 to 60. |
| 17 | Controller Highlight | Four ways to mark what the controller is on. | - |
| 18 | Hidden Actions | What you can't do yet folds into one row. | Show all: grayed, with what each needs. |
| 19 | Inventory and Loot | The game's own: one container per window. | In ZeD every container is a column. |
| 20 | List or Grid | List: one row per item. | Grid: a picture of each item. |
| 21 | Item Cards | - | Click an item to open its card. Food gets a nutrition label! |
| 22 | Equipment Tab | - | Drag a worn item to a bag or the ground to take it off. |
| 23 | Health Tab | - | The Health tab: the body, overall health and exercise. |
| 24 | Thermal Tab | - | The Thermal tab in three of its views. |
| 25 | Context Menus | - | Choose the strip or the list in Options, ZeD setup. |
| 26 | Action Bar | - | Set the action bar in Options, ZeD setup. |
| 27 | Crafting | - | The Crafting tab, with a recipe open. |
| 28 | Building | - | The Building tab, with a recipe open. |
| 29 | Foraging and Furniture | Furniture: pick a mode, then point at a piece. | The Foraging tab while searching. |
| 30 | The Belt | The hands sit at the left end of the belt, then the strap. | A gun in the main hand adds a tab for its rounds. |
| 31 | Speech, Thoughts and Hands | The hands sit at the belt's left end, each with a condition ring. | Over the head: what you say and what you're doing. |
| 32 | Moodles | - | Put the moodles where you want them. |
| 33 | Watches | The watch you wear, on the belt. | - |
| 34 | Messages | - | Notes from other mods wait in one window. |
| 35 | The Car Radio | - | Tune it, store your stations, play a CD. |
| 36 | Dashboards | - | The taxi's dash: key, meter and ash tray all work. |
| 37 | Two-Way Radios | - | Each radio gets its own face, and every knob works. |
| 38 | Ovens and Microwaves | - | In the tab, or in their own window. |
| 39 | Reading and Writing | A notebook opens as a page to write on. | A newspaper opens in a reader. |
| 40 | Fishing | The rod shows the tension on the line. | Past the limit, the line snaps. |
| 41 | Questions | The game's questions, drawn as ZeD windows. | The pad gets an on-screen keyboard. |
| 42 | Controller | - | Every mouse action has a button. |
| 43 | On a Controller | Hold a D-pad direction for a wheel. | Point with the right stick, let go to take. |
| 44 | Quick Actions | Twelve actions, one chord each. | Put things back is off until you turn it on. |
| 45 | Themes and Accents | Three base themes and an accent color. | Click the window box for the window menu. |
| 46 | Wallpapers | Two wallpapers for the desk's monitor. | A square marks the one in use. |
| 47 | The Desk | - | The main menu is a desk with a monitor. |
| 48 | Options | ZeD setup comes first. | The game's pages say what ZeD replaces. |
| 49 | Sandbox Options in Game | Change the sandbox settings in game. | Off until you turn it on in ZeD setup. |
| 50 | Mods | Mods: problems and conflicts. | What each mod needs and what turning it off does. |
| 51 | A Mod's Settings | A mod's own options, kept as you change them. | Sandbox settings, and a reset that asks first. |
| 52 | Picking Files | Two mods, the same file: pick whose copy runs. | Use these picks, then reload. No restart. |
| 53 | Turning a Mod Off | - | Careful or not safe: what it does to a save. |
| 54 | Profiles and Load Order | A profile keeps a mod list and its load order. | A red row loads before what it needs. |
| 55 | Uploading | Upload to the Workshop from one window. | The description editor shows the page as Steam will. |
| 56 | Loadouts | - | Restock a loadout before a trip. |
| 57 | Radios and the CD Player | Each set has its own face in the Radio tab. | Two radios, worked as the sets are. |
| 58 | Television Sets | Three television sets, each with its own face. | Picture, snow or the off-air cards. |
| 59 | Washer and Dryer | Washer, dryer and washer-dryer, each with its own face. | The game's own actions run them. |
| 60 | Machine Plates | - | Each machine has its own plate. |

A "-" means that page is a manual page and gets no sticky. 1 is one picture across both pages, so it has one
sticky. Design added no jokes: the green note on 11 is the director's own, from `book_notes.json`.

**Calls to make (each is left as it is now):**

1. **11's opener:** "The Fossoil station is open, and its first customers are in the store." This is deadpan in
   the publisher's voice, following the shot list's own callout ("Customers queue at the counter"). Keep it, or make
   it plain ("The Fossoil station is open.") and let the green note carry the joke alone.
2. **30 and 31 print the same two hands-on-belt captures.** The shot list gives both slides `zqa_ht_01_two` and
   `zqa_ht_02_both`. Keep both, or let 30 own the hands and make 31 speech and thoughts only.
3. **56's printed Note asks testers to report in Bug reports.** A 1993 publisher would not know Steam's Bug reports.
   The wording follows the shot list's caption, and his green pen underlines "Bug reports". The alternative is to
   put the request on his sticky instead.
4. **The pictures disagree with each other, though no text does:**
   - kills read 23 on the ID card (Figure 2-2), 358 on the journal heading (3-1) and 212 in 13-1;
   - one journal entry is dated Jul 18 in 3-1 and Jul 17 in 13-1;
   - 5 drives the wagon in, and 6 finds it short a tire.

   Only retakes from one save would line these up.

## For Design next time

- **New in `spread.py` on Nov 1:**
  - every render stamps the layout desk (`watch.py`; open `watch.html`);
  - prints at a whole-number scale of 2 or more are pixel-doubled, and `"resample"` overrides that;
  - `"from"` and per-arrow `"bend"` on notes;
  - a sticky with no `"h"` fits its writing;
  - new checks: writing over printed text, a sticky's writing past its foot, a sticky hiding print on a manual page,
    an arrow pointing under tape.
- **Something on this PC holds `spread.py` open.** Replacing it fails with "Access is denied", whether through
  `os.replace` or an editor that saves by rename. Patch it in place: read it, replace, `compile()` the result, write
  over the file with `open(path, "r+b")`, then truncate.
- **`out_spread/` is the PNG masters and is not committed.** `out_spread/_watch/` holds every draft and ignores
  itself.

## Not committed

Design did not commit. These are the gallery's changes, all under `ZeDUI/workshop/gallery/` unless a path says
otherwise:

- the docs: `README.md`, `SPREADS.md`, `fonts/FONTS.md`;
- the scripts: `spread.py`, `title_spread.py`, `make_upload.py`, `watch.py`, `watch.html`, `peek.py`,
  `review_tools.py`;
- the pages: `spreads/` (60 spreads and `_book.json`) and `upload/` (61 replaced, `00_title.jpg` new);
- the fonts: `fonts/FiraSans-SemiBold.ttf`, `fonts/FiraMono-Regular.ttf`;
- the cover's D&B DOCS GROUP line: `cover_px.py`, `znix_01_cover.png`, `znix_01_cover_1x.png`;
- this handoff: `ZeDUI/HANDOFF_gallery_spreads_20261101.md`.

QA's own afternoon change is not part of this: the two arrow numbers in `book_shots.py` and the `out_book/`
re-render.
