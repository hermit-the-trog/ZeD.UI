# ZeD-UI regression - 2026-10-26 17:28 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 17:28:48 |
| Finished | 2026-10-26 17:31:05 (2 min 17 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/minihealth_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13571 to 13574 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13573, 13574)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_charinfo.lua | ci | PASS | 10 | zqa_ci_click_opens_zed.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 13571 at 17:30:18

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 10 s

- go 13572 at 17:30:23
- screenshots: zqa_ci_click_opens_zed.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #2 ok=true
ZEDQA ci ZeD's Character window hook on: true | Mini Health Panel on: true
ZEDQA ci PASS the game's TOGGLE_HEALTH_PANEL key opens ZeD's health tab (tab health, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_SKILL_PANEL key opens ZeD's skills tab (tab skills, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_INFO_PANEL key opens ZeD's identity tab (tab identity, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_CLOTHING_PROTECTION_PANEL key opens ZeD's equip tab (tab equip, the game's window shown false)
ZEDQA ci PASS the same key again folds the tab (tab loot)
ZEDQA ci clicked the mini panel (windows open on health)
ZEDQA ci PASS Mini Health Panel's click opens ZeD's Health tab (tab health, the game's window shown false)
ZEDQA ci PASS it came through the game's toggleView (Health -> health)
ZEDQA ci PASS a second click folds Health (tab loot)
ZEDQA ci PASS both windows shut
ZEDQA ci PASS with the windows shut, the click opens them on Health
ZEDQA ci PASS the windows are still
ZEDQA ci PASS the windows open on Health, the game's window shut (shown false)
ZEDQA ci rect click_opens_zed char 294 0 1617 735
ZEDQA ci rect click_opens_zed mhp 25 784 120 271
ZEDQA ci mini panel visible true, in the UI true
ZEDQA ci shot zqa_ci_click_opens_zed.png
ZEDQA ci all checks passed
ZEDQA ci DONE
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
