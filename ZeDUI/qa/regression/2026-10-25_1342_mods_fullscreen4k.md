# ZeD-UI regression - 2026-10-25 13:42 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 13:42:55 |
| Finished | 2026-10-25 13:45:23 (2 min 28 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/spncc_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 12744 to 12747 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 12746, 12747)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_spncc.lua | spn | PASS | 23 | zqa_spn_first.png, zqa_spn_picked.png, zqa_spn_saved.png, zqa_spn_list.png, zqa_spn_list_unsaved.png, zqa_spn_default.png, zqa_spn_spiffo.png, zqa_spn_choice.png, zqa_spn_shaving.png, zqa_spn_pad.png, zqa_spn_large.png, zqa_spn_light.png |  |
| 2 | zedqa_spncc_figs.lua | spf | PASS | 11 | zqa_spf_1s.png, zqa_spf_3s.png, zqa_spf_6s.png, zqa_spf_10s.png |  |

## Scripts

### 1. zedqa_spncc.lua (`ZEDQA spn`) - PASS, 23 s

- go 12744 at 13:44:18
- screenshots: zqa_spn_first.png, zqa_spn_picked.png, zqa_spn_saved.png, zqa_spn_list.png, zqa_spn_list_unsaved.png, zqa_spn_default.png, zqa_spn_spiffo.png, zqa_spn_choice.png, zqa_spn_shaving.png, zqa_spn_pad.png, zqa_spn_large.png, zqa_spn_light.png

```text
[ZeD.QA] windows reset (R)
ZEDQA spn start
[ZeD.QA] run #1 ok=true
ZEDQA spn data true hasCustomised false first true tab loot
ZEDQA spn PASS the Character window is open on Appearance
ZEDQA spn PASS the first-time look (Save only)
ZEDQA spn PASS the game is paused while it is open
ZEDQA spn PASS faces listed: 7
ZEDQA spn details listed: 0
ZEDQA spn PASS no Cancel the first time
ZEDQA spn PASS Save is a stop the first time
ZEDQA spn PASS the mod's own window is not open
ZEDQA spn shot zqa_spn_first.png
ZEDQA spn picked Chuck + nil
ZEDQA spn PASS the face pick is held
ZEDQA spn shot zqa_spn_picked.png
ZEDQA spn PASS the mod's data says customised
ZEDQA spn PASS the mod's data has the face: Chuck
ZEDQA spn PASS the first-time look is over
ZEDQA spn PASS the game runs again
ZEDQA spn PASS nothing to save or cancel after Save
ZEDQA spn shot zqa_spn_saved.png
ZEDQA spn PASS list rows are stops
ZEDQA spn shot zqa_spn_list.png
ZEDQA spn PASS Cancel appears with an unsaved pick
ZEDQA spn shot zqa_spn_list_unsaved.png
ZEDQA spn PASS Cancel puts the saved face back
ZEDQA spn PASS the face and details are read-only
ZEDQA spn PASS no face stops when read-only
ZEDQA spn PASS no Save when nothing can change
ZEDQA spn PASS Shave (beard stubble) is a stop
ZEDQA spn shot zqa_spn_default.png
ZEDQA spn PASS the Spiffo opens the face
ZEDQA spn shot zqa_spn_spiffo.png
ZEDQA spn PASS player choice: Muscle and Body Hair Growth
ZEDQA spn shot zqa_spn_choice.png
ZEDQA spn queue after Shave: 1
ZEDQA spn PASS Shave queued the mod's action
ZEDQA spn shot zqa_spn_shaving.png
ZEDQA spn PASS focus lands on a face
ZEDQA spn after right: spn:face:Chris
ZEDQA spn PASS D-pad right stays in the tab
ZEDQA spn after down: spn:face:Hank
ZEDQA spn shot zqa_spn_pad.png
ZEDQA spn shot zqa_spn_large.png
ZEDQA spn shot zqa_spn_light.png
ZEDQA spn all checks passed
ZEDQA spn DONE
```

### 2. zedqa_spncc_figs.lua (`ZEDQA spf`) - PASS, 11 s

- go 12745 at 13:44:45
- screenshots: zqa_spf_1s.png, zqa_spf_3s.png, zqa_spf_6s.png, zqa_spf_10s.png

```text
[ZeD.QA] windows reset (R)
ZEDQA spf start
[ZeD.QA] run #2 ok=true
ZEDQA spf 1s preview x=82 y=159 w=261 h=387 lua=true java=true
ZEDQA spf 1s tile1:DefaultFace x=366 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 1s tile2:Chris x=499 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 1s tile3:Chuck x=632 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 1s tile4:Frank x=366 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 1s tile5:Hank x=499 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 1s tile6:James x=632 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 3s preview x=82 y=159 w=261 h=387 lua=true java=true
ZEDQA spf 3s tile1:DefaultFace x=366 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 3s tile2:Chris x=499 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 3s tile3:Chuck x=632 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 3s tile4:Frank x=366 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 3s tile5:Hank x=499 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 3s tile6:James x=632 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 6s preview x=82 y=159 w=261 h=387 lua=true java=true
ZEDQA spf 6s tile1:DefaultFace x=366 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 6s tile2:Chris x=499 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 6s tile3:Chuck x=632 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 6s tile4:Frank x=366 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 6s tile5:Hank x=499 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 6s tile6:James x=632 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 10s preview x=82 y=159 w=261 h=387 lua=true java=true
ZEDQA spf 10s tile1:DefaultFace x=366 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 10s tile2:Chris x=499 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 10s tile3:Chuck x=632 y=199 w=117 h=125 lua=true java=true
ZEDQA spf 10s tile4:Frank x=366 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 10s tile5:Hank x=499 y=368 w=117 h=125 lua=true java=true
ZEDQA spf 10s tile6:James x=632 y=368 w=117 h=125 lua=true java=true
ZEDQA spf DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
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
