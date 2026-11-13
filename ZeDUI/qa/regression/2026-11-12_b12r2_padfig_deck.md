# ZeD-UI regression - 2026-11-12 21:19 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-12 21:19:45 |
| Finished | 2026-11-12 21:21:20 (1 min 35 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/pad_figure.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 26019 to 26022 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800; pointer parked at (2565,1514)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26021, 26022)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_pad_figure.lua | padfig | PASS | 13 | zqa_padfig_01_rest_1280x800.png, zqa_padfig_02_lit_1280x800.png, zqa_padfig_03_set_ps_1280x800.png, zqa_padfig_04_set_nintendo_1280x800.png, zqa_padfig_05_set_deck_1280x800.png, zqa_padfig_06_pull_which_1280x800.png, zqa_padfig_07_pull_actions_1280x800.png, zqa_padfig_08_cmap_1280x800.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 26019 at 21:20:40

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 360,0 276x315 rolled false pinned true/true
ZEDQA pre layout world 644,0 276x315 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta12 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pad_figure.lua (`ZEDQA padfig`) - PASS, 13 s

- go 26020 at 21:20:45
- screenshots: zqa_padfig_01_rest_1280x800.png, zqa_padfig_02_lit_1280x800.png, zqa_padfig_03_set_ps_1280x800.png, zqa_padfig_04_set_nintendo_1280x800.png, zqa_padfig_05_set_deck_1280x800.png, zqa_padfig_06_pull_which_1280x800.png, zqa_padfig_07_pull_actions_1280x800.png, zqa_padfig_08_cmap_1280x800.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA padfig start
[ZeD.QA] run #2 ok=true
ZEDQA padfig PASS the pause menu is up
ZEDQA padfig PASS the in-game Options window is open
ZEDQA padfig PASS Button map and test is a page of ZeD's Options (pad)
ZEDQA padfig PASS the page drew the figure
ZEDQA padfig screen 1280x800, ZeD scale 0.75: k 2, the pad 376x212 at 187,145 in the box 732x416
ZEDQA padfig PASS the whole multiple at this screen is the mockup's 2 (2)
ZEDQA padfig PASS the game has the drawn pad's textures
ZEDQA padfig PASS rest: every label inside the figure's box (0)
ZEDQA padfig PASS rest: no label over another
ZEDQA padfig PASS rest: no label over the pad
ZEDQA padfig shot zqa_padfig_01_rest_1280x800.png
ZEDQA padfig PASS held, pushed and pulled parts light their labels
ZEDQA padfig PASS the rest stay unlit
ZEDQA padfig shot zqa_padfig_02_lit_1280x800.png
ZEDQA padfig PASS the button pictures ps: the ps drawing (ps)
ZEDQA padfig PASS ps: every label inside the figure's box (0)
ZEDQA padfig PASS ps: no label over another
ZEDQA padfig PASS ps: no label over the pad
ZEDQA padfig shot zqa_padfig_03_set_ps_1280x800.png
ZEDQA padfig PASS the button pictures nintendo: the nin drawing (nin)
ZEDQA padfig PASS nintendo: every label inside the figure's box (0)
ZEDQA padfig PASS nintendo: no label over another
ZEDQA padfig PASS nintendo: no label over the pad
ZEDQA padfig shot zqa_padfig_04_set_nintendo_1280x800.png
ZEDQA padfig PASS the button pictures deck: the deck drawing (deck)
ZEDQA padfig PASS deck: every label inside the figure's box (0)
ZEDQA padfig PASS deck: no label over another
ZEDQA padfig PASS deck: no label over the pad
ZEDQA padfig shot zqa_padfig_05_set_deck_1280x800.png
ZEDQA padfig PASS the left stick's label is a stop
ZEDQA padfig PASS the left stick's label asks which element first (2)
ZEDQA padfig shot zqa_padfig_06_pull_which_1280x800.png
ZEDQA padfig PASS the stick's click is one of them
ZEDQA padfig PASS its click's actions open under its name, with B back to the question
ZEDQA padfig shot zqa_padfig_07_pull_actions_1280x800.png
ZEDQA padfig PASS Back leaves the page for the Options
ZEDQA padfig PASS the Controller map opens
ZEDQA padfig shot zqa_padfig_08_cmap_1280x800.png
ZEDQA padfig MANUAL with a controller in hand, on Options > Controls > Button map and test:
ZEDQA padfig MANUAL each face button, View, Menu and both bumpers: held, it fills with the accent; a face button and View / Menu sit one art pixel down and right, their shadow gone
ZEDQA padfig MANUAL each D-pad arm: that arm lights with its arrow; the D-pad's label picture shows the arm
ZEDQA padfig MANUAL each stick: the cap follows the push (up is up), the label's dial dot too; a click lights the cap
ZEDQA padfig MANUAL each trigger: fills from the bottom row up as it is pulled, the label's percent counts to 100
ZEDQA padfig MANUAL the D-pad walks the labels (one stop each); A opens a label's actions; on a stick or the D-pad A first asks which element; B there goes back, B again closes; B on the page backs out
ZEDQA padfig MANUAL Test controller: pick the pad, the page leaves the buttons alone; A and Y held together end the test
ZEDQA padfig MANUAL the same with the button pictures on PlayStation (the D-pad up top) and on Xbox (the left stick up top)
ZEDQA padfig 29 passed, 0 failed
ZEDQA padfig DONE
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
