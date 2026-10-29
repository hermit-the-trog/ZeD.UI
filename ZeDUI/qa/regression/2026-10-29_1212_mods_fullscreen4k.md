# ZeD-UI regression - 2026-10-29 12:12 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 12:12:57 |
| Finished | 2026-10-29 12:15:10 (2 min 12 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/capacity_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 15700 to 15703 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15702, 15703)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_capacity.lua | cci | PASS | 6 | zqa_cci_strip.png, zqa_cci_strip_full.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 15700 at 12:14:26

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 869,13025,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:270 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:271 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_capacity.lua (`ZEDQA cci`) - PASS, 6 s

- go 15701 at 12:14:33
- screenshots: zqa_cci_strip.png, zqa_cci_strip_full.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cci start
[ZeD.QA] run #2 ok=true
ZEDQA cci decorators: char 1 world 1
ZEDQA cci start: bag 0.015 bed 0.002 (capacity 13 / 110)
ZEDQA cci staged: bag 0.796 bed 0.200
ZEDQA cci decorated: bag true main true bed true
ZEDQA cci bag 0.796 band warning bar 51 filled 37 | bed 0.200 band positive bar 51 filled 9
ZEDQA cci bag filled on to 0.969
ZEDQA cci bag 0.969 band danger
ZEDQA cci checks done
ZEDQA cci DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
