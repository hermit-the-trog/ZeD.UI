# ZeD-UI regression - 2026-11-08 20:49 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-08 20:49:57 |
| Finished | 2026-11-08 20:54:41 (4 min 44 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta10 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b10_perf_gbub_manifest.txt (4 scripts) |
| Result | **3/4 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 24244 to 24247 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_guide_bubble.lua: the game closed during this script
- quit: the game was not running
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | suite_perf.lua | perf | PASS | 40 |  |  |
| 4 | zedqa_guide_bubble.lua | gbub | **FAIL** | 174 | zqa_gbub_3840x2160_2_bubble_from_belt.png | no DONE; the game closed during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 24244 at 20:50:54

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 24245 at 20:51:00

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. suite_perf.lua (`ZEDQA perf`) - PASS, 40 s

- go 24246 at 20:51:04

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA perf char loot avg=11.51ms/tick max=23ms
ZEDQA perf char equip avg=20.27ms/tick max=38ms
ZEDQA perf char health avg=14.79ms/tick max=25ms
ZEDQA perf char thermal avg=14.89ms/tick max=24ms
ZEDQA perf char identity avg=17.52ms/tick max=29ms
ZEDQA perf char journal avg=12.24ms/tick max=23ms
ZEDQA perf char skills avg=16.83ms/tick max=24ms
ZEDQA perf world craft avg=13.18ms/tick max=32ms
ZEDQA perf world build avg=12.74ms/tick max=22ms
ZEDQA perf world maps avg=15.04ms/tick max=29ms
ZEDQA perf world forage avg=14.42ms/tick max=22ms
ZEDQA perf world animals avg=10.82ms/tick max=22ms
ZEDQA perf world loot avg=10.39ms/tick max=20ms
ZEDQA perf world craft build: 7 elements, 0.03 ms per build
ZEDQA perf done
```

### 4. zedqa_guide_bubble.lua (`ZEDQA gbub`) - FAIL, 174 s

- go 24247 at 20:51:47
- no DONE
- the game closed during this script
- screenshots: zqa_gbub_3840x2160_2_bubble_from_belt.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gbub start
[ZeD.QA] run #4 ok=true
ZEDQA gbub PASS 1: a fresh machine arms the clock
ZEDQA gbub PASS 1: the guide is not open 20 s after the start (it used to open full screen)
ZEDQA gbub PASS 1: no bubble before 30 s
ZEDQA gbub PASS 2: the bubble is up at about 30 s of play
ZEDQA gbub PASS 2: the director's wording exactly, with F1
ZEDQA gbub PASS 2: a long bare balloon for player one
ZEDQA gbub PASS 2: the line is in Messages, unread
ZEDQA gbub PASS 2: the flag file says shown
ZEDQA gbub PASS 2: the guide is still closed
ZEDQA gbub shot 2_bubble_from_belt
ZEDQA gbub PASS 3: the balloon has a click
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
