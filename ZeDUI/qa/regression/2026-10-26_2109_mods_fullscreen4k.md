# ZeD-UI regression - 2026-10-26 21:10 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 21:10:03 |
| Finished | 2026-10-26 21:12:10 (2 min 7 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_srm.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 13809 to 13812 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13811, 13812)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_srm.lua | srm | **FAIL** | 3 | zqa_srm_on.png | 1 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13809 at 21:11:33

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_srm.lua (`ZEDQA srm`) - FAIL, 3 s

- go 13810 at 21:11:38
- 1 Java exception(s) in the log
- screenshots: zqa_srm_on.png

```text
[ZeD.QA] windows reset (R)
ZEDQA srm start, ZeD true
[ZeD.QA] run #2 ok=true
ERROR: General f:835> Lua((MOD:Smart Radial Menu)).getSliceTooltipUnderMouseFocus> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getSliceTooltipUnderMouseFocus at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Smart Radial Menu)).getSliceTooltipUnderMouseFocus(SRMOverlay.lua:420)
    Lua((MOD:Smart Radial Menu)).updateSelectedSlice(SRMOverlay.lua:870)
    Lua((MOD:Smart Radial Menu)).resetValues(SRMOverlay.lua:890)
    Lua((MOD:Smart Radial Menu)).display(SRMOverlay.lua:895)
    Lua((MOD:Smart Radial Menu)).addToUIManager(SRMMenuObject.lua:629)
ZEDQA srm show false Object tried to call nil in getSliceTooltipUnderMouseFocus java.lang.RuntimeException
ZEDQA srm radial menu ISRadialMenu, javaObject false, visible false
ZEDQA srm DONE
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
