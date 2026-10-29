# ZeD-UI regression - 2026-10-29 11:40 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 11:40:52 |
| Finished | 2026-10-29 11:43:05 (2 min 13 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/moodle_quarters_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 15655 to 15658 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15657, 15658)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_moodle_quarters.lua | mq | PASS | 15 | zqa_mq_right.png, zqa_mq_right_hover.png, zqa_mq_left.png, zqa_mq_left_hover.png, zqa_mq_bottom.png, zqa_mq_bottom_hover.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 15655 at 11:42:16

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_moodle_quarters.lua (`ZEDQA mq`) - PASS, 15 s

- go 15656 at 11:42:20
- screenshots: zqa_mq_right.png, zqa_mq_right_hover.png, zqa_mq_left.png, zqa_mq_left_hover.png, zqa_mq_bottom.png, zqa_mq_bottom_hover.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mq start
[ZeD.QA] run #2 ok=true
ZEDQA mq 90 frames on: moodles on 0; god true
ZEDQA mq 180 frames on: moodles on 4 (TIRED, HUNGRY, STRESS, THIRST)
ZEDQA mq PASS the mod's panel is up and drawing for the player
ZEDQA mq PASS ZeD knows the mod draws the moodles (stand-in)
ZEDQA mq PASS right: the mod's slide in has settled
ZEDQA mq right: 4 moodles on (TIRED, HUNGRY, STRESS, THIRST); the mod's order (TIRED, HUNGRY, STRESS, THIRST)
ZEDQA mq PASS right: the place is in effect (ZeD's rect)
ZEDQA mq PASS right: at least four moodles are on
ZEDQA mq PASS right: ZeD knows the mod draws the moodles
ZEDQA mq right: ZeD's moodles 3782,969 48x222 (size 48, 4 on); the mod's panel 3782,969 48x232, 4 slots, visible true
ZEDQA mq PASS right: the mod's panel has a size
ZEDQA mq PASS right: the mod's panel starts where ZeD put the moodles
ZEDQA mq PASS right: the mod's panel is ZeD's column
ZEDQA mq PASS right: on the right edge (x 3782)
ZEDQA mq PASS right: every moodle is on screen
ZEDQA mq PASS right: one of the mod's slots per moodle ZeD placed
ZEDQA mq PASS right: the mod's moodle size is ZeD's (48)
ZEDQA mq PASS right: the mod drew a plate and an icon per moodle (8 drawn)
ZEDQA mq right: the mod's plates reach 0,0 to 48,222 inside its panel
ZEDQA mq PASS right: every plate lies inside the panel (give or take the mod's wiggle, 16 sideways)
ZEDQA mq PASS right: ZeD lists the moodles in the mod's order
ZEDQA mq right note: for HUNGRY, the mod's moodle 2 is HUNGRY
ZEDQA mq PASS right: the note is for the moodle the mod drew under the pointer
ZEDQA mq PASS left: the mod's slide in has settled
ZEDQA mq left: 4 moodles on (TIRED, HUNGRY, STRESS, THIRST); the mod's order (TIRED, HUNGRY, STRESS, THIRST)
ZEDQA mq PASS left: the place is in effect (ZeD's rect)
ZEDQA mq PASS left: at least four moodles are on
ZEDQA mq PASS left: ZeD knows the mod draws the moodles
ZEDQA mq left: ZeD's moodles 10,969 48x222 (size 48, 4 on); the mod's panel 10,969 48x232, 4 slots, visible true
ZEDQA mq PASS left: the mod's panel has a size
ZEDQA mq PASS left: the mod's panel starts where ZeD put the moodles
ZEDQA mq PASS left: the mod's panel is ZeD's column
ZEDQA mq PASS left: on the left edge (x 10)
ZEDQA mq PASS left: every moodle is on screen
ZEDQA mq PASS left: one of the mod's slots per moodle ZeD placed
ZEDQA mq PASS left: the mod's moodle size is ZeD's (48)
ZEDQA mq PASS left: the mod drew a plate and an icon per moodle (8 drawn)
ZEDQA mq left: the mod's plates reach 0,0 to 48,222 inside its panel
ZEDQA mq PASS left: every plate lies inside the panel (give or take the mod's wiggle, 16 sideways)
ZEDQA mq PASS left: ZeD lists the moodles in the mod's order
ZEDQA mq left note: for HUNGRY, the mod's moodle 2 is HUNGRY
ZEDQA mq PASS left: the note is for the moodle the mod drew under the pointer
ZEDQA mq PASS bottom: the mod's slide in has settled
ZEDQA mq bottom: 4 moodles on (TIRED, HUNGRY, STRESS, THIRST); the mod's order (TIRED, HUNGRY, STRESS, THIRST)
ZEDQA mq PASS bottom: the place is in effect (ZeD's rect)
ZEDQA mq PASS bottom: at least four moodles are on
ZEDQA mq PASS bottom: ZeD knows the mod draws the moodles
ZEDQA mq bottom: ZeD's moodles 1809,1965 222x48 (size 48, 4 on); the mod's panel 1809,1965 222x48, 4 slots, visible true
ZEDQA mq PASS bottom: the mod's panel has a size
ZEDQA mq PASS bottom: the mod's panel starts where ZeD put the moodles
ZEDQA mq PASS bottom: the mod's panel is ZeD's row, exactly
ZEDQA mq PASS bottom: the row is centred
ZEDQA mq PASS bottom: the row sits above the belt
ZEDQA mq PASS bottom: every moodle is on screen
ZEDQA mq PASS bottom: one of the mod's slots per moodle ZeD placed
ZEDQA mq PASS bottom: the mod's moodle size is ZeD's (48)
ZEDQA mq PASS bottom: the mod drew a plate and an icon per moodle (8 drawn)
ZEDQA mq bottom: the mod's plates reach 0,0 to 222,48 inside its panel
ZEDQA mq PASS bottom: every plate lies inside the panel (give or take the mod's wiggle, 16 sideways)
ZEDQA mq PASS bottom: ZeD lists the moodles in the mod's order
ZEDQA mq PASS bottom: ZeD draws no copy of its own (0 frames drawn)
ZEDQA mq bottom note: for HUNGRY, the mod's moodle 2 is HUNGRY
ZEDQA mq PASS bottom: the note is for the moodle the mod drew under the pointer
ZEDQA mq all checks passed
ZEDQA mq DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
