# ZeD-UI regression - 2026-11-18 12:02 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 12:02:51 |
| Finished | 2026-11-18 12:09:22 (6 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_test.txt (12 scripts) |
| Result | **11/12 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 29544 to 29557 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29556, 29557)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 6 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_windows.lua | rt_win | PASS | 20 |  |  |
| 4 | rt_inventory.lua | rt_inv | PASS | 8 |  |  |
| 5 | rt_menus.lua | rt_menu | **FAIL** | 5 |  | 2 ERR line(s); its own checks failed (VERDICT FAIL) |
| 6 | rt_cards.lua | rt_cards | PASS | 11 |  |  |
| 7 | rt_hud.lua | rt_hud | PASS | 25 |  |  |
| 8 | rt_pad.lua | rt_pad | PASS | 14 |  |  |
| 9 | rt_media.lua | rt_media | PASS | 15 |  |  |
| 10 | rt_vehicles.lua | rt_veh | PASS | 16 |  |  |
| 11 | rt_addon.lua | rt_addon | PASS | 2 |  |  |
| 12 | rt_system.lua | rt_sys | PASS | 143 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 6 s

- go 29544 at 12:03:55

```text
[ZeD.QA] state #1 speed=1 paused=false player=917,13027 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 917,13027,0 to the drag strip
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 29545 at 12:04:05

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_windows.lua (`ZEDQA rt_win`) - PASS, 20 s

- go 29546 at 12:04:09

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_win start (149 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_win screen 3840x2160, half card 385 / 455 px, full card 840 px, pair open true
ZEDQA rt_win PASS mouse: the inventory key's action closes both windows | Character false, World false
ZEDQA rt_win PASS mouse: the inventory key's action opens both windows | Character true, World true
ZEDQA rt_win PASS on screen (both windows open): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS mouse: the inventory key's action closes both windows again | Character false, World false
ZEDQA rt_win PASS Character window: its strip offers its tabs | loot, equip, health, thermal, identity, journal, skills
ZEDQA rt_win PASS Character tab loot: pressed on the strip, it is the active tab | active loot
ZEDQA rt_win PASS Character tab loot: no drawer, or the half or the full card | 0 px = closed
ZEDQA rt_win PASS Character tab loot: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab loot: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab loot): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab equip: pressed on the strip, it is the active tab | active equip
ZEDQA rt_win PASS Character tab equip: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab equip: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab equip: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab equip): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab health: pressed on the strip, it is the active tab | active health
ZEDQA rt_win PASS Character tab health: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab health: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab health: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab health): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab thermal: pressed on the strip, it is the active tab | active thermal
ZEDQA rt_win PASS Character tab thermal: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab thermal: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab thermal: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab thermal): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab identity: pressed on the strip, it is the active tab | active identity
ZEDQA rt_win PASS Character tab identity: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab identity: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab identity: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab identity): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab journal: pressed on the strip, it is the active tab | active journal
ZEDQA rt_win PASS Character tab journal: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab journal: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab journal: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab journal): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character tab skills: pressed on the strip, it is the active tab | active skills
ZEDQA rt_win PASS Character tab skills: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS Character tab skills: the other window did not move or change size | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character tab skills: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (Character tab skills): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World window: its strip offers its tabs | loot, craft, build, furniture, maps, forage, animals
ZEDQA rt_win PASS World tab loot: pressed on the strip, it is the active tab | active loot
ZEDQA rt_win PASS World tab loot: no drawer, or the half or the full card | 0 px = closed
ZEDQA rt_win PASS World tab loot: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab loot: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab loot): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab craft: pressed on the strip, it is the active tab | active craft
ZEDQA rt_win PASS World tab craft: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab craft: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab craft: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab craft): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab build: pressed on the strip, it is the active tab | active build
ZEDQA rt_win PASS World tab build: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab build: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab build: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab build): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab furniture: pressed on the strip, it is the active tab | active furniture
ZEDQA rt_win PASS World tab furniture: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab furniture: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab furniture: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab furniture): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab maps: pressed on the strip, it is the active tab | active maps
ZEDQA rt_win PASS World tab maps: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab maps: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab maps: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab maps): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab forage: pressed on the strip, it is the active tab | active forage
ZEDQA rt_win PASS World tab forage: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab forage: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab forage: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab forage): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS World tab animals: pressed on the strip, it is the active tab | active animals
ZEDQA rt_win PASS World tab animals: its drawer is the half card or the full card, nothing between | 840 px = full
ZEDQA rt_win PASS World tab animals: the other window did not move or change size | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World tab animals: it opened and drew with no Lua error | errors 0 -> 0
ZEDQA rt_win PASS on screen (World tab animals): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS Character curtain: the side rolls up under its rod (on skills) | rolled true, rod true
ZEDQA rt_win PASS Character curtain: rolled, the window is its box less the side | 294,0 1617x735 less 714 -> 294,0 903x735
ZEDQA rt_win PASS on screen (Character curtain rolled): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS Character curtain: the rod's tab rolls the side back down | rolled false
ZEDQA rt_win PASS Character curtain: unrolled, the window is back in the same box to the pixel | 294,0 1617x735 -> 294,0 1617x735
ZEDQA rt_win PASS Character curtain: the rod is gone from the screen
ZEDQA rt_win PASS Character curtain: the other window never moved | 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win PASS Character curtain: no Lua error through the roll | 0 -> 0
ZEDQA rt_win PASS World curtain: the side rolls up under its rod (on maps) | rolled true, rod true
ZEDQA rt_win PASS World curtain: rolled, the window is its box less the side | 1929,0 1617x735 less 714 -> 2643,0 903x735
ZEDQA rt_win PASS on screen (World curtain rolled): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_win PASS World curtain: the rod's tab rolls the side back down | rolled false
ZEDQA rt_win PASS World curtain: unrolled, the window is back in the same box to the pixel | 1929,0 1617x735 -> 1929,0 1617x735
ZEDQA rt_win PASS World curtain: the rod is gone from the screen
ZEDQA rt_win PASS World curtain: the other window never moved | 1134,0 777x735 -> 1134,0 777x735
ZEDQA rt_win PASS World curtain: no Lua error through the roll | 0 -> 0
ZEDQA rt_win PASS pad: before Y, both windows are closed
ZEDQA rt_win PASS pad: a tap of Y opens both windows | Character true, World true
ZEDQA rt_win PASS on screen (opened by the pad): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_win PASS pad: a second tap of Y rolls both windows up (hidden)
ZEDQA rt_win PASS pad: a third tap of Y brings both windows back
ZEDQA rt_win PASS pad: holding Y closes both windows | Character false, World false
ZEDQA layout rt_win put back
ZEDQA rt_win PASS put back: both windows are where and as big as they were | Character 1134,0 777x735 -> 1134,0 777x735, World 1929,0 777x735 -> 1929,0 777x735
ZEDQA rt_win end: 99 pass, 0 fail, 0 skipped
ZEDQA rt_win VERDICT PASS 99
ZEDQA rt_win DONE
```

