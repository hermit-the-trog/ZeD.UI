# ZeD-UI regression - 2026-11-20 02:49 - windowed (1280x720 window)

| | |
|---|---|
| Started | 2026-11-20 02:49:31 |
| Finished | 2026-11-20 02:51:21 (1 min 50 s) |
| Mode | windowed (1280x720 window) |
| Display | fontSize=2 fullScreen=false height=720 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\deep_large_shots.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30625 to 30630 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x720 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x720; pointer parked at (2565,1474)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30629, 30630)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_cfg_large.lua | cfl | PASS | 1 |  |  |
| 3 | zedqa_style_lite.lua | stl | PASS | 1 |  |  |
| 4 | deep_large_shots.lua | dls | PASS | 5 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 30625 at 02:50:36

```text
[ZeD.QA] state #1 speed=1 paused=false player=911,13039 grid=13 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 911,13039,0 to the drag strip
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 360,0 276x315 rolled false pinned true/true
ZEDQA pre layout world 644,0 276x315 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_cfg_large.lua (`ZEDQA cfl`) - PASS, 1 s

- go 30626 at 02:50:45

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=13 inCar=false vehicles=3 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA cfl PASS set textSize=2 | now light large lite false
ZEDQA cfl DONE
```

### 3. zedqa_style_lite.lua (`ZEDQA stl`) - PASS, 1 s

- go 30627 at 02:50:49

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=13 inCar=false vehicles=3 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stl Style Lite set true, lite() true
[ZeD.QA] run #3 ok=true
ZEDQA stl DONE
```

### 4. deep_large_shots.lua (`ZEDQA dls`) - PASS, 5 s

- go 30628 at 02:50:53

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=13 inCar=false vehicles=3 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dls start
[ZeD.QA] run #4 ok=true
ZEDQA dls PASS windows open true
ZEDQA dls shot dls_inv at 1280x720, size large, lite true
ZEDQA dls PASS keyboard map open
ZEDQA dls shot dls_kbmap at 1280x720, size large, lite true
ZEDQA dls PASS ZeD setup open
ZEDQA dls shot dls_setup at 1280x720, size large, lite true
ZEDQA dls DONE
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
