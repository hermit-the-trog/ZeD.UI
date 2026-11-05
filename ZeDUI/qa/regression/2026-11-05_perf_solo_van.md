# ZeD-UI regression - 2026-11-04 21:18 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-04 21:18:37 |
| Finished | 2026-11-04 21:24:27 (5 min 50 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/you/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/perf_motion.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 20864 to 20866 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 20865, 20866)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | perf_motion.lua | pmo | PASS | 258 |  |  |

## Scripts

### 1. perf_motion.lua (`ZEDQA pmo`) - PASS, 258 s

- go 20864 at 21:19:45

```text
ZEDQA pmo start
[ZeD.QA] run #1 ok=true
ZEDQA pmo ui vanilla, session solo; to the mall
ZEDQA pmo line 13922,5780 to 13922,5803 (28 containers along it)
ZEDQA pmo RES|vanilla|solo|1|hud_still|2400|120.0|8.33|8|11|12|13|0|0|0
ZEDQA pmo RES|vanilla|solo|1|win_still|2399|120.0|8.33|8|14|15|19|0|0|0
ZEDQA pmo RES|vanilla|solo|1|hud_walk|3548|118.3|8.45|8|11|14|78|1|1|0
ZEDQA pmo RES|vanilla|solo|1|win_walk|3553|118.4|8.44|8|13|15|23|0|0|0
ZEDQA pmo RES|vanilla|solo|2|hud_still|2399|120.0|8.33|8|11|12|15|0|0|0
ZEDQA pmo RES|vanilla|solo|2|win_still|2399|120.0|8.33|8|13|14|17|0|0|0
ZEDQA pmo RES|vanilla|solo|2|hud_walk|3568|118.9|8.41|8|11|13|23|0|0|0
ZEDQA pmo RES|vanilla|solo|2|win_walk|3560|118.7|8.43|8|13|15|22|0|0|0
ZEDQA pmo DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
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
