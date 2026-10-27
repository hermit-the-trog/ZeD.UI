# ZeD-UI regression - 2026-10-27 08:07 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-27 08:07:07 |
| Finished | 2026-10-27 08:09:19 (2 min 12 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\framed_ring.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 14289 to 14292 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 14291, 14292)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_framed_ring.lua | fr | PASS | 21 | zqa_fr_01_dark_small.png, zqa_fr_02_low.png, zqa_fr_03_hicon.png, zqa_fr_04_dark_large.png, zqa_fr_07_both_hands.png, zqa_fr_05_bar_queue.png, zqa_fr_06_bar_done.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 14289 at 08:08:22

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_framed_ring.lua (`ZEDQA fr`) - PASS, 21 s

- go 14290 at 08:08:26
- screenshots: zqa_fr_01_dark_small.png, zqa_fr_02_low.png, zqa_fr_03_hicon.png, zqa_fr_04_dark_large.png, zqa_fr_07_both_hands.png, zqa_fr_05_bar_queue.png, zqa_fr_06_bar_done.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA fr main Base.Hammer off Base.KitchenKnife
ZEDQA fr 01 off x1438 y2041 s91 main x2119 y2041 s91 | main 80 off 50 | dark small hair 2
ZEDQA fr 02 off x1438 y2041 s91 main x2119 y2041 s91 | main 20 off 10 | dark small hair 2
ZEDQA fr 03 off x1438 y2041 s91 main x2119 y2041 s91 | main 80 off 50 | hicon small hair 2
ZEDQA fr 04 off x1374 y2023 s105 main x2139 y2023 s105 | main 80 off 50 | dark large hair 2
ZEDQA fr 07 off x1438 y2041 s91 main x2119 y2041 s91 | main 80 off 50 | dark small hair 2
ZEDQA fr 05 layer x1822 y913 w224 h100 k2 | queue 3 step ISCheckGearAction
ZEDQA fr 06 layer x1822 y913 w224 h100 k2
ZEDQA fr DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
