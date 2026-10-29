# ZeD-UI regression - 2026-10-29 11:55 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 11:55:14 |
| Finished | 2026-10-29 11:57:35 (2 min 21 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/woundexp_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 15671 to 15674 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15673, 15674)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_woundexp.lua | wx | PASS | 7 | zqa_wx_part.png, zqa_wx_menu.png, zqa_wx_healed.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 15671 at 11:56:43

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 869,13024,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:293 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:295 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_woundexp.lua (`ZEDQA wx`) - PASS, 7 s

- go 15672 at 11:56:51
- screenshots: zqa_wx_part.png, zqa_wx_menu.png, zqa_wx_healed.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wx start
[ZeD.QA] run #2 ok=true
ZEDQA wx health extras 1 [WoundExpansion] | mod support true | the mod's table true
ZEDQA wx ok the extra is registered
ZEDQA wx ok a bare arm part to use
ZEDQA wx part Left Forearm (index 2) | mod record before: false | words: Sprain, Bruised, Splint Sprain
ZEDQA wx ok before: no lines for the bare part
ZEDQA wx ok before: the tab's data has none either
ZEDQA wx added Sprain and Bruised to Left Forearm
ZEDQA wx the mod's lines: Sprain[warning], Bruised[warning]
ZEDQA wx ok two lines
ZEDQA wx ok first the wound in the mod's word (Sprain)
ZEDQA wx ok then the condition in the mod's word (Bruised)
ZEDQA wx ok each has a colour
ZEDQA wx colours: Sprain 0.89,0.28,0.28 | Bruised 0.72,0.45,0.85
ZEDQA wx ok the tab's data carries both lines
ZEDQA wx ok the injury list has the part
ZEDQA wx list tags: Sprain, Bruised
ZEDQA wx ok the list tags carry the mod's words
ZEDQA wx ok counted as injured
ZEDQA wx focus on Left Forearm true
ZEDQA wx tab health | active part Left Forearm | extra lines shown 2
ZEDQA wx ok the detail view is on the part
ZEDQA wx ok the detail view shows the mod's two lines
ZEDQA wx ok opening the part's menu raises no error
ZEDQA wx menu rows: Cheat, Wound Expansion, Splint Sprain
ZEDQA wx ok the mod's 'Splint Sprain' entry is in the menu
ZEDQA wx ok healed: no lines
ZEDQA wx ok healed: the tab's data has none
ZEDQA wx ok healed: no tags from the mod in the list
ZEDQA wx healed: extra lines shown 0
ZEDQA wx ok healed: the detail view shows none
ZEDQA wx DONE
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
```
