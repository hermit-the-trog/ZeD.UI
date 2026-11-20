# ZeD-UI regression - 2026-11-20 04:56 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 04:56:54 |
| Finished | 2026-11-20 04:58:44 (1 min 50 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_kbmap_only.txt (3 scripts) |
| Result | **2/3 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 30739 to 30743 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30742, 30743)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_kbmap.lua | rt_kbmap | **FAIL** | 7 |  | 2 ERR line(s); its own checks failed (VERDICT FAIL) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30739 at 04:58:03

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

- go 30740 at 04:58:08

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_kbmap.lua (`ZEDQA rt_kbmap`) - FAIL, 7 s

- go 30741 at 04:58:12
- 2 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_kbmap start (31 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_kbmap PASS Keyboard map: ZeD.KeyboardMap is loaded (open, read, setKey, resetAll)
ZEDQA rt_kbmap as found: Toggle Music on 0, keysB42.ini 95 lines
ZEDQA rt_kbmap PASS Keyboard map: the window menu has its Keyboard map row | Keyboard map
ZEDQA rt_kbmap PASS Keyboard map: its menu row opens the window
ZEDQA rt_kbmap PASS on screen (the keyboard map): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_kbmap PASS Keyboard map: read() lists every binding of the game's keyBinding table with its key now | 83 of 83 bindings, 11 of 11 groups
ZEDQA rt_kbmap PASS Keyboard map: the drawn keyboard lights every bound key and only those | 71 keys drawn, 51 lit, 0 clashes
ZEDQA rt_kbmap PASS Keyboard map: a free key and a held key to test with | Toggle Music: free 40, held 59 (Toggle Survival Guide)
ZEDQA rt_kbmap PASS Keyboard map: setKey gives the game the new key at once (getCore():getKey) | Toggle Music on 40, wanted 40
ZEDQA rt_kbmap PASS Keyboard map: the game's Options key list has the new key too (an Apply there keeps it) | Options list 40, wanted 40
ZEDQA rt_kbmap PASS Keyboard map: keysB42.ini has the new line in the game's format and no other line changed | Toggle Music=key:40 (wanted Toggle Music=key:40), 0 other lines changed, first line VERSION=2
ZEDQA rt_kbmap PASS Keyboard map: the game's Options reading of keysB42.ini finds the new key | version 2, 40
ZEDQA rt_kbmap PASS Keyboard map: the new key is lit on the drawn keyboard | rgb 26 102 85
ZEDQA rt_kbmap PASS Keyboard map: a key given two jobs is a clash in read() | Toggle Music and Toggle Survival Guide on 59
ZEDQA rt_kbmap PASS Keyboard map: a clash is drawn in the bad color (getBadHighlitedColor) on its key | rgb 255 0 0, bad rgb 255 0 0
ZEDQA rt_kbmap PASS Keyboard map: both clashing actions' key boxes are edged in the bad color | Toggle Music true, Toggle Survival Guide true
ZEDQA rt_kbmap PASS Keyboard map: the clash clears once the key is put back | clash nil
ZEDQA rt_kbmap click on Toggle Music's box at 718,1514.0703125 (body 46+2005, scroll 3463.91015625): down bind, listening nil -> Toggle Music
ZEDQA rt_kbmap PASS Keyboard map keys: a click on an action's key box starts the wait | Toggle Music
ZEDQA rt_kbmap PASS Keyboard map keys: while the map waits for a key, the game's Lua key events are off | listening Toggle Music, keys off true, setter last false
ZEDQA rt_kbmap PASS Keyboard map keys: GameKeyboard.setDoLuaKeyPressed(false) was called | false
ZEDQA rt_kbmap PASS Keyboard map keys: Escape ends the wait, leaves the key as it was, and gives the game its keys back | listening nil, keys off false, setter last true
ZEDQA rt_kbmap click on Toggle Music's box at 718,1514.0703125 (body 46+2005, scroll 3463.91015625): down bind, listening nil -> Toggle Music
ZEDQA rt_kbmap click on Toggle Music's box at 718,1514.0703125 (body 46+2005, scroll 3463.91015625): down bind, listening Toggle Music -> Toggle Music
ZEDQA rt_kbmap FAIL Keyboard map keys: a second click on the box ends the wait and gives the game its keys back | listening Toggle Music, keys off true
ZEDQA rt_kbmap click on Toggle Music's box at 718,1514.0703125 (body 46+2005, scroll 3463.91015625): down bind, listening Toggle Music -> Toggle Music
ZEDQA rt_kbmap PASS Keyboard map keys: closing the map mid-wait gives the game its keys back | setter last true
ZEDQA rt_kbmap PASS Keyboard map: the first Reset press asks and changes nothing yet | clicked true, Toggle Music on 40
ZEDQA rt_kbmap PASS Keyboard map: the Reset button reads Press again to reset | Press again to reset / danger
ZEDQA rt_kbmap PASS Keyboard map: a second Reset press at once (a double click) changes nothing | Toggle Music on 40, was 40
ZEDQA rt_kbmap PASS Keyboard map: a second Reset press half a second on puts every key back to the game's own | 83 bindings
ZEDQA rt_kbmap PASS Keyboard map: keysB42.ini holds the game's own keys after the reset |
ZEDQA rt_kbmap PASS put back: every binding as the director had it (getCore():getKey) | 4 set back
ZEDQA rt_kbmap PASS put back: keysB42.ini line for line as found | 95 lines, 95 before
ZEDQA rt_kbmap PASS put back: the keyboard map is shut
ZEDQA rt_kbmap PASS put back: the windows open or shut as found
ZEDQA rt_kbmap PASS the keyboard map ran with no Lua error | 0 new
ZEDQA rt_kbmap end: 31 pass, 1 fail, 0 skipped
ZEDQA rt_kbmap VERDICT FAIL 1
ZEDQA rt_kbmap DONE
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
