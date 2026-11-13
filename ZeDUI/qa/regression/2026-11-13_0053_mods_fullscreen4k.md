# ZeD-UI regression - 2026-11-13 00:53 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-13 00:53:45 |
| Finished | 2026-11-13 00:55:04 (1 min 19 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\_b14_lc_manifest.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 26201 to 26203 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26202, 26203)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | _b14_lc.lua | lc | PASS | 4 | zqa_lcr_lc93_rows.png |  |

## Scripts

### 1. _b14_lc.lua (`ZEDQA lc`) - PASS, 4 s

- go 26201 at 00:54:37
- screenshots: zqa_lcr_lc93_rows.png

```text
ZEDQA lc console in use: LC93's (LC93=true ZeD=false)
ZEDQA lc armed
[ZeD.QA] run #1 ok=true
ZEDQA lc open=true
ZEDQA lc row print [hello] mod=#game
ZEDQA lc row ran [> print("hello")] mod=#console
ZEDQA lc print(hello): print rows = 1 (expect 1); ran rows holding the line = 1 (expect 1)
ZEDQA lc ran row [> print("hello")]
ZEDQA lc row print [a b] mod=#game
ZEDQA lc print(a,b): print rows = 1 (expect 1)
ZEDQA lc scratch run sent
ZEDQA lc row print [s1] mod=#console
ZEDQA lc row ran [> print("s1")] mod=#console
ZEDQA lc scratch print(s1): print rows = 1 (expect 1); ran rows holding it = 1
ZEDQA lc shot rows
ZEDQA lc DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    3x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
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
