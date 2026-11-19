# ZeD-UI regression - 2026-11-19 15:11 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-19 15:11:07 |
| Finished | 2026-11-19 15:20:30 (9 min 22 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_test.txt (15 scripts) |
| Result | **14/15 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 30368 to 30384 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30383, 30384)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back
- ZeD_tutorial.txt removed (there was none before the run)

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_windows.lua | rt_win | PASS | 35 |  |  |
| 4 | rt_inventory.lua | rt_inv | PASS | 29 |  |  |
| 5 | rt_menus.lua | rt_menu | PASS | 7 |  |  |
| 6 | rt_cards.lua | rt_cards | PASS | 44 |  |  |
| 7 | rt_hud.lua | rt_hud | PASS | 45 |  |  |
| 8 | rt_pad.lua | rt_pad | **FAIL** | 22 |  | 2 ERR line(s); its own checks failed (VERDICT FAIL) |
| 9 | rt_media.lua | rt_media | PASS | 27 |  |  |
| 10 | rt_vehicles.lua | rt_veh | PASS | 27 |  |  |
| 11 | rt_addon.lua | rt_addon | PASS | 4 |  |  |
| 12 | rt_lite.lua | rt_lite | PASS | 7 |  |  |
| 13 | rt_kbmap.lua | rt_kbmap | PASS | 3 |  |  |
| 14 | rt_tour.lua | rt_tour | PASS | 14 |  |  |
| 15 | rt_system.lua | rt_sys | PASS | 158 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30368 at 15:12:12

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 30369 at 15:12:17

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_windows.lua (`ZEDQA rt_win`) - PASS, 35 s

