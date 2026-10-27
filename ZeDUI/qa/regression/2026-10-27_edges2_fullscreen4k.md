# ZeD-UI regression - 2026-10-27 03:21 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-27 03:21:02 |
| Finished | 2026-10-27 03:26:31 (5 min 28 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/AppData/Local/Temp/claude/C--Users-danie-Zomboid/7395e6f8-af8b-4442-87a0-5848151409de/scratchpad/edges_manifest.txt (3 scripts) |
| Result | **1/3 pass**, 1 warn, 0 fail, 1 timeout |
| Go numbers | 14189 to 14191 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_prelude.lua: no DONE within 180 s; the script may still be running in the game
- -KeepOpen: the game was left running
- -KeepOpen: ZeD settings are still the test's; the director's file is C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-27_edges2_fullscreen4k.md.modoptions.ini

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_world_pad_take.lua | wpt | WARN | 62 |  | 11 ERR line(s) |
| 3 | zedqa_prelude.lua | pre2 | **TIMEOUT** | 181 |  | late output from pre (4 line(s), not counted); no DONE within 180 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 14189 at 03:22:17

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 62 s

- go 14190 at 03:22:22
- 11 ERR line(s)

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #2 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@100
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldContainerStrip:container:2
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
ZEDQA wpt 3 A on the bandage: World worldMainInv:invrow:4 (Tweezers)
ZEDQA wpt FAIL 3 A on the bandage: focus is on the card's primary action (nil)
ZEDQA wpt 3 Down in the card: World worldCtl:worldCtl:floor
ZEDQA wpt FAIL Down moves to the card's next control
ZEDQA wpt 3 Up: World worldMainInv:invrow:4 (Tweezers)
ZEDQA wpt FAIL Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldItemCard:hverb_1
ZEDQA wpt FAIL B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldMainInv:invrow:3 (Eraser)
ZEDQA wpt FAIL 4 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL the nails' card offers Take as its primary action
ZEDQA wpt FAIL A on Take moved the nails into the bag (vanilla's transfer, 610 ticks)
ZEDQA wpt 4 after the take: World worldItemCard:hverb_1
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
ZEDQA wpt 6 Right: World worldContainerStrip:container:1
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt FAIL Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt FAIL 6 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is nil; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (DROP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt PASS 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold A: World worldMainInv:invrow:2 (Eraser)
ZEDQA wpt PASS 8 hold A moved the hammer out of the crate
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Eraser)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 12 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column exercise:time:dec and it is in view (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 958 px in a 585 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Weak Stomach and it is in view (bottom 575 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 564 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 636 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 210 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:row:RemoveBattery and it is in view (bottom 228 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 228 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 126 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 121 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 121 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 344 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:disclosure is in view at the bottom (bottom 344 of 650)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column bodypart:Left Foot and it is in view (bottom 149 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 152 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 1013 px in a 564 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Weak Stomach and it is in view (bottom 553 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 541 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 622 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 140 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:row:RemoveBattery and it is in view (bottom 260 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 260 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 144 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:section:all is in view at the bottom (bottom 144 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 138 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 138 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 393 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:disclosure is in view at the bottom (bottom 393 of 638)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 628 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 78 passed, 11 failed
ZEDQA wpt DONE
```

### 3. zedqa_prelude.lua (`ZEDQA pre2`) - TIMEOUT, 181 s

- go 14191 at 03:23:27
- late output from pre (4 line(s), not counted)
- no DONE within 180 s; the script may still be running in the game

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start   (late output from pre)
[ZeD.QA] run #3 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61   (late output from pre)
ZEDQA pre search overlay: enabled false, override false, manager false   (late output from pre)
ZEDQA pre DONE   (late output from pre)
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