### 4. rt_inventory.lua (`ZEDQA rt_inv`) - PASS, 8 s

- go 29547 at 12:04:33

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_inv start (62 steps)
[ZeD.QA] run #4 ok=true
ZEDQA rt_inv PASS both windows are open
ZEDQA rt_inv PASS the Character window lists the character's inventory | ItemContainer:[type:none, parent:IsoPlayer{ Name:null, ID:57 }]
ZEDQA rt_inv PASS a crate stands beside the character | ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@380e57d9]
ZEDQA rt_inv PASS the things for the test were made | crate 10 of 10, mover Base.Pan
ZEDQA rt_inv PASS the World window shows the crate (selectContainer) | Crate
ZEDQA rt_inv PASS Sort by name rising from the heading puts the bag's rows in that order | sort name true; 30 rows in order
ZEDQA rt_inv PASS Sort by name rising from the heading puts the crate's rows in that order | sort name true; 6 rows in order
ZEDQA rt_inv PASS Sort by name falling from the heading puts the bag's rows in that order | sort name false; 30 rows in order
ZEDQA rt_inv PASS Sort by name falling from the heading puts the crate's rows in that order | sort name false; 6 rows in order
ZEDQA rt_inv PASS Sort by cat rising from the heading puts the bag's rows in that order | sort cat true; 30 rows in order
ZEDQA rt_inv PASS Sort by cat rising from the heading puts the crate's rows in that order | sort cat true; 6 rows in order
ZEDQA rt_inv PASS Sort by cat falling from the heading puts the bag's rows in that order | sort cat false; 30 rows in order
ZEDQA rt_inv PASS Sort by cat falling from the heading puts the crate's rows in that order | sort cat false; 6 rows in order
ZEDQA rt_inv PASS Sort by cond rising from the heading puts the bag's rows in that order | sort cond true; 30 rows in order
ZEDQA rt_inv PASS Sort by cond rising from the heading puts the crate's rows in that order | sort cond true; 6 rows in order
ZEDQA rt_inv PASS Sort by cond falling from the heading puts the bag's rows in that order | sort cond false; 30 rows in order
ZEDQA rt_inv PASS Sort by cond falling from the heading puts the crate's rows in that order | sort cond false; 6 rows in order
ZEDQA rt_inv PASS Sort by wt rising from the heading puts the bag's rows in that order | sort wt true; 30 rows in order
ZEDQA rt_inv PASS Sort by wt rising from the heading puts the crate's rows in that order | sort wt true; 6 rows in order
ZEDQA rt_inv PASS Sort by wt falling from the heading puts the bag's rows in that order | sort wt false; 30 rows in order
ZEDQA rt_inv PASS Sort by wt falling from the heading puts the crate's rows in that order | sort wt false; 6 rows in order
ZEDQA rt_inv PASS the list draws every thing in the bag | 30 rows, 50 of 50 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the list draws every thing in the crate | 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the bag to the grid, and the grid draws every thing | button true, 30 rows, 50 of 50 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the crate to the grid, and the grid draws every thing | button true, 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the bag back to the list | 30 rows, 50 of 50 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS the view button turns the crate back to the list | 6 rows, 10 of 10 things drawn, 0 rows with no place, 0 extra
ZEDQA rt_inv PASS on screen (the inventory lists): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_inv PASS the crate's heading has the Filter button
ZEDQA rt_inv PASS the Filter button opens the bar
ZEDQA rt_inv PASS the filter "plank" marks the rows whose name holds it and dims the rest | 1 match, 5 dim
ZEDQA rt_inv PASS on screen (the filter bar open): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_inv PASS Clear shows every row again | button true, text ""
ZEDQA rt_inv PASS the Filter button puts the bar away | false
ZEDQA rt_inv PASS the stack's row (three cans) shows its total weight in brackets (2.4) | row true; drew: Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4)
ZEDQA rt_inv PASS the stack's triangle opens it: a row for each of the three cans | triangle true, header true, rows 3
ZEDQA rt_inv PASS the open stack's header keeps the total (2.4) | drew: Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4) | Canned Be... (3) | Food | (2.4)
ZEDQA rt_inv PASS a press on the open stack's header shuts it
ZEDQA rt_inv PASS a press on the list's empty space starts a box
ZEDQA rt_inv PASS the box drawn up over the rows selects every row it crosses | 6 of 6
ZEDQA rt_inv PASS the pan's row drags from the bag and drops on the crate's list | dropped
ZEDQA rt_inv PASS dragged into the crate: the pan is in the crate once the transfer is done, and the counts agree | in the crate true, in the bag false; bag 57 (was 58), crate 11 (was 10)
ZEDQA rt_inv PASS the pan's row drags from the crate and drops on the bag's list | dropped
ZEDQA rt_inv PASS dragged back into the bag: the pan is in the bag and the counts agree | in the crate false, in the bag true; bag 58 (was 57), crate 10 (was 11)
ZEDQA rt_inv PASS the pan's row in the bag takes a right-click
ZEDQA rt_inv PASS the right-click opens ZeD's menu on the pan
ZEDQA rt_inv PASS the menu's Move To lists the crate (Crate) and runs it | picked
ZEDQA rt_inv PASS Move To the crate: the pan is in the crate and the counts agree | in the crate true, in the bag false; bag 57 (was 58), crate 11 (was 10)
ZEDQA rt_inv PASS the pan's row in the crate takes a right-click
ZEDQA rt_inv PASS the right-click opens ZeD's menu on the pan in the crate
ZEDQA rt_inv PASS the menu's Move To lists Inventory and runs it | picked
ZEDQA rt_inv PASS Move To the inventory: the pan is back in the bag and the counts agree | in the crate false, in the bag true; bag 58 (was 57), crate 10 (was 11)
ZEDQA rt_inv PASS the crate's Loot all button presses | Take all
ZEDQA rt_inv PASS Loot all takes everything from the crate into the bag (all the bag has room for) | 10 of 10 in the bag, 0 too heavy for it
ZEDQA rt_inv PASS the bag's Transfer all button presses | Transfer all
ZEDQA rt_inv PASS Transfer all moves every thing it should into the crate (all the crate has room for) | 59 moved, 0 too big for what room was left
ZEDQA rt_inv the bag's own things put back: 48
ZEDQA rt_inv PASS the crate's To floor button presses | To floor
ZEDQA rt_inv PASS To floor puts every thing in the crate on the floor | 10 of 10 on the floor, 0 left in the crate
ZEDQA rt_inv PASS the bag holds all its own things again | 57 of 57
ZEDQA rt_inv end: 59 pass, 0 fail, 0 skipped
ZEDQA rt_inv VERDICT PASS 59
ZEDQA rt_inv DONE
```

### 5. rt_menus.lua (`ZEDQA rt_menu`) - FAIL, 5 s

- go 29548 at 12:04:44
- 2 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_menu start (23 steps)
[ZeD.QA] run #5 ok=true
ZEDQA rt_menu PASS ZeD's Context menu setting is there
ZEDQA rt_menu PASS the Character window is open
ZEDQA rt_menu PASS two tools of kinds the bag does not hold were given | 2 given
ZEDQA rt_menu PASS the strip test: the tool's row in the bag takes a right-click | Crowbar
ZEDQA rt_menu PASS the right-click opens ZeD's strip (ZeD_ContextMenu) on the tool | menu ZeD_ContextMenu, on the tool true
ZEDQA rt_menu FAIL the strip: every row and submenu row has its icon | 19 rows; no icon: Back
ZEDQA rt_menu PASS on screen (the strip open): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_menu PASS the strip: Move to opens its submenu | 1 rows under it; top: Attach, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip in Both Hands, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the strip with its submenu): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_menu PASS the strip: back out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the strip: Equip Primary is picked | picked
ZEDQA rt_menu PASS the strip's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Crowbar, menu false
ZEDQA rt_menu PASS the list test: the tool's row in the bag takes a right-click | Screwdriver
ZEDQA rt_menu PASS the right-click opens ZeD's list (ZeD_ContextList) on the tool | menu ZeD_ContextList, on the tool true
ZEDQA rt_menu PASS the list: every row and submenu row has its icon | 20 rows
ZEDQA rt_menu PASS on screen (the list open): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_menu PASS the list's box is on screen | 1 levels inside 3840x2160
ZEDQA rt_menu PASS the list: Move to opens its submenu | 1 rows under it; top: Attach, Dismantle Simple Electronic Item, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the list with its submenu): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_menu PASS the list and its submenu are on screen | 2 levels inside 3840x2160
ZEDQA rt_menu PASS the list: back out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the list: Equip Primary is picked | picked
ZEDQA rt_menu PASS the list's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Screwdriver, menu false
ZEDQA rt_menu PASS the Context menu setting is back as it was | 2
ZEDQA rt_menu PASS the hands hold what they held
ZEDQA rt_menu end: 24 pass, 1 fail, 0 skipped
ZEDQA rt_menu VERDICT FAIL 1
ZEDQA rt_menu DONE
```

