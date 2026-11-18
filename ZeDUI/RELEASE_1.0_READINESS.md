# ZeD-GUI 1.0: readiness, punch list and the checks a release needs (Nov 17 2026, Build)

The director asked, going to bed on Nov 17: get a beta ready, then prep for 1.0. What's still missing? Any gaps, any
hidden corners in the game's code we missed? Can anything be trimmed? And what kinds of checks is the director missing,
being new to game and mod making?

This is Build's answer, in four parts. The punch list (part 2) and the trims (part 3) come from two code sweeps made
overnight; their findings are summarized there with file references, and the raw lists are linked.

---

## 1. The checks a game mod's release needs, and where ZeD stands

Most of what makes a mod feel finished isn't its features. It's whether it survives the many ways players use it. Here
are the kinds of checks studios run before a release, in plain words, with what ZeD already does and what it doesn't
do yet. **Have** means a check exists and runs. **Partial** means it exists but doesn't cover everything. **Missing**
means nothing checks it today.

| Check | What it protects | ZeD today |
|---|---|---|
| **Regression run** | A change in one place breaking something elsewhere | **Have.** About 85 in-game scripts at 4K and the Deck, plus 160 offline sims, before every upload. |
| **Fresh-player run** | The first hour: a brand-new player with no saved settings, no layout, default everything | **Partial.** QA plays on a stocked months-old character. Nobody checks a clean install: an empty Zomboid folder, a new character, the first time each window opens. |
| **Add to and remove from a save** | A player adding ZeD mid-game, or removing it, and their save surviving | **Partial.** The digital watch's removal is designed for. No test actually loads a long-played save with ZeD, then without it, then with it again. |
| **Upgrade from an older version** | Settings, layouts and records written by beta 5 still read right in 1.0 | **Missing.** Each build starts from the QA's current files. A 1.0 player arrives with files from any beta. |
| **Long session (soak)** | Memory growing, slowdowns and errors that only show after hours | **Partial.** Two soak scripts exist; there's no regular overnight run with memory and frame time recorded. |
| **Performance budget** | The game staying smooth on slow machines (one player plays on an 8 GB Mac Air) | **Partial.** Probes exist, but no agreed limit ("ZeD may take at most N ms a frame") is checked on every build. |
| **Many screens and sizes** | 4K, 1080p, 1440p, ultrawide, 720p, the Deck, UI scale 1x to 2x | **Partial.** 4K, 1080p, 1280x800 and the Deck are covered. Ultrawide (3440x1440) and 1440p aren't checked. |
| **Every input** | Keyboard and mouse, Xbox, PlayStation, Nintendo, the Deck, a pad plugged or unplugged mid-game | **Partial.** A stand-in pad and the Deck. Hot-plugging a pad mid-game and PlayStation's own button layout aren't checked on hardware. |
| **Multiplayer** | Joining, a dedicated server, an admin, PvP, a player with ZeD next to one without | **Partial.** A local two-player kit exists. A dedicated server with several real clients, and lag, aren't checked. |
| **Split screen** | Two players on one PC | **On hold** by the director's call until the end of November. 1.0 must say so plainly. |
| **Other mods** | The top mods players use alongside ZeD | **Have,** in rounds. 1.0 needs one last pass over the most-subscribed UI and QoL mods. |
| **Languages** | Every phrase translated, nothing overflowing, other alphabets showing | **Partial.** A guard checks every phrase has a key. Long languages (German, Russian), Chinese, Japanese, Korean and Thai are not looked at on screen in every window. |
| **Game updates** | The game's next build breaking ZeD | **Partial.** Checked when a build lands. 1.0 needs one run on the game's unstable branch if there is one. |
| **Errors handled** | One failing piece taking down the interface | **Have.** Safe mode, the watchdog that steps aside, and Messages keeping errors. |
| **Accessibility** | High contrast, color blind, large text, no flashing | **Have** by design, but not checked as one pass over every window. |
| **The Workshop page** | Size, description, gallery, tags, the "how to start" steps true on a clean install | **Have.** 1.0 is a separate new item: its page, cover and first-hour text need a fresh read as a stranger. |
| **Support plan** | What happens the week after release: who reads reports, how fast fixes ship, how to roll back | **Missing** as a written plan. |
| **Legal and credits** | Licences of fonts and art, credits for supported mods, no other studio's material | **Have.** The licence and font licences ship. 1.0 needs one sweep that every shipped picture is ZeD's own or licensed. |

