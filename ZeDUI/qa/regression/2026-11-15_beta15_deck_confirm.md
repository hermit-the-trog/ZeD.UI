# ZeD-UI regression - 2026-11-15 14:44 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-15 14:44:16 |
| Finished | 2026-11-15 14:46:28 (2 min 11 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta15 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b15_deck_confirm.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 27436 to 27440 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27439, 27440)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_wt_bracket.lua | wtb | PASS | 23 | zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png |  |
| 3 | zedqa_world_pad_take.lua | wpt | PASS | 12 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27436 at 14:45:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 4.64 -> 11.00 (daylight)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1022,0 888x840 rolled false pinned true/true
ZEDQA pre layout world 1930,0 888x840 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta15 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_wt_bracket.lua (`ZEDQA wtb`) - PASS, 23 s

- go 27437 at 14:45:27
- screenshots: zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wtb start
[ZeD.QA] run #2 ok=true
ZEDQA wtb given: bag 5 x Base.Orange + Base.Crowbar, ground 5 x Base.Apple + Base.Crowbar (6 / 6)
ZEDQA wtb extra columns: char 0 world 0
ZEDQA wtb small list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 615..676 of 744, name ends 276, columns 1
ZEDQA wtb small list char headers: cat true, cond true
ZEDQA wtb small list world stack Apple (Rotten) x5: drew "(1.0)" (expect "(1.0)") at x 643..704 of 744, name ends 296, columns 1
ZEDQA wtb small list world headers: cat true, cond true
ZEDQA wtb small list char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb small list world single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb open stack char: the row "(1.0)", 5 rows under it, 5 with their own weight
ZEDQA wtb open stack world: the row "(1.0)", 5 rows under it, 5 with their own weight
ZEDQA wtb char WT column 114 -> 92
ZEDQA wtb narrow WT char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 641..676 of 744, name ends 300, columns 1
ZEDQA wtb narrow WT char headers: cat true, cond true
ZEDQA wtb narrow WT char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb small grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 647..678 of 684, name ends nil, columns 1
ZEDQA wtb small grid world stack Apple (Rotten) x5: drew "(1.0)" (expect "(1.0)") at x 87..118 of 124, name ends nil, columns 1
ZEDQA wtb small grid char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb small grid world single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb large list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 572..644 of 722, name ends 365, columns 1
ZEDQA wtb large list char headers: cat false, cond true
ZEDQA wtb large list world stack Apple (Rotten) x5: drew "(1.0)" (expect "(1.0)") at x 604..676 of 722, name ends 363, columns 1
ZEDQA wtb large list world headers: cat false, cond true
ZEDQA wtb large list char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb large list world single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb large grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 485..523 of 530, name ends nil, columns 1
ZEDQA wtb large grid world stack Apple (Rotten) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 98..136 of 143, name ends nil, columns 1
ZEDQA wtb large grid char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb large grid world single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb pack column on: true
ZEDQA wtb char columns 2
ZEDQA wtb two columns char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 815..876 of 944, name ends 780, columns 2
ZEDQA wtb two columns char headers: cat false, cond false
ZEDQA wtb two columns char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb two columns large char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 803..844 of 922, name ends 751, columns 2
ZEDQA wtb two columns large char headers: cat false, cond false
ZEDQA wtb two columns large char single Crowbar: drew "2.0" (expect "2.0")
ZEDQA wtb size back to small | bag Base.Orange left 0
ZEDQA wtb all checks held; DONE
```

### 3. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 12 s

- go 27438 at 14:45:53

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt not run: 7 every tab's bottom (cut Nov 12 2026)
ZEDQA wpt start
[ZeD.QA] run #3 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@114
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldTabBar:tab:craft
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldContainerStrip:container:2
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:2
ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
ZEDQA wpt 2 Down x1: World worldContainerStrip:container:1
ZEDQA wpt PASS Down from the ground reaches the crate (1 presses)
ZEDQA wpt 2 after A on the crate: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS A on the crate puts focus on its first item, lit
ZEDQA wpt 2 Left: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from the list lands on the crate (the container on show)
ZEDQA wpt 2 Right: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS Right goes back to the same row
ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from a lower row lands on the crate too
ZEDQA wpt PASS and Right goes back to that row
ZEDQA wpt 3 timing: card buttons ready after 5 ticks, 4 frames; focus in the card after 5 ticks, 4 frames (watched 5 ticks, 4 frames)
ZEDQA wpt 3 A on the bandage: World worldItemCard:hverb_1
ZEDQA wpt PASS 3 A on the bandage: focus is on the card's primary action (TAKE)
ZEDQA wpt 3 Down in the card: World worldItemCard:name_row
ZEDQA wpt PASS Down moves to the card's next control
ZEDQA wpt 3 Up: World worldItemCard:hverb_1
ZEDQA wpt PASS Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldMainInv:invrow:4 (Tweezers)
ZEDQA wpt PASS B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldItemCard:hverb_1
ZEDQA wpt PASS 4 A on the nails: focus is on the card's primary action (TAKE)
ZEDQA wpt PASS the nails' card offers Take as its primary action
ZEDQA wpt PASS A on Take moved the nails into the bag (vanilla's transfer, 10 ticks)
ZEDQA wpt 4 after the take: World worldMainInv:invrow:3 (Tweezers)
ZEDQA wpt 5 before the padlock card: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt 5 the padlock card: World worldItemCard:oc:verb:usecombo
ZEDQA wpt PASS the object card opens with focus on its main live verb (oc:verb:usecombo)
ZEDQA wpt PASS A on it ran the verb (the padlock's code wheel shows)
ZEDQA wpt 5 after B: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS B closes the object card and focus is back in the list, lit
ZEDQA wpt 6 Left from the World window's strip: Char charMainInv:invrow:1 (Animal Feed Bag)
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charTabBar:tab:equip
ZEDQA wpt PASS LB lands in the Character window on a lit element
ZEDQA wpt 6 Right: Char charContainerStrip:container:1
ZEDQA wpt PASS Right from a row lands on the bag on show
ZEDQA wpt PASS Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is DROP; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (USE)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Animal Feed Bag)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt 8 after X: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 X on a crate row moves the thing out of the crate (223)
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA layout wpt put back
ZEDQA wpt 37 passed, 0 failed
ZEDQA wpt DONE
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
