# ZeD-UI regression - 2026-11-04 21:12 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-04 21:12:52 |
| Finished | 2026-11-04 21:18:37 (5 min 45 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/perf_motion.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 20861 to 20863 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 20862, 20863)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | perf_motion.lua | pmo | PASS | 258 |  |  |

## Scripts

### 1. perf_motion.lua (`ZEDQA pmo`) - PASS, 258 s

- go 20861 at 21:13:55

```text
[ZeD.QA] state #1 speed=1 paused=false player=929,13042 grid=19 inCar=false vehicles=33 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pmo start
[ZeD.QA] run #1 ok=true
ZEDQA pmo ui zed, session solo; to the mall
ZEDQA pmo line 13922,5780 to 13922,5803 (28 containers along it)
ZEDQA pmo RES|zed|solo|1|hud_still|2388|119.4|8.37|8|11|12|37|5|0|0
ZEDQA pmo RES|zed|solo|1|win_still|2345|117.2|8.52|9|17|19|43|5|0|0
ZEDQA pmo RES|zed|solo|1|hud_walk|3514|117.1|8.54|8|12|16|41|6|0|0
ZEDQA pmo RES|zed|solo|1|win_walk|3551|118.4|8.45|8|12|14|35|3|0|0
ZEDQA pmo RES|zed|solo|2|hud_still|2389|119.4|8.37|8|11|13|38|2|0|0
ZEDQA pmo RES|zed|solo|2|win_still|2374|118.7|8.42|9|16|18|32|0|0|0
ZEDQA pmo RES|zed|solo|2|hud_walk|3556|118.5|8.44|8|12|15|37|3|0|0
ZEDQA pmo RES|zed|solo|2|win_walk|3554|118.5|8.44|8|12|14|37|3|0|0
ZEDQA pmo DONE
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