**What Build recommends adding before 1.0, in order of value:**
1. **A fresh-player run:** an empty Zomboid folder, a new character, every window opened for the first time.
2. **An upgrade check:** each beta's settings and records (ModOptions.ini, layouts, step-aside, loadouts) loaded into
   1.0, from saved copies of those files.
3. **The save round trip:** a long-played save loaded with ZeD, without it, and with it again, checking the
   character's items and the world.
4. **An overnight soak:** a few hours of the QA's walk with memory and frame time recorded, and a budget agreed on.
5. **One multiplayer evening:** a dedicated server, three or four clients, an admin, PvP.
6. **A language look:** German, Russian, Simplified Chinese and Japanese, every window pictured.
7. **Ultrawide and 1440p:** one regression run each.
8. **The support plan:** a short written note for release week.

---

## 2. Punch list for 1.0

### 2a. The game's screens ZeD still leaves vanilla (coverage sweep, Nov 17)

**How the sweep was done:**
- Every one of the game's roughly 840 UI classes was checked against ZeD's code, along with the way a player actually
  opens each one.
- **The result:** ZeD covers nearly every screen a normal player reaches. That includes the inventory, menus,
  tooltips, character, crafting, stations, appliances, info cards, liquids, furniture, animals, radios, vehicles,
  wheels, maps, print, notes, trade, prompts, death and respawn, sleep, controllers, foraging, fishing, the guide,
  chat, the multiplayer and admin panels, and the main menu, options and mods.
- **Kept on purpose:** the moodles, the loading screen, the tutorial, the genome cheat, the host's server editor and
  the staff's editable server options.
- **The full table** with file references is the sweep's report.

**The gaps, most often met first.** (Build checked gaps 1 and 2 itself: nothing in ZeD touches them.)

| # | What the player sees | Where | Kind |
|---|---|---|---|
| 1 | **The game's version watermark**, bottom right, in every game. On a server it also lists coordinates, ping, the server's name and cheats in use. | `WaterMarkUI` (ISUI/ISVersionWaterMark.lua), made at every game start | Always on screen |
| 2 | **"Show growing seasons"** on a seed's or a magazine's recipes opens the game's own literature window, on its Agriculture tab | `ISInventoryPaneContextMenu.showGrowingSeasons` → `ISCharacterScreen:onShowLiterature` | Hidden corner: the recipe list's other entries go to ZeD's windows |
| 3 | **The FPS overlay** (its key shows the game's FPS and CPU text by the left edge) | ISUI/FPS.lua; ZeD's left-edge code keeps `renderFPS` | Kept without a design note |
| 4 | **The war icon and countdown** on the left edge (a server, a faction at war) | ISEquippedItem, not in ZeD's hide list; ZeD only reroutes its click | Multiplayer |
| 5 | **A server alert** (`/servermsg`): a big red line across the screen for 5 seconds. ZeD's own repeating server message tool sends these. | Chat/ISAlert.lua, `Events.OnAlertMessage` | Multiplayer |
| 6 | **The admin's right-click "Tools"** (teleport, remove items, spawn a vehicle, horde manager, thunder) | DebugUIs/AdminContextMenu.lua, admins and moderators on a server | Staff only |
| 7 | The admin's mini scoreboard | Its only door is a button ZeD hides | Unreachable; no ZeD equivalent |
| 8 | Split-screen players 2 and up | Known, on hold until the end of November | Planned |
| 9 | Maybe a fish catalogue window (`PZAPI.UI.FishWindow`), if the game's Java opens it | No Lua caller found | Unsure |

**Hidden corners that hold:**
- The perform-level hooks catch every route: menu, key and controller.
- Dead game paths were confirmed dead in 42.22: the old open-container action, the pause menu's admin items, the
  emote editor and the weather window.

**Two fallbacks worth knowing:**
- ZeD hands a Character screen back to the game in three cases: a dead character, a page from another mod with no
  ZeD tab, and the tutorial.
- With the "windows" switch off, every World window card falls back to the game's own window.

### 2b. Open from today

| Item | State |
|---|---|
| The controller card on an empty stop | Fixed (4db3b9f36); QA passed it 4/4 at 4K and Deck, Nov 18. |
| Beta 20 | QA passed it, then the director held the upload until the gallery is done; the stage was taken down so QA could shoot, and is restaged at the upload go. |
| A blank box over "Test Controller" (Options, Button map and test) | Real, every size: the Options window's Find field stays on the sub page (ZeD_MainMenuOptions.lua `self.find`; hide it in ZeD_MainMenuOptionsSub.lua's prerender while `self.sub` is set). The director, Nov 18: not before beta 20's upload. |
| The 1.0 gallery | Every QA picture is in `gallery_v1_wip` (Nov 18), except fishing (59): the director says skip it for now and come back later. Next: Design's copy and layout. |
| The fact page | Drafted and answered. It needs a font that draws Thai, Japanese, Chinese and Korean. |
| Design's ten new over-head icons | The director's pick |
| Simple versions of the pins, pointer and eye | The director's call |
| The pin's lens size and the tiny poison mark | Design's call |
| The ZeD-last step-aside record | Passing. The rig fix: reset the record around each run. |