### 6. rt_cards.lua (`ZEDQA rt_cards`) - PASS, 11 s

- go 29549 at 12:04:53

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_cards start (82 steps)
[ZeD.QA] run #6 ok=true
ZEDQA rt_cards PASS an apple, a bat, a book and a pencil are given | Apple, Baseball Bat, Book: "The Opening Argument", by Scot Oakes, Pencil
ZEDQA rt_cards PASS the Character window's list shows the main inventory | none
ZEDQA rt_cards PASS pad: the focus lands on the apple's row (FocusManager, charMainInv)
ZEDQA rt_cards PASS pad: A on the apple's row opens its card | Apple
ZEDQA rt_cards PASS pad: the card is half or full wide | 385
ZEDQA rt_cards PASS on screen (the apple's item card (pad)): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS eat: the card shows EAT and the pad's focus lands on it | EAT MORE
ZEDQA rt_cards PASS eat: A held on Eat queues the game's own eat (ISEatFoodAction) | ISEatFoodAction
ZEDQA rt_cards PASS mouse: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS mouse: a click on the bat's row opens its card | Baseball Bat
ZEDQA rt_cards PASS mouse: the card is half (220 / 260) or full (480) wide | 385
ZEDQA rt_cards PASS facts: the card shows the bat's weight | 2.0 kg (want 2.0 kg)
ZEDQA rt_cards PASS facts: the card's facts show the bat's condition | 15 / 15 (want 15 / 15)
ZEDQA rt_cards PASS on screen (the bat's item card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS read: its row is in the Character window's list | Book: "The Opening Argument", by Scot Oakes
ZEDQA rt_cards PASS read: a click on the book's row opens its card | Book: "The Opening Argument", by Scot Oakes
ZEDQA rt_cards PASS read: the card shows READ and the pad's focus lands on it | READ MORE
ZEDQA rt_cards PASS read: Read queues the game's own read (ISReadABook) | ISReadABook
ZEDQA rt_cards PASS equip: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS equip: the bat's card opens again | Baseball Bat
ZEDQA rt_cards PASS equip: the card shows EQUIP and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS equip: Equip puts the bat in the hand (the game's equip action) | Baseball Bat
ZEDQA rt_cards PASS equip: the card now reads the bat as equipped | equipped
ZEDQA rt_cards PASS drop: its row is in the Character window's list | Pencil
ZEDQA rt_cards PASS drop: a click on the pencil's row opens its card | Pencil
ZEDQA rt_cards PASS drop: the card shows MORE and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS drop: MORE opens the pencil's whole context menu | true
ZEDQA rt_cards PASS drop: the menu has the game's Drop and it can be picked | picked
ZEDQA rt_cards PASS drop: Drop puts the pencil on the ground (the game's drop action) | world item true, container nil
ZEDQA rt_cards PASS generator: placed beside the character
ZEDQA rt_cards PASS generator: ZeD's hook is on the game's Info
ZEDQA rt_cards PASS generator: the game's Info opens ZeD's generator card on it | generator
ZEDQA rt_cards PASS generator: the card is the full card (480) | 840
ZEDQA rt_cards PASS generator: the card reads its fuel and condition | 10 / 90 (want 10 / 90)
ZEDQA rt_cards PASS generator: the card says it is off | Off
ZEDQA rt_cards PASS on screen (the generator card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS fire: a campfire made beside the character (the game's campfire system)
ZEDQA rt_cards PASS fire: ZeD's hook is on the campfire's Info
ZEDQA rt_cards PASS fire: the campfire is in the world
ZEDQA rt_cards PASS fire: the campfire's Info opens ZeD's fire card | fire campfire
ZEDQA rt_cards PASS fire: a new campfire reads no fuel and not lit | 0 false
ZEDQA rt_cards PASS fire: the card says Out | Out
ZEDQA rt_cards PASS on screen (the fire card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS laundry: a washer placed beside the character | appliances_laundry_01_4
ZEDQA rt_cards PASS laundry: the washer is in the World window's container list
ZEDQA rt_cards PASS laundry: the washer's container row has ZeD's gears button | take same floor obj:ZeDLaundry
ZEDQA rt_cards PASS laundry: the gears button opens ZeD's laundry card on the washer | laundry
ZEDQA rt_cards PASS laundry: the card says it is off | Off
ZEDQA rt_cards PASS laundry: the card reads the power as the game has it | false vs false
ZEDQA rt_cards PASS on screen (the laundry card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS fridge: a fridge placed beside the character, milk inside | true
ZEDQA rt_cards PASS fridge: the World window lists the fridge by name | Fridge
ZEDQA rt_cards PASS fridge: it opens in the Loot pane
ZEDQA rt_cards PASS fridge: the pane lists what is inside (the milk) | 7
ZEDQA rt_cards PASS on screen (the fridge in the Loot pane): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS stove: a range placed beside the character
ZEDQA rt_cards PASS stove: ZeD's hook is on the game's stove settings
ZEDQA rt_cards PASS stove: the game's stove settings open ZeD's stove (its face popped out, or the Craft tab on it) | face true, station nil
ZEDQA rt_cards PASS stove: its state reads as the game has it (power, switch) | No power (want No power)
ZEDQA rt_cards PASS on screen (the stove): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS station: a Primitive Kiln built beside the character (a craft bench) | 1 objects
ZEDQA rt_cards PASS station: the game's station option binds the kiln in the World window's Craft tab | Primitive Kiln
ZEDQA rt_cards PASS station: the kiln reads in use by you | In use by you
ZEDQA rt_cards PASS station: the kiln holds the game's one-player lock for you
ZEDQA rt_cards PASS on screen (the kiln in the Craft tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards SKIP a mod's general station card (StationGeneral.lua) (no mod station is installed on the release-test save)
ZEDQA rt_cards PASS put back: the things given are taken back | 0 left
ZEDQA rt_cards PASS put back: the campfire is gone
ZEDQA rt_cards PASS put back: everything placed or built is taken away | 0 left
ZEDQA rt_cards end: 68 pass, 0 fail, 1 skipped
ZEDQA rt_cards VERDICT PASS 68
ZEDQA rt_cards DONE
```

### 7. rt_hud.lua (`ZEDQA rt_hud`) - PASS, 25 s

- go 29550 at 12:05:07

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_hud start (49 steps)
[ZeD.QA] run #7 ok=true
ZEDQA rt_hud PASS safe mode is off, so ZeD draws the HUD
ZEDQA rt_hud PASS every HUD module is loaded
ZEDQA rt_hud PASS belt: drawn
ZEDQA rt_hud PASS belt: at the bottom of the screen | 1535,2034 662x98
ZEDQA rt_hud PASS belt: the game's hotbar is parked off screen (Overrides/Belt.lua)
ZEDQA rt_hud PASS hands: two circles, the main hand the bigger | 98 and 77
ZEDQA rt_hud PASS hands: the off hand left of the main hand (seen from behind)
ZEDQA rt_hud PASS on screen (belt): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS hands: one item in both hands slides the off hand under the main hand
ZEDQA rt_hud PASS hands: one hand free again, the off hand back beside the main hand
ZEDQA rt_hud PASS watch: the worn watch is on the belt | Base.WristWatch_Left_DigitalBlack
ZEDQA rt_hud PASS watch: the mini sits beside its own hand (left wrist)
ZEDQA rt_hud PASS watch: the full watch is tucked away while the mini shows
ZEDQA rt_hud PASS watch: the middle of the mini is its face | face
ZEDQA rt_hud PASS watch: the face opens the full watch | 248x352
ZEDQA rt_hud PASS watch: the full watch stands above the mini on the belt | 2023 over 2037
ZEDQA rt_hud PASS on screen (full watch): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS watch: a second press tucks it back
ZEDQA rt_hud PASS action bar: a bag to pack
ZEDQA rt_hud PASS action bar: the game's timed action is drawn
ZEDQA rt_hud PASS action bar: it names the action | MOVING PENCIL
ZEDQA rt_hud PASS action bar: its layer shows
ZEDQA rt_hud PASS on screen (action bar): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS action bar: the bar follows the action | 0.00 to 0.10
ZEDQA rt_hud PASS action bar: the job ends with Done drawn from it
ZEDQA rt_hud PASS action bar: the Done fades and the bar clears
ZEDQA rt_hud PASS action bar: the action did its work (4 in the bag)
ZEDQA rt_hud PASS right: the moodles are placed right | right
ZEDQA rt_hud PASS right: at least three moodles are on | 4
ZEDQA rt_hud PASS right: every moodle is on screen | 3782,969 48x222
ZEDQA rt_hud PASS right: the column is at the right edge | 3782
ZEDQA rt_hud PASS on screen (moodles right): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS left: the moodles are placed left | left
ZEDQA rt_hud PASS left: at least three moodles are on | 4
ZEDQA rt_hud PASS left: every moodle is on screen | 10,969 48x222
ZEDQA rt_hud PASS left: the column is at the left edge | 10
ZEDQA rt_hud PASS on screen (moodles left): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bottom: the moodles are placed bottom | bottom
ZEDQA rt_hud PASS bottom: at least three moodles are on | 4
ZEDQA rt_hud PASS bottom: every moodle is on screen | 1809,1965 222x48
ZEDQA rt_hud PASS bottom: the row is centred
ZEDQA rt_hud PASS bottom: the row sits above the belt
ZEDQA rt_hud PASS bottom: the game's column is out of sight (no double)
ZEDQA rt_hud PASS on screen (moodles bottom): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: a line the character says is in ZeD's balloon
ZEDQA rt_hud PASS bubble: the over-head layer draws it
ZEDQA rt_hud PASS on screen (speech bubble): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS bubble: it fades and goes
ZEDQA rt_hud PASS xp: Perks.Woodwork exists in this build
ZEDQA rt_hud PASS xp: skill XP goes through with ZeD on, no error
ZEDQA rt_hud PASS xp: the gain is logged in Messages | Carpentry +1.2 XP
ZEDQA rt_hud PASS xp: a game note goes to ZeD's bubble, marked good
ZEDQA rt_hud PASS xp: the over-head layer draws the note
ZEDQA rt_hud PASS on screen (over-head note): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS xp: the note fades and goes
ZEDQA rt_hud PASS guide: a fresh machine arms the bubble
ZEDQA rt_hud PASS guide: the bubble comes out
ZEDQA rt_hud PASS guide: the guide's own words | New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time.
ZEDQA rt_hud PASS guide: a long bare balloon for player one
ZEDQA rt_hud PASS guide: it comes out of the belt's Messages note
ZEDQA rt_hud PASS on screen (guide bubble): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS guide: the bubble goes by itself
ZEDQA rt_hud PASS guide: its line stays in Messages
ZEDQA rt_hud SKIP hint strip at a door (no door within 12 tiles on this floor)
ZEDQA rt_hud PASS forage: ZeD's pin and pointer are loaded
ZEDQA rt_hud PASS forage: search mode is on
ZEDQA rt_hud PASS forage: a find is staged | Base.MushroomGeneric1
ZEDQA rt_hud PASS forage: the pointer to the find is up
ZEDQA rt_hud PASS forage: the pointer is ZeD's hand for the find's side | zed_forage_hand_up_a
ZEDQA rt_hud PASS forage: the hand is 44 x 77
ZEDQA rt_hud PASS forage: white at full alpha
ZEDQA rt_hud PASS forage: the pin over the find is ZeD's magnifying glass | 186 of 225 draws
ZEDQA rt_hud PASS forage: the search-mode eye is in ZeD's over-head stack
ZEDQA rt_hud PASS on screen (forage): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS forage: the find and its pointer are gone again
ZEDQA rt_hud PASS put back: the character where it started
ZEDQA rt_hud PASS put back: the moodles' place
ZEDQA rt_hud PASS put back: the watch's place
ZEDQA rt_hud end: 77 pass, 0 fail, 1 skipped
ZEDQA rt_hud VERDICT PASS 77
ZEDQA rt_hud DONE
```

### 8. rt_pad.lua (`ZEDQA rt_pad`) - PASS, 14 s

- go 29551 at 12:05:36

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_pad start (35 steps)
[ZeD.QA] run #8 ok=true
ZEDQA rt_pad PASS every pad module is loaded
ZEDQA rt_pad PASS the input mode is held on the controller
ZEDQA rt_pad PASS focus: the windows open for the pad
ZEDQA rt_pad PASS focus: the Character window has the pad
ZEDQA rt_pad PASS focus: it lands on the list's first item | charMainInv 1 Apple
ZEDQA rt_pad PASS focus: D-pad Down moves to the next item | Baseball Cap
ZEDQA rt_pad PASS focus: D-pad Up moves back | Apple
ZEDQA rt_pad PASS on screen (windows on the pad): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS card: the pad is on the list
ZEDQA rt_pad PASS card: on the landed item by frame 2 on every move, never the item before, no flicker | 8 of 8
ZEDQA rt_pad PASS on screen (the pad's item card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS left: the Character wheel opens
ZEDQA rt_pad PASS left: the wheel has its slices | 10
ZEDQA rt_pad PASS on screen (Character wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS left: Tabs is there
ZEDQA rt_pad PASS left: Tabs opens its wheel, Back last
ZEDQA rt_pad PASS left: Tabs has Health
ZEDQA rt_pad PASS left: Health opens the Character window on Health | health
ZEDQA rt_pad PASS right: the World wheel opens
ZEDQA rt_pad PASS on screen (World wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS right: Tabs is there
ZEDQA rt_pad PASS right: Tabs has Loot
ZEDQA rt_pad PASS right: Loot opens the World window on Loot | loot
ZEDQA rt_pad PASS up: the Social wheel opens
ZEDQA rt_pad PASS on screen (Social wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS up: Shout is live
ZEDQA rt_pad PASS up: Shout runs the game's shout
ZEDQA rt_pad PASS down: the Here and now wheel opens
ZEDQA rt_pad PASS on screen (Here and now wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS down: Zoom is there
ZEDQA rt_pad PASS down: Zoom has in
ZEDQA rt_pad PASS down: Zoom > in changes the zoom | 1.00 to 0.75
ZEDQA rt_pad PASS select: the ZeD wheel opens
ZEDQA rt_pad PASS on screen (ZeD wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS select: Moodles is there
ZEDQA rt_pad PASS select: Moodles lists the places
ZEDQA rt_pad PASS select: the pick moves the moodles | 2
ZEDQA rt_pad PASS chord: RB + R3 is on Here and now > Crouch
ZEDQA rt_pad PASS chord: no window has the pad (the chord is the world's)
ZEDQA rt_pad PASS chord: the press is taken as RB + R3 | RB+R3
ZEDQA rt_pad PASS chord: the character crouches
ZEDQA rt_pad PASS chord: again, and it stands as it was
ZEDQA rt_pad PASS put back: the switch is on
ZEDQA rt_pad PASS put back: a bottle of water in a bag
ZEDQA rt_pad PASS put back: after the drink the bottle is back in the bag | Bag_Schoolbag
ZEDQA rt_pad PASS map: the Controller map opens
ZEDQA rt_pad PASS map: it draws the pad from its textures | k 4, xbox
ZEDQA rt_pad PASS map: the pad fits the window's width
ZEDQA rt_pad PASS on screen (Controller map): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS put back: the pad is the game's again
ZEDQA rt_pad PASS put back: the stand-ins are gone
ZEDQA rt_pad PASS put back: the moodles' place
ZEDQA rt_pad put back: the input mode lock is nil again; the mode reads gamepad
ZEDQA rt_pad end: 52 pass, 0 fail, 0 skipped
ZEDQA rt_pad VERDICT PASS 52
ZEDQA rt_pad DONE
```

### 9. rt_media.lua (`ZEDQA rt_media`) - PASS, 15 s

- go 29552 at 12:05:53

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_media start (72 steps)
[ZeD.QA] run #9 ok=true
ZEDQA rt_media PASS the media modules are loaded (RtvFace, RadioTab, RadioOps, TwoWayFace, MapNotes, MapsTab, JournalReaders)
ZEDQA rt_media PASS the radio: given (Base.RadioRed)
ZEDQA rt_media PASS the radio: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the radio: its own face draws in the tab | face radio_red, want radio_red
ZEDQA rt_media PASS on screen (the radio's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS the radio: the face has its power control (power)
ZEDQA rt_media PASS the radio: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the radio: the face has its tuning knob
ZEDQA rt_media PASS the radio: TUNE's right half tunes up one step | 89400 -> 89600
ZEDQA rt_media PASS the radio: TUNE's left half tunes back down | now 89400, want 89400
ZEDQA rt_media PASS the radio: power again turns it off
ZEDQA rt_media PASS the radio: the pad's first stop on the face is power | radio:tw:power
ZEDQA rt_media PASS the radio: A on the power stop turns it on
ZEDQA rt_media PASS the radio: A again turns it off
ZEDQA rt_media PASS the two-way: given (Base.WalkieTalkie2)
ZEDQA rt_media PASS the two-way: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the two-way: its own face draws in the tab | face walkie_valutech@180, want walkie_valutech
ZEDQA rt_media PASS on screen (the two-way's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS the two-way: the face has its power control (vol)
ZEDQA rt_media PASS the two-way: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the two-way: the face has its tuning knob
ZEDQA rt_media PASS the two-way: TUNE's right half tunes up one step | 191400 -> 191600
ZEDQA rt_media PASS the two-way: TUNE's left half tunes back down | now 191400, want 191400
ZEDQA rt_media PASS the two-way: power again turns it off
ZEDQA rt_media PASS the CD player: given (Base.CDplayer)
ZEDQA rt_media PASS the CD player: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the CD player: its own face draws in the tab | face cd_player, want cd_player
ZEDQA rt_media PASS on screen (the CD player's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS the CD player: the face has its power control (power)
ZEDQA rt_media PASS the CD player: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the CD player: VOL raises the volume (0.50 -> 0.60; it has no tuner)
ZEDQA rt_media PASS the CD player: power again turns it off
ZEDQA rt_media PASS a free room square with room for the TV beside it is found
ZEDQA rt_media PASS the TV's room has grid power (the grid turned on for the test)
ZEDQA rt_media PASS a TV is placed beside the character
ZEDQA rt_media PASS the World window's Radio list has the TV
ZEDQA rt_media PASS the World window's Radio tab opens from the strip
ZEDQA rt_media PASS the TV: its own face draws in the tab | face tv_black@392
ZEDQA rt_media PASS on screen (the TV's face in the World window): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS the TV: on the grid and off to start with
ZEDQA rt_media PASS the TV's face has its power key
ZEDQA rt_media PASS the TV: a click on power turns it on
ZEDQA rt_media PASS the TV's face has CH up
ZEDQA rt_media PASS the TV: CH up tunes the next channel | 1 -> 2
ZEDQA rt_media PASS the TV: power again turns it off
ERROR: General f:9585 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rt_media back at 925,13040
ZEDQA rt_media PASS the World window's Maps tab opens from the strip
ZEDQA rt_media PASS the Maps tab draws its map
ZEDQA rt_media PASS on screen (the Maps tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
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
ZEDQA rt_media PASS on screen (the menu on a map note): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS Delete takes the note off the map | marks now 2
ZEDQA rt_media PASS a flyer and a notebook are given
ZEDQA rt_media PASS the Character window's Journal tab opens from the strip
ZEDQA rt_media PASS Papers lists the flyer carried
ZEDQA rt_media PASS the flyer has its row on the page
ZEDQA rt_media PASS on screen (the Journal's Papers page): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS Notebooks lists the notebook carried, with its row
ZEDQA rt_media PASS a click on the notebook's row picks it
ZEDQA rt_media PASS on screen (the Journal's Notebooks page): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_media PASS light to write by (noon set for the test)
ZEDQA rt_media PASS the quick note's Write button is live
ZEDQA rt_media PASS the line written from the quick note is kept on the notebook's page (ZeD_WriteNoteAction)
ZEDQA rt_media PASS the notebook's Open full button is live
ZEDQA rt_media PASS Open full opens the notebook in ZeD's reader
ZEDQA rt_media PASS the reader opens it to write (a pencil carried)
ZEDQA rt_media PASS the reader shows the written line on its first page
ZEDQA rt_media PASS on screen (the reader): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Done keeps the second page's text as written
ZEDQA rt_media PASS Done keeps the first page's line
ZEDQA rt_media PASS Done closes the reader
ZEDQA rt_media PASS put back: the character is where it started | 925,13040
ZEDQA rt_media PASS put back: the hands hold what they held
ZEDQA rt_media end: 84 pass, 0 fail, 0 skipped
ZEDQA rt_media VERDICT PASS 84
ZEDQA rt_media DONE
```

### 10. rt_vehicles.lua (`ZEDQA rt_veh`) - PASS, 16 s

- go 29553 at 12:06:12

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_veh start (37 steps)
[ZeD.QA] run #10 ok=true
ZEDQA vp rt_veh player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.ModernCarLightsMeadeSheriff at 917.0,13030.0 dist=13.5 vehicles=32
ZEDQA car rt_veh Base.CarLightsPolice spawned on spot 11 (917,13030)
ZEDQA rt_veh PASS a police car spawned beside the character, the character in the driver's seat | nil
ZEDQA rt_veh PASS dash: ZeD's dash shows in the car
ZEDQA rt_veh PASS dash: it has a design for the car | police
ZEDQA rt_veh PASS dash: its design has gauges | 5 needles
ZEDQA rt_veh PASS dash: its design has lamps | 9 lamps
ZEDQA rt_veh PASS on screen (the dash): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_veh PASS dash: a click on the ignition puts the key in
ZEDQA rt_veh PASS dash: key on, engine off: the bulb check lights the lamps | check true, battery true, engine true, oil true
ZEDQA rt_veh PASS dash: a second click on the ignition starts the engine (the game's start) | 0 retries
ZEDQA rt_veh PASS dash: running: the rev needle is up | rpm 743
ZEDQA rt_veh PASS dash: the fuel needle reads the full tank | fuel 1.00
ZEDQA rt_veh PASS dash: running: the bulb check is over (oil lamp dark) | false
ZEDQA rt_veh PASS on screen (the dash, engine running): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_veh PASS radio: ZeD's hook is on the wheel's Device Options
ZEDQA rt_veh PASS radio: Device Options brings the car radio up close | ham
ZEDQA rt_veh PASS on screen (the car radio): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS radio: it has a power control | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: the click turns it on (the game's radio action)
ZEDQA rt_veh PASS radio: with the engine running it plays
ZEDQA rt_veh PASS radio: it has a tuning knob | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: a click on TUNE's right half moves the frequency | 99600 -> 99800
ZEDQA rt_veh PASS radio: TUNE's left half tunes it back | 99600
ZEDQA rt_veh PASS radio: Device Options again puts it away
ZEDQA rt_veh PASS seats: ZeD's hook is on the seat key
ZEDQA rt_veh PASS seats: the seat key opens ZeD's seat chooser | ZeD_SeatPopout
ZEDQA rt_veh PASS seats: it lists every seat of the car | 4 of 4
ZEDQA rt_veh PASS seats: the driver's seat is yours | you
ZEDQA rt_veh PASS on screen (the seat chooser): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS seats: it closes
ZEDQA rt_veh PASS siren: the police car has a lightbar
ZEDQA rt_veh PASS siren: ZeD's hook is on the wheel's Lightbar
ZEDQA rt_veh PASS siren: the Lightbar brings the siren controller up close
ZEDQA rt_veh PASS siren: its plate is loaded (SirenPlate, PhysPx)
ZEDQA rt_veh PASS on screen (the siren controller): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS siren: LIGHTS has its 1 position | lights:0 lights:1 lights:2 lights:3 lights:knob siren:0 siren:1 siren:2 siren:3 siren:knob
ZEDQA rt_veh PASS siren: a click on LIGHTS 1 turns the bar on (the game's command) | 1
ZEDQA rt_veh PASS siren: the dash's lightbar lamp follows | true
ZEDQA rt_veh PASS siren: a click on its OFF puts the bar back | 0
ZEDQA rt_veh PASS dash: a click on the ignition shuts the engine off
ZEDQA rt_veh PASS vehicle: the game's Vehicle Mechanics inspects the car and opens the World window's Vehicle tab
ZEDQA rt_veh PASS vehicle: the tab lists the car's parts | 41 of 41
ZEDQA rt_veh PASS vehicle: the parts' rows are drawn | 41
ZEDQA rt_veh PASS on screen (the Vehicle tab): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_veh PASS vehicle: a click on a part's row opens its card | Muffler (want Muffler)
ZEDQA rt_veh PASS vehicle: the same row again closes the card | nil
ZEDQA rt_veh PASS put back: the character out, the key taken back, the car removed
ZEDQA rt_veh end: 46 pass, 0 fail, 0 skipped
ZEDQA rt_veh VERDICT PASS 46
ZEDQA rt_veh DONE
```

### 11. rt_addon.lua (`ZEDQA rt_addon`) - PASS, 2 s

- go 29554 at 12:06:32

```text
[ZeD.QA] state #11 speed=1 paused=false player=917,13027 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_addon start (12 steps)
[ZeD.QA] run #11 ok=true
ZEDQA rt_addon PASS the stand-in provider registers (hook version 2)
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
ZEDQA rt_addon PASS on screen (the bag as the provider's grid): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_addon PASS the pad's place mode carries the L cell's mask | mask XX/X., squares 3
ZEDQA rt_addon PASS the place mode's ghost is the mask's outline, not its box | 12 edges drawn, 0 missing, 0 in the hole
ZEDQA rt_addon PASS unregistered, the hook has no provider
ZEDQA rt_addon PASS the bag's grid is ZeD's own again (no add-on layout on the list)
ZEDQA rt_addon PASS the place mode was cancelled: nothing was dropped
ZEDQA rt_addon end: 24 pass, 0 fail, 0 skipped
ZEDQA rt_addon VERDICT PASS 24
ZEDQA rt_addon DONE
```

### 12. rt_system.lua (`ZEDQA rt_sys`) - PASS, 143 s

- go 29555 at 12:06:37

```text
[ZeD.QA] state #12 speed=1 paused=false player=917,13027 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_sys start (91 steps)
[ZeD.QA] run #12 ok=true
ZEDQA rt_sys PASS ZeD's settings, safe mode, main menu and scale modules are loaded
ZEDQA rt_sys PASS a changed setting is written to ModOptions.ini | file 2, want 2
ZEDQA rt_sys PASS the saved setting comes back when the game reads ModOptions.ini | value 2
ZEDQA rt_sys PASS the setting is put back, in memory and in the file | value 1, file 1
ZEDQA rt_sys PASS ModOptions.ini is back line for line | 63 lines, 63 before
ZEDQA rt_sys PASS the pause menu opens (ZeD's pause window)
ZEDQA rt_sys PASS Options opens from the pause menu (ZeD's window)
ZEDQA rt_sys PASS every Options group's page was opened | 9 of 9
ZEDQA rt_sys PASS ZeD setup opens with its groups and rows | 9 groups, 89 rows
ZEDQA rt_sys PASS Options, ZeD setup: the page opens, the window on screen | 89 rows
ZEDQA rt_sys PASS Options, Display: the page opens, the window on screen | 7 rows
ZEDQA rt_sys PASS Options, Graphics: the page opens, the window on screen | 30 rows
ZEDQA rt_sys PASS Options, Audio: the page opens, the window on screen | 19 rows
ZEDQA rt_sys PASS Options, Controls: the page opens, the window on screen | 118 rows
ZEDQA rt_sys PASS Options, Gameplay: the page opens, the window on screen | 35 rows
ZEDQA rt_sys PASS Options, Interface: the page opens, the window on screen | 29 rows
ZEDQA rt_sys PASS Options, Accessibility: the page opens, the window on screen | 8 rows
ZEDQA rt_sys PASS Options, Mods: the page opens, the window on screen | 63 rows
ZEDQA rt_sys PASS Options has ZeD setup
ZEDQA rt_sys PASS the Options pages drew with no Lua error | 0 new
ZEDQA rt_sys PASS Back leaves Options for the pause menu | pause
ZEDQA rt_sys PASS the pause menu shuts again
ZEDQA rt_sys PASS UI scale UI_ZeD_Settings_ScaleAuto: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS on screen (UI scale UI_ZeD_Settings_ScaleAuto): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys scale step 0.5x: not offered on this screen (retired or too big)
ZEDQA rt_sys PASS UI scale 0.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.75x: drawn at that scale | root 0.75
ZEDQA rt_sys PASS on screen (UI scale 0.75x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 1x: the theme follows the new scale and both windows are open again | root 1
ZEDQA rt_sys PASS UI scale 1x: drawn at that scale | root 1
ZEDQA rt_sys PASS on screen (UI scale 1x): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_sys PASS UI scale 1.25x: the theme follows the new scale and both windows are open again | root 1.25
ZEDQA rt_sys PASS UI scale 1.25x: drawn at that scale | root 1.25
ZEDQA rt_sys PASS on screen (UI scale 1.25x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 1.5x: the theme follows the new scale and both windows are open again | root 1.5
ZEDQA rt_sys PASS UI scale 1.5x: drawn at that scale | root 1.5
ZEDQA rt_sys PASS on screen (UI scale 1.5x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 1.75x: the theme follows the new scale and both windows are open again | root 1.75
ZEDQA rt_sys PASS UI scale 1.75x: drawn at that scale | root 1.75
ZEDQA rt_sys PASS on screen (UI scale 1.75x): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_sys PASS UI scale 2x: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS UI scale 2x: drawn at that scale | root 2
ZEDQA rt_sys PASS on screen (UI scale 2x): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_sys PASS UI scale put back on the run's own step | option 7, root 1.75
ZEDQA layout rt_sys scale put back
ZEDQA rt_sys PASS on screen (the windows back after the scale steps): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS theme dark: applies to ZeD's table | dark
ZEDQA rt_sys PASS on screen (theme dark): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS theme light: applies to ZeD's table | light
ZEDQA rt_sys PASS on screen (theme light): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS theme hicon: applies to ZeD's table | hicon
ZEDQA rt_sys PASS on screen (theme hicon): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS accent red: applies to ZeD's table | red
ZEDQA rt_sys PASS accent orange: applies to ZeD's table | orange
ZEDQA rt_sys PASS accent yellow: applies to ZeD's table | yellow
ZEDQA rt_sys PASS accent green: applies to ZeD's table | green
ZEDQA rt_sys PASS accent blue: applies to ZeD's table | blue
ZEDQA rt_sys PASS accent teal: applies to ZeD's table | teal
ZEDQA rt_sys PASS accent purple: applies to ZeD's table | purple
ZEDQA rt_sys PASS accent pink: applies to ZeD's table | pink
ZEDQA rt_sys PASS accent mono: applies to ZeD's table | mono
ZEDQA rt_sys PASS the run's own theme, accent and text size are back | light / teal / small
ZEDQA rt_sys safe mode baseline: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode: ZeD runs to start with (its windows, its hotbar)
ZEDQA rt_sys tripped: on true | pair shut true | game's inventory true | hotbar vanilla | moodle layer false
ZEDQA rt_sys PASS a trip: ZeD's windows shut
ZEDQA rt_sys PASS a trip: the game's own inventory page, hotbar and moodles come back
ZEDQA rt_sys PASS a trip: the note shows (the game's own dialog) and closes
ZEDQA rt_sys PASS tripped, the inventory key works the game's own page (hides, shows) | true -> false -> true
ZEDQA rt_sys reset: on false | pair shut true | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS a reset brings ZeD back and hides the game's page
ZEDQA rt_sys PASS after the reset ZeD's windows open again
ZEDQA rt_sys PASS on screen (the windows after a safe mode reset): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS the Safe mode option On is picked up by itself within a second | 46 ms
ZEDQA rt_sys PASS Safe mode On: the game's own pages, no trip note
ZEDQA rt_sys PASS the Safe mode option Off is picked up by itself within a second | 472 ms
ZEDQA rt_sys PASS Safe mode Off: ZeD back
ZEDQA rt_sys PASS the watchdog: a five-frame burst of faults leaves ZeD on
ZEDQA rt_sys PASS the watchdog: under two seconds of faults ZeD stays on | 2010 ms, 121 frames
ZEDQA rt_sys PASS the watchdog: two seconds of faults every frame trip it | 2010 ms
ZEDQA rt_sys PASS the watchdog's note shows and closes
ZEDQA rt_sys safe mode put back: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode put back: the option as it was, ZeD running
ZEDQA rt_sys SKIP step-aside (no active mod replaces a ZeD screen in this game)
ZEDQA rt_sys PASS another mod's note is kept in Messages, not shown over the game
ZEDQA rt_sys PASS Messages keeps the note, new, under the mod's name | 1
ZEDQA rt_sys PASS the Messages window opens on the mod
ZEDQA rt_sys PASS the window shows the note's card with its OK | 1
ZEDQA rt_sys PASS on screen (the Messages window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS OK in Messages runs the mod's own callback once | 1 calls
ZEDQA rt_sys PASS put back: the test mod's messages are cleared
ZEDQA rt_sys soak start: 1800192 KB, 0 Lua errors so far
ZEDQA rt_sys PASS the soak ran its two minutes | 120 s
ZEDQA rt_sys PASS the soak: no Lua error in two minutes with the windows open | 0 new
ZEDQA rt_sys PASS the soak: Lua memory grows by no more than 262144 KB | 1800192 KB -> 1798144 KB (-2048 KB)
ZEDQA rt_sys PASS on screen (the windows after the soak): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS every key in ZeD's English UI.json has text in the game | 6822 keys
ZEDQA rt_sys PASS every ZeD key read while the script ran has text | 322 keys
ZEDQA rt_sys PASS every game key ZeD borrowed while the script ran has text | 41 keys
ZEDQA layout rt_sys put back
ZEDQA rt_sys PASS put back: ZeD.tr is ZeD's own again
ZEDQA rt_sys PASS put back: every setting this script changed is as it was
ZEDQA rt_sys end: 93 pass, 0 fail, 1 skipped
ZEDQA rt_sys VERDICT PASS 93
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