- go 30370 at 15:12:22

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_win start (252 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_win screen 3840x2160, half card 385 / 455 px, full card 840 px, pair open true
ZEDQA rt_win PASS mouse: the inventory key's action closes both windows | Character false, World false
ZEDQA rt_win PASS mouse: the inventory key's action opens both windows | Character true, World true
ZEDQA rt_win PASS on screen (both windows open): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS mouse: the inventory key's action closes both windows again | Character false, World false
ZEDQA rt_win PASS Character window: its strip offers its tabs | loot, equip, health, thermal, identity, journal, skills
ZEDQA rt_win PASS Character strip: every tab has its lit pixel icon (ZeD.TabPx.has) | 7 tabs
ZEDQA rt_win PASS Character strip: each tab's zone is what hitZoneAt finds at its middle | 7 zones
ZEDQA rt_win PASS Character tab loot: pressed on the strip, it is the active tab | active loot
ZEDQA rt_win PASS Character tab loot: no drawer, or the half or the full card | 0 px = closed
ZEDQA rt_win PASS Character tab loot: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab loot: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab loot): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab equip: pressed on the strip, it is the active tab | active equip
ZEDQA rt_win PASS Character tab equip: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab equip: the title names the open tab | title 'Angel Cross + Equipment', want 'Angel Cross + Equipment'
ZEDQA rt_win PASS Character tab equip: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab equip: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab equip: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab equip): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab health: pressed on the strip, it is the active tab | active health
ZEDQA rt_win PASS Character tab health: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab health: the title names the open tab | title 'Angel Cross + Health', want 'Angel Cross + Health'
ZEDQA rt_win PASS Character tab health: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab health: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab health: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab health): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab thermal: pressed on the strip, it is the active tab | active thermal
ZEDQA rt_win PASS Character tab thermal: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab thermal: the title names the open tab | title 'Angel Cross + Thermal', want 'Angel Cross + Thermal'
ZEDQA rt_win PASS Character tab thermal: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab thermal: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab thermal: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab thermal): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab identity: pressed on the strip, it is the active tab | active identity
ZEDQA rt_win PASS Character tab identity: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab identity: the title names the open tab | title 'Angel Cross + Identity', want 'Angel Cross + Identity'
ZEDQA rt_win PASS Character tab identity: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab identity: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab identity: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab identity): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab journal: pressed on the strip, it is the active tab | active journal
ZEDQA rt_win PASS Character tab journal: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab journal: the title names the open tab | title 'Angel Cross + Journal', want 'Angel Cross + Journal'
ZEDQA rt_win PASS Character tab journal: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab journal: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab journal: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab journal): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character tab skills: pressed on the strip, it is the active tab | active skills
ZEDQA rt_win PASS Character tab skills: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab skills: the title names the open tab | title 'Angel Cross + Skills', want 'Angel Cross + Skills'
ZEDQA rt_win PASS Character tab skills: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS Character tab skills: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab skills: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab skills): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World window: its strip offers its tabs | loot, craft, build, furniture, maps, forage, animals
ZEDQA rt_win PASS World strip: every tab has its lit pixel icon (ZeD.TabPx.has) | 7 tabs
ZEDQA rt_win PASS World strip: each tab's zone is what hitZoneAt finds at its middle | 7 zones
ZEDQA rt_win PASS World tab loot: pressed on the strip, it is the active tab | active loot
ZEDQA rt_win PASS World tab loot: no drawer, or the half or the full card | 0 px = closed
ZEDQA rt_win PASS World tab loot: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab loot: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab loot): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab craft: pressed on the strip, it is the active tab | active craft
ZEDQA rt_win PASS World tab craft: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab craft: the title names the open tab | title 'Ground + Crafting', want 'Ground + Crafting'
ZEDQA rt_win PASS World tab craft: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab craft: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab craft: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab craft): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab build: pressed on the strip, it is the active tab | active build
ZEDQA rt_win PASS World tab build: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab build: the title names the open tab | title 'Ground + Building', want 'Ground + Building'
ZEDQA rt_win PASS World tab build: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab build: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab build: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab build): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab furniture: pressed on the strip, it is the active tab | active furniture
ZEDQA rt_win PASS World tab furniture: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab furniture: the title names the open tab | title 'Ground + Furniture', want 'Ground + Furniture'
ZEDQA rt_win PASS World tab furniture: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab furniture: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab furniture: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab furniture): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab maps: pressed on the strip, it is the active tab | active maps
ZEDQA rt_win PASS World tab maps: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab maps: the title names the open tab | title 'Ground + Maps', want 'Ground + Maps'
ZEDQA rt_win PASS World tab maps: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab maps: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab maps: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab maps): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab forage: pressed on the strip, it is the active tab | active forage
ZEDQA rt_win PASS World tab forage: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab forage: the title names the open tab | title 'Ground + Foraging', want 'Ground + Foraging'
ZEDQA rt_win PASS World tab forage: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab forage: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab forage: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab forage): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World tab animals: pressed on the strip, it is the active tab | active animals
ZEDQA rt_win PASS World tab animals: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab animals: the title names the open tab | title 'Ground + Animals', want 'Ground + Animals'
ZEDQA rt_win PASS World tab animals: a full-card tab, the same card as the window's other full-card tabs | full (the window's: full)
ZEDQA rt_win PASS World tab animals: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab animals: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab animals): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character curtain: the side rolls up under its rod (on skills) | rolled true, rod true
ZEDQA rt_win PASS Character curtain: rolled, the window is its box less the side | 294,0 1617x735 less 714 -> 294,0 903x735
ZEDQA rt_win PASS on screen (Character curtain rolled): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_win PASS Character curtain: the rod's tab rolls the side back down | rolled false
ZEDQA rt_win PASS Character curtain: unrolled, the window is back in the same box to the pixel | 294,0 1617x735 -> 294,0 1617x735
ZEDQA rt_win PASS Character curtain: the rod is gone from the screen
ZEDQA rt_win PASS Character curtain: the other window never moved | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character curtain: no Lua error through the roll | 0 -> 0
ZEDQA rt_win PASS World curtain: the side rolls up under its rod (on maps) | rolled true, rod true
ZEDQA rt_win PASS World curtain: rolled, the window is its box less the side | 1929,0 1617x735 less 714 -> 2643,0 903x735
ZEDQA rt_win PASS on screen (World curtain rolled): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_win PASS World curtain: the rod's tab rolls the side back down | rolled false
ZEDQA rt_win PASS World curtain: unrolled, the window is back in the same box to the pixel | 1929,0 1617x735 -> 1929,0 1617x735
ZEDQA rt_win PASS World curtain: the rod is gone from the screen
ZEDQA rt_win PASS World curtain: the other window never moved | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World curtain: no Lua error through the roll | 0 -> 0
ZEDQA rt_win PASS Equip: the doll button shows the doll view, the option follows | view doll, option 2
ZEDQA rt_win PASS Equip: the list button brings the list back | view list
ZEDQA rt_win PASS Equip: a group heading pressed folds or opens its group (head) | false -> true
ZEDQA rt_win PASS Equip: pressed again, the group is back as it was | false
ZEDQA rt_win PASS Equip: a press on a column divider starts its drag (slot)
ZEDQA rt_win PASS Equip: the drag sets the column's width from the pointer | 147 -> 129, want 129
ZEDQA rt_win PASS Equip: the release ends the column drag
ZEDQA rt_win PASS Health: the figure's heading pressed folds or opens the figure | true -> false
ZEDQA rt_win PASS Health: pressed again, the figure is back as it was
ZEDQA rt_win PASS Health: the exercise box opens its list
ZEDQA rt_win PASS Health: a row picked is the exercise, the list shut | pushups, open false
ZEDQA rt_win PASS Health: the session time's + steps it 10 minutes | 10 -> 20
ZEDQA rt_win PASS Health: the other button steps it back | 10
ZEDQA rt_win PASS Health: + at 60 minutes holds at 60 | 60
ZEDQA rt_win PASS Thermal: the figure's heading pressed folds or opens the figure | true -> false
ZEDQA rt_win PASS Thermal: pressed again, the figure is back as it was
ZEDQA rt_win PASS Thermal: the View box opens its list
ZEDQA rt_win PASS Thermal: the View list offers 7 views | 7 rows
ZEDQA rt_win PASS Thermal: a view picked is the view, the list shut | 2, open false
ZEDQA rt_win PASS Thermal: temperatures follow the game's Celsius option | option false: '98.6°F' (C '37.0°C', F '98.6°F')
ZEDQA rt_win PASS Character title: the health pixel is drawn, its help line gives the health | Health: 100% (want Health: 100%)
ZEDQA rt_win PASS Skills: the grid's heading pressed folds or opens the grid | true -> false
ZEDQA rt_win PASS Skills: pressed again, the grid is back as it was
ZEDQA rt_win PASS Show all: first the unpinned halves roll (the pad's aim)
ZEDQA rt_win PASS Show all: brought back (a bumper or Y), no half rolled and the window not shaded | anyRolled false, shaded false
ZEDQA rt_win PASS Half pins: a half's pin pressed flips it, saved with the character | inv: true -> false, charInv false
ZEDQA rt_win PASS Half pins: pressed again, the pin is back as it was | inv
ZEDQA rt_win PASS Half pins: a half's pin pressed flips it, saved with the character | drawer: true -> false, charTabs false
ZEDQA rt_win PASS Half pins: pressed again, the pin is back as it was | drawer
ZEDQA rt_win PASS Identity: one controller stop per trait row | 10 stops, 10 rows
ZEDQA rt_win PASS Craft: the Sort box opens its list
ZEDQA rt_win PASS Craft: a Sort choice picked is the order, the list shut | known
ZEDQA rt_win PASS Craft: the Show box opens its list
ZEDQA rt_win PASS Craft: a Show choice picked is what the list shows, the list shut | all
ZEDQA rt_win PASS Craft: the Category select opens its list
ZEDQA rt_win PASS Craft: a category picked filters the list, the select shut | armor (want armor)
ZEDQA rt_win PASS Craft: a right-click on a recipe row pins it, saved with the character | TakeACigarette
ZEDQA rt_win PASS Craft: a right-click on it again unpins it | TakeACigarette
ZEDQA rt_win PASS Foraging: the focus drop-down opens
ZEDQA rt_win PASS Foraging: a focus picked is the game's search focus, the drop-down shut | Tracks, the game's Tracks
ZEDQA rt_win PASS Foraging: More detail pressed opens or folds it | false -> true
ZEDQA rt_win PASS Foraging: pressed again, More detail is back as it was
ZEDQA rt_win PASS World extension tabs: each one added (addTab) is registered and on the tab list | admin, fishing
ZEDQA rt_win PASS Character extension tabs: each one added (addTab) is registered and on the tab list | server, cooking
ZEDQA rt_win PASS Window menu: the window box pulls its menu down | menu true, box open true
ZEDQA rt_win PASS on screen (the window menu): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Window menu: it has its rows (Theme to ZeD setup) | 13 rows
ZEDQA rt_win PASS Window menu: Accent > Red is this window's own accent | red
ZEDQA rt_win PASS Window menu: Accent > Same as Accent color clears it | nil
ZEDQA rt_win PASS Window menu: it closes | box open nil
ZEDQA rt_win PASS Save position: the window's place is in the file under char, read back | char x 648.00 y 0.00 w 444.00
ZEDQA rt_win PASS Save position: a note says it was saved
ZEDQA rt_win PASS Go to saved position: the window is back at its saved place | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS on screen (after Go to saved position): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Reset this window: the Character window is back in the spread (right edge mid-screen less 5 px), on Loot | right 1911 (want 1911), y 0, tab loot
ZEDQA rt_win PASS Reset both windows: the World window is back in the spread (left edge mid-screen plus 5 px), on Loot | x 1929 (want 1929), tab loot
ZEDQA rt_win PASS on screen (after Reset both windows): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Resize: the edge dragged 40 units in, the window follows and keeps the inventory's new width | 777 -> 707, inventory 372 -> 332
ZEDQA rt_win PASS Resize: dragged past it, the window stops at the half-screen cap | 1920 (cap 1920)
ZEDQA rt_win PASS Resize: dragged back, the window is its old width | 777 (was 777)
ZEDQA rt_win PASS on screen (after the resize): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Layout kept: closed on Skills, the character keeps the window's place and tab | tab skills, drawer tab true
ZEDQA rt_win PASS The game's inventory and loot pages stay hidden (the pair closed) | inventory false, loot false
ZEDQA rt_win PASS Layout kept: opened again, the Character window is back on Skills | tab skills
ZEDQA rt_win PASS The game's inventory and loot pages stay hidden (the pair open) | inventory false, loot false
ZEDQA rt_win PASS Force close (safe mode's hand-back): the World window is gone | window false
ZEDQA rt_win PASS Force close: the inventory key's action opens the World window again
ZEDQA rt_win PASS Paused: the inventory key's action opens the Character window alone | Character true, World false
ZEDQA rt_win PASS on screen (paused, the Character window alone): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Paused: the key again closes it
ZEDQA rt_win PASS pad: before Y, both windows are closed
ZEDQA rt_win PASS pad: a tap of Y opens both windows | Character true, World true
ZEDQA rt_win PASS on screen (opened by the pad): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_win PASS pad: a second tap of Y rolls both windows up (hidden)
ZEDQA rt_win PASS pad: a third tap of Y brings both windows back
ZEDQA rt_win PASS pad: holding Y closes both windows | Character false, World false
ZEDQA rt_win PASS wheels: the same direction again (D-pad Left) closes the wheel
ZEDQA rt_win PASS wheels: B on the wheel's top level closes it
ZEDQA rt_win PASS wheels: another direction (D-pad Right) swaps to that wheel | dir right
ZEDQA rt_win PASS on screen (the World wheel, swapped to): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS chord: LB held and A on the pointed slice puts it on LB + A, the wheel stays open | character:1 (want character:1)
ZEDQA rt_win PASS Controller map: it opens
ZEDQA rt_win PASS on screen (the Controller map): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Controller map: B closes it (A does not) and it lets go of the pad | after A true, after B false, holds the pad false
ZEDQA layout rt_win put back
ZEDQA rt_win PASS put back: both windows are where and as big as they were | Character 1134,0 777x735 -> 1134,0 777x735, World 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win end: 205 pass, 0 fail, 0 skipped
ZEDQA rt_win VERDICT PASS 205
ZEDQA rt_win DONE
```

### 4. rt_inventory.lua (`ZEDQA rt_inv`) - PASS, 29 s

- go 30371 at 15:13:00

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_inv start (163 steps)
[ZeD.QA] run #4 ok=true
ZEDQA rt_inv PASS both windows are open
ZEDQA rt_inv PASS the Character window lists the character's inventory | ItemContainer:[type:none, parent:IsoPlayer{ Name:null, ID:50 }]
ZEDQA rt_inv PASS a crate stands beside the character | ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@7dcb03a9]
ZEDQA rt_inv PASS the things for the test were made | crate 10 of 10, mover Base.Pan
ZEDQA rt_inv PASS the World window shows the crate (selectContainer) | Crate
ZEDQA rt_inv PASS Sort by name rising from the heading puts the bag's rows in that order | sort name true; 26 rows in order
ZEDQA rt_inv PASS Sort by name rising from the heading puts the crate's rows in that order | sort name true; 6 rows in order
ZEDQA rt_inv PASS Sort by name falling from the heading puts the bag's rows in that order | sort name false; 26 rows in order
ZEDQA rt_inv PASS Sort by name falling from the heading puts the crate's rows in that order | sort name false; 6 rows in order
ZEDQA rt_inv PASS Sort by cat rising from the heading puts the bag's rows in that order | sort cat true; 26 rows in order
ZEDQA rt_inv PASS Sort by cat rising from the heading puts the crate's rows in that order | sort cat true; 6 rows in order
ZEDQA rt_inv PASS Sort by cat falling from the heading puts the bag's rows in that order | sort cat false; 26 rows in order
ZEDQA rt_inv PASS Sort by cat falling from the heading puts the crate's rows in that order | sort cat false; 6 rows in order
ZEDQA rt_inv PASS Sort by cond rising from the heading puts the bag's rows in that order | sort cond true; 26 rows in order
ZEDQA rt_inv PASS Sort by cond rising from the heading puts the crate's rows in that order | sort cond true; 6 rows in order
ZEDQA rt_inv PASS Sort by cond falling from the heading puts the bag's rows in that order | sort cond false; 26 rows in order
ZEDQA rt_inv PASS Sort by cond falling from the heading puts the crate's rows in that order | sort cond false; 6 rows in order
ZEDQA rt_inv PASS Sort by wt rising from the heading puts the bag's rows in that order | sort wt true; 26 rows in order
ZEDQA rt_inv PASS Sort by wt rising from the heading puts the crate's rows in that order | sort wt true; 6 rows in order
ZEDQA rt_inv PASS Sort by wt falling from the heading puts the bag's rows in that order | sort wt false; 26 rows in order
ZEDQA rt_inv PASS Sort by wt falling from the heading puts the crate's rows in that order | sort wt false; 6 rows in order
ZEDQA rt_inv PASS the list draws every thing in the bag | 26 rows, 48 of 48 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the list draws every thing in the crate | 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the bag's pad rows (_invRowItems) are its shown rows, one each, each drawn | 26 pad rows, 26 shown rows, 0 with no place
ZEDQA rt_inv PASS the crate's pad rows (_invRowItems) are its shown rows, one each, each drawn | 6 pad rows, 6 shown rows, 0 with no place
ZEDQA rt_inv PASS the view button turns the bag to the grid, and the grid draws every thing | button true, 26 rows, 48 of 48 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the crate to the grid, and the grid draws every thing | button true, 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS item-colored tiles: GridTint and its setting are there
ZEDQA rt_inv PASS item-colored tiles on: the crowbar's icon gives a tile color, an unknown icon none | switch true, crowbar 0.6619999999999999,0.7133417721518986,0.8180000000000001, unknown nil
ZEDQA rt_inv PASS item-colored tiles off: no tile is tinted | nil
ZEDQA rt_inv PASS the view button turns the bag back to the list | 26 rows, 48 of 48 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the crate back to the list | 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS on screen (the inventory lists): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_inv PASS the crate's heading has the Filter button
ZEDQA rt_inv PASS the Filter button opens the bar
ZEDQA rt_inv PASS the filter "plank" marks the rows whose name holds it and dims the rest | 1 match, 5 dim
ZEDQA rt_inv PASS on screen (the filter bar open): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_inv PASS Clear shows every row again | button true, text ""
ZEDQA rt_inv PASS the chip CookingWeapon marks that category's rows and dims the rest | 1 match, 5 dim
ZEDQA rt_inv PASS the filter is saved on the crate's key | obj:926,13040,0:crate =
    CookingWeapon
ZEDQA rt_inv PASS the floor shown: it keeps no filter (the bar empties) | nCats 0, text ""
ZEDQA rt_inv PASS the crate shown again takes its saved filter back (the chip on, the bar open) | open true, chip true
ZEDQA rt_inv PASS Clear takes the chip off and the crate's saved filter with it | nil
ZEDQA rt_inv PASS the Filter button puts the bar away | false
ZEDQA rt_inv PASS the stack's row (three cans) shows its total weight in brackets (2.4) | row true; drew: Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4)
ZEDQA rt_inv PASS the stack's triangle opens it: a row for each of the three cans | triangle true, header true, rows 3
ZEDQA rt_inv PASS the open stack's header keeps the total (2.4) | drew: Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4)
ZEDQA rt_inv PASS a press on the open stack's header shuts it
ZEDQA rt_inv PASS a press on the list's empty space starts a box
ZEDQA rt_inv PASS the box drawn up over the rows selects every row it crosses | 6 of 6
ZEDQA rt_inv PASS a double-click on the list's empty space selects every row | 6 of 6
ZEDQA rt_inv PASS the pan's row drags from the bag and drops on the crate's list | dropped
ZEDQA rt_inv PASS dragged into the crate: the pan is in the crate once the transfer is done, and the counts agree | in the crate true, in the bag false; bag 55 (was 56), crate 11 (was 10)
ZEDQA rt_inv PASS the pan's row drags from the crate and drops on the bag's list | dropped
ZEDQA rt_inv PASS dragged back into the bag: the pan is in the bag and the counts agree | in the crate false, in the bag true; bag 56 (was 55), crate 10 (was 11)
ZEDQA rt_inv PASS the pan's row in the bag takes a right-click
ZEDQA rt_inv PASS the right-click opens ZeD's menu on the pan
ZEDQA rt_inv PASS the menu's Move To lists the crate (Crate) and runs it | picked
ZEDQA rt_inv PASS Move To the crate: the pan is in the crate and the counts agree | in the crate true, in the bag false; bag 55 (was 56), crate 11 (was 10)
ZEDQA rt_inv PASS the pan's row in the crate takes a right-click
ZEDQA rt_inv PASS the right-click opens ZeD's menu on the pan in the crate
ZEDQA rt_inv PASS the menu's Move To lists Inventory and runs it | picked
ZEDQA rt_inv PASS Move To the inventory: the pan is back in the bag and the counts agree | in the crate false, in the bag true; bag 56 (was 55), crate 10 (was 11)
ZEDQA rt_inv PASS a drag on the Weight divider widens the column by the drag (the list's own press, move and release) | was 101, now 136, want 136
ZEDQA rt_inv PASS the Weight heading stays inside the list after the resize | 472+136 in 651
ZEDQA rt_inv PASS Sort by Category draws the category headings
ZEDQA rt_inv PASS a press on the heading CookingWeapon folds it: its rows leave the list | rows 1 -> 0
ZEDQA rt_inv PASS a second press opens it: its rows come back | 1 of 1
ZEDQA rt_inv PASS a click selects its row alone | Bandage
ZEDQA rt_inv PASS Ctrl-click adds a row | Bandage, Crowbar
ZEDQA rt_inv PASS Shift-click adds the run from the last row clicked | Bandage, Crowbar, Empty Saucepan, Plank
ZEDQA rt_inv PASS Ctrl-click on a picked row takes it out | Bandage, Empty Saucepan, Plank
ZEDQA rt_inv PASS the picked line counts the picks (a closed stack's row is its whole stack) and their weight | "5 of 10 picked | 6.9 kg", want "5 of 10 picked | 6.9 kg"
ZEDQA rt_inv PASS the crowbar's row in the crate takes a double-click
ZEDQA rt_inv PASS a double-click in the crate brings the crowbar to the bag (the game's transfer) | ItemContainer:[type:none, parent:IsoPlayer{ Name:null, ID:50 }]
ZEDQA rt_inv PASS the crowbar's row in the bag takes a double-click
ZEDQA rt_inv PASS a double-click in the bag is the game's basic action: the crowbar in the hand | Crowbar
ZEDQA rt_inv PASS pad L3 on Name A-Z turns it to Z-A | name false; 26 rows in order
ZEDQA rt_inv PASS pad L3 again goes on to Category A-Z | cat true
ZEDQA rt_inv PASS pad: the focus lands on the pan's row (charMainInv)
ZEDQA rt_inv PASS pad: hold A on the pan's row marks it (one mark) | 1 marked
ZEDQA rt_inv PASS pad: with A held, D-pad down paints the row it lands on | 2 marked, on Holster
ZEDQA rt_inv PASS pad: B clears every mark and the focus stays where it was | invrow:13 -> invrow:13
ZEDQA rt_inv PASS pad: the focus is on the pan's row for X
ZEDQA rt_inv PASS pad: X on the pan's row in the bag moves it to the crate, and the counts agree | in the crate true, in the bag false; bag 55 (was 56), crate 11 (was 10)
ZEDQA rt_inv PASS pad: the focus lands on the pan's row in the crate (worldMainInv)
ZEDQA rt_inv PASS pad: X on the pan's row in the crate moves it back to the bag, and the counts agree | in the crate false, in the bag true; bag 56 (was 55), crate 10 (was 11)
ZEDQA rt_inv PASS the crate's Loot all button presses | Take all
ZEDQA rt_inv PASS Loot all takes everything from the crate into the bag (all the bag has room for) | 10 of 10 in the bag, 0 too heavy for it
ZEDQA rt_inv PASS the bag's Transfer all button presses | Transfer all
ZEDQA rt_inv PASS Transfer all moves every thing it should into the crate (all the crate has room for) | 57 moved, 0 too big for what room was left
ZEDQA rt_inv the bag's own things put back: 46
ZEDQA rt_inv PASS the crate's To floor button presses | To floor
ZEDQA rt_inv PASS To floor puts every thing in the crate on the floor | 10 of 10 on the floor, 0 left in the crate
ZEDQA rt_inv PASS openTab (Character window): on Skills within 20 frames, its drawer open | returned true, tab skills, open true
ZEDQA rt_inv PASS openTab (Character window) with toggle on the open tab folds it | loot
ZEDQA rt_inv PASS the game's Health page (toggleView) opens ZeD's Health tab, the game's window hidden | tab health, game's window false, routed 0 -> 1
ZEDQA rt_inv PASS Loot columns: the given school bag is in the Character window's containers
ZEDQA rt_inv PASS toggleColumn (Character window): the bag's column opens, one more column | 0 -> 1
ZEDQA rt_inv PASS another tab than Loot closes the Character window's columns | 0 left
ZEDQA rt_inv PASS openTab (World window): isTabShowing(craft) within 20 frames | returned true
ZEDQA rt_inv PASS toggleColumn (World window): the crate's column opens, one more column | 0 -> 1
ZEDQA rt_inv PASS closeColumns (World window): back to the one list | 0 left
ZEDQA rt_inv PASS World window close: isOpen false and getWindow nil | open false, window false
ZEDQA rt_inv PASS World window open: isOpen true and the window is there again
ZEDQA rt_inv PASS the Equip tab opens on its list (for its own rows) | tab equip
ZEDQA rt_inv PASS the Equipped heading pressed folds or opens the slot list | true -> false
ZEDQA rt_inv PASS the Equipped heading pressed again is back as it was
ZEDQA rt_inv PASS a right-click on a worn slot opens the game's menu on that thing (ZeD's menu) | menu ZeD_ContextList, on it true
ZEDQA rt_inv PASS Find (Equipment): the slot that matches stays lit, others dim, none hidden | "shirt - lumberjack": 6 of 6 others dimmed, 7 of 7 slots drawn
ZEDQA rt_inv PASS Find (Equipment) cleared: every slot lit again | 7 of 7
ZEDQA rt_inv PASS the Skills tab draws its skill rows (for Find)
ZEDQA rt_inv PASS Find (Skills): the skill typed stays lit, the others dim | "aiming": 34 of 34 others dimmed
ZEDQA rt_inv PASS Find (Skills) cleared: the rows are lit again
ZEDQA rt_inv PASS License card: forced Simple and narrow, it draws Simple and narrow | simple true, tall true
ZEDQA rt_inv PASS on screen (the license card, Simple and narrow): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_inv PASS License card: forced Immersive and wide, it draws Immersive and wide | simple false, tall false
ZEDQA rt_inv PASS on screen (the license card, Immersive and wide): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_inv PASS Photo: a press on it swaps bust and full body | false -> true
ZEDQA rt_inv PASS Photo: on the full body the wheel zooms | 0 -> -2
ZEDQA rt_inv PASS a pot of water and food on the player: the Cooking tab is on the strip | loot equip health thermal cooking identity journal skills
ZEDQA rt_inv PASS the pot taken back: the Cooking tab leaves the strip
ZEDQA rt_inv PASS a fishing rod in the hand: the World window offers the Fishing tab | loot craft build furniture maps forage animals fishing
ZEDQA rt_inv PASS the rod put away (no water near): the Fishing tab leaves the strip
ZEDQA rt_inv PASS Moodle notices on: a moodle that changes queues its notice | boredom 0 -> 90; queued: HEAVY_LOAD BORED
ZEDQA rt_inv PASS Moodle notices: the notice shows its few seconds and leaves | left:
ZEDQA rt_inv PASS paused under a window: the Paused balloon shows at the top of the screen | box true at y 11
ZEDQA rt_inv PASS on screen (the paused balloon): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_inv PASS playing again, the Paused balloon goes
ZEDQA rt_inv PASS an unbound controller's press files "Controller plugged in" in Messages | note true, listed true, game list box false
ZEDQA rt_inv PASS the Simple guide window opens with its topics
ZEDQA rt_inv PASS the guide window: a topic's row pressed shows that topic | vaulting, want vaulting
ZEDQA rt_inv PASS the guide window: Next shows the topic after it | aiming, want aiming
ZEDQA rt_inv PASS restock: a kind of thing the character lacks is found
ZEDQA rt_inv PASS restock: a loadout asks for a Base.Twine the crate holds
ZEDQA rt_inv PASS restock: the to-do pins at the screen's left edge while it runs | pin true at x 21, mode casual
ZEDQA rt_inv PASS on screen (the pinned restock to-do): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_inv PASS restock: the missing thing comes out of the crate to the character, the list done | done true, stopped nil
ZEDQA rt_inv PASS restock: the list done, the pin goes after its last line
ZEDQA rt_inv PASS the bag holds all its own things again | 55 of 55
ZEDQA rt_inv end: 139 pass, 0 fail, 0 skipped
ZEDQA rt_inv VERDICT PASS 139
ZEDQA rt_inv DONE
```

### 5. rt_menus.lua (`ZEDQA rt_menu`) - PASS, 7 s

- go 30372 at 15:13:32

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_menu start (48 steps)
[ZeD.QA] run #5 ok=true
ZEDQA rt_menu PASS ZeD's Context menu setting is there
ZEDQA rt_menu PASS the Character window is open
ZEDQA rt_menu PASS three tools of kinds the bag does not hold were given | 3 given
ZEDQA rt_menu PASS the strip test: the tool's row in the bag takes a right-click | Crowbar
ZEDQA rt_menu PASS the right-click opens ZeD's strip (ZeD_ContextMenu) on the tool | menu ZeD_ContextMenu, on the tool true
ZEDQA rt_menu PASS the strip: every row and submenu row has its icon | 19 rows
ZEDQA rt_menu PASS the strip: every top row has its category (USE to ADMIN) |
ZEDQA rt_menu PASS on screen (the strip open): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_menu PASS the strip: the pad's D-pad Right steps one cell on, Left steps back | 1 -> 2 -> 1 of 15
ZEDQA rt_menu PASS the strip: the pad's RB jumps to the next group, LB back to the group before | ACTION -> CRAFT -> ACTION
ZEDQA rt_menu PASS the strip: a click on the right chevron pages on, the left one pages back | 1 -> 11 -> 1 of 15
ZEDQA rt_menu SKIP the strip: a click on a bumper jumps groups (no bumpers drawn on this strip)
ZEDQA rt_menu PASS the strip stays open through its navigation
ZEDQA rt_menu PASS the strip: the selected option is the one lit in the game's menu (its target outline) | Attach / lit Attach
ZEDQA rt_menu PASS the strip: the target reads as the tool (getTargetDisplay; getMetaFor answers) | Crowbar / meta "cond 100%"
ZEDQA rt_menu PASS the strip: Move to opens its submenu | 1 rows under it; top: Attach, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip in Both Hands, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the strip with its submenu): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_menu PASS the strip: the pad's B backs out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the strip: Equip Primary is picked | picked
ZEDQA rt_menu PASS the strip's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Crowbar, menu false
ZEDQA rt_menu PASS the list test: the tool's row in the bag takes a right-click | Screwdriver
ZEDQA rt_menu PASS the right-click opens ZeD's list (ZeD_ContextList) on the tool | menu ZeD_ContextList, on the tool true
ZEDQA rt_menu PASS the list: every row and submenu row has its icon | 20 rows
ZEDQA rt_menu PASS the list: every top row has its category (USE to ADMIN) |
ZEDQA rt_menu PASS on screen (the list open): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the list's box is on screen | 1 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's Down moves the selection a row, Up back | 1 -> 2 -> 1
ZEDQA rt_menu PASS the list: the pad's Right on Move to opens its submenu, its first row selected | levels 2
ZEDQA rt_menu PASS the list: the submenu cascades beside the list, on screen | 2 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's Left backs out of the submenu | levels 1
ZEDQA rt_menu SKIP the list: the balloon for the selected row (the row Dismantle Simple Electronic Item has no words to show)
ZEDQA rt_menu PASS the list: a click on Move to opens its submenu | levels 2
ZEDQA rt_menu PASS the list: the selected option is the one lit in the game's menu (its target outline) | Move to / lit Move to
ZEDQA rt_menu PASS the list: the target reads as the tool (getTargetDisplay; getMetaFor answers) | Screwdriver / meta "cond 100%"
ZEDQA rt_menu PASS the list: its heading names the tool | drew: Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Put in Container (Crate) | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename | Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Put in Container (Crate) | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename | Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Put in Container (Crate) | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename
ZEDQA rt_menu PASS the list: Move to opens its submenu | 1 rows under it; top: Attach, Dismantle Simple Electronic Item, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the list with its submenu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the list and its submenu are on screen | 2 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's B backs out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the list: Equip Primary is picked | picked
ZEDQA rt_menu PASS the list's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Screwdriver, menu false
ZEDQA rt_menu PASS pins: the third tool's row takes a right-click
ZEDQA rt_menu PASS pins: the tool's row takes a right-click again
ZEDQA rt_menu PASS pins: a saved pin (Equip Secondary) comes first in its group (EQUIP), marked pinned | first: Equip Secondary, pinned true
ZEDQA rt_menu PASS tooltip: ZeD's methods are on the game's tooltips
ZEDQA rt_menu PASS tooltip: a tooltip and the tool's tooltip are made and shown |
ZEDQA rt_menu PASS tooltip: a tooltip (ISToolTip) draws as ZeD's box (its frame, ZeD's frame color, no error) | framed true, error nil, the game's menu visibleCheck nil
ZEDQA rt_menu PASS tooltip: a tooltip (ISToolTip) is on screen | 1280,720 420x104 in 3840x2160
ZEDQA rt_menu PASS tooltip: the tool's tooltip (ISToolTipInv) draws as ZeD's box (its frame, ZeD's frame color, no error) | framed true, error nil, the game's menu visibleCheck nil
ZEDQA rt_menu PASS tooltip: the tool's tooltip (ISToolTipInv) is on screen | 1946,1105 255x113 in 3840x2160
ZEDQA rt_menu PASS context icons: the data is loaded (Walk to has its icon) | person-walking-arrow-right
ZEDQA rt_menu PASS the pause menu opens (for the pad and Options checks)
ZEDQA rt_menu PASS pause menu up: no ZeD window takes the pad (claimFocus declines) | menu up true, focused nil
ZEDQA rt_menu PASS Options opens from the pause menu (for its sub-pages)
ZEDQA rt_menu PASS Options: the controller page (Button map and test) opens as its sub-page | pad
ZEDQA rt_menu PASS on screen (the controller page): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_menu PASS Options: Advanced game sounds opens with its sounds | sounds, 10 categories
ZEDQA rt_menu SKIP Options, game sounds: a slider step sets the sound's volume and reads back (the game's advanced sound options are off (SystemDisabler), so every sound's volume reads 1.0)
ZEDQA rt_menu PASS on screen (the game sounds page): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_menu PASS the pause menu shuts again
ZEDQA rt_menu PASS the Context menu setting is back as it was | 2
ZEDQA rt_menu PASS the hands hold what they held
ZEDQA rt_menu end: 59 pass, 0 fail, 3 skipped
ZEDQA rt_menu VERDICT PASS 59
ZEDQA rt_menu DONE
```

### 6. rt_cards.lua (`ZEDQA rt_cards`) - PASS, 44 s

- go 30373 at 15:13:43

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_cards start (257 steps)
[ZeD.QA] run #6 ok=true
ZEDQA rt_cards PASS an apple, a bat, a book and a pencil are given | Apple, Baseball Bat, Book: "Adapting For Success", by Rey Cooks, Pencil
ZEDQA rt_cards PASS the Character window's list shows the main inventory | none
ZEDQA rt_cards PASS pad: the focus lands on the apple's row (FocusManager, charMainInv)
ZEDQA rt_cards PASS pad: A on the apple's row opens its card | Apple
ZEDQA rt_cards PASS pad: the card is half or full wide | 385
ZEDQA rt_cards PASS on screen (the apple's item card (pad)): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS pad: the focus goes back to the apple's row, its card still open
ZEDQA rt_cards PASS pad: A on the row whose card is open opens the game's menu for the apple (ZeD's menu) | menu ZeD_ContextList, on the apple true
ZEDQA rt_cards PASS on screen (the apple's menu (pad A)): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS on screen (the apple's menu (pad A)): every level of the list | 1 levels
ZEDQA rt_cards PASS eat: the card shows EAT and the pad's focus lands on it | EAT MORE
ZEDQA rt_cards PASS eat: A held on Eat queues the game's own eat (ISEatFoodAction) | ISEatFoodAction
ZEDQA rt_cards PASS mouse: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS mouse: a click on the bat's row opens its card | Baseball Bat
ZEDQA rt_cards PASS mouse: the card is half (220) or full (480) wide | 385
ZEDQA rt_cards PASS facts: the card shows the bat's weight | 2.0 kg (want 2.0 kg)
ZEDQA rt_cards PASS facts: the card's facts show the bat's condition | 15 / 15 (want 15 / 15)
ZEDQA rt_cards PASS on screen (the bat's item card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS width: the drawer's card is the compact one (under 320) and it draws its name row, back bar and verbs | 385 wide, 2 verbs
ZEDQA rt_cards PASS rename: the pad's focus lands on the card's name row (name_row)
ZEDQA rt_cards PASS rename: A on the name row opens the rename prompt with the bat's name | Baseball Bat
ZEDQA rt_cards PASS on screen (the rename prompt): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS rename: OK names the bat as typed | ZeD QA bat
ZEDQA rt_cards PASS rename: the prompt opens again
ZEDQA rt_cards PASS rename: Cancel leaves the name as it was | ZeD QA bat
ZEDQA rt_cards PASS lists: the card shows its Lists mark and the pad's focus lands on it (toggle_lists) | true
ZEDQA rt_cards PASS lists: A on the Lists mark opens the lists' pop-up | Baseball Bat in lists
ZEDQA rt_cards PASS on screen (the Lists pop-up): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS on screen (the Lists pop-up): every level of the list | 1 levels
ZEDQA rt_cards PASS lists: the pop-up opens at the card (from the mark's lower left) | 1028+443 vs card 812
ZEDQA rt_cards PASS read: its row is in the Character window's list | Book: "Adapting For Success", by Rey Cooks
ZEDQA rt_cards PASS read: a click on the book's row opens its card | Book: "Adapting For Success", by Rey Cooks
ZEDQA rt_cards PASS read: the card shows READ and the pad's focus lands on it | READ MORE
ZEDQA rt_cards PASS read: Read queues the game's own read (ISReadABook) | ISReadABook
ZEDQA rt_cards PASS equip: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS equip: the bat's card opens again | Baseball Bat
ZEDQA rt_cards PASS equip: the card shows EQUIP and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS equip: Equip puts the bat in the hand (the game's equip action) | Baseball Bat
ZEDQA rt_cards PASS equip: the card now reads the bat as equipped | equipped
ZEDQA rt_cards PASS width: the Equip tab opens the bat's card at full width (480) and it draws its back bar and verbs | 840 wide, item Baseball Bat
ZEDQA rt_cards PASS on screen (the Equip tab's card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS width: the card's back key returns the Equip tab to its list
ZEDQA rt_cards PASS drop: its row is in the Character window's list | Pencil
ZEDQA rt_cards PASS drop: a click on the pencil's row opens its card | Pencil
ZEDQA rt_cards PASS drop: the card shows MORE and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS drop: MORE opens the pencil's whole context menu | true
ZEDQA rt_cards PASS more: the menu MORE opens is the pencil's, and it shows | ZeD_ContextList, on the pencil true
ZEDQA rt_cards PASS on screen (the pencil's MORE menu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS on screen (the pencil's MORE menu): every level of the list | 1 levels
ZEDQA rt_cards PASS drop: the menu has the game's Drop and it can be picked | picked
ZEDQA rt_cards PASS drop: Drop puts the pencil on the ground (the game's drop action) | world item true, container nil
ZEDQA rt_cards PASS tool verbs: a dull knife, a whetstone, a dirty shirt, sewing things and a barrel of water | knife true, shirt true, water true
ZEDQA rt_cards PASS sharpen: its row is in the Character window's list | Hunting Knife
ZEDQA rt_cards PASS sharpen: the card offers sharpen and the pad's focus lands on it
ZEDQA rt_cards NOTE sharpen: one frame after A the queue holds none
ZEDQA rt_cards PASS sharpen: A on it queues the game's own action (Craft) | ISHandcraftAction
ZEDQA rt_cards PASS repair: its row is in the Character window's list | Hunting Knife
ZEDQA rt_cards PASS repair: with no fixing for the knife, the card offers no repair (verb_repair) | card true, repair stop false
ZEDQA rt_cards PASS wash: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS wash: the card offers wash and the pad's focus lands on it
ZEDQA rt_cards NOTE wash: one frame after A the queue holds none
ZEDQA rt_cards PASS wash: A on it queues the game's own action (ISWashClothing) | ISWashClothing
ZEDQA rt_cards PASS pad all: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS pad all: the card offers pad_all and the pad's focus lands on it
ZEDQA rt_cards NOTE pad all: one frame after A the queue holds none
ZEDQA rt_cards PASS pad all: A on it queues the game's own action (ISRepairClothing) | ISRepairClothing ISRepairClothing ISRepairClothing ISRepairClothing
ZEDQA rt_cards PASS repair all: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS repair all: the card offers repair_all and the pad's focus lands on it
ZEDQA rt_cards NOTE repair all: one frame after A the queue holds none
ZEDQA rt_cards PASS repair all: A on it queues the game's own action (ISRepairClothing) | ISRepairClothing
ZEDQA rt_cards PASS preview: the Craft tab lists a recipe row in view
ZEDQA rt_cards PASS preview: a click on the recipe's row opens its craft card (the icon at its top) | RipClothing
ZEDQA rt_cards PASS preview: a click on the craft card's icon opens the recipe preview card | preview
ZEDQA rt_cards PASS preview: the preview card is the half card (220) | 385
ZEDQA rt_cards PASS on screen (the recipe preview card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS preview: picking another recipe closes the preview card | nil
ZEDQA rt_cards PASS generator: placed beside the character
ZEDQA rt_cards PASS generator: ZeD's hook is on the game's Info
ZEDQA rt_cards PASS generator: the game's Info opens ZeD's generator card on it | generator
ZEDQA rt_cards PASS generator: the card is the full card (480) | 840
ZEDQA rt_cards PASS generator: the card reads its fuel and condition | 10 / 90 (want 10 / 90)
ZEDQA rt_cards PASS generator: the card says it is off | Off
ZEDQA rt_cards PASS on screen (the generator card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS generator: connected with fuel, its engine switch is live (gen:engine)
ZEDQA rt_cards PASS generator: the engine switch starts it (the game's own activate)
ZEDQA rt_cards PASS generator: running, its card reads it on | Running
ZEDQA rt_cards PASS generator: the engine switch again stops it
ZEDQA rt_cards PASS generator: with no fuel the engine switch refuses (nothing to run) | zone run false, verb on false
ZEDQA rt_cards PASS fire: a campfire made beside the character (the game's campfire system)
ZEDQA rt_cards PASS fire: ZeD's hook is on the campfire's Info
ZEDQA rt_cards PASS fire: the campfire is in the world
ZEDQA rt_cards PASS fire: the campfire's Info opens ZeD's fire card | fire campfire
ZEDQA rt_cards PASS fire: a new campfire reads no fuel and not lit | 0 false
ZEDQA rt_cards PASS fire: the card says Out | Out
ZEDQA rt_cards PASS on screen (the fire card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS fire: with fuel carried, the card lists it to add (fire:fuel:1)
ZEDQA rt_cards PASS fire: Add fuel adds fuel time (the game's add fuel) | 0 -> 120
ZEDQA rt_cards PASS fire: with matches and paper, the card offers Light (fire:light:1)
ZEDQA rt_cards PASS fire: Light lights it (the game's light) and the pill reads burning | Burning
ZEDQA rt_cards PASS fire: a lit campfire beside the character logs no exception (its flame has no window) | pcall true, answer false
ZEDQA rt_cards PASS fire: Put out puts the lit campfire out (the game's put-out action)
ZEDQA rt_cards PASS laundry: a washer placed beside the character | appliances_laundry_01_4
ZEDQA rt_cards PASS laundry: the washer is in the World window's container list
ZEDQA rt_cards PASS laundry: the washer's container row has ZeD's gears button | take same floor obj:ZeDLaundry
ZEDQA rt_cards PASS laundry: the gears button opens ZeD's laundry card on the washer | laundry
ZEDQA rt_cards PASS laundry: the card says it is off | Off
ZEDQA rt_cards PASS laundry: the card reads the power as the game has it | false vs false
ZEDQA rt_cards PASS on screen (the laundry card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS fridge: a fridge placed beside the character, milk inside | true
ZEDQA rt_cards PASS fridge: the World window lists the fridge by name | Fridge
ZEDQA rt_cards PASS fridge: it opens in the Loot pane
ZEDQA rt_cards PASS fridge: the pane lists what is inside (the milk) | 8
ZEDQA rt_cards PASS on screen (the fridge in the Loot pane): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS stove: a range placed beside the character
ZEDQA rt_cards PASS stove: ZeD's hook is on the game's stove settings
ZEDQA rt_cards PASS stove: the game's stove settings open ZeD's stove (its face popped out, or the Craft tab on it) | face true, station nil
ZEDQA rt_cards PASS stove: its state reads as the game has it (power, switch) | No power (want No power)
ZEDQA rt_cards PASS on screen (the stove): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS band: the stove's container row draws its button band
ZEDQA rt_cards SKIP band: the stove's buttons scroll sideways (they all fit the list's 651 px here (no overflow))
ZEDQA rt_cards PASS oven: the stove has power (the grid, or the generator beside it run for the test)
ZEDQA rt_cards PASS oven: the stove is bound in the Craft tab, its panel's controls drawn
ZEDQA rt_cards PASS oven: a knob or key on its panel changes the stove's setting | heat: heat 200 -> 250, timer -1 -> -1
ZEDQA rt_cards PASS oven: its timer knob sets the timer | -1 -> 60
ZEDQA rt_cards PASS oven: its power key turns the stove on (the game's stove command) | on
ZEDQA rt_cards PASS oven: pressed again it turns off
ZEDQA rt_cards PASS pop-out: the stove's panel (Simple) has its pop-out button
ZEDQA rt_cards PASS pop-out: the stove opens in its own window, centred | up true, middle 1919 of 3840
ZEDQA rt_cards PASS on screen (the stove's own window): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS pop-out: the tab's bring-it-back closes the stove's window
ZEDQA rt_cards PASS pop-out: letting the station go closes its window | opened again true
ZEDQA rt_cards PASS station: a Primitive Kiln built beside the character (a craft bench) | 1 objects
ZEDQA rt_cards PASS station: the game's station option binds the kiln in the World window's Craft tab | Primitive Kiln
ZEDQA rt_cards PASS station: the kiln reads in use by you | In use by you
ZEDQA rt_cards PASS station: the kiln holds the game's one-player lock for you
ZEDQA rt_cards PASS on screen (the kiln in the Craft tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards SKIP a mod's general station card (StationGeneral.lua) (no mod station is installed on the release-test save)
ZEDQA rt_cards PASS rack: a herb drying rack built beside the character | 2 objects
ZEDQA rt_cards PASS rack: bound in the Craft tab, its Add offers the basil carried
ZEDQA rt_cards NOTE rack Add: queue ISItemSlotAddAction ISItemSlotAddAction, free output slots 20, distance 1.4, basil 2
ZEDQA rt_cards PASS rack: Add puts the basil into its input slots (the game's slot action) | 2 -> 0 carried
ZEDQA rt_cards PASS rack: its input slots show the basil to take
ZEDQA rt_cards SKIP rack: Take all empties the output (nothing has dried (the drying takes 24 game hours); a slot's take is checked instead)
ZEDQA rt_cards PASS rack: a slot's take brings the basil back out (the game's slot action) | 0 -> 1 carried
ZEDQA rt_cards PASS rack: Start runs it (isRunning)
ZEDQA rt_cards NOTE rack stop: at the press, isUsingPlayer true (getUsingPlayer you), isStopRequested false, isRunning true, Start zone true running false
ZEDQA rt_cards NOTE rack stop: just after the press, queue none, isUsingPlayer true (getUsingPlayer you), isStopRequested true
ZEDQA rt_cards PASS rack: Start pressed again stops it (its stop request is taken) | isRunning false, isStopRequested false, queue none
ZEDQA rt_cards NOTE rack stop: at the check, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack stop (ZeD Stop): unwrapped; isValid ran 0 times, perform 0 times
ZEDQA rt_cards NOTE rack Cancel: the first stop stopped it; Start pressed again before the comparison
ZEDQA rt_cards NOTE rack Cancel: before the comparison, isRunning true, isStopRequested false, queue none, restarted true
ZEDQA rt_cards NOTE rack Cancel: safe mode on (was 1), ZeD.Safe.on() true, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack Cancel: the game's window is open, isUsingPlayer false (getUsingPlayer nil), isRunning true, isStopRequested false, same component as ZeD's false
ZEDQA rt_cards NOTE rack stop (game Cancel): isValid ran (call 1) -> false, funcCanStart true, isUsingPlayer false (getUsingPlayer nil)
ZEDQA rt_cards NOTE rack Cancel: cancelCraft called, queue ISGenericCraftStart
ZEDQA rt_cards NOTE rack stop (game Cancel): isValid ran (call 2) -> false, funcCanStart true, isUsingPlayer false (getUsingPlayer nil)
ZEDQA rt_cards NOTE rack Cancel: queue empty, after the game's Cancel isRunning true, isStopRequested false, isUsingPlayer false (getUsingPlayer nil)
ZEDQA rt_cards NOTE rack stop (game Cancel): unwrapped; isValid ran 2 times, perform 0 times
ZEDQA rt_cards NOTE rack Cancel: safe mode option put back to 1, ZeD.Safe.on() false
ZEDQA rt_cards NOTE rack Cancel: with ZeD back, isRunning true, isStopRequested false, ZeD.Safe.on() false
ZEDQA rt_cards PASS tab strip (Character window): a press on Skills opens it | tab skills
ZEDQA rt_cards PASS tab strip (Character window): Skills pressed again folds back to Loot | tab loot
ZEDQA rt_cards PASS Loot snaps the Character window to the inventory alone, its right edge kept | 777 wide, want 777; right 1911, anchor 1911
ZEDQA rt_cards SKIP tab strip scroll arrows (the strip shows every tab at this size (no overflow, no arrows))
ZEDQA rt_cards PASS tab strip (World window): a press on Craft opens it | tab craft
ZEDQA rt_cards PASS tab strip (World window): Craft pressed again folds back to Loot | tab loot
ZEDQA rt_cards NOTE halves at the wait's end: pad=false, cw.drag=table 0x821657309{ active=false, pending=false, ghostCount=0, ghostX=0, ghostY=0, startX=0, startY=0, threshold=4 }, cw.dragActive=false, ww.drag=table 0x1022947881{ active=false, pending=false, ghostCount=0, ghostX=0, ghostY=0, startX=0, startY=0, threshold=4 }, ww.dragActive=false, moving=nil, pinned=false, outSince-now=nil, halves=table 0x1442520941{ key=char, side=left, strip=_tabStripPanel, zone=charTitlePins, inv=table 0x1326531802, drawer=table 0x879084659, rightRect=table 0x1333199212, leftRect=table 0x1123708824, dragMine=false, invShown=true, lastEffW=840, foldTab=skills }, halves.drawer=table 0x879084659{ pinned=false, rolled=true, hover=false }, drawer.out=nil, drawer.rolled=true, drawer.pinned=false, invDrawerOpen=true, _drawerOpen=false, _drawerMode=nil, mouseDown0=false, mouseDown1=false, absX=294, absY=0, width=1617, shownH=735, spot=1920,24, mouse=1920,24, split=903, hit(drawer)=false/false
ZEDQA rt_cards PASS halves: the unpinned drawer rolls up after 2 s with the pointer away | 2149 ms
ZEDQA rt_cards PASS halves: the rolled drawer keeps its tab (Skills) | folded skills, shaded false, tab skills
ZEDQA rt_cards PASS queued transfers: both moves waiting show on their rows (InvTip.queued) | 2 of 2
ZEDQA rt_cards PASS queued transfers: the queue stopped, no row shows a move waiting | 0 still shown
ZEDQA rt_cards PASS watch: the game's clock and speed controls are parked off screen | clock y -4000, speed controls y -4000
ZEDQA rt_cards PASS Maps: the header has its Key button
ZEDQA rt_cards PASS Maps: the Key button opens the map's key | true
ZEDQA rt_cards PASS on screen (the map's key): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS Maps: the key's close box shuts it | false
ZEDQA rt_cards PASS Read Map: a town map is given |
ZEDQA rt_cards PASS Read Map on a paper map opens ZeD's map on that paper (a pop-out) | Base.MuldraughMap:zombie.inventory.types.MapItem@47f5859d
ZEDQA rt_cards PASS on screen (the paper map): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS Read Map: the paper gone from the main inventory, its map folds away
ZEDQA rt_cards PASS wheel: the game's emote wheel opens drawn ZeD's way (menu._zed) | opened true, zed true
ZEDQA rt_cards PASS on screen (the emote wheel): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS wheel: a click towards a slice runs that slice's command | slice under the click 2, ran 2
ZEDQA rt_cards PASS form card: it opens from its spec and shows
ZEDQA rt_cards PASS on screen (the form card): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS form card: A on its check row runs the row | 1 runs
ZEDQA rt_cards PASS form card: B is its cancel and the card closes | cancel 1, finished 1
ZEDQA rt_cards PASS put back: the things given are taken back | 0 left
ZEDQA rt_cards PASS put back: the campfire is gone
ZEDQA rt_cards PASS put back: everything placed or built is taken away | 0 left
ZEDQA rt_cards end: 166 pass, 0 fail, 4 skipped
ZEDQA rt_cards VERDICT PASS 166
ZEDQA rt_cards DONE
```

### 7. rt_hud.lua (`ZEDQA rt_hud`) - PASS, 45 s

- go 30374 at 15:14:30

```text
[ZeD.QA] state #7 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_hud start (126 steps)
[ZeD.QA] run #7 ok=true
ZEDQA rt_hud PASS safe mode is off, so ZeD draws the HUD
ZEDQA rt_hud PASS every HUD module is loaded
ZEDQA rt_hud PASS window alone: toggle opens the Character window without the World window
ZEDQA rt_hud PASS window alone: it opens on Loot with the drawer shut | loot, drawer false
ZEDQA rt_hud PASS on screen (the Character window alone): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS window alone: toggle again closes it
ZEDQA rt_hud PASS UI scale Auto: ZeD.Scale is loaded
ZEDQA rt_hud PASS UI scale Auto: the root is the screen height over 1080, held to 0.75 .. 4, times the font knob | 2, want 2 at 2160 px high
ZEDQA rt_hud PASS belt: drawn
ZEDQA rt_hud PASS belt: at the bottom of the screen | 1535,2034 747x98
ZEDQA rt_hud PASS belt: the game's hotbar is parked off screen (Overrides/Belt.lua)
ZEDQA rt_hud PASS belt: the game's left column shows no hands and no window buttons | column up; showing:
ZEDQA rt_hud PASS hands: two circles, the main hand the bigger | 98 and 77
ZEDQA rt_hud PASS hands: the off hand left of the main hand (seen from behind)
ZEDQA rt_hud PASS on screen (belt): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS hands: one item in both hands slides the off hand under the main hand
ZEDQA rt_hud PASS hands: one hand free again, the off hand back beside the main hand
ZEDQA rt_hud PASS belt menu: the hammer is in the main hand
ZEDQA rt_hud PASS belt menu: the belt takes a right-click on the main hand
ZEDQA rt_hud PASS belt menu, right-click on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, right-click on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, right-click on the main hand): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt menu: it holds the hammer's own options | 12
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on the main hand): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt menu: the pad's menu names the belt its origin (the way back to it)
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on a slot): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt: a number key held past half a second opens its slot's list
ZEDQA rt_hud PASS belt: the slot's list opens at its slot, on screen | 0,0 3840x2160, slot at x 1798
ZEDQA rt_hud PASS on screen (the slot's list): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt: the key's release after the list draws nothing
ZEDQA rt_hud PASS belt: the Messages note is on the belt
ZEDQA rt_hud PASS belt: a click on the Messages note opens the Messages window
ZEDQA rt_hud PASS belt: the Messages window is on screen
ZEDQA rt_hud PASS on screen (the Messages window): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS belt: the note's anchor is a point on the belt | 2248,2049
ZEDQA rt_hud PASS Lite belt: Style Lite gives the simple belt (Z.Belt.simple())
ZEDQA rt_hud PASS simple belt: no strap and no buckle
ZEDQA rt_hud PASS simple belt: the slots SIMPLE_GAP apart | 11 px, want 11
ZEDQA rt_hud PASS simple belt: on screen
ZEDQA rt_hud PASS on screen (simple belt): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS Lite belt: Style Full brings the strap back
ZEDQA rt_hud PASS watch: the worn watch is on the belt | Base.WristWatch_Left_DigitalBlack
ZEDQA rt_hud PASS watch: the mini sits beside its own hand (left wrist)
ZEDQA rt_hud PASS watch: the full watch is tucked away while the mini shows
ZEDQA rt_hud PASS watch: the middle of the mini is its face | face
ZEDQA rt_hud PASS watch: the face opens the full watch | 248x352
ZEDQA rt_hud PASS watch: the full watch stands above the mini on the belt | 2023 over 2037
ZEDQA rt_hud PASS on screen (full watch): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS watch: a second press tucks it back
ZEDQA rt_hud PASS watch: its light comes on | no light spot on the mini: the watch's own light control
ZEDQA rt_hud PASS action bar: a bag to pack
ZEDQA rt_hud PASS action bar: the game's timed action is drawn
ZEDQA rt_hud PASS action bar: it names the action | MOVING PENCIL
ZEDQA rt_hud PASS action bar: the queue count reads the moves queued | qi 0 of 4, queued 4
ZEDQA rt_hud PASS action bar: its layer shows
ZEDQA rt_hud PASS on screen (action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS action bar: the bar follows the action | 0.00 to 0.10
ZEDQA rt_hud PASS action bar: the job ends with Done drawn from it
ZEDQA rt_hud PASS action bar: the Done fades and the bar clears
ZEDQA rt_hud PASS action bar: the action did its work (4 in the bag)
ZEDQA rt_hud PASS bar style: Style Lite draws the simple bar | simple
ZEDQA rt_hud PASS bar style: the simple bar is 53 x 9 units | 53 x 9
ZEDQA rt_hud PASS bar style: the simple bar is on screen | 1867,987 106x18
ZEDQA rt_hud PASS bar style: the simple bar stands above the head | 1005 over 1017.40625
ZEDQA rt_hud PASS on screen (simple action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the simple job ends
ZEDQA rt_hud PASS bar style: Detailed draws the thought bubble | verbose
ZEDQA rt_hud PASS bar style: the detailed bar has its size | 64 x 30
ZEDQA rt_hud PASS bar style: the detailed bar is on screen | 1858,909 152x104
ZEDQA rt_hud PASS on screen (detailed action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the detailed job ends
ZEDQA rt_hud PASS no bar: the attach starts
ZEDQA rt_hud PASS no bar: the game's own flag is read (useProgressBar false, _zedBar false)
ZEDQA rt_hud PASS no bar: the action bar has no state for it
ZEDQA rt_hud PASS right: the moodles are placed right | right
ZEDQA rt_hud PASS right: at least three moodles are on | 5
ZEDQA rt_hud PASS right: every moodle is on screen | 3782,940 48x280
ZEDQA rt_hud PASS right: the column is at the right edge | 3782
ZEDQA rt_hud PASS on screen (moodles right): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS left: the moodles are placed left | left
ZEDQA rt_hud PASS left: at least three moodles are on | 5
ZEDQA rt_hud PASS left: every moodle is on screen | 10,940 48x280
ZEDQA rt_hud PASS left: the column is at the left edge | 10
ZEDQA rt_hud PASS on screen (moodles left): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bottom: the moodles are placed bottom | bottom
ZEDQA rt_hud PASS bottom: at least three moodles are on | 5
ZEDQA rt_hud PASS bottom: every moodle is on screen | 1780,1965 280x48
ZEDQA rt_hud PASS bottom: the row is centred
ZEDQA rt_hud PASS bottom: the row sits above the belt
ZEDQA rt_hud PASS bottom: the game's column is out of sight (no double)
ZEDQA rt_hud PASS on screen (moodles bottom): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: a line the character says is in ZeD's balloon
ZEDQA rt_hud PASS bubble: the over-head layer draws it
ZEDQA rt_hud PASS on screen (speech bubble): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: it fades and goes
ZEDQA rt_hud PASS xp: Perks.Woodwork exists in this build
ZEDQA rt_hud PASS xp: skill XP goes through with ZeD on, no error
ZEDQA rt_hud PASS xp: the gain is logged in Messages | Carpentry +1.2 XP
ZEDQA rt_hud PASS xp: a game note goes to ZeD's bubble, marked good
ZEDQA rt_hud PASS xp: the over-head layer draws the note
ZEDQA rt_hud PASS on screen (over-head note): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS xp: the note fades and goes
ZEDQA rt_hud PASS guide: a fresh machine arms the bubble
ZEDQA rt_hud PASS guide: the bubble comes out
ZEDQA rt_hud PASS guide: the guide's own words | New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time.
ZEDQA rt_hud PASS guide: a long bare balloon for player one
ZEDQA rt_hud PASS guide: it comes out of the belt's Messages note
ZEDQA rt_hud PASS on screen (guide bubble): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS guide: the bubble goes by itself
ZEDQA rt_hud PASS guide: its line stays in Messages
ZEDQA rt_hud SKIP hint strip at a door (no door within 12 tiles on this floor)
ZEDQA home rt_hud moved from 928,13039,0 to the drag strip
ZEDQA rt_hud PASS forage: ZeD's pin and pointer are loaded
ZEDQA rt_hud PASS forage: search mode is on
ZEDQA rt_hud NOTE forage: 0 things earlier runs left on the ground by the home taken away
ZEDQA rt_hud PASS forage: a find is staged | Base.MushroomGeneric1
ZEDQA rt_hud PASS forage: a pinned find's pointer is empty (its pin marks it) | zed_forage_hand_none
ZEDQA rt_hud PASS forage: the pointer to the find is up | a find in sight, not spotted yet: true
ZEDQA rt_hud PASS forage: the pointer is ZeD's hand for the find's side | zed_forage_hand_up_a
ZEDQA rt_hud PASS forage: the hand is its set size | 36 x 63, want 36 x 63
ZEDQA rt_hud PASS forage: white at its set alpha | alpha 0.4000000059604645, want 0.4
ZEDQA rt_hud PASS forage: the pin over the find is ZeD's magnifying glass | 184 of 222 draws
ZEDQA rt_hud PASS forage: the search-mode eye is in ZeD's over-head stack
ZEDQA rt_hud PASS forage pointer: a find on the ground shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud SKIP forage pointer: a stash find shows ZeD's hand (the game draws no pointer to a stash (ISBaseIcon:updateWorldMarker skips iconClass stashObject))
ZEDQA rt_hud PASS forage pointer: an animal track shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud PASS on screen (forage): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS forage: the find and its pointer are gone again
ZEDQA rt_hud PASS forage tab: the World window's Foraging tab opens from the strip
ZEDQA rt_hud PASS forage tab: the band draws its Search button
ZEDQA rt_hud PASS forage tab: a click on Search flips the game's search mode | true
ZEDQA rt_hud PASS forage tab: a second click puts search mode back
ZEDQA rt_hud PASS balloon: it shows | rtqa:a
ZEDQA rt_hud PASS balloon: near the screen's corner it stays fully on screen | 3454,2015 350x80
ZEDQA rt_hud PASS balloon: one at a time (a second one asked while it is up does not draw) | up: rtqa:a
ZEDQA rt_hud PASS balloon: dismissed, it stays down while its control still asks
ZEDQA rt_hud PASS balloon: the focus on another control brings a balloon back
ZEDQA rt_hud PASS paused: the Character window is open
ZEDQA rt_hud PASS paused: the game reads paused
ZEDQA rt_hud PASS paused: the glass lies on the Character window
ZEDQA rt_hud PASS paused: the glass covers the item list
ZEDQA rt_hud PASS paused: the glass takes a press and a right press (nothing is used)
ZEDQA rt_hud PASS paused: the pad's A and X are held outside the tab strip and the bags | no live zone
ZEDQA rt_hud PASS on screen (paused Character window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS paused: the tab strip still switches tabs | equip, want equip
ZEDQA rt_hud PASS paused: playing again, the glass is gone
ZEDQA rt_hud PASS pin: the Skills tab opens from the strip
ZEDQA rt_hud PASS pin: the Skills tab draws its skill rows
ZEDQA rt_hud PASS pin: a right-click on the skill row opens its menu
ZEDQA rt_hud PASS on screen (skill row menu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS pin: the menu offers Pin to title bar
ZEDQA rt_hud PASS pin: the skill is pinned | Aiming
ZEDQA rt_hud PASS pin: the title bar shows its level and XP | 0/75 in: Long Blade - Lv.0 - 0/75 | Aiming - Lv.0 - 0/75 | 28.4 / 16 kg
ZEDQA rt_hud PASS pin item: four pinnable things to pin | 4 of 4
ZEDQA rt_hud PASS pin item: the item's own menu offers Pin to title bar
ZEDQA rt_hud PASS pin item: the pick puts the item's kind and id in ZeD_Pins | cond 678748544
ZEDQA rt_hud PASS pin item: ZeD.Pins.stats gives its row | Claw Hammer | 10/10
ZEDQA rt_hud PASS pin item: the Character window's title bar shows it | Claw in: Claw Hammer | 10/10 | 36.9 / 16 kg
ZEDQA rt_hud PASS pins: a fourth pin takes off the oldest (three at most) | 3 pins
ZEDQA rt_hud PASS pins: a note over the head says which pin went | Firefighter Axe pinned. Claw Hammer was taken off (3 at most).
ZEDQA rt_hud PASS popclear: a ZeD window is open to keep clear of
ZEDQA rt_hud PASS popclear: a pop-out over a ZeD window moves clear of it, on screen | 2265,367 to 2265,749
ZEDQA rt_hud PASS popclear: a spot clear of the windows is kept | 0,0 to 0,0
ZEDQA rt_hud PASS prompt: the game's ISTextBox is ZeD's text prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the text prompt shows
ZEDQA rt_hud PASS prompt: the text prompt is on screen
ZEDQA rt_hud PASS on screen (text prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the text prompt has its OK
ZEDQA rt_hud PASS prompt: OK hands the typed text back in entry | OK ZeD QA typed
ZEDQA rt_hud PASS prompt: the text prompt closes on OK
ZEDQA rt_hud PASS prompt: the game's ISModalRichText is ZeD's rich prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the rich prompt shows
ZEDQA rt_hud PASS prompt: the long rich text stays on screen | 1537,616 770x930 on 3840x2160
ZEDQA rt_hud PASS prompt: the long text scrolls inside it instead of growing past the screen | 1889.390625
ZEDQA rt_hud PASS on screen (rich prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the rich prompt has its OK
ZEDQA rt_hud PASS prompt: OK answers and closes the rich prompt
ZEDQA rt_hud PASS prompt: the game's ISModalDialog is ZeD's question
ZEDQA rt_hud PASS prompt: the question is the prompt on top
ZEDQA rt_hud PASS prompt: Escape answers No on the prompt on top | NO
ZEDQA rt_hud PASS prompt: that Escape does not open the pause menu
ZEDQA rt_hud PASS prompt: the second question is the prompt on top
ZEDQA rt_hud PASS prompt: Enter presses the main answer (Yes) | YES
ZEDQA rt_hud SKIP the mini-map stays hidden (the game made no mini-map for this player)
ZEDQA rt_hud PASS run-sneak: the module and its setting are loaded
ZEDQA rt_hud PASS run-sneak: Run held 400 ms standing still crouches | crouch
ZEDQA rt_hud PASS run-sneak: held again, it stands | stand
ZEDQA rt_hud PASS put back: the character where it started
ZEDQA rt_hud PASS put back: the moodles' place
ZEDQA rt_hud PASS put back: the watch's place
ZEDQA rt_hud end: 189 pass, 0 fail, 3 skipped
ZEDQA rt_hud VERDICT PASS 189
ZEDQA rt_hud DONE
```

### 8. rt_pad.lua (`ZEDQA rt_pad`) - FAIL, 22 s

- go 30375 at 15:15:18
- 2 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #8 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_pad start (95 steps)
[ZeD.QA] run #8 ok=true
ZEDQA rt_pad PASS every pad module is loaded
ZEDQA rt_pad PASS the input mode is held on the controller
ZEDQA rt_pad PASS focus: the windows open for the pad
ZEDQA rt_pad PASS focus: the Character window has the pad
ZEDQA rt_pad PASS focus: it lands on the list's first item | charMainInv 1 Apple
ZEDQA rt_pad PASS focus: D-pad Down moves to the next item | Baseball Cap
ZEDQA rt_pad PASS focus: D-pad Up moves back | Apple
ZEDQA rt_pad PASS on screen (windows on the pad): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS grid view: R3 on the list turns its container between List and Grid | grid false to true, every item placed true
ZEDQA rt_pad PASS grid view: R3 again puts the container's view back | false
ZEDQA rt_pad PASS card: the pad is on the list
ZEDQA rt_pad PASS card: on the landed item by frame 2 on every move, never the item before, no flicker | 8 of 8
ZEDQA rt_pad PASS on screen (the pad's item card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS left: the Character wheel opens
ZEDQA rt_pad PASS left: the wheel has its slices | 10
ZEDQA rt_pad PASS on screen (Character wheel): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS left: Tabs is there
ZEDQA rt_pad PASS left: Tabs opens its wheel, Back last
ZEDQA rt_pad PASS left: Tabs has Health
ZEDQA rt_pad PASS left: Health opens the Character window on Health | health
ZEDQA rt_pad PASS inner wheel: Character has Tabs
ZEDQA rt_pad PASS inner wheel: Back goes up one level, then from the top closes the wheel | 2, 1, closed true
ZEDQA rt_pad PASS right: the World wheel opens
ZEDQA rt_pad PASS on screen (World wheel): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS right: the eight slices, Tabs to Designated zones | Tabs, Map, Vehicle, Animal, Craft and build, Search, Lights and power, Designated Zones
ZEDQA rt_pad PASS right: Vehicle is live with a car in reach, else off with its reason | No vehicle in reach.
ZEDQA rt_pad PASS right: Animal is live with an animal in reach, else off with its reason | No tame animal in reach.
ZEDQA rt_pad PASS right: Tabs is there
ZEDQA rt_pad PASS right: Tabs has Loot
ZEDQA rt_pad PASS right: Loot opens the World window on Loot | loot
ZEDQA rt_pad PASS up: the Social wheel opens
ZEDQA rt_pad PASS on screen (Social wheel): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS up: Shout is live
ZEDQA rt_pad PASS up: Shout runs the game's shout
ZEDQA rt_pad PASS down: the Here and now wheel opens
ZEDQA rt_pad PASS on screen (Here and now wheel): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS down: Sit, Crouch, Auto walk, Game speed, Zoom, View, Help, Light | Sit, Crouch, Auto-walk, Game speed, Zoom, View, Help, Lighter
ZEDQA rt_pad PASS down: on foot, Sit, Crouch and Auto walk are not off for a vehicle
ZEDQA rt_pad SKIP down: Sit, Crouch and Auto walk off "in vehicle" in a car (on foot here; rt_vehicles has the car)
ZEDQA rt_pad PASS down: Zoom is there
ZEDQA rt_pad PASS down: Zoom has in
ZEDQA rt_pad PASS down: Zoom > in changes the zoom and the wheel closes | 1.00 to 0.75, closed true
ZEDQA rt_pad PASS select: the ZeD wheel opens
ZEDQA rt_pad PASS on screen (ZeD wheel): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad FAIL select: the slices by name, Theme to Safe mode | Base theme, Accent color, Text size, See-through, Controller highlight, UI scale, Moodles, Style, Messages, Bug report, Reset windows, ZeD setup, Safe mode
ZEDQA rt_pad PASS select: Moodles is there
ZEDQA rt_pad PASS select: Moodles lists the places
ZEDQA rt_pad PASS select: the pick moves the moodles | 2
ZEDQA rt_pad PASS reset: the pair is open
ZEDQA rt_pad PASS reset: the ZeD wheel has Reset windows
ZEDQA rt_pad PASS reset: both windows back at their places, side by side at the top | char 1134,0 777x735; world 1929,0; middle 1920, gap 9
ZEDQA rt_pad PASS on screen (the pair after Reset windows): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_pad PASS highlight: the pair is open for the pad
ZEDQA rt_pad PASS highlight hand: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight hand: the style is on its wheel
ZEDQA rt_pad PASS highlight hand: the style reads back | hand
ZEDQA rt_pad PASS highlight hand: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight hand: the words keep their color
ZEDQA rt_pad PASS highlight hand: the hand stays on the screen | 1197 - 32
ZEDQA rt_pad PASS on screen (highlight hand): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS highlight corners: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight corners: the style is on its wheel
ZEDQA rt_pad PASS highlight corners: the style reads back | corners
ZEDQA rt_pad PASS highlight corners: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight corners: the words keep their color
ZEDQA rt_pad PASS on screen (highlight corners): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_pad PASS highlight wash: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight wash: the style is on its wheel
ZEDQA rt_pad PASS highlight wash: the style reads back | wash
ZEDQA rt_pad PASS highlight wash: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight wash: the words turn to textOnFocus on a plain stop
ZEDQA rt_pad PASS on screen (highlight wash): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS highlight ants: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight ants: the style is on its wheel
ZEDQA rt_pad PASS highlight ants: the style reads back | ants
ZEDQA rt_pad PASS highlight ants: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight ants: the words keep their color
ZEDQA rt_pad PASS on screen (highlight ants): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_pad PASS pointer: on the mouse it shows (as Display cursor has it) | true
ZEDQA rt_pad PASS pointer: back on the pad it hides | false
ZEDQA rt_pad PASS pointer: the mouse moved shows it again | true
ZEDQA rt_pad PASS pointer: a pad press on a ZeD window hides it again | false
ZEDQA rt_pad PASS mode: with no lock a key press reads the mouse and keyboard; players 2 to 4 read the controller | kbm, player 2 gamepad
ZEDQA rt_pad PASS flip: the pair is shut before the flip
ZEDQA rt_pad PASS flip: locking the controller opens the Character and World windows
ZEDQA rt_pad PASS flip: on the pad the focus marks show; back on the mouse they hide | before true
ZEDQA rt_pad PASS moodles: the pointer on a moodle brings up its balloon, fully on screen | moodle:HEAVY_LOAD 1848,1856 483x86
ZEDQA rt_pad PASS fishing: the line's tension is kept and drawn as the rod in hand | drawn true, tension 0.5
ZEDQA rt_pad PASS routes: Designated zones opens the World window on Animals | animals
ZEDQA rt_pad PASS on screen (World window on Animals): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS routes: Investigate area opens the World window on Foraging | forage
ZEDQA rt_pad PASS on screen (World window on Foraging): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS gesture: Here and now opens with Crouch on it
ZEDQA rt_pad PASS gesture tap: the wheel opens and stays up | tap
ZEDQA rt_pad PASS gesture tap: the stick lights Crouch | 2
ZEDQA rt_pad PASS gesture tap: letting the stick go takes Crouch and the wheel closes
ZEDQA rt_pad PASS gesture trigger: a trigger closes the wheel, nothing taken
ZEDQA rt_pad PASS gesture hold: the wheel is held | hold
ZEDQA rt_pad PASS gesture hold: A takes the lit slice
ZEDQA rt_pad PASS gesture click: the wheel waits for the stick's click | click
ZEDQA rt_pad PASS gesture click: letting the stick go keeps Crouch lit
ZEDQA rt_pad PASS gesture click: R3 takes it
ZEDQA rt_pad PASS gesture toggle: the wheel opens in Toggle mode | toggle
ZEDQA rt_pad PASS gesture toggle: D-pad Up lights the top slice, Right walks to the next | 1 then 2
ZEDQA rt_pad PASS gesture toggle: A takes the lit slice
ZEDQA rt_pad PASS gesture bumper: LB tapped on a wheel closes it and opens the pair, the pad on the Character window | wheel false, focus ZeD_Window
ZEDQA rt_pad PASS chord: RB + R3 is on Here and now > Crouch
ZEDQA rt_pad PASS chord: no window has the pad (the chord is the world's)
ZEDQA rt_pad PASS chord: the press is taken as RB + R3 | RB+R3
ZEDQA rt_pad PASS chord: the press is the chord's, so the game's own press never runs | true
ZEDQA rt_pad PASS chord: the character crouches
ZEDQA rt_pad PASS chord: again, and it stands as it was
ZEDQA rt_pad PASS chord: the Character window is open for the window checks
ZEDQA rt_pad PASS chord: with a window holding the pad the chord does nothing | false
ZEDQA rt_pad PASS D-pad on a focused window: no wheel opens, the window's focus moves | 1 to 2
ZEDQA rt_pad PASS chord: on a slice that is off it does nothing and says why | No vehicle in reach.
ZEDQA rt_pad PASS chord: on a slice that is gone it says so | No QA gone on you.
ZEDQA rt_pad PASS put back: the switch is on
ZEDQA rt_pad PASS put back: a bottle of water in a bag
ZEDQA rt_pad PASS put back: after the drink the bottle is back in the bag | Bag_Schoolbag
ZEDQA rt_pad PASS map: Here and now has Help
ZEDQA rt_pad PASS map: Help has Controller map
ZEDQA rt_pad PASS map: the Controller map opens
ZEDQA rt_pad PASS map: its twelve rows are drawn | 12 of 12
ZEDQA rt_pad PASS map: it draws the pad from its textures | k 4, xbox
ZEDQA rt_pad PASS map: the pad fits the window's width
ZEDQA rt_pad PASS on screen (Controller map): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS put back: the pad is the game's again
ZEDQA rt_pad PASS put back: the stand-ins are gone
ZEDQA rt_pad PASS put back: the controller highlight | hand
ZEDQA rt_pad PASS put back: the moodles' place
ZEDQA rt_pad put back: the input mode lock is nil again; the mode reads gamepad
ZEDQA rt_pad end: 129 pass, 1 fail, 1 skipped
ZEDQA rt_pad VERDICT FAIL 1
ZEDQA rt_pad DONE
```

### 9. rt_media.lua (`ZEDQA rt_media`) - PASS, 27 s

- go 30376 at 15:15:44

```text
[ZeD.QA] state #9 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_media start (159 steps)
[ZeD.QA] run #9 ok=true
ZEDQA rt_media PASS the media modules are loaded (RtvFace, RadioTab, RadioOps, TwoWayFace, MapNotes, MapsTab, JournalReaders)
ZEDQA rt_media PASS the radio: given (Base.RadioRed)
ZEDQA rt_media PASS the radio: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the radio: its own face draws in the tab | face radio_red, want radio_red
ZEDQA rt_media PASS on screen (the radio's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the radio: the face has its power control (power)
ZEDQA rt_media PASS the radio: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the radio: the face has its tuning knob
ZEDQA rt_media PASS the radio: TUNE's right half tunes up one step | 89400 -> 89600
ZEDQA rt_media PASS the radio: TUNE's left half tunes back down | now 89400, want 89400
ZEDQA rt_media PASS the radio: power again turns it off
ZEDQA rt_media PASS the radio: the pad's first stop on the face is power | radio:tw:power
ZEDQA rt_media PASS the radio: A on the power stop turns it on
ZEDQA rt_media PASS the radio: A again turns it off
ZEDQA rt_media PASS the radio: the face has its pop-out button
ZEDQA rt_media PASS the radio: the pop-out button pops its face out
ZEDQA rt_media PASS on screen (the radio's face popped out): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS the radio: Escape puts the popped face away | Escape
ZEDQA rt_media PASS the radio wheel: Radio has its slices for the set in hand | 3 slices
ZEDQA rt_media PASS the radio wheel: its power slice turns the set on
ZEDQA rt_media PASS the radio wheel: Next station moves the channel | 89400 -> 91200
ZEDQA rt_media PASS the radio wheel: the power slice again turns it off
ZEDQA rt_media PASS the two-way: given (Base.WalkieTalkie2)
ZEDQA rt_media PASS the two-way: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the two-way: its own face draws in the tab | face walkie_valutech@180, want walkie_valutech
ZEDQA rt_media PASS on screen (the two-way's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the two-way: the face has its power control (vol)
ZEDQA rt_media PASS the two-way: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the two-way: the face has its tuning knob
ZEDQA rt_media PASS the two-way: TUNE's right half tunes up one step | 143800 -> 144000
ZEDQA rt_media PASS the two-way: TUNE's left half tunes back down | now 143800, want 143800
ZEDQA rt_media PASS the two-way: power again turns it off
ZEDQA rt_media PASS the CD player: given (Base.CDplayer)
ZEDQA rt_media PASS the CD player: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the CD player: its own face draws in the tab | face cd_player, want cd_player
ZEDQA rt_media PASS on screen (the CD player's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the CD player: the face has its power control (power)
ZEDQA rt_media PASS the CD player: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the CD player: VOL raises the volume (0.50 -> 0.60; it has no tuner)
ZEDQA rt_media PASS the CD player: power again turns it off
ZEDQA rt_media PASS a free room square with room for the TV beside it is found
ZEDQA rt_media PASS the TV's room has grid power (the grid turned on for the test)
ZEDQA rt_media PASS a TV is placed beside the character
ZEDQA rt_media PASS the World window's Radio list has the TV
ZEDQA rt_media PASS the World window's Radio tab opens from the strip
ZEDQA rt_media PASS the World window's Radio tab: a click on the TV's own tab picks it among the radios | idx 1, want 1 of 2
ZEDQA rt_media PASS the TV: its own face draws in the tab | face tv_black@392
ZEDQA rt_media PASS on screen (the TV's face in the World window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the TV: on the grid and off to start with
ZEDQA rt_media PASS the TV's face has its power key
ZEDQA rt_media PASS the TV: a click on power turns it on
ZEDQA rt_media PASS the TV's face has CH up
ZEDQA rt_media PASS the TV: CH up tunes the next channel | 1 -> 2
ZEDQA rt_media PASS the TV: power again turns it off
ZEDQA rt_media PASS the TV: a click on it in the world pops its face out |
ZEDQA rt_media PASS on screen (the TV's face popped out): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS the TV: a second click on it puts its face away
ERROR: General f:16386 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rt_media back at 928,13039
ZEDQA rt_media PASS the World window's Maps tab opens from the strip
ZEDQA rt_media PASS the Maps tab draws its map
ZEDQA rt_media PASS on screen (the Maps tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey: the map restyles and draws | style survey
ZEDQA rt_media PASS survey: the map's own place labels show | 8 label layers, strongest alpha 255
ZEDQA rt_media PASS survey: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS color: the map restyles and draws | style color
ZEDQA rt_media PASS color: the map's own place labels show | 8 label layers, strongest alpha 255
ZEDQA rt_media PASS color: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS paper: the map restyles and draws | style paper
ZEDQA rt_media PASS paper: the map's own place labels are hidden (the paper prints its own) | 8 label layers, strongest alpha 0
ZEDQA rt_media PASS paper: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS the note tool arms from the Maps header
ZEDQA rt_media PASS a note placed at the cursor lands once in the game's own map marks | marks 2 -> 3
ZEDQA rt_media PASS the cursor finds the note
ZEDQA rt_media PASS ZeD's menu on the note offers Delete
ZEDQA rt_media PASS on screen (the menu on a map note): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Delete takes the note off the map | marks now 2
ZEDQA rt_media PASS zoom: the map is up
ZEDQA rt_media PASS zoom: the mouse wheel zooms the map | 16.00 to 16.14
ZEDQA rt_media PASS zoom: the pad's trigger zooms it (gpZoom)
ZEDQA rt_media PASS pan: the pad's cursor at the map's edge pans it (gpMoveCursor) | 727.6 to 79.6
ZEDQA rt_media SKIP pan: a drag pans the map (the pointer could not be moved on this run)
ZEDQA rt_media PASS unfold: the Maps header has its unfold button
ZEDQA rt_media PASS unfold: the map opens in a window of its own and draws there
ZEDQA rt_media PASS unfold: the live map is the pop-out's
ZEDQA rt_media PASS on screen (the unfolded map): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS fold: the drawer shows the fold-back place
ZEDQA rt_media PASS fold: a click on the drawer folds the map back into the tab
ZEDQA rt_media PASS survey: MapsSurvey is loaded and the map is up
ZEDQA rt_media PASS survey: opening Survey raises no Lua error and trips no fault | errors 0 -> 0
ZEDQA rt_media PASS on screen (the Survey map): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey colors: the roads, water and buildings in the theme's palette | light
ZEDQA rt_media PASS survey colors: the map keeps the palette it drew | light
ZEDQA rt_media PASS survey woods: the forest layer carries the theme's tree-mark tile | 1 texture stops, media/textures/ZeD/map/woods_light.png
ZEDQA rt_media PASS survey lakes: a lake layer per lake, just above the water, in the lake blue | 59 lakes, water at 2
ZEDQA rt_media PASS survey recolor: a status-colour change recolors it once, no new layers | light:cb, 1 restyles, layers 85 -> 85
ZEDQA rt_media PASS survey recolor: the status colours put back, the palette follows
ZEDQA rt_media PASS survey grid: lines and letters drawn, all on the map | 9 lines, 5 letters, 0 off the map
ZEDQA rt_media PASS survey scale: the bar is its metres x px per square, boxed at the foot | want 186 px for 2 km; bar true, box true, label true, N true
ZEDQA rt_media PASS survey places: MapsSurveyData has places
ZEDQA rt_media PASS survey places: a badge at each place in view from zoom 15 | zoom 15, 15 badges of 19 px, 15 places in view
ZEDQA rt_media PASS survey places: no place badges below zoom 15 | zoom 14.899999618530273, 0 badges
ZEDQA rt_media PASS survey shields: MapsSurveyData has route shields
ZEDQA rt_media PASS survey shields: every shield drawn carries its number, 110 px apart, off the town names | zoom 14, 3 shields, 3 numbered, 0 too close, 0 on a town name
ZEDQA rt_media PASS survey bridges: MapsSurveyData has bridges
ZEDQA rt_media PASS survey bridges: a bridge in view gets its two lines, wholly on the map | zoom 16, 30 marks by it, 0 off the map
ZEDQA rt_media PASS survey towns: MapsSurveyData has a city (size 3)
ZEDQA rt_media PASS survey towns: a dot per town in view, a filled square for a city | zoom 12, 3 dots and 1 squares for 4 towns (1 cities)
ZEDQA rt_media PASS survey zone: MapsSurveyData has the map's bounds
ZEDQA rt_media PASS survey zone: magenta bars inside the edge, its label wholly on the map | 210 bars, 0 outside the bounds, label true
ZEDQA rt_media PASS survey key: the Maps band has the Key button
ZEDQA rt_media PASS survey key: the Key button opens Survey's key with its two pages
ZEDQA rt_media PASS survey key: Symbols turns the page; the key fits on the map | symbols, panel 812x424.15234375 on a 840x456 map
ZEDQA rt_media PASS on screen (the map key, Symbols): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey key: Colors turns it back; the key fits on the map | colors
ZEDQA rt_media PASS on screen (the map key, Colors): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey key: its close box shuts it
ZEDQA rt_media PASS a flyer and a notebook are given
ZEDQA rt_media PASS the Character window's Journal tab opens from the strip
ZEDQA rt_media PASS Papers lists the flyer carried
ZEDQA rt_media PASS the flyer has its row on the page
ZEDQA rt_media PASS on screen (the Journal's Papers page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Papers: a click on the flyer's row opens it on the page | ustoreitmuldraugh
ZEDQA rt_media PASS on screen (the flyer open on the Papers page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Papers: Back on the open flyer returns to the list
ZEDQA rt_media PASS Notebooks lists the notebook carried, with its row
ZEDQA rt_media PASS a click on the notebook's row picks it
ZEDQA rt_media PASS on screen (the Journal's Notebooks page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS light to write by (noon set for the test)
ZEDQA rt_media PASS the quick note's Write button is live
ZEDQA rt_media PASS the line written from the quick note is kept on the notebook's page (ZeD_WriteNoteAction)
ZEDQA rt_media PASS the notebook's Open full button is live
ZEDQA rt_media PASS Open full opens the notebook in ZeD's reader
ZEDQA rt_media PASS the reader opens it to write (a pencil carried)
ZEDQA rt_media PASS the reader shows the written line on its first page
ZEDQA rt_media PASS on screen (the reader): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS Done keeps the second page's text as written
ZEDQA rt_media PASS Done keeps the first page's line
ZEDQA rt_media PASS Done closes the reader
ZEDQA rt_media PASS the Journal page draws its write box and tag picks
ZEDQA rt_media PASS on screen (the Journal page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS a click on a tag pick ticks it (news)
ZEDQA rt_media PASS the Journal page has its Save
ZEDQA rt_media PASS Save writes the entry at the top of the log | ZEDQA rt log: the water tower is dry (2 entries, were 1)
ZEDQA rt_media PASS the entry keeps the ticked tag
ZEDQA rt_media PASS Save clears the box and the ticks
ZEDQA rt_media PASS Recipes: the page draws its recipe rows | 1167 rows
ZEDQA rt_media PASS on screen (the Journal's Recipes page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Recipes: a click on the All recipes head is taken
ZEDQA rt_media PASS Recipes: the head folds its group | 0 rows now
ZEDQA rt_media PASS Recipes: a second click opens it again | 1167 rows
ZEDQA rt_media PASS book: the guide opens as the book, at its first spread
ZEDQA rt_media PASS on screen (the guide book): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS book: its strip has Next page
ZEDQA rt_media PASS book: Next page turns a page (mouse) | 2
ZEDQA rt_media PASS book: the wheel turns back | 1
ZEDQA rt_media PASS book: RB turns on (its own pad handler) | 2
ZEDQA rt_media PASS book: the right arrow key turns on | 3
ZEDQA rt_media PASS book: its strip has Contents
ZEDQA rt_media PASS book: Contents opens the contents spread | 2, want 2
ZEDQA rt_media PASS book: the contents spread lists its chapters
ZEDQA rt_media PASS book: a contents row opens its chapter | 4, want 4
ZEDQA rt_media PASS book: its strip has the start-up box
ZEDQA rt_media PASS book: the start-up box flips the game's own option
ZEDQA rt_media PASS book: a second press puts the option back
ZEDQA rt_media PASS book: a click on a spoiler bar shows its numbers | SurvivalGuide_treat_water_title#1
ZEDQA rt_media PASS book: that bar is gone from the page
ZEDQA rt_media PASS book: opening the guide again hides the spoilers again
ZEDQA rt_media PASS book: A on the pages shows every spoiler on the spread
ZEDQA rt_media PASS Escape closes the book (and the pause menu stays shut)
ZEDQA rt_media PASS B closes the book (its own pad handler)
ZEDQA rt_media PASS F1: with the Health tab open the guide's topic is First aid | SurvivalGuide_first_aid_title
ZEDQA rt_media PASS F1: the key opens the book on that topic, past its first spread | 22
ZEDQA rt_media PASS on screen (the guide book opened by F1): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS F1: the key again closes the guide
ZEDQA rt_media PASS the Simple look opens the guide window
ZEDQA rt_media PASS on screen (the guide window): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_media PASS Escape closes the guide window
ZEDQA rt_media PASS Health: its fill blocks draw their heads
ZEDQA rt_media PASS Health: a click on a fill block's head is taken
ZEDQA rt_media PASS Health: a fill block's head folds or opens its block | moodles: false -> true
ZEDQA rt_media PASS Health: pressed again, the block is back as it was
ZEDQA rt_media PASS Thermal: the region grid draws its cells
ZEDQA rt_media PASS Thermal: a click on a grid cell picks that region | Head, want Head
ZEDQA rt_media PASS on screen (the Thermal tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Hair and beard: the Identity tab draws the section's part switch
ZEDQA rt_media PASS Hair and beard: a click on the switch changes the part | beard, want beard
ZEDQA rt_media PASS Hair and beard: a click on a row picks it | h:cut:Bald
ZEDQA rt_media PASS Hair and beard: Cut is live for the picked row
ZEDQA rt_media PASS Hair and beard: Cut queues the game's haircut (ISCutHair)
ZEDQA rt_media PASS Hair and beard: stopped at once, the hair is as it was | Grungey
ZEDQA rt_media PASS put back: the character is where it started | 928,13039
ZEDQA rt_media PASS put back: the hands hold what they held
ZEDQA rt_media end: 190 pass, 0 fail, 1 skipped
ZEDQA rt_media VERDICT PASS 190
ZEDQA rt_media DONE
```

### 10. rt_vehicles.lua (`ZEDQA rt_veh`) - PASS, 27 s

- go 30377 at 15:16:14

```text
[ZeD.QA] state #10 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_veh start (48 steps)
[ZeD.QA] run #10 ok=true
ZEDQA vp rt_veh player=928,13039 grid=19 chunks (152 tiles) loaded x 856-1008 y 12960-13112 sq=917,13030 dist=14.9 chunk=true inMap=true car=Base.CarLightsKST at 917.0,13030.0 dist=14.9 vehicles=21
ZEDQA car rt_veh Base.CarLightsPolice spawned on spot 11 (917,13030)
ZEDQA rt_veh PASS a police car spawned beside the character, the character in the driver's seat | nil
ZEDQA rt_veh PASS dash: ZeD's dash shows in the car
ZEDQA rt_veh PASS dash: the game's own dash is not shown beside ZeD's
ZEDQA rt_veh PASS dash: it has a design for the car | police
ZEDQA rt_veh PASS dash: its design has gauges | 5 needles
ZEDQA rt_veh PASS dash: its design has lamps | 9 lamps
ZEDQA rt_veh PASS on screen (the dash): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS dash: a click on the ignition puts the key in
ZEDQA rt_veh PASS dash: key on, engine off: the bulb check lights the lamps | check true, battery true, engine true, oil true
ZEDQA rt_veh PASS dash: a second click on the ignition starts the engine (the game's start) | 0 retries
ZEDQA rt_veh PASS dash: running: the rev needle is up | rpm 754
ZEDQA rt_veh PASS dash: the fuel needle reads the full tank | fuel 1.00
ZEDQA rt_veh PASS dash: running: the bulb check is over (oil lamp dark) | false
ZEDQA rt_veh PASS on screen (the dash, engine running): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS dash: it has its headlight switch | tripReset lights lock trunk ignition lbar siren temp heat fan ac def vol radio chup chdn mem mic mute tune
ZEDQA rt_veh PASS dash: a click on the headlight switch flips the headlights | false -> true
ZEDQA rt_veh PASS dash: a second click puts the headlights back | false
ZEDQA rt_veh PASS radio: ZeD's hook is on the wheel's Device Options
ZEDQA rt_veh PASS radio: Device Options brings the car radio up close | ham
ZEDQA rt_veh PASS on screen (the car radio): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_veh PASS radio: it has a power control | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: the click turns it on (the game's radio action)
ZEDQA rt_veh PASS radio: with the engine running it plays
ZEDQA rt_veh PASS radio: it has a tuning knob | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: a click on TUNE's right half moves the frequency | 99600 -> 99800
ZEDQA rt_veh PASS radio: TUNE's left half tunes it back | 99600
ZEDQA rt_veh PASS radio: Device Options again puts it away
ZEDQA rt_veh PASS seats: ZeD's hook is on the seat key
ZEDQA rt_veh PASS seats: a car the cabin cannot lay out gets ZeD's seat chooser | ZeD_SeatChooser
ZEDQA rt_veh PASS seats: it lists every seat of the car | 4 of 4
ZEDQA rt_veh PASS seats: the driver's seat is yours | you
ZEDQA rt_veh PASS on screen (the seat chooser): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_veh PASS seats: it closes
ZEDQA rt_veh PASS seats: in Lite the seat key opens the cabin pop-out | pop-out true, chooser false
ZEDQA rt_veh PASS on screen (the seat pop-out): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_veh PASS seats: the cabin pop-out closes
ZEDQA rt_veh PASS siren: the police car has a lightbar
ZEDQA rt_veh PASS siren: ZeD's hook is on the wheel's Lightbar
ZEDQA rt_veh PASS siren: the Lightbar brings the siren controller up close
ZEDQA rt_veh PASS siren: its plate is loaded (SirenPlate, PhysPx)
ZEDQA rt_veh PASS on screen (the siren controller): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_veh PASS siren: LIGHTS has its 1 position | lights:0 lights:1 lights:2 lights:3 lights:knob siren:0 siren:1 siren:2 siren:3 siren:knob
ZEDQA rt_veh PASS siren: a click on LIGHTS 1 turns the bar on (the game's command) | 1
ZEDQA rt_veh PASS siren: the dash's lightbar lamp follows | true
ZEDQA rt_veh PASS siren: a click on its OFF puts the bar back | 0
ZEDQA rt_veh PASS dash: a click on the ignition shuts the engine off
ZEDQA rt_veh PASS vehicle: the game's Vehicle Mechanics inspects the car and opens the World window's Vehicle tab
ZEDQA rt_veh PASS dash: out of the car, ZeD's dash is put away | in a car false, dash false
ZEDQA rt_veh PASS vehicle: the tab lists the car's parts | 41 of 41
ZEDQA rt_veh PASS vehicle: the parts' rows are drawn | 41
ZEDQA rt_veh PASS on screen (the Vehicle tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS vehicle: a click on a part's row opens its card | Muffler (want Muffler)
ZEDQA rt_veh PASS vehicle: the same row again closes the card | nil
ZEDQA home rt_veh moved from 916,13027,0 to the drag strip
ZEDQA car rt_veh took away a car an earlier spawn left behind
ZEDQA vp rt_veh player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=15.9 chunk=true inMap=true car=Base.Trailer_Livestock at 910.0,13037.0 dist=15.9 vehicles=40
ZEDQA car rt_veh Base.Trailer_Livestock spawned on spot 12 (910,13037)
ZEDQA rt_veh PASS trailer: an animal trailer spawned beside the character | nil
ZEDQA rt_veh PASS trailer: ZeD's hook is on the game's Check Animals
ZEDQA rt_veh PASS trailer: Check Animals opens the Vehicle tab on the trailer's page | tab vehicle, trailer true
ZEDQA rt_veh PASS on screen (the trailer's page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS put back: the character out, the key taken back, the car removed
ZEDQA rt_veh end: 58 pass, 0 fail, 0 skipped
ZEDQA rt_veh VERDICT PASS 58
ZEDQA rt_veh DONE
```

### 11. rt_addon.lua (`ZEDQA rt_addon`) - PASS, 4 s

- go 30378 at 15:16:45

```text
[ZeD.QA] state #11 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_addon start (39 steps)
[ZeD.QA] run #11 ok=true
ZeD.GridLayout.register(zedqa_rt_addon_standin): the provider has no layout function; not registered
ZEDQA rt_addon PASS the stand-in provider registers (hook version 2)
ZEDQA rt_addon PASS a provider with no layout function is refused (register returns false) | false
ZEDQA rt_addon PASS the provider's layout is asked, with version 2's avail, cell and gap | calls 1
ZEDQA rt_addon PASS the bag is laid out by the provider | layout true
ZEDQA rt_addon PASS its answer is taken: shapes on, one flat grid
ZEDQA rt_addon PASS the L cell takes its mask: a 2 x 2 box of three squares | 2x2, 3 squares
ZEDQA rt_addon PASS the bar cell takes its mask: three squares down | 1x3
ZEDQA rt_addon PASS the L cell holds the three apples as one stack | count 3
ZEDQA rt_addon PASS the L cell's labels are placed on its first square (the strip's and the weight's square is the picture's)
ZEDQA rt_addon PASS both shaped cells are drawn as shapes (with their drawing, not a box) | L true, bar true
ZEDQA rt_addon PASS the squares are the provider's scale of ZeD's own | 81 px, want 81 (ZeD's 91, scale 0.9)
ZEDQA rt_addon PASS the L cell draws nothing in its hole | 0 of 23 draws there
ZEDQA rt_addon PASS the L cell takes no click in its hole | 0 click zones there
ZEDQA rt_addon PASS each of the L cell's squares takes a click | 1, 1, 1
ZEDQA rt_addon PASS the L cell's picture and labels sit on its first square | all on it; texts (0.6) (3)
ZEDQA rt_addon PASS the L cell shows its count (3) | (0.6) (3)
ZEDQA rt_addon PASS the L cell shows its weight as well | (0.6) (3)
ZEDQA rt_addon PASS the bar cell's picture and labels sit on its first square (the top one) | all on it; texts 1.5
ZEDQA rt_addon PASS the bar cell's condition strip is on its first square's foot | 5 rects there
ZEDQA rt_addon PASS on screen (the bag as the provider's grid): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_addon PASS the pad's place mode carries the L cell's mask | mask XX/X., squares 3
ZEDQA rt_addon PASS the place mode's ghost is the mask's outline, not its box | 12 edges drawn, 0 missing, 0 in the hole
ZEDQA rt_addon PASS the place mode's prompts: D-pad Move, A Turn, X Place, B Cancel | D-PAD A X B
ZEDQA rt_addon PASS the place mode: B ends it, nothing placed
ZEDQA rt_addon PASS the place mode: letting X go hands the square to the provider's drop | on true, dropped true
ZEDQA rt_addon PASS mouse drag: a press on the L cell past the threshold starts ZeD's drag
ZEDQA rt_addon PASS mouse drag: over the grid, the over-state says canPlace's yes | ok true, on this list true
ZEDQA rt_addon PASS mouse drag: the ghost is the mask's outline, in the yes colour | 12 edges drawn, 0 missing, 0 in another colour (last frame, at the over-state's square 0,0)
ZEDQA rt_addon PASS mouse drag: the wheel (as R) turns the dragged shape | 1 turns, shape asked 1 times since
ZEDQA rt_addon PASS mouse drag: the release hands the square to the provider's drop | dropped true
ZEDQA rt_addon PASS mouse drag: canPlace's no turns the ghost the no colour, its reason said | ok false, reason QA stand-in: no room here; 12 edges, 0 missing, 0 other colour (last frame)
ZEDQA rt_addon PASS mouse drag: a refused release drops nothing, the reason kept | dropped nil, kept QA stand-in: no room here
ZEDQA rt_addon PASS mail store: a box is made for a server and name, a letter queued and one received | nil
ZEDQA rt_addon PASS mail store: the box's file holds the queued letter (its pipe escaped) and the received one; the index names the box | 4 lines in ZeD_mail_1.txt, box listed true
ZEDQA rt_addon PASS mail store: the Outbox letter reads back whole (subject, words with the pipe and the line break, to) | A letter | with a pipe
    and a second line.
ZEDQA rt_addon PASS mail store: the Inbox letter reads back, unread | QA reply, unread 1
ZEDQA rt_addon PASS mail store: a sent letter leaves the Outbox for Sent, read back | 0 out, 1 sent
ZEDQA rt_addon PASS mail store put back: its own file access again, the QA files emptied
ZEDQA rt_addon PASS item bar: a water bottle's bar is its fluid, amount over capacity | fluid 1 (want 1)
ZEDQA rt_addon PASS item bar: a weapon's bar is its condition | cond
ZEDQA rt_addon PASS item bar: a can of beans has no bar | nil
ZEDQA rt_addon PASS loot card: the card names the item with its count and leads with its weight | Apple (Fresh) (3), first row Weight
ZEDQA rt_addon PASS item rules: the stand-in rule refuses its apple, with its reason | false, QA stand-in: no room for this apple
ZEDQA rt_addon PASS item rules: the refused apple stays put, the other moves into the bag | other moved true, refused one in place true
ZEDQA rt_addon PASS item rules: the reason shows once over the head | 1 notes: QA stand-in: no room for this apple
ZEDQA rt_addon PASS Loadouts: a new list is saved with the character, by its name | 3 lists (were 2)
ZEDQA rt_addon PASS Loadouts: a list renamed keeps its new name | zedqa renamed
ZEDQA rt_addon PASS Loadouts: a line's amount is set and kept | 3
ZEDQA rt_addon PASS Loadouts: a list deleted is gone from the character's lists | 2 lists
ZEDQA rt_addon PASS fishing log: the game's landing (PickupFish.start) is wrapped
ZEDQA rt_addon PASS fishing log: a catch is logged, newest, with its name and weight | table 0x1029349489{ k=fish, name=QA Bass, wt=2.5, len=40, yr=0, mo=0, dy=6, hr=12, mn=22, wa=101.38323974609375 }, 1 in the log
ZEDQA rt_addon PASS add-on options: addGroup takes a stand-in group and refuses one with no owner | version 1, 1 groups
ZEDQA rt_addon PASS add-on options: the same owner and title again replaces it, never twice | 1 groups
ZEDQA rt_addon PASS watch registry: a registered watch is filed under its item type
ZEDQA rt_addon PASS item facts: a registered factory gives its item's facts on the card | key zedqa_rt_addon_facts, gen 0 -> 1
ZEDQA rt_addon PASS traits tab: no source here, so no Traits tab | nil
ZEDQA rt_addon PASS traits tab: a source added is listed, counted, laid out and owns its ids | count +2, y +5
ZEDQA rt_addon PASS keyboard: A on a text box opens ZeD's keyboard on it
ZEDQA rt_addon PASS keyboard: A on the a and b keys types ab | 'ab'
ZEDQA rt_addon PASS on screen (ZeD's keyboard): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_addon PASS keyboard: B leaves it and the text is kept | 'ab'
ZEDQA rt_addon PASS Lua console: it opens as ZeD's window
ZEDQA rt_addon PASS on screen (the Lua console): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_addon console mark 1795130208311
ZEDQA rt_addon PASS Lua console: a print reaches its log
ZEDQA rt_addon PASS Lua console: closed again, as it was
ZEDQA rt_addon PASS unregistered, the hook has no provider
ZEDQA rt_addon PASS the bag's grid is ZeD's own again (no add-on layout on the list)
ZEDQA rt_addon PASS the place mode was cancelled: nothing was dropped
ZEDQA rt_addon end: 68 pass, 0 fail, 0 skipped
ZEDQA rt_addon VERDICT PASS 68
ZEDQA rt_addon DONE
```

### 12. rt_lite.lua (`ZEDQA rt_lite`) - PASS, 7 s

- go 30379 at 15:16:53

```text
[ZeD.QA] state #12 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_lite start (39 steps)
[ZeD.QA] run #12 ok=true
ZEDQA rt_lite PASS Lite: ZeD's settings, molecules and options are loaded
ZEDQA rt_lite as found: Style 1 (1 Full, 2 Lite), additions preset 4
ZEDQA rt_lite PASS Style Lite: Options opens from the pause menu
ZEDQA rt_lite PASS Style Lite: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Lite: ZeD setup leaves out the Additions and Chords groups | additions false, chords false/0
ZEDQA rt_lite PASS Style Lite: none of the eight retired switches is in ZeD setup |
ZEDQA rt_lite PASS Style Lite: the Style row stays in ZeD setup
ZEDQA rt_lite PASS on screen (ZeD setup in Lite): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_lite PASS Style Lite: the pause menu shuts
ZEDQA rt_lite PASS Style Lite: ZeD.Settings.lite() is true once applied | 2
ZEDQA rt_lite PASS Style Lite: the forms' helpers all answer Lite (devices, watch, guide, mods, identity, belt) | 6 helpers
ZEDQA rt_lite PASS Style Lite: the additions are on the Vanilla preset | preset 1, 15 additions
ZEDQA rt_lite PASS Lite buttons: ZeD.Molecules.lite() is true
ZEDQA rt_lite PASS Lite buttons: Cancel, No and a danger button are the bad kind | Cancel bad, No bad, danger bad
ZEDQA rt_lite PASS Lite buttons: a primary or default answer is the good kind, a plain button neither | good / nil
ZEDQA rt_lite PASS Lite buttons: a grayed button has no kind
ZEDQA rt_lite PASS Lite buttons: the good color is the game's getGoodHighlitedColor | rgb 0 255 0 / rgb 0 255 0
ZEDQA rt_lite PASS Lite buttons: the bad color is the game's getBadHighlitedColor | rgb 255 0 0 / rgb 255 0 0
ZEDQA rt_lite PASS Lite watch: off the belt, in the corner (W.beltMode() false) | lite true, belt false
ZEDQA rt_lite PASS Lite watch: its keys are the speed row speed0 to speed3, then the face and the alarm line | speed0 speed1 speed2 speed3 alarmline fold
ZEDQA rt_lite PASS on screen (Lite: the watch in its corner): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite buttons: a primary button is drawn filled with the good color under a two-hairline line | x1: 2 lines, 0 double
ZEDQA rt_lite PASS Lite dashboard: every car gets the Dash Elite (a pickup, a police car) | dashelite, dashelite
ZEDQA rt_lite PASS Lite dashboard: in the black cabin | v_black
ZEDQA rt_lite SKIP Lite watch: the big time is in the accent color (the big time is not drawn through drawText (another drawing path))
ZEDQA rt_lite PASS Lite watch fold: the face has its fold hit and a click lands on it
ZEDQA rt_lite PASS Lite watch fold: a click on the face folds it to one line (shorter, the strip is one fold hit) | thin true, h 43.1484375 < 182.4453125, hits fold
ZEDQA rt_lite PASS Lite watch fold: the strip's time is in the accent color | 12:24
ZEDQA rt_lite PASS on screen (Lite: the folded watch): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite watch fold: a click on the strip unfolds it to its full height | thin false, h 182.4453125
ZEDQA rt_lite PASS Lite watch: the alarm line has its hit
ZEDQA rt_lite PASS Lite watch: a click on the alarm line opens the alarm setting | true
ZEDQA rt_lite PASS Lite device faces: no preset keys, memory key or dial lamp on any radio's plain controls | 17 readings, 0 with them:
ZEDQA rt_lite PASS Lite device faces: the memory key and the lamp are on the Lite drop list
ZEDQA rt_lite PASS Lite windows: the inventory has its List or Grid key
ZEDQA rt_lite PASS Lite windows: List or Grid is drawn as its word | List view: 153.76953125 wide, the word's button 153.76953125
ZEDQA rt_lite PASS Lite windows: Filter is drawn as its word | 116.7734375 wide, the word's button 116.7734375
ZEDQA rt_lite PASS Lite windows: no Same type or Same type nearby button | xfer
ZEDQA rt_lite PASS Lite windows: the container buttons' trim keeps Transfer all only | 1 left
ZEDQA rt_lite PASS Lite windows: the pencil's row is in the Character window's list
ZEDQA rt_lite PASS Lite windows: a click on the row opens its item card
ZEDQA rt_lite PASS Lite windows: the item card has no marks strip | nil
ZEDQA rt_lite PASS on screen (Lite: both windows and the item card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite windows: a second click closes the card
ZEDQA rt_lite PASS Style Full: Options opens from the pause menu
ZEDQA rt_lite PASS Style Full: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Full: ZeD setup has the Additions and Chords groups again | additions true, chords true
ZEDQA rt_lite PASS Style Full: the retired switches stay out of ZeD setup |
ZEDQA rt_lite PASS on screen (ZeD setup in Full): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_lite PASS Style Full: the pause menu shuts
ZEDQA rt_lite PASS Style Full: ZeD.Settings.lite() is false once applied | 1
ZEDQA rt_lite PASS Style Full: the forms' helpers all answer Full | 6 helpers
ZEDQA rt_lite PASS Full buttons: ZeD.Molecules.lite() is false
ZEDQA rt_lite PASS Full watch: its place is the Watch option's again | belt false, option 2
ZEDQA rt_lite PASS Full dashboard: a pickup and a police car have their own dash again | d6, police
ZEDQA rt_lite PASS Full device faces: the radios' preset keys, memory key and lamp come back | 12 readings with them
ZEDQA rt_lite PASS Lite device faces: every plate's power row stays in Lite |
ZEDQA rt_lite PASS Full windows: List or Grid is the square picture key again | 46x46
ZEDQA rt_lite PASS Full windows: Same type and Same type nearby come back | xfer same near
ZEDQA rt_lite PASS Full windows: the item card has its marks strip again | 85.9765625
ZEDQA rt_lite PASS Map always light: in Dark, Always light reads the Light map | light
ZEDQA rt_lite PASS Map always light: in Dark, Follows the theme reads the Dark map | dark
ZEDQA rt_lite PASS Map always light: High contrast keeps its own map | hicon
ZEDQA rt_lite PASS Map always light: the theme and the option put back | light
ZEDQA rt_lite PASS put back: every ZeD option as found, Style among them | Style 1
ZEDQA rt_lite PASS put back: ModOptions.ini line for line | 65 lines, 65 before
ZEDQA rt_lite PASS put back: the windows open or shut as found
ZEDQA rt_lite PASS Lite and Full drew with no Lua error | 0 new
ZEDQA rt_lite end: 66 pass, 0 fail, 1 skipped
ZEDQA rt_lite VERDICT PASS 66
ZEDQA rt_lite DONE
```

### 13. rt_kbmap.lua (`ZEDQA rt_kbmap`) - PASS, 3 s

- go 30380 at 15:17:03

```text
[ZeD.QA] state #13 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_kbmap start (16 steps)
[ZeD.QA] run #13 ok=true
ZEDQA rt_kbmap PASS Keyboard map: ZeD.KeyboardMap is loaded (open, read, setKey, resetAll)
ZEDQA rt_kbmap as found: Toggle Music on 0, keysB42.ini 95 lines
ZEDQA rt_kbmap PASS Keyboard map: the window menu has its Keyboard map row | Keyboard map
ZEDQA rt_kbmap PASS Keyboard map: its menu row opens the window
ZEDQA rt_kbmap PASS on screen (the keyboard map): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_kbmap PASS Keyboard map: read() lists every binding of the game's keyBinding table with its key now | 83 of 83 bindings, 11 of 11 groups
ZEDQA rt_kbmap PASS Keyboard map: the drawn keyboard lights every bound key and only those | 71 keys drawn, 51 lit, 0 clashes
ZEDQA rt_kbmap PASS Keyboard map: a free key and a held key to test with | Toggle Music: free 40, held 59 (Toggle Survival Guide)
ZEDQA rt_kbmap PASS Keyboard map: setKey gives the game the new key at once (getCore():getKey) | Toggle Music on 40, wanted 40
ZEDQA rt_kbmap PASS Keyboard map: keysB42.ini has the new line in the game's format and no other line changed | Toggle Music=key:40 (wanted Toggle Music=key:40), 0 other lines changed, first line VERSION=2
ZEDQA rt_kbmap PASS Keyboard map: the game's Options reading of keysB42.ini finds the new key | version 2, 40
ZEDQA rt_kbmap PASS Keyboard map: the new key is lit on the drawn keyboard | rgb 26 102 85
ZEDQA rt_kbmap PASS Keyboard map: a key given two jobs is a clash in read() | Toggle Music and Toggle Survival Guide on 59
ZEDQA rt_kbmap PASS Keyboard map: a clash is drawn in the bad color (getBadHighlitedColor) on its key | rgb 255 0 0, bad rgb 255 0 0
ZEDQA rt_kbmap PASS Keyboard map: both clashing actions' key boxes are edged in the bad color | Toggle Music true, Toggle Survival Guide true
ZEDQA rt_kbmap PASS Keyboard map: the clash clears once the key is put back | clash nil
ZEDQA rt_kbmap PASS Keyboard map: the first Reset press asks and changes nothing yet | clicked true, Toggle Music on 40
ZEDQA rt_kbmap PASS Keyboard map: the Reset button reads Press again to reset | Press again to reset / danger
ZEDQA rt_kbmap PASS Keyboard map: a second Reset press within 4 s puts every key back to the game's own | 83 bindings
ZEDQA rt_kbmap PASS Keyboard map: keysB42.ini holds the game's own keys after the reset |
ZEDQA rt_kbmap PASS put back: every binding as the director had it (getCore():getKey) | 4 set back
ZEDQA rt_kbmap PASS put back: keysB42.ini line for line as found | 95 lines, 95 before
ZEDQA rt_kbmap PASS put back: the keyboard map is shut
ZEDQA rt_kbmap PASS put back: the windows open or shut as found
ZEDQA rt_kbmap PASS the keyboard map ran with no Lua error | 0 new
ZEDQA rt_kbmap end: 24 pass, 0 fail, 0 skipped
ZEDQA rt_kbmap VERDICT PASS 24
ZEDQA rt_kbmap DONE
```

### 14. rt_tour.lua (`ZEDQA rt_tour`) - PASS, 14 s

- go 30381 at 15:17:09

```text
[ZeD.QA] state #14 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_tour start (31 steps)
[ZeD.QA] run #14 ok=true
ZEDQA rt_tour the file at the start: nil; wanted() nil
ZEDQA rt_tour PASS no start by itself: the file asked for nothing, and no tour is running 9 s into the game
ZEDQA rt_tour PASS the tour has eleven steps (belt, watch, Character window, its tabs, Health, Identity, Skills, card, World window, menu, guide) | 11
ZEDQA rt_tour PASS words: every step's title and text, Next, Done, Stop tour and the step count are in the game's words |
ZEDQA rt_tour PASS words: the step count fills in its numbers | 3 of 7
ZEDQA rt_tour PASS mouse: both windows are shut before the tour starts
ZEDQA rt_tour PASS mouse: TU.start runs the tour
ZEDQA rt_tour PASS mouse: the balloon's layer and the keys are on the screen
ZEDQA rt_tour PASS mouse: the layer under the balloon lets the pointer through | onMouseDown false, consumes false
ZEDQA rt_tour PASS mouse step 1 (Belt): the tour is on step 1 | on 1
ZEDQA rt_tour PASS mouse step 1 (Belt): its thing is on screen | 1535,2034 747x98
ZEDQA rt_tour PASS mouse step 1 (Belt): its balloon is drawn | tutorial:1
ZEDQA rt_tour PASS mouse step 1 (Belt): the balloon has the step's title | Your belt
ZEDQA rt_tour PASS mouse step 1 (Belt): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 1 (Belt): it counts the step | 1 of 11
ZEDQA rt_tour PASS mouse step 1 (Belt): the balloon points at its thing | anchor 1535,2034 747x98, thing 1535,2034 747x98
ZEDQA rt_tour PASS mouse step 1 (Belt): the balloon is on screen | 1545,1864 560x147
ZEDQA rt_tour PASS mouse step 1 (Belt): the balloon does not cover its thing | balloon 1545,1864 560x147, thing 1535,2034 747x98
ZEDQA rt_tour PASS mouse step 1 (Belt): the keys are shown, on screen | 1837,1807 267x46
ZEDQA rt_tour PASS mouse step 1 (Belt): the keys sit off the balloon | keys 1837,1807 267x46, balloon 1545,1864 560x147
ZEDQA rt_tour PASS mouse step 1 (Belt): the keys do not cover its thing | keys 1837,1807 267x46, thing 1535,2034 747x98
ZEDQA rt_tour PASS mouse step 1 (Belt): its key reads Next | Next
ZEDQA rt_tour PASS on screen (mouse step 1 (Belt)): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_tour PASS mouse step 2 (Watch): the tour is on step 2 | on 2
ZEDQA rt_tour PASS mouse step 2 (Watch): its thing is on screen | 3596,10 228x52
ZEDQA rt_tour PASS mouse step 2 (Watch): its balloon is drawn | tutorial:2
ZEDQA rt_tour PASS mouse step 2 (Watch): the balloon has the step's title | Your watch
ZEDQA rt_tour PASS mouse step 2 (Watch): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 2 (Watch): it counts the step | 2 of 11
ZEDQA rt_tour PASS mouse step 2 (Watch): the balloon points at its thing | anchor 3596,10 228x52, thing 3596,10 228x52
ZEDQA rt_tour PASS mouse step 2 (Watch): the balloon is on screen | 3178,84 452x114
ZEDQA rt_tour PASS mouse step 2 (Watch): the balloon does not cover its thing | balloon 3178,84 452x114, thing 3596,10 228x52
ZEDQA rt_tour PASS mouse step 2 (Watch): the keys are shown, on screen | 3362,209 267x46
ZEDQA rt_tour PASS mouse step 2 (Watch): the keys sit off the balloon | keys 3362,209 267x46, balloon 3178,84 452x114
ZEDQA rt_tour PASS mouse step 2 (Watch): the keys do not cover its thing | keys 3362,209 267x46, thing 3596,10 228x52
ZEDQA rt_tour PASS mouse step 2 (Watch): its key reads Next | Next
ZEDQA rt_tour PASS on screen (mouse step 2 (Watch)): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_tour PASS mouse step 3 (Char): the tour is on step 3 | on 3
ZEDQA rt_tour PASS mouse step 3 (Char): its thing is on screen | 1134,0 777x735
ZEDQA rt_tour PASS mouse step 3 (Char): its balloon is drawn | tutorial:3
ZEDQA rt_tour PASS mouse step 3 (Char): the balloon has the step's title | The Character window
ZEDQA rt_tour PASS mouse step 3 (Char): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 3 (Char): it counts the step | 3 of 11
ZEDQA rt_tour PASS mouse step 3 (Char): the balloon points at its thing | anchor 1134,0 777x735, thing 1134,0 777x735
ZEDQA rt_tour PASS mouse step 3 (Char): the balloon is on screen | 1933,357 560x180
ZEDQA rt_tour PASS mouse step 3 (Char): the balloon does not cover its thing | balloon 1933,357 560x180, thing 1134,0 777x735
ZEDQA rt_tour PASS mouse step 3 (Char): the keys are shown, on screen | 2225,548 267x46
ZEDQA rt_tour PASS mouse step 3 (Char): the keys sit off the balloon | keys 2225,548 267x46, balloon 1933,357 560x180
ZEDQA rt_tour PASS mouse step 3 (Char): the keys do not cover its thing | keys 2225,548 267x46, thing 1134,0 777x735
ZEDQA rt_tour PASS mouse step 3 (Char): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 3 (Char): the Character window is open
ZEDQA rt_tour PASS on screen (mouse step 3 (Char)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 4 (Tabs): the tour is on step 4 | on 4
ZEDQA rt_tour PASS mouse step 4 (Tabs): its thing is on screen | 1134,46 63x650
ZEDQA rt_tour PASS mouse step 4 (Tabs): its balloon is drawn | tutorial:4
ZEDQA rt_tour PASS mouse step 4 (Tabs): the balloon has the step's title | The tabs
ZEDQA rt_tour PASS mouse step 4 (Tabs): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 4 (Tabs): it counts the step | 4 of 11
ZEDQA rt_tour PASS mouse step 4 (Tabs): the balloon points at its thing | anchor 1134,46 63x650, thing 1134,46 63x650
ZEDQA rt_tour PASS mouse step 4 (Tabs): the balloon is on screen | 1219,360 560x247
ZEDQA rt_tour PASS mouse step 4 (Tabs): the balloon does not cover its thing | balloon 1219,360 560x247, thing 1134,46 63x650
ZEDQA rt_tour PASS mouse step 4 (Tabs): the keys are shown, on screen | 1511,618 267x46
ZEDQA rt_tour PASS mouse step 4 (Tabs): the keys sit off the balloon | keys 1511,618 267x46, balloon 1219,360 560x247
ZEDQA rt_tour PASS mouse step 4 (Tabs): the keys do not cover its thing | keys 1511,618 267x46, thing 1134,46 63x650
ZEDQA rt_tour PASS mouse step 4 (Tabs): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 4 (Tabs): it points at the Character window's tab strip | anchor 1134,46 63x650
ZEDQA rt_tour PASS on screen (mouse step 4 (Tabs)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 5 (Health): the tour is on step 5 | on 5
ZEDQA rt_tour PASS mouse step 5 (Health): its thing is on screen | 294,0 1617x735
ZEDQA rt_tour PASS mouse step 5 (Health): its balloon is drawn | tutorial:5
ZEDQA rt_tour PASS mouse step 5 (Health): the balloon has the step's title | Health
ZEDQA rt_tour PASS mouse step 5 (Health): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 5 (Health): it counts the step | 5 of 11
ZEDQA rt_tour PASS mouse step 5 (Health): the balloon points at its thing | anchor 294,0 1617x735, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 5 (Health): the balloon is on screen | 1933,357 560x214
ZEDQA rt_tour PASS mouse step 5 (Health): the balloon does not cover its thing | balloon 1933,357 560x214, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 5 (Health): the keys are shown, on screen | 2225,582 267x46
ZEDQA rt_tour PASS mouse step 5 (Health): the keys sit off the balloon | keys 2225,582 267x46, balloon 1933,357 560x214
ZEDQA rt_tour PASS mouse step 5 (Health): the keys do not cover its thing | keys 2225,582 267x46, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 5 (Health): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 5 (Health): the Character window is on its health tab | health
ZEDQA rt_tour PASS on screen (mouse step 5 (Health)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 6 (Identity): the tour is on step 6 | on 6
ZEDQA rt_tour PASS mouse step 6 (Identity): its thing is on screen | 294,0 1617x735
ZEDQA rt_tour PASS mouse step 6 (Identity): its balloon is drawn | tutorial:6
ZEDQA rt_tour PASS mouse step 6 (Identity): the balloon has the step's title | Your ID
ZEDQA rt_tour PASS mouse step 6 (Identity): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 6 (Identity): it counts the step | 6 of 11
ZEDQA rt_tour PASS mouse step 6 (Identity): the balloon points at its thing | anchor 294,0 1617x735, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 6 (Identity): the balloon is on screen | 1933,357 560x180
ZEDQA rt_tour PASS mouse step 6 (Identity): the balloon does not cover its thing | balloon 1933,357 560x180, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 6 (Identity): the keys are shown, on screen | 2225,548 267x46
ZEDQA rt_tour PASS mouse step 6 (Identity): the keys sit off the balloon | keys 2225,548 267x46, balloon 1933,357 560x180
ZEDQA rt_tour PASS mouse step 6 (Identity): the keys do not cover its thing | keys 2225,548 267x46, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 6 (Identity): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 6 (Identity): the Character window is on its identity tab | identity
ZEDQA rt_tour PASS on screen (mouse step 6 (Identity)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 7 (Skills): the tour is on step 7 | on 7
ZEDQA rt_tour PASS mouse step 7 (Skills): its thing is on screen | 294,0 1617x735
ZEDQA rt_tour PASS mouse step 7 (Skills): its balloon is drawn | tutorial:7
ZEDQA rt_tour PASS mouse step 7 (Skills): the balloon has the step's title | Skills
ZEDQA rt_tour PASS mouse step 7 (Skills): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 7 (Skills): it counts the step | 7 of 11
ZEDQA rt_tour PASS mouse step 7 (Skills): the balloon points at its thing | anchor 294,0 1617x735, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 7 (Skills): the balloon is on screen | 1933,357 560x147
ZEDQA rt_tour PASS mouse step 7 (Skills): the balloon does not cover its thing | balloon 1933,357 560x147, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 7 (Skills): the keys are shown, on screen | 2225,515 267x46
ZEDQA rt_tour PASS mouse step 7 (Skills): the keys sit off the balloon | keys 2225,515 267x46, balloon 1933,357 560x147
ZEDQA rt_tour PASS mouse step 7 (Skills): the keys do not cover its thing | keys 2225,515 267x46, thing 294,0 1617x735
ZEDQA rt_tour PASS mouse step 7 (Skills): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 7 (Skills): the Character window is on its skills tab | skills
ZEDQA rt_tour PASS on screen (mouse step 7 (Skills)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 8 (Card): the tour is on step 8 | on 8
ZEDQA rt_tour PASS mouse step 8 (Card): its thing is on screen | 749,0 1162x735
ZEDQA rt_tour PASS mouse step 8 (Card): its balloon is drawn | tutorial:8
ZEDQA rt_tour PASS mouse step 8 (Card): the balloon has the step's title | An item's card
ZEDQA rt_tour PASS mouse step 8 (Card): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 8 (Card): it counts the step | 8 of 11
ZEDQA rt_tour PASS mouse step 8 (Card): the balloon points at its thing | anchor 749,0 1162x735, thing 749,0 1162x735
ZEDQA rt_tour PASS mouse step 8 (Card): the balloon is on screen | 1933,357 560x147
ZEDQA rt_tour PASS mouse step 8 (Card): the balloon does not cover its thing | balloon 1933,357 560x147, thing 749,0 1162x735
ZEDQA rt_tour PASS mouse step 8 (Card): the keys are shown, on screen | 2225,515 267x46
ZEDQA rt_tour PASS mouse step 8 (Card): the keys sit off the balloon | keys 2225,515 267x46, balloon 1933,357 560x147
ZEDQA rt_tour PASS mouse step 8 (Card): the keys do not cover its thing | keys 2225,515 267x46, thing 749,0 1162x735
ZEDQA rt_tour PASS mouse step 8 (Card): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 8 (Card): the Character window is on its loot tab | loot
ZEDQA rt_tour PASS mouse step 8 (Card): an item's card is open (the drawer in item mode) | drawer item, item Base.Shotgun:zombie.inventory.types.HandWeapon@538c6ab2, card shown true
ZEDQA rt_tour PASS on screen (mouse step 8 (Card)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 9 (World): the tour is on step 9 | on 9
ZEDQA rt_tour PASS mouse step 9 (World): its thing is on screen | 1929,0 777x735
ZEDQA rt_tour PASS mouse step 9 (World): its balloon is drawn | tutorial:9
ZEDQA rt_tour PASS mouse step 9 (World): the balloon has the step's title | The World window
ZEDQA rt_tour PASS mouse step 9 (World): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 9 (World): it counts the step | 9 of 11
ZEDQA rt_tour PASS mouse step 9 (World): the balloon points at its thing | anchor 1929,0 777x735, thing 1929,0 777x735
ZEDQA rt_tour PASS mouse step 9 (World): the balloon is on screen | 1347,357 560x147
ZEDQA rt_tour PASS mouse step 9 (World): the balloon does not cover its thing | balloon 1347,357 560x147, thing 1929,0 777x735
ZEDQA rt_tour PASS mouse step 9 (World): the keys are shown, on screen | 1639,515 267x46
ZEDQA rt_tour PASS mouse step 9 (World): the keys sit off the balloon | keys 1639,515 267x46, balloon 1347,357 560x147
ZEDQA rt_tour PASS mouse step 9 (World): the keys do not cover its thing | keys 1639,515 267x46, thing 1929,0 777x735
ZEDQA rt_tour PASS mouse step 9 (World): its key reads Next | Next
ZEDQA rt_tour PASS mouse step 9 (World): the World window is open
ZEDQA rt_tour PASS on screen (mouse step 9 (World)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 10 (Menu): the tour is on step 10 | on 10
ZEDQA rt_tour PASS mouse step 10 (Menu): its thing is on screen | 2665,11 23x23
ZEDQA rt_tour PASS mouse step 10 (Menu): its balloon is drawn | tutorial:10
ZEDQA rt_tour PASS mouse step 10 (Menu): the balloon has the step's title | Every window's menu
ZEDQA rt_tour PASS mouse step 10 (Menu): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 10 (Menu): it counts the step | 10 of 11
ZEDQA rt_tour PASS mouse step 10 (Menu): the balloon points at its thing | anchor 2665,11 23x23, thing 2665,11 23x23
ZEDQA rt_tour PASS mouse step 10 (Menu): the balloon is on screen | 2666,56 560x147
ZEDQA rt_tour PASS mouse step 10 (Menu): the balloon does not cover its thing | balloon 2666,56 560x147, thing 2665,11 23x23
ZEDQA rt_tour PASS mouse step 10 (Menu): the keys are shown, on screen | 2958,214 267x46
ZEDQA rt_tour PASS mouse step 10 (Menu): the keys sit off the balloon | keys 2958,214 267x46, balloon 2666,56 560x147
ZEDQA rt_tour PASS mouse step 10 (Menu): the keys do not cover its thing | keys 2958,214 267x46, thing 2665,11 23x23
ZEDQA rt_tour PASS mouse step 10 (Menu): its key reads Next | Next
ZEDQA rt_tour PASS on screen (mouse step 10 (Menu)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS mouse step 11 (Guide): the tour is on step 11 | on 11
ZEDQA rt_tour PASS mouse step 11 (Guide): its thing is on screen | 2215,2049 67x67
ZEDQA rt_tour PASS mouse step 11 (Guide): its balloon is drawn | tutorial:11
ZEDQA rt_tour PASS mouse step 11 (Guide): the balloon has the step's title | Messages and the guide
ZEDQA rt_tour PASS mouse step 11 (Guide): the balloon has the step's words
ZEDQA rt_tour PASS mouse step 11 (Guide): it counts the step | 11 of 11
ZEDQA rt_tour PASS mouse step 11 (Guide): the balloon points at its thing | anchor 2215,2049 67x67, thing 2215,2049 67x67
ZEDQA rt_tour PASS mouse step 11 (Guide): the balloon is on screen | 2225,1846 560x180
ZEDQA rt_tour PASS mouse step 11 (Guide): the balloon does not cover its thing | balloon 2225,1846 560x180, thing 2215,2049 67x67
ZEDQA rt_tour PASS mouse step 11 (Guide): the keys are shown, on screen | 2517,1789 267x46
ZEDQA rt_tour PASS mouse step 11 (Guide): the keys sit off the balloon | keys 2517,1789 267x46, balloon 2225,1846 560x180
ZEDQA rt_tour PASS mouse step 11 (Guide): the keys do not cover its thing | keys 2517,1789 267x46, thing 2215,2049 67x67
ZEDQA rt_tour PASS mouse step 11 (Guide): its key reads Done | Done
ZEDQA rt_tour PASS mouse step 11 (Guide): it points at the belt's Messages note (the lamp box) | anchor 2215,2049 67x67, lamp 2215,2049 67x67
ZEDQA rt_tour PASS on screen (mouse step 11 (Guide)): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_tour PASS Done: the last step's Done ends the tour | visited Belt, Watch, Char, Tabs, Health, Identity, Skills, Card, World, Menu, Guide
ZEDQA rt_tour PASS Done: the balloon's layer and the keys are gone
ZEDQA rt_tour PASS Done: the file says "0", so the tour never comes back by itself | 0
ZEDQA rt_tour PASS Done: wanted() is nothing after it
ZEDQA rt_tour PASS passed over: the tour opens on the belt | 1
ZEDQA rt_tour PASS passed over: Next from the belt goes past the watch (nothing on screen) to the Character window | 3
ZEDQA rt_tour PASS Stop tour: the keys' Stop tour ends the tour at once
ZEDQA rt_tour PASS Stop tour: the layer and the keys are gone
ZEDQA rt_tour PASS Stop tour: the file says "0" | 0
ZEDQA rt_tour PASS controller: "pad" in the file asks for the controller's tour | pad
ZEDQA rt_tour SKIP controller: the keys take the controller (no controller on this machine)
ZEDQA rt_tour PASS controller: the tour runs, on the belt | 1
ZEDQA rt_tour PASS controller: a step with no controller words keeps the mouse's
ZEDQA rt_tour PASS controller: A goes on to the Character window | Char
ZEDQA rt_tour PASS controller: the Character window step shows the controller's words
ZEDQA rt_tour PASS controller: B stops the tour
ZEDQA rt_tour PASS controller: the file says "0" | 0
ZEDQA rt_tour put back: tour stopped, windows open as found, the file's word nil
ZEDQA rt_tour end: 187 pass, 0 fail, 1 skipped
ZEDQA rt_tour VERDICT PASS 187
ZEDQA rt_tour DONE
```

### 15. rt_system.lua (`ZEDQA rt_sys`) - PASS, 158 s

- go 30382 at 15:17:27

```text
[ZeD.QA] state #15 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_sys start (170 steps)
[ZeD.QA] run #15 ok=true
ZEDQA rt_sys PASS ZeD's settings, safe mode, main menu and scale modules are loaded
ZEDQA rt_sys PASS a changed setting is written to ModOptions.ini | file 2, want 2
ZEDQA rt_sys PASS the saved setting comes back when the game reads ModOptions.ini | value 2
ZEDQA rt_sys PASS the setting is put back, in memory and in the file | value 1, file 1
ZEDQA rt_sys PASS ModOptions.ini is back line for line | 65 lines, 65 before
ZEDQA rt_sys PASS the pause menu opens (ZeD's pause window)
ZEDQA rt_sys PASS Options opens from the pause menu (ZeD's window)
ZEDQA rt_sys PASS every Options group's page was opened | 9 of 9
ZEDQA rt_sys PASS ZeD setup opens with its groups and rows | 8 groups, 82 rows
ZEDQA rt_sys PASS Options, ZeD setup: the page opens, the window on screen | 82 rows
ZEDQA rt_sys PASS Options, Display: the page opens, the window on screen | 7 rows
ZEDQA rt_sys PASS Options, Graphics: the page opens, the window on screen | 30 rows
ZEDQA rt_sys PASS Options, Audio: the page opens, the window on screen | 19 rows
ZEDQA rt_sys PASS Options, Controls: the page opens, the window on screen | 118 rows
ZEDQA rt_sys PASS Options, Gameplay: the page opens, the window on screen | 35 rows
ZEDQA rt_sys PASS Options, Interface: the page opens, the window on screen | 29 rows
ZEDQA rt_sys PASS Options, Accessibility: the page opens, the window on screen | 8 rows
ZEDQA rt_sys PASS Options, Mods: the page opens, the window on screen | 65 rows
ZEDQA rt_sys PASS Options has ZeD setup
ZEDQA rt_sys PASS the Options pages drew with no Lua error | 0 new
ZEDQA rt_sys PASS Back leaves Options for the pause menu | pause
ZEDQA rt_sys PASS the pause menu shuts again
ZEDQA rt_sys PASS the Select wheel's ZeD setup row: the pause screen, then Options on its first page | view options, page 1, pause up true
ZEDQA rt_sys PASS on screen (ZeD setup from the Select wheel): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_sys PASS the pause menu shuts after the wheel's ZeD setup
ZEDQA rt_sys PASS Options: the game's Inventory font row is marked moot and takes no change | UI_ZeD_Options_MootInventoryFont, item 1 -> 1
ZEDQA rt_sys PASS Options: the game's Dyslexic font row says where it still works | UI_ZeD_Options_OnlyDyslexic
ZEDQA rt_sys PASS ZeD setup: the game settings it mirrors (Font size first) work the game's own control | 6 rows
ZEDQA rt_sys PASS Options, Find "scale": only the matching rows, UI scale among them | 1 of 344 rows, UI scale true
ZEDQA rt_sys PASS Options, Find cleared: ZeD setup's rows come back | 72 rows, 72 before
ZEDQA rt_sys PASS ZeD setup: every group has its heading and a named row for each of its options | 7 groups, 56 rows
ZEDQA rt_sys PASS ZeD setup: with Wheel toggle mode On, Wheel open and Wheel commit are dimmed and take no change | toggle true, open 1, commit 1
ZEDQA rt_sys PASS ZeD setup: with Toggle mode Off, Wheel open Hold and Wheel commit Stick click are read live | hold, click
ZEDQA rt_sys PASS ZeD setup: each Wheel dead zone step is read live | 9 steps
ZEDQA rt_sys PASS Options: Back with a change pending asks first, and the window stays | changed true, confirm back, view options
ZEDQA rt_sys PASS Options: Discard puts every changed ZeD setup control back on its stored pick |
ZEDQA rt_sys PASS ZeD setup, Additions: picking Vanilla Plus sets every addition to the preset's | preset 2
ZEDQA rt_sys PASS ZeD setup, Additions: one addition changed by hand makes the preset read Custom | preset 4
ZEDQA rt_sys PASS Options: Discard puts the preset and the additions back |
ZEDQA rt_sys PASS ZeD setup: a base theme picked without Apply shows at once (the live preview) | dark, want dark
ZEDQA rt_sys PASS Discard puts back the live preview: the stored base theme is on screen again | light, want light |
ZEDQA rt_sys PASS Restock needs Loadouts: with Loadouts Off its row takes no change, with Loadouts On it does | item 2, Loadouts Off 2, Loadouts On 1
ZEDQA rt_sys PASS Options: Discard puts Loadouts and Restock back |
ZEDQA rt_sys PASS ZeD setup, Defaults: every ZeD option's control is on the item it starts on | 53 rows
ZEDQA rt_sys PASS ZeD setup, Defaults: afterwards nothing is off its default (the button greys out)
ZEDQA rt_sys PASS Options: Discard after Defaults puts every control and the look back | | light / teal
ZEDQA rt_sys PASS Back leaves Options with nothing pending | pause
ZEDQA rt_sys PASS after ZeD setup's controls the scale is the run's own | root 1.75
ZEDQA rt_sys PASS on screen (the windows after ZeD setup's controls): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale UI_ZeD_Settings_ScaleAuto: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS on screen (UI scale UI_ZeD_Settings_ScaleAuto): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys SKIP UI scale 0.5x drawn at 0.5x (retired in the beta: ZeD setup's slider dims it and the wheel leaves it out)
ZEDQA rt_sys PASS UI scale 0.5x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.5x set by hand: drawn at the floor 0.75x, the saved pick kept | root 0.75, ZeD.T.root 0.75, item 2
ZEDQA rt_sys PASS on screen (UI scale 0.5x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 0.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.75x: drawn at that scale (ZeD.T.root) | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 0.75x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 1x: the theme follows the new scale and both windows are open again | root 1
ZEDQA rt_sys PASS UI scale 1x: drawn at that scale (ZeD.T.root) | root 1, ZeD.T.root 1
ZEDQA rt_sys PASS on screen (UI scale 1x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 1.25x: the theme follows the new scale and both windows are open again | root 1.25
ZEDQA rt_sys PASS UI scale 1.25x: drawn at that scale (ZeD.T.root) | root 1.25, ZeD.T.root 1.25
ZEDQA rt_sys PASS on screen (UI scale 1.25x): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys PASS UI scale 1.5x: the theme follows the new scale and both windows are open again | root 1.5
ZEDQA rt_sys PASS UI scale 1.5x: drawn at that scale (ZeD.T.root) | root 1.5, ZeD.T.root 1.5
ZEDQA rt_sys PASS on screen (UI scale 1.5x): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys PASS UI scale 1.75x: the theme follows the new scale and both windows are open again | root 1.75
ZEDQA rt_sys PASS UI scale 1.75x: drawn at that scale (ZeD.T.root) | root 1.75, ZeD.T.root 1.75
ZEDQA rt_sys PASS on screen (UI scale 1.75x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 2x: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS UI scale 2x: drawn at that scale (ZeD.T.root) | root 2, ZeD.T.root 2
ZEDQA rt_sys PASS on screen (UI scale 2x): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys PASS UI scale cap: every step fits this screen and there is no too-big line | cap 2
ZEDQA rt_sys PASS ZeD text follows the root scale: the body font's zoom is the root times its size at every step | 8 steps, zoom 0.15234375 to 0.40625
ZEDQA rt_sys PASS UI scale put back on the run's own step | option 7, root 1.75
ZEDQA layout rt_sys scale put back
ZEDQA rt_sys PASS on screen (the windows back after the scale steps): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme dark: the window box's Theme pick applies to ZeD's table and is saved as item 1 | dark, option 1
ZEDQA rt_sys PASS theme dark: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme dark: See-through is the player's pick | surfaceAlpha 0.9, want 0.9
ZEDQA rt_sys PASS on screen (theme dark): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme light: the window box's Theme pick applies to ZeD's table and is saved as item 2 | light, option 2
ZEDQA rt_sys PASS theme light: the accent is its light variant | rgb 26 102 85, want rgb 26 102 85
ZEDQA rt_sys PASS theme light: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme light): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme hicon: the window box's Theme pick applies to ZeD's table and is saved as item 3 | hicon, option 3
ZEDQA rt_sys PASS theme hicon: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme hicon: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme hicon): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS accent red: the window box's Accent pick gives its light color and is saved as item 1 | red, rgb 122 26 26, want rgb 122 26 26, option 1
ZEDQA rt_sys PASS accent orange: the window box's Accent pick gives its light color and is saved as item 2 | orange, rgb 122 80 16, want rgb 122 80 16, option 2
ZEDQA rt_sys PASS accent yellow: the window box's Accent pick gives its light color and is saved as item 3 | yellow, rgb 107 95 10, want rgb 107 95 10, option 3
ZEDQA rt_sys PASS accent green: the window box's Accent pick gives its light color and is saved as item 4 | green, rgb 18 85 24, want rgb 18 85 24, option 4
ZEDQA rt_sys PASS accent blue: the window box's Accent pick gives its light color and is saved as item 5 | blue, rgb 26 68 119, want rgb 26 68 119, option 5
ZEDQA rt_sys PASS accent teal: the window box's Accent pick gives its light color and is saved as item 6 | teal, rgb 26 102 85, want rgb 26 102 85, option 6
ZEDQA rt_sys PASS accent purple: the window box's Accent pick gives its light color and is saved as item 7 | purple, rgb 68 24 136, want rgb 68 24 136, option 7
ZEDQA rt_sys PASS accent pink: the window box's Accent pick gives its light color and is saved as item 8 | pink, rgb 136 34 68, want rgb 136 34 68, option 8
ZEDQA rt_sys PASS accent mono: the window box's Accent pick gives its light color and is saved as item 9 | mono, rgb 58 58 58, want rgb 58 58 58, option 9
ZEDQA rt_sys PASS text size small: the window box's Text size pick sets the scale and the sort font, saved as item 1 | scale 1.75, want 1.75, option 1
ZEDQA rt_sys PASS on screen (text size small): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS text size large: the window box's Text size pick sets the scale and the sort font, saved as item 2 | scale 2.0124999999999997, want 2.0124999999999997, option 2
ZEDQA rt_sys PASS on screen (text size large): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS the run's own theme, accent and text size are back | light / teal / small
ZEDQA rt_sys PASS Status colors Color blind: good, warning and bad come from the color blind set | light, rgb 1 78 142, want rgb 1 78 142
ZEDQA rt_sys PASS Status colors Standard: good, warning and bad are the base theme's own | rgb 42 85 17, want rgb 42 85 17
ZEDQA rt_sys PASS split view per-player theme: player 2's pick is in player 2's table only (a stand-in player 2) | dark / light, shared light
ZEDQA rt_sys PASS the Character window's own accent: its window box's pick sets it and saves it | purple, option 7
ZEDQA rt_sys PASS the World window's own accent: its window box's pick sets it and saves it | green, option 4
ZEDQA rt_sys PASS a window's own accent leaves the interface's accent alone | teal
ZEDQA rt_sys PASS the windows' own accents are kept over a close and reopen | purple / green
ZEDQA rt_sys PASS the Character window's "Same as Accent color" follows the interface's accent again | nil, option 10
ZEDQA rt_sys PASS See-through 60: the window box's pick draws the windows at 0.6 in Dark and is saved | surfaceAlpha 0.6
ZEDQA rt_sys PASS one see-through layer per window: the windows and their bands draw at 60 with no guarded fault and no Lua error | 0 faults, 0 new errors
ZEDQA rt_sys PASS on screen (the windows at 60 see-through): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS See-through and the theme put back | 2, light
ZEDQA rt_sys PASS Solid while in use: the window box's row flips it and saves it | true -> false, option 1
ZEDQA rt_sys PASS Solid while in use: a second pick puts it back | true
ZEDQA rt_sys PASS Low-health pixel blink Off: the pixel holds lit | 41 of 41 moments lit
ZEDQA rt_sys PASS Low-health pixel blink On: the pixel blinks | 20 of 41 moments dark
ZEDQA rt_sys PASS Low-health pixel blink put back | true
ZEDQA rt_sys PASS Item-colored grid tiles: the switch is read back at once | true
ZEDQA rt_sys PASS Item-colored grid tiles put back | false
ZEDQA rt_sys PASS Item-colored grid tiles: the item colors are loaded (Acorn) | 8806442
ZEDQA rt_sys PASS Controller highlight hand: the window box's pick is read and saved | hand, option 1
ZEDQA rt_sys PASS Controller highlight corners: the window box's pick is read and saved | corners, option 2
ZEDQA rt_sys PASS Controller highlight wash: the window box's pick is read and saved | wash, option 3
ZEDQA rt_sys PASS Controller highlight ants: the window box's pick is read and saved | ants, option 4
ZEDQA rt_sys PASS the controller highlights drew with no Lua error | 0 new
ZEDQA rt_sys PASS Controller highlight put back | hand
ZEDQA rt_sys PASS Lite or Full forms: each form's getter follows Style at once (belt, devices, watch, guide, mods, identity; the dash has no plain form) | 6 forms
ZEDQA rt_sys PASS UI sounds: Off plays no click, Full plays it (a sound id) | Off nil, Full 146411008
ZEDQA rt_sys PASS Button glyph set: item 3 reads the PlayStation set, item 1 Auto | ps / auto
ZEDQA rt_sys PASS Test language On: within half a second a ZeD phrase reads stretched, in brackets | 258 ms, 15 letters, plain 9
ZEDQA rt_sys PASS Test language Off: the phrase is plain again | Safe mode
ZEDQA rt_sys PASS the inventory key: the Character and World windows close together and open together, the game's page hidden | open true, shut true, game's page false, open again true
ZEDQA rt_sys safe mode baseline: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode: ZeD runs to start with (its windows, its hotbar)
ZEDQA rt_sys tripped: on true | pair shut true | game's inventory true | hotbar vanilla | moodle layer false
ZEDQA rt_sys PASS a trip: ZeD's windows shut
ZEDQA rt_sys PASS a trip: the game's own inventory page, hotbar and moodles come back
ZEDQA rt_sys PASS a trip: the note shows (the game's own dialog) and closes
ZEDQA rt_sys PASS tripped, the inventory key works the game's own page (hides, shows) | true -> false -> true
ZEDQA rt_sys reset: on false | pair shut true | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS a reset brings ZeD back and hides the game's page
ZEDQA rt_sys PASS trip recovery by hand: ZeD.Safe.reset() clears the trip and the switch reads Off | tripped false
ZEDQA rt_sys PASS after the reset ZeD's windows open again
ZEDQA rt_sys PASS on screen (the windows after a safe mode reset): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS the Safe mode option On is picked up by itself within a second | 243 ms
ZEDQA rt_sys PASS Safe mode On: the game's own pages, no trip note
ZEDQA rt_sys PASS never caught in safe mode: with safe mode On, Messages keeps no other mod's note
ZEDQA rt_sys PASS the Safe mode option Off is picked up by itself within a second | 479 ms
ZEDQA rt_sys PASS Safe mode Off: ZeD back
ZEDQA rt_sys PASS Safe mode recovery: switched Off, nothing of the game's own is left applied | applied false
ZEDQA rt_sys PASS with safe mode Off the same note would be kept again (the control)
ZEDQA rt_sys PASS Safe mode recovery: the ZeD Character and World windows open again
ZEDQA rt_sys PASS the watchdog: a five-frame burst of faults leaves ZeD on
ZEDQA rt_sys PASS the watchdog: under two seconds of faults ZeD stays on | 2022 ms, 122 frames
ZEDQA rt_sys PASS the watchdog: two seconds of faults every frame trip it | 2022 ms
ZEDQA rt_sys PASS the watchdog's note shows and closes
ZEDQA rt_sys safe mode put back: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode put back: the option as it was, ZeD running
ZEDQA rt_sys PASS Safe mode from the Select wheel asks first (Yes and No), and nothing is on yet | question true, safe mode false
ZEDQA rt_sys PASS Safe mode asks first: No leaves safe mode off and the option as it was | safe mode false, option 1
ZEDQA rt_sys PASS one screen handed back: the belt's switch On gives the belt alone to the game | belt true, all false, hook true
ZEDQA rt_sys PASS one screen handed back: the belt's switch Off makes the belt ZeD's again | hook false
ZEDQA rt_sys SKIP step-aside (no active mod replaces a ZeD screen in this game)
ZEDQA rt_sys PASS step-aside: a supported mod (AutoHideHotbar and the rest) is never detected | none detected
ZEDQA rt_sys PASS another mod's note is kept in Messages, not shown over the game
ZEDQA rt_sys PASS Messages keeps the note, new, under the mod's name | 1
ZEDQA rt_sys PASS the Messages window opens on the mod
ZEDQA rt_sys PASS the window shows the note's card with its OK | 1
ZEDQA rt_sys PASS on screen (the Messages window): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS OK in Messages runs the mod's own callback once | 1 calls
ZEDQA rt_sys PASS put back: the test mod's messages are cleared
ZEDQA rt_sys PASS Messages, balloons On: a new message shows its balloon | 1 balloons
ZEDQA rt_sys PASS Messages: the balloon goes after six seconds | 6022 ms
ZEDQA rt_sys PASS Messages, balloons Off: a new message shows no balloon | 0 balloons
ZEDQA rt_sys PASS put back: the balloon test's messages and the switch
ZEDQA rt_sys PASS Bug report: the count it returns is the caught errors' | 0, want 0
ZEDQA rt_sys PASS Bug report: the clipboard holds the report (it starts "ZeD-GUI ") | ZeD-GUI 0.3.0-beta21 | Project Zomboid 4
ZEDQA rt_sys PASS put back: the clipboard as it was | 9 characters, 9 before
ZEDQA rt_sys PASS on screen (the Messages window with its foot band): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS Messages foot band: Pop-ups on saves the mod in ZeD_messages.txt, pressed again it is off | on true, in the file true, after false
ZEDQA rt_sys PASS Messages foot band: Mark all read leaves nothing unread | 1 -> 0
ZEDQA rt_sys PASS Messages foot band: Delete asks first and deletes nothing yet | asking true
ZEDQA rt_sys PASS Messages foot band: Yes to the question deletes the mod's messages | Yes button true
ZEDQA rt_sys PASS put back: every message's read mark, ZeD_messages.txt and the balloon switch | 0 marks off, 1 lines, 1 before
ZEDQA rt_sys soak start: 1855488 KB, 0 Lua errors so far
ZEDQA rt_sys PASS the soak ran its two minutes | 120 s
ZEDQA rt_sys PASS the soak: no Lua error in two minutes with the windows open | 0 new
ZEDQA rt_sys PASS the soak: Lua memory grows by no more than 262144 KB | 1855488 KB -> 1859584 KB (4096 KB)
ZEDQA rt_sys PASS on screen (the windows after the soak): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS every key in ZeD's English UI.json has text in the game | 6949 keys
ZEDQA rt_sys PASS every ZeD key read while the script ran has text | 430 keys
ZEDQA rt_sys PASS every game key ZeD borrowed while the script ran has text | 53 keys
ZEDQA rt_sys PASS sandbox tags: each setting's WHEN and RISK is one the window knows (DayLength now) | |
ZEDQA rt_sys PASS sandbox tags: a "fix" setting's row is locked, a "now" one is not | true / false
ZEDQA rt_sys PASS capitals: the sharp s stays one letter and an accented letter takes its capital | 6 letters
ZEDQA rt_sys PASS pixel fonts: the 3x5 and 5x7 faces have their signs, accented capitals and Cyrillic (the extra file merged)
ZEDQA rt_sys PASS Sandbox options line on the pause window: shown with its switch On, gone Off | true / false
ZEDQA rt_sys PASS Read marks: a skill book's mark follows the pages read (unread, part, read), none with the switch Off | 0:u 110:p 220:r
ZEDQA rt_sys PASS put back: the character's pages read and the read marks switch | 0 pages, 0 before
ZEDQA rt_sys PASS Chord setup: a chord given a path reads it back, saved, off its default | zedqa:1, saved zedqa:1, default false
ZEDQA rt_sys PASS Chord setup: a reset chord is its default again | now:3, want now:3
ZEDQA rt_sys PASS put back: the chord and ZeD_chords.txt as found | now:3, was now:3
ZEDQA layout rt_sys put back
ZEDQA rt_sys PASS put back: ZeD.tr is ZeD's own again
ZEDQA rt_sys PASS put back: every setting this script changed is as it was
ZEDQA rt_sys PASS put back: every ZeD option's value, the accent, the text size and the see-through as found |
ZEDQA rt_sys PASS put back: ModOptions.ini is as found, line for line | 65 lines, 65 before
ZEDQA rt_sys end: 202 pass, 0 fail, 2 skipped
ZEDQA rt_sys VERDICT PASS 202
ZEDQA rt_sys DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
