# ZeD-UI regression - 2026-10-24 17:44 - windowed (1920x1080 window)

| | |
|---|---|
| Started | 2026-10-24 17:44:31 |
| Finished | 2026-10-24 17:49:02 (4 min 30 s) |
| Mode | windowed (1920x1080 window) |
| Display | fullScreen=false height=1080 width=1920 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\offsave\2026-10-24_1744\before_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 0 fail, 1 timeout |
| Go numbers | 11996 to 11999 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1080p window) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1920x1080
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_offsave.lua: no DONE within 180 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 11998, 11999)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_offsave.lua | off | **TIMEOUT** | 181 | zqa_off_before.png | no DONE within 180 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 11996 at 17:45:33

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre DONE
```

### 2. zedqa_offsave.lua (`ZEDQA off`) - TIMEOUT, 181 s

- go 11997 at 17:45:38
- no DONE within 180 s; the script may still be running in the game
- screenshots: zqa_off_before.png

```text
[ZeD.QA] windows reset (R)
ZEDQA off before worn Timez true
ZEDQA off before Timez in Base.Bag_Schoolbag true
ZEDQA off before items 46, worn 9, written zedqa_off_before.txt
ZEDQA off before ZeD_UI active true
ZEDQA off before DONE
[ZeD.QA] run #2 ok=true
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
```
