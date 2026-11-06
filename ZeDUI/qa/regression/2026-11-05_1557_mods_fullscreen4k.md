# ZeD-UI regression - 2026-11-05 15:58 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 15:58:18 |
| Finished | 2026-11-05 16:02:17 (3 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\after_f59f2.txt (4 scripts) |
| Result | **2/4 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 21183 to 21188 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21187, 21188)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 3 | zedqa_world_pad_take.lua | wpt | WARN | 110 |  | 2 ERR line(s) |
| 4 | zedqa_btn_look.lua | bnl | PASS | 25 | zqa_bnl_dark_hand.png, zqa_bnl_dark_corners.png, zqa_bnl_dark_wash.png, zqa_bnl_dark_ants.png, zqa_bnl_hicon_hand.png, zqa_bnl_hicon_corners.png, zqa_bnl_hicon_wash.png, zqa_bnl_hicon_ants.png, zqa_bnl_light_hand.png, zqa_bnl_light_corners.png, zqa_bnl_light_wash.png, zqa_bnl_light_ants.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21183 at 15:59:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 21184 at 15:59:26
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA an spawned Base.ChickenHutch at 927,13037
ZEDQA an spawned Base.FeedingTroughDoubleMetal at 922,13043
ZEDQA an spawned Base.ButcherHook at 922,13038
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=3 dirt=46
ERROR: General f:467 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:467> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an cow killed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 3. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 110 s

- go 21185 at 15:59:31
- 2 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #3 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@100
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldMainInv:invrow:1 (Firefighter Axe Head)
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldMainInv:invrow:1 (Firefighter Axe Head)
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
ZEDQA wpt 3 timing: card buttons ready after 6 ticks, 5 frames; focus in the card after 6 ticks, 5 frames (watched 6 ticks, 5 frames)
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
ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charContainerStrip:container:1
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
ZEDQA wpt PASS 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold X: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 hold X moved the thing out of the crate
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 12 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control health:exercise is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 616 px in a 521 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:view is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 628 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:__save is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 65 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 65 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:style:survey is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:search is in view at the bottom (bottom 641 of 650)
ZEDQA wpt FAIL 7 World animals small pad: Down reaches the lowest control of its column animals:disclosure:totalsExpanded and it is in view (bottom 1871 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:disclosure:totalsExpanded is in view at the bottom (bottom 461 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 623 px in a 491 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 626 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 614 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 75 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 75 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 628 of 638)
ZEDQA wpt FAIL 7 World animals large pad: Down reaches the lowest control of its column animals:disclosure:totalsExpanded and it is in view (bottom 2211 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:disclosure:totalsExpanded is in view at the bottom (bottom 418 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 87 passed, 2 failed
ZEDQA wpt DONE
```

### 4. zedqa_btn_look.lua (`ZEDQA bnl`) - PASS, 25 s

- go 21186 at 16:01:25
- screenshots: zqa_bnl_dark_hand.png, zqa_bnl_dark_corners.png, zqa_bnl_dark_wash.png, zqa_bnl_dark_ants.png, zqa_bnl_hicon_hand.png, zqa_bnl_hicon_corners.png, zqa_bnl_hicon_wash.png, zqa_bnl_hicon_ants.png, zqa_bnl_light_hand.png, zqa_bnl_light_corners.png, zqa_bnl_light_wash.png, zqa_bnl_light_ants.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA bnl shot dark hand
ZEDQA bnl shot dark corners
ZEDQA bnl shot dark wash
ZEDQA bnl shot dark ants
ZEDQA bnl shot hicon hand
ZEDQA bnl shot hicon corners
ZEDQA bnl shot hicon wash
ZEDQA bnl shot hicon ants
ZEDQA bnl shot light hand
ZEDQA bnl shot light corners
ZEDQA bnl shot light wash
ZEDQA bnl shot light ants
ZEDQA bnl DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
