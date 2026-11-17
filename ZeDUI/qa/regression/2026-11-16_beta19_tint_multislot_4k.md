# ZeD-UI regression - 2026-11-16 22:46 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-16 22:46:20 |
| Finished | 2026-11-16 22:48:12 (1 min 52 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b19_tint.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 10000 to 10003 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam -cachedir=%USERPROFILE%\ZomboidBranch (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10002, 10003)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b19_tint.lua | b19t | **FAIL** | 16 | zqa_b19t_off_dark.png, zqa_b19t_dark_on.png, zqa_b19t_dark_hover.png, zqa_b19t_light_on.png, zqa_b19t_light_hover.png, zqa_b19t_hicon_on.png, zqa_b19t_hicon_hover.png | 1 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 22:47:28

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
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\ZomboidBranch\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_b19_tint.lua (`ZEDQA b19t`) - FAIL, 16 s

- go 10001 at 22:47:33
- 1 Java exception(s) in the log
- screenshots: zqa_b19t_off_dark.png, zqa_b19t_dark_on.png, zqa_b19t_dark_hover.png, zqa_b19t_light_on.png, zqa_b19t_light_hover.png, zqa_b19t_hicon_on.png, zqa_b19t_hicon_hover.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b19t start
[ZeD.QA] run #2 ok=true
ERROR: General f:440> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:27)
    Lua(Vanilla).step(spawnpoints.lua:27)
    Lua(Vanilla).tick(spawnpoints.lua:100)
ZEDQA b19t as found: 1, default nil
ZEDQA b19t PASS the choice is off as found (1)
ZEDQA b19t PASS off: an axe tile has no tint
ZEDQA b19t shot zqa_b19t_off_dark
ZEDQA b19t PASS dark: on, the axe tile has a tint
ZEDQA b19t PASS dark: the axe tile's lightness 0.17 near 0.17 (r 0.22 g 0.13 b 0.12)
ZEDQA b19t PASS dark: no texture, no tint
ZEDQA b19t shot zqa_b19t_dark_on
ZEDQA b19t shot zqa_b19t_dark_hover
ZEDQA b19t PASS light: on, the axe tile has a tint
ZEDQA b19t PASS light: the axe tile's lightness 0.74 near 0.74 (r 0.82 g 0.68 b 0.66)
ZEDQA b19t PASS light: no texture, no tint
ZEDQA b19t shot zqa_b19t_light_on
ZEDQA b19t shot zqa_b19t_light_hover
ZEDQA b19t PASS hicon: on, the axe tile has a tint
ZEDQA b19t PASS hicon: the axe tile's lightness 0.13 near 0.13 (r 0.18 g 0.09 b 0.08)
ZEDQA b19t PASS hicon: no texture, no tint
ZEDQA b19t shot zqa_b19t_hicon_on
ZEDQA b19t shot zqa_b19t_hicon_hover
ZEDQA b19t put back: choice 1, theme light
ZEDQA b19t all checks passed
ZEDQA b19t DONE
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
