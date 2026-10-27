# ZeD-UI regression - 2026-10-26 10:41 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 10:41:58 |
| Finished | 2026-10-26 10:44:11 (2 min 12 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/drawprobe_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13298 to 13301 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13300, 13301)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_drawprobe.lua | dp | PASS | 3 | zqa_dp.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13298 at 10:43:29

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_drawprobe.lua (`ZEDQA dp`) - PASS, 3 s

- go 13299 at 10:43:34
- screenshots: zqa_dp.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dp start
[ZeD.QA] run #2 ok=true
ZEDQA dp def c zombie.worldMap.symbols.MapSymbolDefinitions$MapSymbolDefinition@7ff2d082 tex media/ui/maps/symbols/solid-circle.png w 20 h 20
ZEDQA dp def Skull 20
ZEDQA dp worldScale 1.959128975868225 zoom 17
ZEDQA dp c scale 0.167 visible true dispW 0 dispH 0 at 493,279
ZEDQA dp Skull scale 0.167 visible true dispW 0 dispH 0 at 493,319
ZEDQA dp c scale 0.666 visible true dispW 0 dispH 0 at 512,279
ZEDQA dp Skull scale 0.666 visible true dispW 0 dispH 0 at 512,319
ZEDQA dp c scale 2.000 visible true dispW 0 dispH 0 at 532,279
ZEDQA dp Skull scale 2.000 visible true dispW 0 dispH 0 at 532,319
ZEDQA dp DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    4x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at CellLoader.DoTileObjectCreation > CellLoader> missing tile vegetation_groundcover_01_22
    1x ERROR: General f:N at CellLoader.DoTileObjectCreation > CellLoader> missing tile vegetation_groundcover_01_23
    1x ERROR: General f:N at CellLoader.DoTileObjectCreation > CellLoader> missing tile vegetation_groundcover_01_19
    1x ERROR: General f:N at CellLoader.DoTileObjectCreation > CellLoader> missing tile vegetation_groundcover_01_18
    1x ERROR: General f:N at CellLoader.DoTileObjectCreation > CellLoader> missing tile vegetation_groundcover_01_21
```
