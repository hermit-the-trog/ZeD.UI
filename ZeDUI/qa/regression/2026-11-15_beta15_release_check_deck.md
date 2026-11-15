# ZeD-UI regression - 2026-11-15 13:44 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-15 13:44:52 |
| Finished | 2026-11-15 13:46:44 (1 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta15 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_check.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 27343 to 27346 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27345, 27346)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_release_check.lua | rel | PASS | 17 | zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27343 at 13:45:57

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 6.08 -> 11.00 (daylight)
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

### 2. zedqa_release_check.lua (`ZEDQA rel`) - PASS, 17 s

- go 27344 at 13:46:02
- screenshots: zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel version=0.3.0-beta15 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA rel start
[ZeD.QA] run #2 ok=true
ZEDQA rel PASS the windows start shut
ZEDQA rel PASS 1: both windows open
ZEDQA rel rolled up before the hold: Character false, World false
ZEDQA rel the test item: Base.Spiffo
ZEDQA rel PASS 2: the test item is in the Character window's list
ZEDQA rel PASS 2: the test item went to the floor (the game's transfer)
ZEDQA rel PASS 2: the World window lists it
ZEDQA rel rolled up now: Character false, World false
ZEDQA rel PASS 2: it came back to the inventory
ZEDQA rel PASS 2: the Character window lists it again
ZEDQA rel PASS 4: the controller's focus is on the test item's row
ZEDQA rel 4: after A: charItemCard:hverb_1
ZEDQA rel PASS 4: A on the row opens its card, focus on its primary action (charItemCard:hverb_1)
ZEDQA rel 4: after B: invrow:28
ZEDQA rel PASS 4: B goes back to the row
ZEDQA rel PASS 3: the test item's row has a place on screen
ZEDQA rel PASS 3: the row is in the list's view (y 612 of 744)
ZEDQA rel 3: row invrow:28 at 0,612 400x60 in the window; the window at 1094,52
ZEDQA rel asked the helper for a right-click at 1154,694
ZEDQA rel PASS 3: the helper made the real right-click
ZEDQA rel 3: menu open true (ZeD_ContextList)
ZEDQA rel PASS 3: a real right-click on the row opens the item menu for that item (1 items)
ZEDQA rel PASS 5: the worn watch shows (belt false, corner true)
ZEDQA rel PASS 5: its face reads the game's time (11:4, the game 11:04)
ZEDQA layout rel put back
ZEDQA rel RESULT PASS: all 16 checks
ZEDQA rel DONE
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