### 2c. Before 1.0 (the checks in part 1)

1. The fresh-player run.
2. The upgrade check from old beta files.
3. The save round trip.
4. The overnight soak.
5. One multiplayer evening.
6. The language look.
7. Ultrawide and 1440p.
8. The release-week support note.

---

## 3. What can be trimmed

**What ships today:** 5,808 files, 81 MB (from the staging script's dry run).

| Part | Size |
|---|---|
| Pictures | 38 MB |
| Fonts | 18 MB |
| Translations | 13 MB |
| Lua | 12 MB |

**Safe to remove before 1.0** (nothing loads them; Build checked the two biggest itself):

| What | Size | Why it's dead |
|---|---|---|
| `textures/ZeD/dash/` (old radio and siren plates) | 1.3 MB | Replaced by the `physpx/` art. A seat window's path into a "dash" folder points under `seats/popout/`, not here. |
| `fonts/**/rsv1-4` | 2.0 MB | No font list names them; Tokens.lua says they're unmapped |
| `textures/ZeD/watch/` and `body/m-body.png` | 0.1 MB | Replaced by `physpx/`; the body figure loads its parts only |
| `WatchPlates.lua`, `RadioPlates.lua`, `SirenPlate.lua` | 18 KB | Generated tables nothing reads |
| Two wheel icons (`zw_medkit`, `zw_point`) | 1 KB | The wheel uses `r_medkit` |
| About 750 lines of unused functions; 10 unused locals | small | Each one is named nowhere else |
| 149 unused translation phrases, plus 8 radio phrases that exist in 27 languages but not English (unused too) | about 0.3 MB | The `Settings_Screen*Tip`, `Dash_Lamp*`, `Mods_Rule*` and `Adm_*` families may be built by joining strings: check those before cutting |

**Smaller files, same look:**

| What | Saves | Cost |
|---|---|---|
| The guide's stills (82 files, 128 colours each) and the studio backdrops (34) stored as palette pictures | 3 to 4 MB | None. The pictures are identical; no code changes. |
| The TV's static: 45 baked "snow" frames at 14 sizes (8.6 MB), replaced by one noise tile drawn scaled | 8.6 MB | A small code change in the TV face |

Together that's about 15 MB off 81.

**Leave alone for 1.0:**
- The 218 groups of identical small pictures: only 0.27 MB, and each is addressed by its own name.
- The Chile and Mexico Spanish files: the game doesn't fall back from them to Spain's Spanish.
- The overlap between the Character and World windows' code: a refactor for after 1.0.

**Dev leftovers that ship:**
- **The QA hooks:** about 275 lines name QA hooks, most of them cheap "skip if QA" checks. They're harmless to players.
  The bridge itself never ships.
- **Chatty console lines:** about 30 per-event lines, mostly in the controller's focus code. They write to
  console.txt on every move and every mode switch: not a slowdown, but noisy for anyone reading a bug report's log.
  Worth quieting for 1.0.
- **Stand-in art:** two pieces are still marked as stand-ins, the fishing rod frames and the clock radio. Design
  should either finish them or confirm them as final.

---

## 4. Open calls for the director

1. **The game's version watermark** (bottom right, every game): hide it, give it a ZeD look, or leave it?
2. **"Show growing seasons":** build it as a ZeD page, or leave the game's literature window for that one entry?
3. **The FPS overlay:** keep the game's, or draw it the ZeD way?
4. **Multiplayer leftovers:** the war icon and countdown, the red server alert and the admin's right-click Tools. Do
   these before 1.0, or after?
5. **The trims:** remove the dead files and unused code before 1.0 (about 3.5 MB), re-save the pictures as palette
   pictures (3 to 4 MB), and replace the TV static (8.6 MB)? Build recommends all three; none changes what a player
   sees.
6. **Split screen at 1.0:** state plainly that it's single-screen only, as planned?
7. **Which of the 8 new checks** (part 1) to run before 1.0?
